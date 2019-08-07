require "../codegen"
require "../c/llvm/debug_info"

module Runic
  DW_LANG_C = LibC::LLVMDWARFSourceLanguage.new(0x0001)

  # DWARF Attribute Type Encodings:
  DW_ATE_address       = 0x01
  DW_ATE_boolean       = 0x02
  DW_ATE_complex_float = 0x03
  DW_ATE_float         = 0x04
  DW_ATE_signed        = 0x05
  DW_ATE_signed_char   = 0x06
  DW_ATE_unsigned      = 0x07
  DW_ATE_unsigned_char = 0x08

  # DWARF v3:
  DW_ATE_imaginary_float = 0x09
  DW_ATE_packed_decimal  = 0x0a
  DW_ATE_numeric_string  = 0x0b
  DW_ATE_edited          = 0x0c
  DW_ATE_signed_fixed    = 0x0d
  DW_ATE_unsigned_fixed  = 0x0e
  DW_ATE_decimal_float   = 0x0f

  # DWARF v4:
  DW_ATE_UTF = 0x10

  # DWARF v5:
  DW_ATE_UCS   = 0x11
  DW_ATE_ASCII = 0x12

  enum DebugLevel : UInt32
    None = LibC::LLVMDWARFEmissionKind::DWARFEmissionNone
    Full = LibC::LLVMDWARFEmissionKind::DWARFEmissionFull
    Default = LibC::LLVMDWARFEmissionKind::DWARFEmissionLineTablesOnly

    def to_unsafe
      LibC::LLVMDWARFEmissionKind.new(value)
    end
  end

  class Codegen
    abstract class Debug
      getter level

      def initialize(@level : DebugLevel)
      end

      abstract def path=(value : String)
      abstract def program=(value : Program)
      abstract def codegen=(value : Codegen)
      abstract def flush
      abstract def with_lexical_block(lexical_block, &block)
      abstract def create_subprogram(node : AST::Function, func : LibC::LLVMValueRef)
      abstract def parameter_variable(arg : AST::Variable, arg_no : Int32, alloca : LibC::LLVMValueRef)
      abstract def sret_variable(sret : LibC::LLVMValueRef, type : Type, location : Location)
      abstract def auto_variable(variable : AST::Variable, alloca : LibC::LLVMValueRef)
      abstract def emit_location(node : AST::Node)
      abstract def emit_location(location : Location)

      class NULL < Debug
        def path=(value : String)
        end

        def program=(value : Program)
        end

        def codegen=(value : Codegen)
        end

        def flush
        end

        def with_lexical_block(lexical_block)
          yield
        end

        def create_subprogram(node : AST::Function, func : LibC::LLVMValueRef)
        end

        def sret_variable(sret : LibC::LLVMValueRef, type : Type, location : Location)
        end

        def parameter_variable(arg : AST::Variable, arg_no : Int32, alloca : LibC::LLVMValueRef)
        end

        def auto_variable(variable : AST::Variable, alloca : LibC::LLVMValueRef)
        end

        def emit_location(node : AST::Node)
        end

        def emit_location(node : Location)
        end
      end

      class DWARF < Debug
        private getter! compile_unit : LibC::LLVMMetadataRef?
        property! program : Program?
        property! codegen : Codegen?

        def initialize(@module : LibC::LLVMModuleRef, @builder : LibC::LLVMBuilderRef, @context : LibC::LLVMContextRef, @level : DebugLevel, @optimized = false)
          @di_builder = LibC.LLVMCreateDIBuilder(@module)
          @lexical_blocks = [] of LibC::LLVMMetadataRef
          @structs = {} of String => LibC::LLVMMetadataRef

          return if @level.none?
          add_metadata("llvm.module.flags", LibC::LLVMModuleFlagBehavior::Require.value, "Debug Info Version", LibC.LLVMDebugMetadataVersion())

          #if darwin || android
          #  add_metadata("llvm.module.flags", LibC::LLVMModuleFlagBehavior::Require.value, "Dwarf Version", 2)
          #else
            add_metadata("llvm.module.flags", LibC::LLVMModuleFlagBehavior::Require.value, "Dwarf Version", 4)
          #end
        end

        private def add_metadata(name, *values)
          refs = values.map do |val|
            case val
            when Int32, UInt32
              LibC.LLVMConstInt(LibC.LLVMInt32TypeInContext(@context), val, 0)
            when String
              LibC.LLVMMDStringInContext(@context, val.to_unsafe, val.as(String).bytesize)
            else
              raise CodegenError.new("unsupported metadata value: #{val} (#{typeof(val)})")
            end
          end.to_a
          metadata = LibC.LLVMMDNodeInContext(@context, refs, refs.size)
          LibC.LLVMAddNamedMetadataOperand(@module, name, metadata)
        end

        def path=(path)
          producer = "Runic Compiler"

          @compile_unit = LibC.LLVMDIBuilderCreateCompileUnit(
            self,
            DW_LANG_C,
            di_file(path),
            producer,
            producer.bytesize,
            @optimized ? 1 : 0,
            "", # Flags
            0,  # FlagsLen
            0,  # RuntimeVer
            "", # SplitName
            0,  # SplitNameLen
            @level,
            0,  # DWOId
            0,  # SplitDebugInlining
            0   # DebugInfoForProfiling
          )
        end

        def finalize
          LibC.LLVMDisposeDIBuilder(self)
        end

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

        def create_subprogram(node : AST::Function, func : LibC::LLVMValueRef)
          flags = LibC::LLVMDIFlags::DIFlagPrototyped
          flags |= LibC::LLVMDIFlags::DIFlagMainSubprogram if node.name == "main"

          subprogram = LibC.LLVMDIBuilderCreateFunction(
            self,
            @lexical_blocks.last? || compile_unit, # scope   FIXME: ends up null?
            node.name,                             # internal name
            node.name.bytesize,
            node.symbol_name,                      # symbol (mangled or not)
            node.symbol_name.bytesize,
            di_file(node.location),
            node.location.line,
            create_function_type(node),
            false,                                 # true=internal linkage
            true,                                  # definition
            node.location.line,
            flags,
            @optimized ? 1: 0
          )
          LibC.LLVMSetSubprogram(func, subprogram)

          subprogram
        end

        private def create_function_type(node : AST::Function)
          if @level.full?
            types = Array(LibC::LLVMMetadataRef).new(node.args.size + 1)

            if node.type.aggregate?
              # TODO: unless the struct fits in a register
              types << di_type(node.type) # sret
            end

            # followed by argument types (if any)
            node.args.each do |arg|
              types << di_type(arg)
            end
          else
            types = [] of LibC::LLVMMetadataRef
          end

          LibC.LLVMDIBuilderCreateSubroutineType(self, di_file(node.location), types, types.size, LibC::LLVMDIFlags::DIFlagZero)
        end

        # FIXME: that shouldn't exist but be an actual variable (anonymous or
        #        explicit) whose alloca is the sret parameter
        def sret_variable(sret : LibC::LLVMValueRef, type : Type, location : Location)
          insert_declare_at_end(sret) do
            LibC.LLVMDIBuilderCreateAutoVariable(
              self,
              @lexical_blocks.last? || compile_unit,
              "sret",
              "sret".bytesize,
              di_file(location),
              location.line,
              di_type(type),
              1, # AlwaysPreserve
              LibC::LLVMDIFlags::DIFlagZero,
              0  # AlignInBits
            )
          end
        end

        def parameter_variable(arg : AST::Variable, arg_no : Int32, alloca : LibC::LLVMValueRef)
          insert_declare_at_end(alloca) do
            LibC.LLVMDIBuilderCreateParameterVariable(
              self,
              @lexical_blocks.last? || compile_unit,
              arg.name,
              arg.name.bytesize,
              arg_no,
              di_file(arg.location),
              arg.location.line,
              di_type(arg),
              1, # AlwaysPreserve
              LibC::LLVMDIFlags::DIFlagZero
            )
          end
        end

        def auto_variable(variable : AST::Variable, alloca : LibC::LLVMValueRef)
          insert_declare_at_end(alloca) do
            LibC.LLVMDIBuilderCreateAutoVariable(
              self,
              @lexical_blocks.last? || compile_unit,
              variable.name,
              variable.name.bytesize,
              di_file(variable.location),
              variable.location.line,
              di_type(variable),
              1, # AlwaysPreserve
              LibC::LLVMDIFlags::DIFlagZero,
              0  # AlignInBits
            )
          end
        end

        protected def insert_declare_at_end(alloca : LibC::LLVMValueRef)
          return unless @level.full?

          di_local_variable = yield
          location = LibC.LLVMGetCurrentDebugLocation(@builder)

          LibC.LLVMDIBuilderInsertDeclareAtEnd(
            self,
            alloca,
            di_local_variable,
            LibC.LLVMDIBuilderCreateExpression(self, nil, 0),
            LibC.LLVMValueAsMetadata(location),
            LibC.LLVMGetInsertBlock(@builder)
          )
        end

        private def di_file(location : Location)
          di_file(location.file)
        end

        private def di_file(path : String)
          basename = File.basename(path)
          dirname = File.dirname(path)
          LibC.LLVMDIBuilderCreateFile(self, basename, basename.bytesize, dirname, dirname.bytesize)
        end

        private def di_type(node : AST::Struct) : LibC::LLVMMetadataRef
          @structs[node.name] ||=
            begin
              elements = node.variables.map do |ivar|
                LibC.LLVMDIBuilderCreateMemberType(
                  self,
                  @lexical_blocks.last? || compile_unit, # Scope
                  ivar.name,                             # Name
                  ivar.name.bytesize,                    # NameLen
                  di_file(ivar.location),                # File
                  ivar.location.line,                    # LineNo
                  codegen.sizeof(ivar) * 8,              # SizeInBits
                  0,                                     # AlignInBits
                  codegen.offsetof(node, ivar) * 8,      # OffsetInBits
                  LibC::LLVMDIFlags::DIFlagZero,         # Flags
                  di_type(ivar.type)
                )
              end

              LibC.LLVMDIBuilderCreateStructType(
                self,
                compile_unit,
                node.name,
                node.name.bytesize,
                di_file(node.location),
                node.location.line,
                codegen.sizeof(node) * 8,       # SizeInBits
                0,                              # AlignInBits
                LibC::LLVMDIFlags::DIFlagZero,  # Flags
                nil,                            # DerivedFrom (?)
                elements,                       # Elements
                elements.size,
                0,                              # RunTimeLang (optional)
                nil,                            # VTableHolder (?)
                node.name,                      # UniqueId
                node.name.bytesize
              )
            end
        end

        private def di_type(node : AST::Node) : LibC::LLVMMetadataRef
          di_type(node.type)
        end

        private def di_type(type : Type) : LibC::LLVMMetadataRef
          if type.pointer?
            LibC.LLVMDIBuilderCreatePointerType(
              self,
              di_type(type.pointee_type),
              codegen.data_layout.pointer_size_in_bits, # SizeInBits
              0,                                        # AlignInBits (optional)
              0,                                        # AddressSpace (optional)
              type.name,
              type.name.bytesize
            )
          else
            di_type(type.name)
          end
        end

        private def di_type(name : String) : LibC::LLVMMetadataRef
          case name
          when "bool"
            LibC.LLVMDIBuilderCreateBasicType(self, "i1", 2, 1, DW_ATE_boolean, LibC::LLVMDIFlags::DIFlagZero)
          when "f32"
            LibC.LLVMDIBuilderCreateBasicType(self, "f32", 3, 32, DW_ATE_float, LibC::LLVMDIFlags::DIFlagZero)
          when "f64"
            LibC.LLVMDIBuilderCreateBasicType(self, "f64", 3, 64, DW_ATE_float, LibC::LLVMDIFlags::DIFlagZero)
          when "i8"
            LibC.LLVMDIBuilderCreateBasicType(self, "i8", 2, 8, DW_ATE_signed, LibC::LLVMDIFlags::DIFlagZero)
          when "i16"
            LibC.LLVMDIBuilderCreateBasicType(self, "i16", 3, 16, DW_ATE_signed, LibC::LLVMDIFlags::DIFlagZero)
          when "i32"
            LibC.LLVMDIBuilderCreateBasicType(self, "i32", 3, 32, DW_ATE_signed, LibC::LLVMDIFlags::DIFlagZero)
          when "i64"
            LibC.LLVMDIBuilderCreateBasicType(self, "i64", 3, 64, DW_ATE_signed, LibC::LLVMDIFlags::DIFlagZero)
          when "i128"
            LibC.LLVMDIBuilderCreateBasicType(self, "i128", 4, 128, DW_ATE_signed, LibC::LLVMDIFlags::DIFlagZero)
          when "u8"
            LibC.LLVMDIBuilderCreateBasicType(self, "u8", 2, 8, DW_ATE_unsigned, LibC::LLVMDIFlags::DIFlagZero)
          when "u16"
            LibC.LLVMDIBuilderCreateBasicType(self, "u16", 3, 16, DW_ATE_unsigned, LibC::LLVMDIFlags::DIFlagZero)
          when "u32"
            LibC.LLVMDIBuilderCreateBasicType(self, "u32", 3, 32, DW_ATE_unsigned, LibC::LLVMDIFlags::DIFlagZero)
          when "u64"
            LibC.LLVMDIBuilderCreateBasicType(self, "u64", 3, 64, DW_ATE_unsigned, LibC::LLVMDIFlags::DIFlagZero)
          when "u128"
            LibC.LLVMDIBuilderCreateBasicType(self, "u128", 4, 128, DW_ATE_unsigned, LibC::LLVMDIFlags::DIFlagZero)
          else
            if st = program.resolve_type?(name)
              di_type(st)
            else
              raise CodegenError.new("unsupported #{name}")
            end
          end
        end

        def emit_location(node : AST::Node)
          emit_location(node.location)
        end

        def emit_location(l : Location)
          location = LibC.LLVMDIBuilderCreateDebugLocation(
            @context,
            l.line,
            l.column,
            @lexical_blocks.last? || compile_unit,
            nil)
          LibC.LLVMSetCurrentDebugLocation(@builder, LibC.LLVMMetadataAsValue(@context, location))
        end

        def to_unsafe
          @di_builder
        end
      end
    end
  end
end
