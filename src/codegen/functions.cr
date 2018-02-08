require "../codegen"

module Runic
  class Codegen
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

      @debug.flush
      #if LibC.LLVMVerifyFunction(func, LibC::LLVMVerifierFailureAction::PrintMessage) == 1
      #  # STDERR.puts print(func)
      #  raise "function validation failed"
      #end

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

    private def create_entry_block_alloca(func : LibC::LLVMValueRef, node : AST::Variable)
      build_alloca(node)
    end
  end
end
