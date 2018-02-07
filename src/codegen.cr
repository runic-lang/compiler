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
      if node.value.starts_with?('0') && node.value.size > 2
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
      if node.assignment?
        rhs = codegen(node.rhs)

        @debug.emit_location(node)

        case node.operator
        when "="
          lhse = node.lhs.as(AST::Variable)
          alloca = @named_values[lhse.name] ||= build_alloca(lhse)
          LibC.LLVMBuildStore(@builder, rhs, alloca)
          return rhs
        else
          unsupported_operation!(node)
        end
      end

      case node.operator
      when "&&" # logical and (with automatic skip of RHS if LHS is falsy)
        lhs = codegen_condition(node.lhs)

        entry = LibC.LLVMGetInsertBlock(@builder)
        parent_block = LibC.LLVMGetBasicBlockParent(entry)
        rhs_block = LibC.LLVMAppendBasicBlockInContext(@context, parent_block, "rhs_and")
        merge_block = LibC.LLVMAppendBasicBlockInContext(@context, parent_block, "merge_and")

        # declare conditional branching: execute RHS if LHS was truthy
        LibC.LLVMBuildCondBr(@builder, lhs, rhs_block, merge_block)

        # execute RHS in alternative branching
        LibC.LLVMPositionBuilderAtEnd(@builder, rhs_block)
        rhs = codegen_condition(node.rhs)
        LibC.LLVMBuildBr(@builder, merge_block)

        # continuation
        LibC.LLVMPositionBuilderAtEnd(@builder, merge_block)

        # retrieve value from the branch that ran
        phi = LibC.LLVMBuildPhi(@builder, llvm_type("bool"), "")
        LibC.LLVMAddIncoming(phi, pointerof(lhs), pointerof(entry), 1)
        LibC.LLVMAddIncoming(phi, pointerof(rhs), pointerof(rhs_block), 1)
        return phi

      when "||" # logical or (with automatic skip of RHS if LHS is truthy)
        lhs = codegen_condition(node.lhs)

        entry = LibC.LLVMGetInsertBlock(@builder)
        parent_block = LibC.LLVMGetBasicBlockParent(entry)
        rhs_block = LibC.LLVMAppendBasicBlockInContext(@context, parent_block, "rhs_or")
        merge_block = LibC.LLVMAppendBasicBlockInContext(@context, parent_block, "merge_or")

        # declare conditional branching
        LibC.LLVMBuildCondBr(@builder, lhs, merge_block, rhs_block)

        # execute RHS in alternative branching
        LibC.LLVMPositionBuilderAtEnd(@builder, rhs_block)
        rhs = codegen_condition(node.rhs)
        LibC.LLVMBuildBr(@builder, merge_block)

        # continuation
        LibC.LLVMPositionBuilderAtEnd(@builder, merge_block)

        # retrieve value from the branch that ran
        phi = LibC.LLVMBuildPhi(@builder, llvm_type("bool"), "")
        LibC.LLVMAddIncoming(phi, pointerof(lhs), pointerof(entry), 1)
        LibC.LLVMAddIncoming(phi, pointerof(rhs), pointerof(rhs_block), 1)
        return phi
      end

      lhs = codegen(node.lhs)
      rhs = codegen(node.rhs)

      @debug.emit_location(node)

      # float division: int / int always returns a float
      if node.operator == "/" && node.lhs.integer? && node.rhs.integer?
        lhs = integer_to_float(lhs, node.type)
        rhs = integer_to_float(rhs, node.type)
        return LibC.LLVMBuildFDiv(@builder, lhs, rhs, "")
      end

      # operations depends on LHS —or RHS when it's a float
      case node.operator
      when "+" # addition
        codegen_binary_operation(node, node.lhs.type, node.rhs.type, lhs, rhs) do |lhs, rhs|
          case node.type
          when .float?
            LibC.LLVMBuildFAdd(@builder, lhs, rhs, "")
          when .integer?
            LibC.LLVMBuildAdd(@builder, lhs, rhs, "")
          else
            unsupported_operation!(node)
          end
        end

      when "-" # substraction
        codegen_binary_operation(node, node.lhs.type, node.rhs.type, lhs, rhs) do |lhs, rhs|
          case node.type
          when .float?
            LibC.LLVMBuildFSub(@builder, lhs, rhs, "")
          when .integer?
            LibC.LLVMBuildSub(@builder, lhs, rhs, "")
          else
            unsupported_operation!(node)
          end
        end

      when "*" # multiplication
        codegen_binary_operation(node, node.lhs.type, node.rhs.type, lhs, rhs) do |lhs, rhs|
          case node.type
          when .float?
            LibC.LLVMBuildFMul(@builder, lhs, rhs, "")
          when .integer?
            LibC.LLVMBuildMul(@builder, lhs, rhs, "")
          else
            unsupported_operation!(node)
          end
        end

      when "/" # division (float or mix float/int)
        codegen_binary_operation(node, node.lhs.type, node.rhs.type, lhs, rhs) do |lhs, rhs|
          case node.type
          when .float?
            LibC.LLVMBuildFDiv(@builder, lhs, rhs, "")
          else
            unsupported_operation!(node)
          end
        end

      when "//" # floor division
        result = codegen_binary_operation(node, node.lhs.type, node.rhs.type, lhs, rhs) do |lhs, rhs|
          case node.type
          when .float?
            LibC.LLVMBuildFDiv(@builder, lhs, rhs, "")
          when .unsigned?
            LibC.LLVMBuildUDiv(@builder, lhs, rhs, "")
          when .integer?
            LibC.LLVMBuildSDiv(@builder, lhs, rhs, "")
          else
            unsupported_operation!(node)
          end
        end
        if node.type.float?
          LibC.LLVMBuildCall(@builder, intrinsic("llvm.floor", node.type), [result], 1, "")
        else
          result
        end

      when "%" # modulo
        codegen_binary_operation(node, node.lhs.type, node.rhs.type, lhs, rhs) do |lhs, rhs|
          case node.type
          when .float?
            LibC.LLVMBuildFRem(@builder, lhs, rhs, "")
          when .unsigned?
            LibC.LLVMBuildURem(@builder, lhs, rhs, "")
          when .integer?
            LibC.LLVMBuildSRem(@builder, lhs, rhs, "")
          else
            unsupported_operation!(node)
          end
        end

      when "<<" # shift left
        case node.type
        when .integer?
          LibC.LLVMBuildShl(@builder, lhs, rhs, "")
        else
          unsupported_operation!(node)
        end

      when ">>" # shift right
        case node.type
        when .unsigned?
          LibC.LLVMBuildLShr(@builder, lhs, rhs, "")
        when .integer?
          LibC.LLVMBuildAShr(@builder, lhs, rhs, "")
        else
          unsupported_operation!(node)
        end

      when "&" # and
        case node.type
        when .integer?
          LibC.LLVMBuildAnd(@builder, lhs, rhs, "")
        else
          unsupported_operation!(node)
        end

      when "|" # or
        case node.type
        when .integer?
          LibC.LLVMBuildOr(@builder, lhs, rhs, "")
        else
          unsupported_operation!(node)
        end

      when "^" # xor
        case node.type
        when .integer?
          LibC.LLVMBuildXor(@builder, lhs, rhs, "")
        else
          unsupported_operation!(node)
        end

      when "==" # equality
        codegen_equality_operator(node, lhs, rhs, false, LibC::LLVMIntPredicate::IntEQ, LibC::LLVMRealPredicate::RealOEQ)

      when "!=" # inequality
        codegen_equality_operator(node, lhs, rhs, true, LibC::LLVMIntPredicate::IntNE, LibC::LLVMRealPredicate::RealONE)

      when "<" # lower than
        codegen_binary_operation(node, node.lhs.type, node.rhs.type, lhs, rhs) do |lhs, rhs|
          if node.lhs.float? || node.rhs.float?
            LibC.LLVMBuildFCmp(@builder, LibC::LLVMRealPredicate::RealOLT, lhs, rhs, "")
          elsif node.lhs.unsigned? && node.rhs.unsigned?
            LibC.LLVMBuildICmp(@builder, LibC::LLVMIntPredicate::IntULT, lhs, rhs, "")
          elsif node.lhs.signed? && node.rhs.signed?
            LibC.LLVMBuildICmp(@builder, LibC::LLVMIntPredicate::IntSLT, lhs, rhs, "")
          else
            unsupported_operation!(node)
          end
        end

      when "<=" # lower than or equal
        codegen_binary_operation(node, node.lhs.type, node.rhs.type, lhs, rhs) do |lhs, rhs|
          if node.lhs.float? || node.rhs.float?
            LibC.LLVMBuildFCmp(@builder, LibC::LLVMRealPredicate::RealOLE, lhs, rhs, "")
          elsif node.lhs.unsigned? && node.rhs.unsigned?
            LibC.LLVMBuildICmp(@builder, LibC::LLVMIntPredicate::IntULE, lhs, rhs, "")
          elsif node.lhs.signed? && node.rhs.signed?
            LibC.LLVMBuildICmp(@builder, LibC::LLVMIntPredicate::IntSLE, lhs, rhs, "")
          else
            unsupported_operation!(node)
          end
        end

      when ">" # greater than
        codegen_binary_operation(node, node.lhs.type, node.rhs.type, lhs, rhs) do |lhs, rhs|
          if node.lhs.float? || node.rhs.float?
            LibC.LLVMBuildFCmp(@builder, LibC::LLVMRealPredicate::RealOGT, lhs, rhs, "")
          elsif node.lhs.unsigned? && node.rhs.unsigned?
            LibC.LLVMBuildICmp(@builder, LibC::LLVMIntPredicate::IntUGT, lhs, rhs, "")
          elsif node.lhs.signed? && node.rhs.signed?
            LibC.LLVMBuildICmp(@builder, LibC::LLVMIntPredicate::IntSGT, lhs, rhs, "")
          else
            unsupported_operation!(node)
          end
        end

      when ">=" # greater than or equal
        codegen_binary_operation(node, node.lhs.type, node.rhs.type, lhs, rhs) do |lhs, rhs|
          if node.lhs.float? || node.rhs.float?
            LibC.LLVMBuildFCmp(@builder, LibC::LLVMRealPredicate::RealOGE, lhs, rhs, "")
          elsif node.lhs.unsigned? && node.rhs.unsigned?
            LibC.LLVMBuildICmp(@builder, LibC::LLVMIntPredicate::IntUGE, lhs, rhs, "")
          elsif node.lhs.signed? && node.rhs.signed?
            LibC.LLVMBuildICmp(@builder, LibC::LLVMIntPredicate::IntSGE, lhs, rhs, "")
          else
            unsupported_operation!(node)
          end
        end

      #when "<=>" # lower, equal or greater than?
      #  codegen_compare_operator(node, lhs, rhs)

      else
        raise CodegenError.new("unsupported binary operator: '#{node.operator}' (yet?)")
      end
    end

    private def codegen_equality_operator(node : AST::Binary, lhs, rhs, default, int_predicate, real_predicate)
      llvm_default = LibC.LLVMConstInt(llvm_type("bool"), default ? 1 : 0, 0)

      # NOTE: bool checks shall eventually be removed when primitive types can
      #       be defined programmatically, overloaded functions and explicit type
      #       casts made available.
      if node.lhs.bool?
        if node.rhs.bool?
          LibC.LLVMBuildICmp(@builder, int_predicate, lhs, rhs, "")
        else
          llvm_default
        end
      elsif node.rhs.bool?
        llvm_default
      else
        codegen_binary_operation(node, node.lhs.type, node.rhs.type, lhs, rhs) do |lhs, rhs|
          if node.lhs.float? || node.rhs.float?
            LibC.LLVMBuildFCmp(@builder, real_predicate, lhs, rhs, "")
          elsif node.lhs.integer? && node.rhs.integer?
            LibC.LLVMBuildICmp(@builder, int_predicate, lhs, rhs, "")
          else
            unsupported_operation!(node)
          end
        end
      end
    end

    # Returns false (0_i1) if the expression evaluates to false or a null
    # pointer. Returns true (1_i1) otherwise.
    private def codegen_condition(node : AST::Node)
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

    #private def codegen_compare_operator(node : AST::Binary, lhs, rhs)
    #end

    private def unsupported_operation!(node : AST::Binary)
      raise CodegenError.new("unsupported #{node.lhs.type} #{node.operator} #{node.rhs.type} binary operation (yet)")
    end

    private def unsupported_operation!(node : AST::Unary)
      raise CodegenError.new("unsupported #{node.operator}#{node.expression.type} unary operation (yet)")
    end

    # Harmonizes both operands (if possible) for a given binary operation, in
    # order for the operation to operate on the same type.
    #
    # NOTE: should eventually be replaced when primitive types can be defined
    #       programmatically and overloaded functions are available, along with
    #       explicit type casts.
    private def codegen_binary_operation(node : AST::Binary, lty, rty, lhs, rhs)
      if lty.float?
        if rty.float?
          return codegen_bin_op_ff(node, lty, rty, lhs, rhs) { |l, r | yield l, r }
        elsif rty.integer?
          return codegen_bin_op_fi(node, lty, rty, lhs, rhs) { |l, r | yield l, r }
        end
      elsif lty.integer?
        if rty.float?
          # same as float+integer so we exchange rhs <-> lhs then exchange them
          # again to the block (so operands are correct).
          return codegen_bin_op_fi(node, rty, lty, rhs, lhs) { |l, r | yield r, l }
        elsif rty.integer?
          return codegen_bin_op_ii(node, lty, rty, lhs, rhs) { |l, r | yield l, r }
        end
      end
      unsupported_operation!(node)
    end

    # float + float
    private def codegen_bin_op_ff(node : AST::Binary, lty, rty, lhs, rhs)
      intermediary_type = lty

      # harmonize representation to largest common denominator
      if lty < rty
        lhs = LibC.LLVMBuildFPExt(@builder, lhs, llvm_type(rty), "")
        intermediary_type = rty
      elsif lty > rty
        rhs = LibC.LLVMBuildFPExt(@builder, rhs, llvm_type(lty), "")
      end

      result = yield lhs, rhs

      # eventually trunc or extend the result (if needed)
      if intermediary_type == node.type
        result
      elsif intermediary_type < node.type
        LibC.LLVMBuildFPExt(@builder, result, llvm_type(node.type), "")
      else # intermediary_type > node.type
        LibC.LLVMBuildFPTrunc(@builder, result, llvm_type(node.type), "")
      end
    end

    # float+integer
    private def codegen_bin_op_fi(node : AST::Binary, lty, rty, lhs, rhs)
      # extend RHS to match LHS size
      if rty < lty
        case lty.name
        when "f32" then rhs = extend_integer(rhs, "i32", rty.unsigned?)
        when "f64" then rhs = extend_integer(rhs, "i64", rty.unsigned?)
        else unsupported_operation!(node)
        end
      end

      # cast integer to float
      rhs = LibC.LLVMBuildSIToFP(@builder, rhs, llvm_type(lty), "")

      # generator operation (resulting type is )
      yield lhs, rhs
    end

    # integer+integer
    private def codegen_bin_op_ii(node : AST::Binary, lty, rty, lhs, rhs)
      # extend smaller operand to match the size of the larger one (if needed)
      intermediary_type = lty

      if lty < rty
        lhs = extend_integer(lhs, rty, lty.unsigned?)
        intermediary_type = rty
      elsif lty > rty
        rhs = extend_integer(rhs, lty, rty.unsigned?)
      end

      result = yield lhs, rhs

      # eventually trunc or extend the result (if needed)
      if intermediary_type == node.type
        result
      elsif intermediary_type < node.type
        extend_integer(result, node.type, node.unsigned?)
        else # intermediary_type > node.type
        LibC.LLVMBuildTrunc(@builder, result, llvm_type(node), "")
      end
    end

    private def extend_integer(value, type, unsigned = false)
      if unsigned
        LibC.LLVMBuildZExt(@builder, value, llvm_type(type), "")
      else
        LibC.LLVMBuildSExt(@builder, value, llvm_type(type), "")
      end
    end

    private def integer_to_float(value, type : Type)
      if type.unsigned?
        LibC.LLVMBuildUIToFP(@builder, value, llvm_type(type), "")
      else
        LibC.LLVMBuildSIToFP(@builder, value, llvm_type(type), "")
      end
    end

    def codegen(node : AST::Unary) : LibC::LLVMValueRef
      expression = codegen(node.expression)
      @debug.emit_location(node)

      case node.operator
      when "-" # negative
        case node.type
        when .float?
          LibC.LLVMBuildFNeg(@builder, expression, "")
        when .integer?
          LibC.LLVMBuildNeg(@builder, expression, "")
        else
          unsupported_operation!(node)
        end
      when "!" # not
        case node.expression.type
        when .bool?
          bool_true = LibC.LLVMConstInt(llvm_type("bool"), 1, 0)
          LibC.LLVMBuildICmp(@builder, LibC::LLVMIntPredicate::IntNE, expression, bool_true, "")
        # when .pointer?
        # TODO: NULL pointer must return false
        else
          # other types are always truthy, so !truthy is always false
          LibC.LLVMConstInt(llvm_type("bool"), 0, 0)
        end
      when "~" # bitwise not
        case node.type
        when .integer?
          LibC.LLVMBuildNot(@builder, expression, "")
        else
          unsupported_operation!(node)
        end
      else
        raise CodegenError.new("unsupported unary operator: '#{node.operator}'")
      end
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
