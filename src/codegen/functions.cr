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

      func = llvm_function(node.prototype, node.symbol_name)

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
          # TODO: pass as integer if the struct fits in a register (data_layout.native_integers.max)
          byval << arg_no
          llvm_type("#{arg.type.name}*")
        else
          llvm_type(arg)
        end
      end

      return_type =
        if sret = node.type.aggregate?
          # TODO: return as integer if the struct fits in a register (data_layout.native_integers.max)
          param_types.unshift(llvm_type("#{node.type.name}*"))
          llvm_type("void")
        else
          llvm_type(node.type)
        end

      func_type = LibC.LLVMFunctionType(return_type, param_types, param_types.size, 0)
      func = LibC.LLVMAddFunction(@module, name, func_type)

      if sret
        LibC.LLVMAddAttributeAtIndex(func, 1, attribute_ref("sret"))
      end
      byval.each do |arg_no|
        LibC.LLVMAddAttributeAtIndex(func, (sret ? 2 : 1) + arg_no, attribute_ref("byval"))
      end

      func
    end

    private def codegen_function_body(node : AST::Function, func : LibC::LLVMValueRef)
      @debug.emit_location(node)

      # bind func params as named variables
      @scope.push(:function) do
        if node.type.aggregate?
          # TODO: unless the struct fits in a register (data_layout.native_integers.max)

          # the function returns a struca which may not fit inside a register,
          # so we pass a pointer to a caller stack allocated struct (sret) as
          # the first argument to the function
          sret = LibC.LLVMGetParam(func, 0)
          @debug.sret_variable(sret, Type.new("#{node.type.name}*"), node.location)
        end

        # then we declare all arguments to the function:
        node.args.each_with_index do |arg, arg_no|
          @debug.emit_location(arg)

          if sret
            arg_no += 1
          end

          if arg.type.aggregate?
            # TODO: bitcast from integer if the struct fits in a register (data_layout.native_integers.max)

            # arg is passed byval (use it directly):
            alloca = LibC.LLVMGetParam(func, arg_no)
          else
            # create alloca (stack pointer) to store the param value (it will be
            # optimized by LLVM if possible):
            param = LibC.LLVMGetParam(func, arg_no)
            alloca = build_alloca(arg)
            LibC.LLVMBuildStore(@builder, param, alloca)
          end

          # declare debug info
          @debug.parameter_variable(arg, arg_no, alloca)

          # remember variable
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
        elsif sret
          # TODO: avoid the eventual copy by using the sret variable directly in
          #       the function body (?) for example by having the semantic
          #       analysis determine which variable is eventually returned, and
          #       in case of returning an expression, use a temporary variable
          #       (to identify as sret).
          LibC.LLVMBuildStore(@builder, ret, sret)
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
      elsif func = LibC.LLVMGetNamedFunction(@module, node.symbol_name)
        build_call(func, node.type, nil, node.args, node.location)
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

      @debug.emit_location(node)

      if func = LibC.LLVMGetNamedFunction(@module, node.symbol_name)
        value = LibC.LLVMBuildCall(@builder, func, args, args.size, "")
        {value, args.first}
      else
        {llvm_void_value, args.first}
      end
    end

    protected def build_sret_call(node : AST::Call, sret : LibC::LLVMValueRef)
      if func = LibC.LLVMGetNamedFunction(@module, node.symbol_name)
        build_call(func, node.type, nil, node.args, node.location, sret)
      else
        raise CodegenError.new("undefined function '#{node.callee}'")
      end
    end

    protected def build_sret_call(node : AST::Binary, sret : LibC::LLVMValueRef)
      if func = LibC.LLVMGetNamedFunction(@module, node.method.symbol_name)
        build_call(func, node.method.type, node.lhs, [node.rhs], node.location, sret)
      else
        raise CodegenError.new("undefined function '#{node.method.name}'")
      end
    end

    #protected def build_sret_call(node : AST::Unary, sret : LibC::LLVMValueRef)
    #  if func = LibC.LLVMGetNamedFunction(@module, node.method.symbol_name)
    #    build_call(func, node.method.type, node.lhs, [] of AST::Node, node.location, sret)
    #  else
    #    raise CodegenError.new("undefined function '#{node.method.name}'")
    #  end
    #end

    protected def build_call(func : LibC::LLVMValueRef, type : Type, receiver : AST::Node?, args : Array(AST::Node), location : Location, sret : LibC::LLVMValueRef? = nil)
      params = Array(LibC::LLVMValueRef).new(args.size + (receiver ? 1 : 0))
      byval = [] of Int32

      if receiver
        # inject receiver as first argument (self), this should only happen for
        # custom binary/unary operator methods on non-primitive types; remember
        # that 'self' is always passed by reference:
        if receiver.primitive? || receiver.is_a?(AST::Reference)
          params << codegen(receiver)
        else
          params << codegen(AST::Reference.new(receiver, receiver.location))
        end
      end

      args.each_with_index do |arg, arg_no|
        value = codegen(arg)

        if arg.type.aggregate?
          # TODO: bitcast as integer if the struct fits in a register (data_layout.native_integers.max)

          # collect struct argument that must be passed byval:
          byval << arg_no + (receiver ? 1 : 0)

          # try to pass an existing alloca if we know about it...
          case arg
          when AST::Variable
            if alloca = @scope.get(arg.name)
              params << alloca
            else
              raise CodegenError.new("using variable before definition: #{arg.name}")
            end
          when AST::InstanceVariable
            params << build_ivar(arg.name)
          else
            # failed: we must store the value on the stack to pass it byval
            alloca = LibC.LLVMBuildAlloca(@builder, llvm_type(arg.type), "")
            LibC.LLVMBuildStore(@builder, value, alloca)
            params << alloca
          end
        else
          # pass basic/primitive type directly (it fits in a register)
          params << value
        end
      end

      if type.aggregate?
        # TODO: bitcast as integer if the struct fits in a register (data_layout.native_integers.max)

        # pass returned struct value... as the first argument (sret) which is a
        # pointer to the caller stack allocated struct:
        sret ||= LibC.LLVMBuildAlloca(@builder, llvm_type(type), "")
        params.unshift(sret)
      end

      # finally, we can codegen the call:
      @debug.emit_location(location)
      call = LibC.LLVMBuildCall(@builder, func, params, params.size, "")

      # and set the sret/byval attributes:
      byval.each do |arg_no|
        LibC.LLVMAddCallSiteAttribute(call, (sret ? 2 : 1) + arg_no, attribute_ref("byval"))
      end

      if sret
        LibC.LLVMAddCallSiteAttribute(call, 1, attribute_ref("sret"))

        # the call returns 'void', so the call result is actually 'sret':
        LibC.LLVMBuildLoad(@builder, sret, "")
      else
        call
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

        when "to_unsafe"
          case node.name
          when "String::to_unsafe"
            LibC.LLVMBuildLoad(@builder, @scope.get("self"), "self")
          end
        end
      raise "unknown primitive function '#{node.name}'" unless result
      result
    end
  end
end
