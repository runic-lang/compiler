require "../codegen"

module Runic
  class Codegen
    def codegen(node : AST::Prototype) : LibC::LLVMValueRef
      llvm_function(node, node.name).tap do |func|
        LibC.LLVMSetLinkage(func, EXTERN_LINKAGE)
      end
    end

    def codegen(node : AST::Function) : LibC::LLVMValueRef
      linkage = PUBLIC_LINKAGE

      if node.attribute?("primitive")
        if node.operator?
          # builtin operator primitives are always inlined
          return llvm_void_value
        end
        linkage = PRIVATE_LINKAGE
      end

      func = llvm_function(node.prototype, node.mangled_name)
      LibC.LLVMSetLinkage(func, linkage)

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
        # STDERR.puts node
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

        ret =
          if node.attribute?("primitive")
            codegen_builtin_function_body(node)
          else
            codegen(node.body)
          end

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

    private def codegen_builtin_function_body(node)
      result =
        case node.original_name
        when "to_u8", "to_u16", "to_u32", "to_u64", "to_u128"
          builtin_cast_to_unsigned("self", node.args[0].type, node.type)
        when "to_i8", "to_i16", "to_i32", "to_i64", "to_i128"
          builtin_cast_to_signed("self", node.args[0].type, node.type)
        when "to_f32", "to_f64"
          builtin_cast_to_float("self", node.args[0].type, node.type)
        end
      raise "unknown primitive function '#{node.name}'" unless result
      result
    end
  end
end
