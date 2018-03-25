require "../codegen"

module Runic
  class Codegen
    def codegen(node : AST::Binary) : LibC::LLVMValueRef
      if node.assignment?
        rhs = codegen(node.rhs)

        @debug.emit_location(node)

        case node.operator
        when "="
          case node.lhs
          when AST::Variable
            # store value on the stack
            lhse = node.lhs.as(AST::Variable)
            alloca = @scope.fetch(lhse.name) { build_alloca(lhse) }
            LibC.LLVMBuildStore(@builder, rhs, alloca)
          else
            raise CodegenError.new("invalid LHS for assignment: #{node.lhs.class}")
          end

          return rhs
        else
          unsupported_operation!(node)
        end
      end

      case node.operator
      when "&&" # logical and (with automatic skip of RHS if LHS is falsy)
        lhs = build_condition(node.lhs)

        entry = LibC.LLVMGetInsertBlock(@builder)
        parent_block = LibC.LLVMGetBasicBlockParent(entry)
        rhs_block = LibC.LLVMAppendBasicBlockInContext(@context, parent_block, "rhs_and")
        merge_block = LibC.LLVMAppendBasicBlockInContext(@context, parent_block, "merge_and")

        # declare conditional branching: execute RHS if LHS was truthy
        LibC.LLVMBuildCondBr(@builder, lhs, rhs_block, merge_block)

        # execute RHS in alternative branching
        LibC.LLVMPositionBuilderAtEnd(@builder, rhs_block)
        rhs = build_condition(node.rhs)
        LibC.LLVMBuildBr(@builder, merge_block)

        # continuation
        LibC.LLVMPositionBuilderAtEnd(@builder, merge_block)

        # retrieve value from the branch that ran
        phi = LibC.LLVMBuildPhi(@builder, llvm_type("bool"), "")
        LibC.LLVMAddIncoming(phi, pointerof(lhs), pointerof(entry), 1)
        LibC.LLVMAddIncoming(phi, pointerof(rhs), pointerof(rhs_block), 1)
        return phi

      when "||" # logical or (with automatic skip of RHS if LHS is truthy)
        lhs = build_condition(node.lhs)

        entry = LibC.LLVMGetInsertBlock(@builder)
        parent_block = LibC.LLVMGetBasicBlockParent(entry)
        rhs_block = LibC.LLVMAppendBasicBlockInContext(@context, parent_block, "rhs_or")
        merge_block = LibC.LLVMAppendBasicBlockInContext(@context, parent_block, "merge_or")

        # declare conditional branching
        LibC.LLVMBuildCondBr(@builder, lhs, merge_block, rhs_block)

        # execute RHS in alternative branching
        LibC.LLVMPositionBuilderAtEnd(@builder, rhs_block)
        rhs = build_condition(node.rhs)
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

      when "&" # bitwise and
        case node.type
        when .integer?
          LibC.LLVMBuildAnd(@builder, lhs, rhs, "")
        else
          unsupported_operation!(node)
        end

      when "|" # bitwise or
        case node.type
        when .integer?
          LibC.LLVMBuildOr(@builder, lhs, rhs, "")
        else
          unsupported_operation!(node)
        end

      when "^" # bitwise xor
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
  end
end
