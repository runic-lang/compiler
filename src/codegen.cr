require "./codegen/control_flow"
require "./codegen/debug"
require "./codegen/functions"
require "./codegen/literals"
require "./codegen/operators"
require "./codegen/pointers"
require "./codegen/structures"
require "./data_layout"
require "./llvm"
require "./errors"
require "./scope"

module Runic
  class Codegen
    EXTERN_LINKAGE = LibC::LLVMLinkage::External
    PUBLIC_LINKAGE = LibC::LLVMLinkage::External
    PRIVATE_LINKAGE = LibC::LLVMLinkage::Internal

    @debug : Debug
    @opt_level : LibC::LLVMCodeGenOptLevel

    def initialize(@program : Program, debug = DebugLevel::Default, @opt_level = LibC::LLVMCodeGenOptLevel::CodeGenLevelDefault, @optimize = true)
      @context = LibC.LLVMContextCreate()
      @builder = LibC.LLVMCreateBuilderInContext(@context)
      @module = LibC.LLVMModuleCreateWithNameInContext("main", @context)

      # custom types (i.e. structs):
      @llvm_types = {} of String => LibC::LLVMTypeRef

      # global constant values:
      @constant_values = {} of String => LibC::LLVMValueRef

      # local variables (i.e. pointers)
      @scope = Scope(LibC::LLVMValueRef).new

      # name(+index) of current struct ivars:
      @ivars = [] of String

      if debug.none?
        @debug = Debug::NULL.new(debug)
      else
        @debug = Debug::DWARF.new(@module, @builder, @context, debug, @optimize)
        @debug.codegen = self
      end
    end

    def finalize
      if fpm = @function_pass_manager
        LibC.LLVMDisposePassManager(fpm)
      end
      if mpm = @module_pass_manager
        LibC.LLVMDisposePassManager(mpm)
      end
      if pmb = @pass_manager_builder
        LibC.LLVMPassManagerBuilderDispose(pmb)
      end
      LibC.LLVMDisposeModule(@module)
      LibC.LLVMDisposeBuilder(@builder)
      LibC.LLVMContextDispose(@context)
    end


    def data_layout
      @data_layout ||= DataLayout.from(@module)
    end

    def data_layout=(layout)
      @data_layout = @target_data = nil
      LibC.LLVMSetModuleDataLayout(@module, layout)
    end

    def target_triple=(triple)
      @data_layout = @target_data = nil
      LibC.LLVMSetTarget(@module, triple)
    end

    private def target_data
      @target_data ||= LibC.LLVMGetModuleDataLayout(@module)
    end


    def verify
      @debug.flush

      if LibC.LLVMVerifyModule(@module, LibC::LLVMVerifierFailureAction::ReturnStatus, nil) == 1
        emit_llvm("dump.ll")
        raise CodegenError.new("module validation failed")
      end
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

      # write object file
      if LibC.LLVMTargetMachineEmitToFile(target_machine, @module, path,
          LibC::LLVMCodeGenFileType::Object, out emit_err_msg) == 1
        msg = String.new(emit_err_msg)
        LibC.LLVMDisposeMessage(emit_err_msg)
        raise CodegenError.new(msg)
      end
    end

    def execute(ret : T.class, func : LibC::LLVMValueRef) : T? forall T
      execute(ret, func) do |func_ptr|
        Proc(T)
          .new(func_ptr, Pointer(Void).null)
          .call
      end
    end

    def execute(ret : String.class, func : LibC::LLVMValueRef) : String?
      execute(ret, func) do |func_ptr|
        sret = uninitialized {UInt8*, Int32}

        Proc(Pointer({UInt8*, Int32}), Void)
          .new(func_ptr, Pointer(Void).null)
          .call(pointerof(sret))

        String.new(sret[0], sret[1])
      end
    end

    private def execute(ret, func)
      # (re)inject module since it may have been removed
      LibC.LLVMAddModule(execution_engine, @module)

      # get pointer to compiled function, cast to proc and execute
      if func_ptr = LibC.LLVMGetPointerToGlobal(execution_engine, func)
        yield func_ptr
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


    @pass_manager_builder : LibC::LLVMPassManagerBuilderRef?
    @function_pass_manager : LibC::LLVMPassManagerRef?
    @module_pass_manager : LibC::LLVMPassManagerRef?

    def optimize
      return unless @optimize

      if fpm = function_pass_manager
        LibC.LLVMInitializeFunctionPassManager(fpm)

        func = LibC.LLVMGetFirstFunction(@module)
        while func
          LibC.LLVMRunFunctionPassManager(fpm, func)
          func = LibC.LLVMGetNextFunction(func)
        end

        LibC.LLVMFinalizeFunctionPassManager(fpm)
      end

      if mpm = module_pass_manager
        LibC.LLVMRunPassManager(mpm, @module)
      end
    end

    private def pass_manager_builder
      @pass_manager_builder ||= begin
        pmb = LibC.LLVMPassManagerBuilderCreate()
        LibC.LLVMPassManagerBuilderSetOptLevel(pmb, @opt_level)
        LibC.LLVMPassManagerBuilderSetSizeLevel(pmb, 0) # 1 => -Os, 2 => -Oz
        pmb
      end
    end

    private def function_pass_manager
      @function_pass_manager ||= LibC.LLVMCreateFunctionPassManagerForModule(@module).tap do |pm|
        LibC.LLVMPassManagerBuilderPopulateFunctionPassManager(pass_manager_builder, pm)
        pm
      end
    end

    private def module_pass_manager
      @module_pass_manager ||= LibC.LLVMCreatePassManager().tap do |pm|
        LibC.LLVMPassManagerBuilderPopulateModulePassManager(pass_manager_builder, pm)
        LibC.LLVMAddAlwaysInlinerPass(pm)
      end
    end


    def codegen(path : String) : Nil
      @debug.path = path
      @debug.program = @program
      @program.each { |node| codegen(node) }
    end

    def codegen(nodes : AST::Body) : LibC::LLVMValueRef
      nodes.reduce(llvm_void_value) { |_, node| codegen(node) }
    end

    def codegen(node : AST::Module)
      raise "FATAL: can't codegen module statement"
    end

    def codegen(node : AST::Require)
      raise "FATAL: can't codegen require statement"
    end


    private def build_alloca(node : AST::Variable)
      alloca = build_alloca(node)
      yield alloca
      alloca
    end

    private def build_alloca(node : AST::Variable)
      @debug.emit_location(node)
      LibC.LLVMBuildAlloca(@builder, llvm_type(node.type), "")
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

    # The `codegen` methods must return a value, but sometimes they must return
    # void, that is nothing, in this case we return a zero value —semantic
    # analysis verified the value is never used.
    private def llvm_void_value
      LibC.LLVMConstInt(llvm_type("i32"), 0, 0)
    end

    private def llvm_type(node : AST::Struct)
      build_llvm_struct(node.name)
    end

    private def llvm_type(node : AST::Node)
      llvm_type(node.type)
    end

    private def llvm_type(node : String)
      llvm_type(Type.new(node))
    end

    private def llvm_type(type : Type)
      if type.pointer?
        LibC.LLVMPointerType(llvm_type(type.pointee_type), 0)
      else
        case type.name
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
        when "void"
          LibC.LLVMVoidTypeInContext(@context)
        else
          build_llvm_struct(type.name)
        end
      end
    end

    private def build_llvm_struct(name : String)
      @llvm_types[name] ||= LibC.LLVMStructCreateNamed(@context, "struct.#{name}")
    end


    protected def sizeof(node : AST::Struct)
      LibC.LLVMABISizeOfType(target_data, llvm_type(node.name))
    end

    protected def sizeof(node : AST::Node)
      LibC.LLVMABISizeOfType(target_data, llvm_type(node.type))
    end

    #protected def alignment(node : AST::Struct)
    #  LibC.LLVMABIAlignmentOfType(target_data, llvm_type(node.name))
    #end

    #protected def alignment(node : AST::Node)
    #  LibC.LLVMABIAlignmentOfType(target_data, llvm_type(node.type))
    #end

    protected def offsetof(node : AST::Struct, ivar : AST::InstanceVariable)
      index = -1

      node.variables.each_with_index do |v, i|
        index = i if v.name == ivar.name
      end

      if index == -1
        raise CodegenError.new("can't take offsetof of unknown instance variable '@#{ivar.name}' for struct #{node.name}")
      end

      LibC.LLVMOffsetOfElement(target_data, llvm_type(node.name), index)
    end
  end
end
