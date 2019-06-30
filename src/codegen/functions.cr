require "../codegen"

module Runic
  class Codegen
    def codegen(node : AST::Prototype) : LibC::LLVMValueRef
      llvm_function(node, node.name).tap do |func|
        LibC.LLVMSetLinkage(func, EXTERN_LINKAGE)
      end
    end

    def codegen(node : AST::Function) : LibC::LLVMValueRef
      if node.attributes.includes?("primitive")
        return llvm_void_value
      end

      func = llvm_function(node.prototype, node.mangled_name)
      LibC.LLVMSetLinkage(func, PUBLIC_LINKAGE)

      block = LibC.LLVMAppendBasicBlockInContext(@context, func, "entry")
      LibC.LLVMPositionBuilderAtEnd(@builder, block)

      if @debug.level.none?
        codegen_function_body(node, func)
      else
        di_subprogram = @debug.create_subprogram(node, func)
        @debug.with_lexical_block(di_subprogram) do
          codegen_function_body(node, func)
        end
      end

      @debug.flush

      if LibC.LLVMVerifyFunction(func, LibC::LLVMVerifierFailureAction::PrintMessage) == 1
        STDERR.puts print(func)
        raise "FATAL: function validation failed"
      end

      if fpm = function_pass_manager
        LibC.LLVMRunFunctionPassManager(fpm, func)
      end

      func
    end

    protected def llvm_function(node : AST::Prototype, name : String) : LibC::LLVMValueRef
      param_types = node.args.map { |arg| llvm_type(arg) }
      return_type = llvm_type(node.type)
      func_type = LibC.LLVMFunctionType(return_type, param_types, param_types.size, 0)
      LibC.LLVMAddFunction(@module, name, func_type)
    end

    private def codegen_function_body(node : AST::Function, func : LibC::LLVMValueRef)
      @debug.emit_location(node)

      # bind func params as named variables
      @scope.push(:function) do
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
          @scope.set(arg.name, alloca)
        end

        ret = codegen(node.body)

        if !ret || node.void?
          LibC.LLVMBuildRetVoid(@builder)
        else
          LibC.LLVMBuildRet(@builder, ret)
        end
      end
    end

    def codegen(node : AST::Call) : LibC::LLVMValueRef
      if func = LibC.LLVMGetNamedFunction(@module, node.mangled_callee)
        args = node.args.map { |arg| codegen(arg) }
        LibC.LLVMBuildCall(@builder, func, args, args.size, "")
      else
        raise CodegenError.new("undefined function '#{node.callee}'")
      end
    end

    private def create_entry_block_alloca(func : LibC::LLVMValueRef, node : AST::Variable)
      build_alloca(node)
    end
  end
end
