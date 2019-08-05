require "../codegen"

module Runic
  class Codegen
    def codegen(node : AST::Prototype) : LibC::LLVMValueRef
      llvm_function(node, node.name).tap do |func|
        LibC.LLVMSetLinkage(func, EXTERN_LINKAGE)
      end
    end

    private def attribute_ref(name)
      attr_kind = LibC.LLVMGetEnumAttributeKindForName(name, name.bytesize)
      LibC.LLVMCreateEnumAttribute(@context, attr_kind, 0)
    end

    def codegen(node : AST::Function) : LibC::LLVMValueRef
      if node.attribute?("primitive")
        if node.operator?
          # builtin operator primitives are always inlined
          return llvm_void_value
        end
      end

      func = llvm_function(node.prototype, node.mangled_name)

      if node.attribute?("primitive") || node.attribute?("inline")
        LibC.LLVMAddAttributeAtIndex(func, LibC::LLVMAttributeFunctionIndex, attribute_ref("alwaysinline"))
        LibC.LLVMSetLinkage(func, PRIVATE_LINKAGE)
      else
        LibC.LLVMSetLinkage(func, PUBLIC_LINKAGE)
      end

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
        STDERR.puts emit_llvm(func)
        raise "FATAL: function validation failed"
      end

      func
    end

    protected def llvm_function(node : AST::Prototype, name : String) : LibC::LLVMValueRef
      byval = [] of Int32

      param_types = node.args.map_with_index do |arg, arg_no|
        if arg.type.aggregate?
          byval << arg_no
          llvm_type("#{arg.type.name}*")
        else
          llvm_type(arg)
        end
      end

      return_type = llvm_type(node.type)
      func_type = LibC.LLVMFunctionType(return_type, param_types, param_types.size, 0)

      func = LibC.LLVMAddFunction(@module, name, func_type)

      byval.each do |arg_no|
        LibC.LLVMAddAttributeAtIndex(func, 1 + arg_no, attribute_ref("byval"))
      end

      func
    end

    private def codegen_function_body(node : AST::Function, func : LibC::LLVMValueRef)
      @debug.emit_location(node)

      # bind func params as named variables
      @scope.push(:function) do
        node.args.each_with_index do |arg, arg_no|
          @debug.emit_location(arg)

          if arg.type.aggregate?
            # arg is passed byval (use it directly):
            alloca = LibC.LLVMGetParam(func, arg_no)
          else
            # create alloca (stack pointer) and store value:
            param = LibC.LLVMGetParam(func, arg_no)
            alloca = build_alloca(arg)
            LibC.LLVMBuildStore(@builder, param, alloca)
          end

          # debug info
          @debug.parameter_variable(arg, arg_no, alloca)

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
      if node.constructor?
        _, alloca = build_stack_constructor(node)
        LibC.LLVMBuildLoad(@builder, alloca, "") # return self

      elsif func = LibC.LLVMGetNamedFunction(@module, node.mangled_callee)
        byval = [] of Int32

        args = node.args.map_with_index do |arg, arg_no|
          value = codegen(arg)

          if arg.type.aggregate?
            byval << arg_no

            # pass an existing alloca if possible
            case arg
            when AST::Variable
              @scope.get(arg.name) ||
                raise CodegenError.new("using variable before definition: #{arg.name}")
            when AST::InstanceVariable
              build_ivar(arg.name)
            else
              # must store the value on the stack to pass it byval
              alloca = LibC.LLVMBuildAlloca(@builder, llvm_type(arg.type), "")
              LibC.LLVMBuildStore(@builder, value, alloca)
              alloca
            end
          else
            # pass basic type directly (fits in register)
            value
          end
        end

        call = LibC.LLVMBuildCall(@builder, func, args, args.size, "")

        byval.each do |arg_no|
          LibC.LLVMAddCallSiteAttribute(call, 1 + arg_no, attribute_ref("byval"))
        end

        call
      else
        raise CodegenError.new("undefined function '#{node.callee}'")
      end
    end

    protected def build_stack_constructor(node : AST::Call, alloca : LibC::LLVMValueRef? = nil)
      args = node.args.map_with_index do |arg, i|
        if i == 0 && alloca
          # override temporary 'self' alloca with the specified alloca:
          alloca
        else
          codegen(arg)
        end
      end

      if func = LibC.LLVMGetNamedFunction(@module, node.mangled_callee)
        value = LibC.LLVMBuildCall(@builder, func, args, args.size, "")
        {value, args.first}
      else
        {llvm_void_value, args.first}
      end
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

        when "div"
          builtin_div("self", "other", node.type)

        when "floor"
          builtin_floor("self", node.type)

        when "ceil"
          builtin_ceil("self", node.type)

        when "truncate"
          builtin_truncate("self", node.type)
        end
      raise "unknown primitive function '#{node.name}'" unless result
      result
    end
  end
end
