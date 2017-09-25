require "./codegen/debug"
require "./llvm"
require "./errors"

module Runic
  class Codegen
    EXTERN_LINKAGE = LibC::LLVMLinkage::External
    PUBLIC_LINKAGE = LibC::LLVMLinkage::External
    PRIVATE_LINKAGE = LibC::LLVMLinkage::Internal

    @debug : Debug

    def initialize(debug = DebugLevel::Default, @optimize = true)
      @context = LibC.LLVMContextCreate()
      @builder = LibC.LLVMCreateBuilderInContext(@context)
      @module = LibC.LLVMModuleCreateWithNameInContext("main", @context)

      if debug.none?
        @debug = Debug::NULL.new(debug)
      else
        @debug = Debug::DWARF.new(@module, @builder, @context, debug)
      end

      @named_values = {} of String => LibC::LLVMValueRef
    end

    def path=(path : String)
      @debug.path = path
    end

    def finalize
      if fpm = @function_pass_manager
        LibC.LLVMDisposePassManager(fpm)
      end
      LibC.LLVMDisposeModule(@module)
      LibC.LLVMDisposeBuilder(@builder)
      LibC.LLVMContextDispose(@context)
    end

    def data_layout=(layout)
      LibC.LLVMSetModuleDataLayout(@module, layout)
    end

    def target_triple=(triple)
      LibC.LLVMSetTarget(@module, triple)
    end

    def emit_llvm(path : String)
      @debug.flush

      if LibC.LLVMPrintModuleToFile(@module, path, out err_msg) == 1
        msg = String.new(err_msg)
        LibC.LLVMDisposeMessage(err_msg)
        raise CodegenError.new(msg)
      end
    end

    def emit_llvm(value : LibC::LLVMValueRef)
      ll = LibC.LLVMPrintValueToString(value)
      begin
        String.new(ll)
      ensure
        LibC.LLVMDisposeMessage(ll)
      end
    end

    def emit_object(target_machine, path)
      @debug.flush

      if LibC.LLVMVerifyModule(@module, LibC::LLVMVerifierFailureAction::ReturnStatus, nil) == 1
        raise CodegenError.new("module validation failed")
      end

      # write object file
      if LibC.LLVMTargetMachineEmitToFile(target_machine, @module, path,
          LibC::LLVMCodeGenFileType::Object, out emit_err_msg) == 1
        msg = String.new(emit_err_msg)
        LibC.LLVMDisposeMessage(emit_err_msg)
        raise CodegenError.new(msg)
      end
    end

    def execute(ret, func : LibC::LLVMValueRef)
      # (re)inject module since it may have been removed
      LibC.LLVMAddModule(execution_engine, @module)

      # get pointer to compiled function, cast to proc and execute
      if func_ptr = LibC.LLVMGetPointerToGlobal(execution_engine, func)
        Proc(typeof(ret)).new(func_ptr, Pointer(Void).null).call
      end
    ensure
      # remove module so next run will recompile code
      if LibC.LLVMRemoveModule(execution_engine, @module, out mod, out err_msg) == 1
        STDERR.puts(String.new(err_msg))
        LibC.LLVMDisposeMessage(err_msg)
        exit
      end
    end

    @execution_engine : LibC::LLVMExecutionEngineRef?

    private def execution_engine
      if ee = @execution_engine
        return ee
      end
      if LibC.LLVMCreateJITCompilerForModule(out engine, @module, 0, out err_msg) == 1
        STDERR.puts(String.new(err_msg))
        LibC.LLVMDisposeMessage(err_msg)
        exit
      end
      @execution_engine = engine
    end

    def codegen(node : AST::Boolean) : LibC::LLVMValueRef
      @debug.emit_location(node)
      LibC.LLVMConstInt(llvm_type(node), node.value == "true" ? 1 : 0, 0)
    end

    def codegen(node : AST::Integer) : LibC::LLVMValueRef
      @debug.emit_location(node)
      if node.value.starts_with?('0')
        value = node.value[2..-1]
      else
        value = node.negative ? "-#{node.value}" : node.value
      end
      LibC.LLVMConstIntOfStringAndSize(llvm_type(node), value, value.bytesize, node.radix)
    end

    def codegen(node : AST::Float) : LibC::LLVMValueRef
      @debug.emit_location(node)
      value = node.negative ? "-#{node.value}" : node.value
      LibC.LLVMConstRealOfStringAndSize(llvm_type(node), value, value.bytesize)
    end

    def codegen(node : AST::Variable) : LibC::LLVMValueRef
      if alloca = @named_values[node.name]?
        @debug.emit_location(node)
        LibC.LLVMBuildLoad(@builder, alloca, node.name)
      else
        raise CodegenError.new("using variable before definition: #{node.name}")
      end
    end

    # FIXME: ASSUMEs that lhs.type == rhs.type but we MUST transform each
    #        operand so it matches node.type !
    def codegen(node : AST::Binary) : LibC::LLVMValueRef
      lhs = codegen(node.lhs) unless node.assignment?
      rhs = codegen(node.rhs)

      @debug.emit_location(node)

      case node.operator
      when "="
        lhse = node.lhs.as(AST::Variable)
        alloca = @named_values[lhse.name] ||= build_alloca(lhse)
        LibC.LLVMBuildStore(@builder, rhs, alloca)
        rhs

      when "+"
        case node.lhs
        when .float?
          LibC.LLVMBuildFAdd(@builder, lhs, rhs, "")
        when .integer?
          LibC.LLVMBuildAdd(@builder, lhs, rhs, "")
        else
          raise CodegenError.new("unsupported #{node.lhs.type} + #{node.rhs.type} binary operation (yet)")
        end

      when "-"
        case node.lhs
        when .float?
          LibC.LLVMBuildFSub(@builder, lhs, rhs, "")
        when .integer?
          LibC.LLVMBuildSub(@builder, lhs, rhs, "")
        else
          raise CodegenError.new("unsupported #{node.lhs.type} - #{node.rhs.type} binary operation (yet)")
        end

      when "*"
        case node.lhs
        when .float?
          LibC.LLVMBuildFMul(@builder, lhs, rhs, "")
        when .integer?
          LibC.LLVMBuildMul(@builder, lhs, rhs, "")
        else
          raise CodegenError.new("unsupported #{node.lhs.type} * #{node.rhs.type} binary operation (yet)")
        end

      when "/" # float division
        {% for hs in %w(lhs rhs) %}
          if node.{{hs.id}}.integer?
            if node.{{hs.id}}.unsigned?
              {{hs.id}} = LibC.LLVMBuildUIToFP(@builder, {{hs.id}}, llvm_type(node.type), "")
            else
              {{hs.id}} = LibC.LLVMBuildSIToFP(@builder, {{hs.id}}, llvm_type(node.type), "")
            end
          end
        {% end %}
        LibC.LLVMBuildFDiv(@builder, lhs, rhs, "")

      when "//" # floor division
        case node.lhs
        when .float?
          result = LibC.LLVMBuildFDiv(@builder, lhs, rhs, "")
          LibC.LLVMBuildCall(@builder, intrinsic("llvm.floor", node.type), [result], 1, "")
        when .integer?
          if node.lhs.as(AST::Integer).unsigned?
            LibC.LLVMBuildUDiv(@builder, lhs, rhs, "")
          else
            LibC.LLVMBuildSDiv(@builder, lhs, rhs, "")
          end
        else
          raise CodegenError.new("unsupported #{node.lhs.type} // #{node.rhs.type} binary operation (yet)")
        end

      # when "%"
      # when "&"
      # when "|"
      # when "^"
      # when "<<"
      # when ">>"
      # when "=="
      # when "!="
      # when "<"
      # when "<="
      # when ">"
      # when ">="
      # when "&&"
      # when "||"
      # when "<=>"
      else
        raise CodegenError.new("unsupported binary operator: '#{node.operator}' (yet?)")
      end
    end

    def codegen(node : AST::Unary) : LibC::LLVMValueRef
      expression = codegen(node.expression)
      @debug.emit_location(node)

      #case node.operator
      #when "!"
      #when "~"
      #else
        raise CodegenError.new("unsupported unary operator: '#{node.operator}'")
      #end
    end

    def codegen(node : AST::Prototype, linkage : LibC::LLVMLinkage = EXTERN_LINKAGE) : LibC::LLVMValueRef
      param_types = node.args.map { |arg| llvm_type(arg) }
      return_type = llvm_type(node.type)
      func_type = LibC.LLVMFunctionType(return_type, param_types, param_types.size, 0)
      func = LibC.LLVMAddFunction(@module, node.name, func_type)
      LibC.LLVMSetLinkage(func, linkage)
      func
    end

    def codegen(node : AST::Function) : LibC::LLVMValueRef
      func = codegen(node.prototype, PUBLIC_LINKAGE)

      block = LibC.LLVMAppendBasicBlockInContext(@context, func, "entry")
      LibC.LLVMPositionBuilderAtEnd(@builder, block)

      if @debug.level.none?
        codegen_function_body(node, func)
      else
        di_subprogram = @debug.create_subprogram(node, func, optimized: @optimize)
        @debug.with_lexical_block(di_subprogram) do
          codegen_function_body(node, func)
        end
      end

      # FIXME: "fails with expected no forward declaration"
      @debug.flush
      if LibC.LLVMVerifyFunction(func, LibC::LLVMVerifierFailureAction::PrintMessage) == 1
        # STDERR.puts print(func)
        raise "function validation failed"
      end

      if fpm = function_pass_manager
        LibC.LLVMRunFunctionPassManager(fpm, func)
      end

      func
    end

    private def codegen_function_body(node : AST::Function, func : LibC::LLVMValueRef)
      @debug.emit_location(node)

      # bind func params as named variables
      @named_values.clear

      node.args.each_with_index do |arg, arg_no|
        @debug.emit_location(arg)

        # create alloca (stack pointer)
        param = LibC.LLVMGetParam(func, arg_no)
        alloca = create_entry_block_alloca(func, arg)

        # create debug descriptor
        @debug.parameter_variable(arg, arg_no, alloca)

        # store initial value (on stack)
        LibC.LLVMBuildStore(@builder, param, alloca)

        # remember symbol
        @named_values[arg.name] = alloca
      end

      ret = nil
      node.body.each { |n| ret = codegen(n) }

      if !ret || node.void?
        LibC.LLVMBuildRetVoid(@builder)
      else
        LibC.LLVMBuildRet(@builder, ret)
      end
    end

    def codegen(node : AST::Call) : LibC::LLVMValueRef
      if func = LibC.LLVMGetNamedFunction(@module, node.callee)
        args = node.args.map { |arg| codegen(arg) }
        LibC.LLVMBuildCall(@builder, func, args, args.size, "")
      else
        raise CodegenError.new("undefined function '#{node.callee}'")
      end
    end

    @function_pass_manager : LibC::LLVMPassManagerRef?

    private def function_pass_manager
      return unless @optimize

      @function_pass_manager ||= begin
        fpm = LibC.LLVMCreateFunctionPassManagerForModule(@module)
        LibC.LLVMAddPromoteMemoryToRegisterPass(fpm)
        LibC.LLVMAddInstructionCombiningPass(fpm)
        LibC.LLVMAddReassociatePass(fpm)
        LibC.LLVMAddGVNPass(fpm)
        LibC.LLVMAddCFGSimplificationPass(fpm)
        LibC.LLVMInitializeFunctionPassManager(fpm)
        fpm
      end
    end

    private def create_entry_block_alloca(func : LibC::LLVMValueRef, node : AST::Variable)
      build_alloca(node)
    end

    private def build_alloca(node : AST::Variable)
      @debug.emit_location(node)
      LibC.LLVMBuildAlloca(@builder, llvm_type(node.type), "#{node.name}_ptr")
    end

    # Searches an LLVM intrinsic in extern definitions, translating the Runic
    # types to the LLVM overload types. For example:
    #
    # ```
    # intrinsic("llvm.floor", "float32") # => searches llvm.floor.f32
    # ```
    private def intrinsic(name, *types)
      overload_types = types.map do |type|
        case type
        when "int8", "uint8" then "i8"
        when "int16", "uint16" then "i16"
        when "int32", "uint32" then "i32"
        when "int64", "uint64" then "i64"
        when "int128", "uint128" then "i128"
        when "float32" then "f32"
        when "float64" then "f64"
        else
          raise CodegenError.new("unsupported overload type '#{type}' for '#{name}' intrinsic")
       end
      end

      overload_name = String.build do |str|
        str << name
        overload_types.each do |type|
          str << '.'
          str << type
        end
      end

      if func = LibC.LLVMGetNamedFunction(@module, name)
        func
      else
        raise CodegenError.new("intrinsic '#{name}': no such definition")
      end
    end

    private def llvm_type(node : AST::Node)
      llvm_type(node.type)
    end

    private def llvm_type(type : String)
      case type
      when "bool"
        LibC.LLVMInt1TypeInContext(@context)
      when "int8", "uint8"
        LibC.LLVMInt8TypeInContext(@context)
      when "int16", "uint16"
        LibC.LLVMInt16TypeInContext(@context)
      when "int32", "uint32"
        LibC.LLVMInt32TypeInContext(@context)
      when "int64", "uint64"
        LibC.LLVMInt64TypeInContext(@context)
      when "int128", "uint128"
        LibC.LLVMInt128TypeInContext(@context)
      #when "long", "ulong"
      #  LibC.LLVMInt32TypeInContext(@context)   # 32-bit: x86, arm, mips, ...
      #  LibC.LLVMInt64TypeInContext(@context)   # 64-bit: x86_64, aarch64, mips64, ...
      when "float64"
        LibC.LLVMDoubleTypeInContext(@context)
      when "float32"
        LibC.LLVMFloatTypeInContext(@context)
      else
        raise CodegenError.new("unsupported #{type}")
      end
    end
  end
end
