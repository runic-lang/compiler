require "./codegen/debug"
require "./codegen/functions"
require "./codegen/literals"
require "./codegen/operators"
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

      @constant_values = {} of String => LibC::LLVMValueRef
      @named_values = {} of String => LibC::LLVMValueRef
    end

    def finalize
      if fpm = @function_pass_manager
        LibC.LLVMDisposePassManager(fpm)
      end
      LibC.LLVMDisposeModule(@module)
      LibC.LLVMDisposeBuilder(@builder)
      LibC.LLVMContextDispose(@context)
    end


    def path=(path : String)
      @debug.path = path
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


    private def build_alloca(node : AST::Variable)
      @debug.emit_location(node)
      LibC.LLVMBuildAlloca(@builder, llvm_type(node.type), "#{node.name}_ptr")
    end

    # Returns false (0_i1) if the expression evaluates to false or a null
    # pointer. Returns true (1_i1) otherwise.
    private def build_condition(node : AST::Node)
      value = codegen(node)

      if node.bool?
        value
      #elsif node.pointer?
      #  is_null = LibC.LLVMBuildIsNull(@builder, value, "")
      #  bool_false = LibC.LLVMConstInt(llvm_type("bool"), 0, 0)
      #  LibC.LLVMBuildICmp(@builder, LibC::LLVMIntPredicate::IntEQ, is_null, bool_false, "")
      else
        LibC.LLVMConstInt(llvm_type("bool"), 1, 0)
      end
    end

    # Searches an LLVM intrinsic in extern definitions, translating the Runic
    # types to the LLVM overload types. For example:
    #
    # ```
    # intrinsic("llvm.floor", "f32") # => searches llvm.floor.f32
    # ```
    private def intrinsic(name, *types)
      overload_types = types.map do |type|
        case type.name
        when "i8", "u8" then "i8"
        when "i16", "u16" then "i16"
        when "i32", "u32" then "i32"
        when "i64", "u64" then "i64"
        when "i128", "u128" then "i128"
        when "f32" then "f32"
        when "f64" then "f64"
        else raise CodegenError.new("unsupported overload type '#{type}' for '#{name}' intrinsic")
       end
      end

      overload_name = String.build do |str|
        str << name
        overload_types.each do |type|
          str << '.'
          type.to_s(str)
        end
      end

      if func = LibC.LLVMGetNamedFunction(@module, overload_name)
        func
      else
        raise CodegenError.new("intrinsic '#{overload_name}': no such definition")
      end
    end

    private def llvm_type(node : AST::Node)
      llvm_type(node.type.name)
    end

    private def llvm_type(type : Type)
      llvm_type(type.name)
    end

    private def llvm_type(type : String)
      case type
      when "bool"
        LibC.LLVMInt1TypeInContext(@context)
      when "i8", "u8"
        LibC.LLVMInt8TypeInContext(@context)
      when "i16", "u16"
        LibC.LLVMInt16TypeInContext(@context)
      when "i32", "u32"
        LibC.LLVMInt32TypeInContext(@context)
      when "i64", "u64"
        LibC.LLVMInt64TypeInContext(@context)
      when "i128", "u128"
        LibC.LLVMInt128TypeInContext(@context)
      when "f64"
        LibC.LLVMDoubleTypeInContext(@context)
      when "f32"
        LibC.LLVMFloatTypeInContext(@context)
      #when "long", "ulong"
      #  LibC.LLVMInt32TypeInContext(@context)   # 32-bit: x86, arm, mips, ...
      #  LibC.LLVMInt64TypeInContext(@context)   # 64-bit: x86_64, aarch64, mips64, ...
      else
        raise CodegenError.new("unsupported #{type}")
      end
    end
  end
end
