require "../ext/llvm/di_builder"

module Runic
  DW_LANG_C = 0x0002

  DW_ATE_address       = 0x01
  DW_ATE_boolean       = 0x02
  DW_ATE_complex_float = 0x03
  DW_ATE_float         = 0x04
  DW_ATE_signed        = 0x05
  DW_ATE_signed_char   = 0x06
  DW_ATE_unsigned      = 0x07
  DW_ATE_unsigned_char = 0x08

  enum DebugLevel
    None = 0
    Default = 1
    Full = 2
  end

  class Codegen
    abstract class Debug
      getter level

      def initialize(@level : DebugLevel)
      end

      abstract def path=(path : String)
      abstract def flush
      abstract def with_lexical_block(lexical_block, &block)
      abstract def create_subprogram(node : AST::Function, func : LibC::LLVMValueRef, optimized = true)
      abstract def parameter_variable(arg : AST::Variable, arg_no : Int32, alloca : LibC::LLVMValueRef)
      abstract def emit_location(node : AST::Node)

      class NULL < Debug
        def path=(path : String)
        end

        def flush
        end

        def with_lexical_block(lexical_block)
          yield
        end

        def create_subprogram(node : AST::Function, func : LibC::LLVMValueRef, optimized = true)
        end

        def parameter_variable(arg : AST::Variable, arg_no : Int32, alloca : LibC::LLVMValueRef)
        end

        def emit_location(node : AST::Node)
        end
      end

      class DWARF < Debug
        private getter! compile_unit : LibC::LLVMMetadataRef?
        private getter! file : LibC::LLVMMetadataRef?

        def initialize(@module : LibC::LLVMModuleRef, @builder : LibC::LLVMBuilderRef, @context : LibC::LLVMContextRef, @level : DebugLevel)
          @di_builder = LibC.LLVMCreateDIBuilder(@module)
          @lexical_blocks = [] of LibC::LLVMMetadataRef

          return if @level.none?
          add_metadata("llvm.module.flags", LibC::LLVMModFlagBehavior::Warning.value, "Debug Info Version", LibC::LLVM_DEBUG_METADATA_VERSION)

          # if darwin || android
          #  add_metadata("llvm.module.flags", LibC::LLVMModFlagBehavior::Warning.value, "Dwarf Version", 2)
          # end
        end

        private def add_metadata(name, *values)
          refs = values.map do |val|
            case val
            when Int32
              LibC.LLVMConstInt(LibC.LLVMInt32TypeInContext(@context), val, 0)
            when String
              LibC.LLVMMDStringInContext(@context, val.to_unsafe, val.as(String).bytesize)
            else
              raise CodegenError.new("unsupported metadata value: #{val}")
            end
          end.to_a
          metadata = LibC.LLVMMDNodeInContext(@context, refs, refs.size)
          LibC.LLVMAddNamedMetadataOperand(@module, name, metadata)
        end

        def path=(path)
          @compile_unit = LibC.LLVMDIBuilderCreateCompileUnit(
            self,
            DW_LANG_C,
            File.basename(path),
            File.dirname(path),
            "Runic Compiler",
            0, "", 0
          )
          @file = LibC.LLVMDIBuilderCreateFile(self, File.basename(path), File.dirname(path))
        end

        # def finalize
        #   LibC.LLVMDIBuilderDispose(self)
        # end

        def flush
          return if @level.none?
          LibC.LLVMDIBuilderFinalize(self)
        end

        def with_lexical_block(lexical_block : LibC::LLVMMetadataRef)
          @lexical_blocks << lexical_block
          begin
            yield
          ensure
            @lexical_blocks.pop
          end
        end

        def with_lexical_block(lexical_block : Nil, &block)
          raise "unreachable"
        end

        def create_subprogram(node : AST::Function, func : LibC::LLVMValueRef, optimized = true)
          flags = LibC::LLVMDIFlags::FlagPrototyped
          flags |= LibC::LLVMDIFlags::FlagMainSubprogram if node.name == "main"

          LibC.LLVMDIBuilderCreateFunction(
            self,
            file,                # context
            node.name,           # internal name
            node.name,           # mangled symbol
            file,
            node.location.line,
            create_function_type(node),
            false,               # true=internal linkage
            true,                # definition
            node.location.line,
            flags,
            optimized,           # optimized
            func
          )
        end

        private def create_function_type(node : AST::Function)
          types = node.args.map { |arg| di_type(arg) } # args
          types.unshift(di_type(node.type))            # result
          array_element_types = LibC.LLVMDIBuilderGetOrCreateTypeArray(self, types, types.size)
          LibC.LLVMDIBuilderCreateSubroutineType(self, file, array_element_types)
        end

        def parameter_variable(arg : AST::Variable, arg_no : Int32, alloca : LibC::LLVMValueRef)
          return unless @level.full?
          scope = @lexical_blocks.last? || @compile_unit

          di_local_variable = LibC.LLVMDIBuilderCreateParameterVariable(
            self,
            scope,
            arg.name,
            arg_no,
            file,
            arg.location.line,
            di_type(arg),
            1,
            LibC::LLVMDIFlags::FlagZero
          )
          LibC.LLVMDIBuilderInsertDeclareAtEnd(
            self,
            alloca,
            di_local_variable,
            LibC.LLVMDIBuilderCreateExpression(self, nil, 0),
            LibC.LLVMGetCurrentDebugLocation(@builder),
            LibC.LLVMGetInsertBlock(@builder)
          )
        end

        #def di_auto_variable(node, alloca)
        #  return unless @level.full?
        #  scope = @lexical_blocks.last? || compile_unit

        #  di_local_variable = LibC.LLVMDIBuilderCreateAutoVariable(
        #    self,
        #    scope,
        #    node.name,
        #    file,
        #    node.location.line,
        #    di_type(node),
        #    1,
        #    LibC::LLVMDIFlags::FlagZero,
        #    0
        #  )
        #  LibC.LLVMDIBuilderInsertDeclareAtEnd(
        #    self,
        #    alloca,
        #    di_local_variable,
        #    LibC.LLVMDIBuilderCreateExpression(self, nil, 0),
        #    LibC.LLVMGetCurrentDebugLocation(self),
        #    LibC.LLVMGetInsertBlock(self)
        #  )
        #end

        private def di_type(node : AST::Node)
          di_type(node.type)
        end

        # FIXME: alignments are probably TARGET DEPENDENT (and thus WRONG):
        private def di_type(type : String)
          case type
          when "float32"
            LibC.LLVMDIBuilderCreateBasicType(self, "float32", 32, 32, DW_ATE_float)
          when "float64"
            LibC.LLVMDIBuilderCreateBasicType(self, "float64", 64, 64, DW_ATE_float)
          when "int8"
            LibC.LLVMDIBuilderCreateBasicType(self, "int8", 8, 8, DW_ATE_signed)
          when "int16"
            LibC.LLVMDIBuilderCreateBasicType(self, "int16", 16, 16, DW_ATE_signed)
          when "int32"
            LibC.LLVMDIBuilderCreateBasicType(self, "int32", 32, 32, DW_ATE_signed)
          when "int64"
            LibC.LLVMDIBuilderCreateBasicType(self, "int64", 64, 64, DW_ATE_signed)
          when "int128"
            LibC.LLVMDIBuilderCreateBasicType(self, "int128", 128, 128, DW_ATE_signed)
          when "uint8"
            LibC.LLVMDIBuilderCreateBasicType(self, "uint8", 8, 8, DW_ATE_unsigned)
          when "uint16"
            LibC.LLVMDIBuilderCreateBasicType(self, "uint16", 16, 16, DW_ATE_unsigned)
          when "uint32"
            LibC.LLVMDIBuilderCreateBasicType(self, "uint32", 32, 32, DW_ATE_unsigned)
          when "uint64"
            LibC.LLVMDIBuilderCreateBasicType(self, "uint64", 64, 64, DW_ATE_unsigned)
          when "uint128"
            LibC.LLVMDIBuilderCreateBasicType(self, "uint128", 128, 128, DW_ATE_unsigned)
          else
            raise CodegenError.new("unsupported #{type}")
          end
        end

        def emit_location(node : AST::Node)
          scope = @lexical_blocks.last? || compile_unit
          LibC.LLVMSetCurrentDebugLocation2(@builder, node.location.line, node.location.column, scope, nil)
        end

        def to_unsafe
          @di_builder
        end
      end
    end
  end
end
