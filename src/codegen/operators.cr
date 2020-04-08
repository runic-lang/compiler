require "../codegen"
require "./intrinsics"

module Runic
  class Codegen
    def codegen(node : AST::Assignment) : LibC::LLVMValueRef
      lhs = node.lhs

      unless node.operator == "="
        raise CodegenError.new("unsupported #{lhs.type} #{node.operator} #{node.rhs.type} assignment")
      end

      if node.lhs.is_a?(AST::Call)
        # assignment is a setter call:
        return codegen(node.lhs)
      end

      # avoid creating a temporary alloca when LHS can be used; this avoids
      # using 2 allocas + struct copy when initializing a struct on the stack:
      case n = node.rhs
      when AST::Call
        if n.constructor?
          if alloca = get_or_build_assignment_alloca(lhs)
            build_stack_constructor(n, alloca)
            return LibC.LLVMBuildLoad(@builder, alloca, "") # return self
          end
        elsif n.type.aggregate?
          # TODO: unless the struct fits in a register (data_layout.native_integers.max)
          if alloca = get_or_build_assignment_alloca(lhs)
            build_sret_call(n, alloca)
            return LibC.LLVMBuildLoad(@builder, alloca, "") # return sret
          end
        end
      when AST::Binary #, AST::Unary
        if n.type.aggregate?
          # TODO: unless the struct fits in a register (data_layout.native_integers.max)
          if alloca = get_or_build_assignment_alloca(lhs)
            build_sret_call(n, alloca)
            return LibC.LLVMBuildLoad(@builder, alloca, "") # return sret
          end
        end
      else
        # shut up, crystal
      end

      rhs = codegen(node.rhs)

      if alloca = get_or_build_assignment_alloca(lhs)
        # set value (stack, dereferenced pointer, ...):
        @debug.emit_location(node)
        LibC.LLVMBuildStore(@builder, rhs, alloca)
      else
        raise CodegenError.new("invalid LHS for assignment: #{lhs.class.name}")
      end

      rhs
    end

    private def get_or_build_assignment_alloca(node : AST::Node) : LibC::LLVMValueRef?
      case node
      when AST::Variable
        # get or create alloca (stack pointer)
        @scope.fetch(node.name) do
          build_alloca(node) do |alloca|
            @debug.auto_variable(node, alloca)
          end
        end
      when AST::InstanceVariable
        build_ivar(node.name)
      when AST::Dereference
        if (pointee = node.pointee).is_a?(AST::Variable)
          LibC.LLVMBuildLoad(@builder, @scope.get(pointee.name), "")
        end
      else
        # shut up, crystal
      end
    end

    def codegen(node : AST::Binary) : LibC::LLVMValueRef
      method = node.method

      if method.attributes.includes?("primitive")
        case method.original_name
        when "+" then codegen_addition(node)
        when "-" then codegen_substraction(node)
        when "*" then codegen_multiplication(node)
        when "**" then codegen_exponentiation(node)
        when "/" then codegen_float_division(node)
        when "%" then codegen_remainder(node)

        when "&" then codegen_bitwise_and(node)
        when "|" then codegen_bitwise_or(node)
        when "^" then codegen_bitwise_xor(node)
        when "<<" then codegen_bitwise_shift_left(node)
        when ">>" then codegen_bitwise_shift_right(node)

        when "==" then codegen_equal(node)
        when "!=" then codegen_not_equal(node)
        when "<" then codegen_less_than(node)
        when "<=" then codegen_less_than_or_equal_to(node)
        when ">" then codegen_greater_than(node)
        when ">=" then codegen_greater_than_or_equal_to(node)

        when "&&" then codegen_boolean_and(node)
        when "||" then codegen_boolean_or(node)

        else
          unsupported_operation!(node)
        end
      elsif func = LibC.LLVMGetNamedFunction(@module, method.symbol_name)
        build_call(func, method.type, node.lhs, [node.rhs], node.location)
      else
        raise CodegenError.new("undefined function '#{method.name}'")
      end
    end

    private def codegen_addition(node : AST::Binary)
      codegen_operation(node) do |type, lhs, rhs|
        case node.type
        when .integer?
          LibC.LLVMBuildAdd(@builder, lhs, rhs, "")
        when .float?
          LibC.LLVMBuildFAdd(@builder, lhs, rhs, "")
        else
          raise "unreachable"
        end
      end
    end

    private def codegen_substraction(node : AST::Binary)
      codegen_operation(node) do |type, lhs, rhs|
        case type
        when .integer?
          LibC.LLVMBuildSub(@builder, lhs, rhs, "")
        when .float?
          LibC.LLVMBuildFSub(@builder, lhs, rhs, "")
        else
          raise "unreachable"
        end
      end
    end

    private def codegen_multiplication(node : AST::Binary)
      codegen_operation(node) do |type, lhs, rhs|
        case type
        when .integer?
          LibC.LLVMBuildMul(@builder, lhs, rhs, "")
        when .float?
          LibC.LLVMBuildFMul(@builder, lhs, rhs, "")
        else
          raise "unreachable"
        end
      end
    end

    private def codegen_exponentiation(node : AST::Binary)
      codegen_operation(node) do |type, lhs, rhs|
        if type.float?
          LibC.LLVMBuildCall(@builder, llvm_intrinsic("pow", type), [lhs, rhs], 2, "")
        end
      end
    end

    private def codegen_float_division(node : AST::Binary)
      codegen_operation(node) do |type, lhs, rhs|
        if type.float?
          LibC.LLVMBuildFDiv(@builder, lhs, rhs, "")
        end
      end
    end

    private def codegen_remainder(node : AST::Binary)
      codegen_operation(node) do |type, lhs, rhs|
        case type
        when .unsigned?
          LibC.LLVMBuildURem(@builder, lhs, rhs, "")
        when .integer?
          LibC.LLVMBuildSRem(@builder, lhs, rhs, "")
        when .float?
          LibC.LLVMBuildFRem(@builder, lhs, rhs, "")
        else
          raise "unreachable"
        end
      end
    end

    private def codegen_bitwise_and(node : AST::Binary)
      codegen_operation(node) do |type, lhs, rhs|
        if type.integer?
          LibC.LLVMBuildAnd(@builder, lhs, rhs, "")
        end
      end
    end

    private def codegen_bitwise_or(node : AST::Binary)
      codegen_operation(node) do |type, lhs, rhs|
        if type.integer?
          LibC.LLVMBuildOr(@builder, lhs, rhs, "")
        end
      end
    end

    private def codegen_bitwise_xor(node : AST::Binary)
      codegen_operation(node) do |type, lhs, rhs|
        if type.integer?
          LibC.LLVMBuildXor(@builder, lhs, rhs, "")
        end
      end
    end

    private def codegen_bitwise_shift_left(node : AST::Binary)
      codegen_operation(node) do |type, lhs, rhs|
        if type.integer?
          LibC.LLVMBuildShl(@builder, lhs, rhs, "")
        end
      end
    end

    private def codegen_bitwise_shift_right(node : AST::Binary)
      codegen_operation(node) do |type, lhs, rhs|
        case type
        when .unsigned?
          LibC.LLVMBuildLShr(@builder, lhs, rhs, "")
        when .integer?
          LibC.LLVMBuildAShr(@builder, lhs, rhs, "")
        else
          raise "unreachable"
        end
      end
    end

    private def codegen_equal(node : AST::Binary)
      codegen_operation(node) do |type, lhs, rhs|
        case type
        when .bool?, .integer?
          LibC.LLVMBuildICmp(@builder, LibC::LLVMIntPredicate::IntEQ, lhs, rhs, "")
        when .float?
          LibC.LLVMBuildFCmp(@builder, LibC::LLVMRealPredicate::RealOEQ, lhs, rhs, "")
        else
          raise "unreachable"
        end
      end
    end

    private def codegen_not_equal(node : AST::Binary)
      codegen_operation(node) do |type, lhs, rhs|
        case type
        when .bool?, .integer?
          LibC.LLVMBuildICmp(@builder, LibC::LLVMIntPredicate::IntNE, lhs, rhs, "")
        when .float?
          LibC.LLVMBuildFCmp(@builder, LibC::LLVMRealPredicate::RealONE, lhs, rhs, "")
        else
          raise "unreachable"
        end
      end
    end

    private def codegen_less_than(node : AST::Binary)
      codegen_operation(node) do |type, lhs, rhs|
        case type
        when .unsigned?
          LibC.LLVMBuildICmp(@builder, LibC::LLVMIntPredicate::IntULT, lhs, rhs, "")
        when .integer?
          LibC.LLVMBuildICmp(@builder, LibC::LLVMIntPredicate::IntSLT, lhs, rhs, "")
        when .float?
          LibC.LLVMBuildFCmp(@builder, LibC::LLVMRealPredicate::RealOLT, lhs, rhs, "")
        else
          raise "unreachable"
        end
      end
    end

    private def codegen_less_than_or_equal_to(node : AST::Binary)
      codegen_operation(node) do |type, lhs, rhs|
        case type
        when .unsigned?
          LibC.LLVMBuildICmp(@builder, LibC::LLVMIntPredicate::IntULE, lhs, rhs, "")
        when .integer?
          LibC.LLVMBuildICmp(@builder, LibC::LLVMIntPredicate::IntSLE, lhs, rhs, "")
        when .float?
          LibC.LLVMBuildFCmp(@builder, LibC::LLVMRealPredicate::RealOLE, lhs, rhs, "")
        else
          raise "unreachable"
        end
      end
    end

    private def codegen_greater_than(node : AST::Binary)
      codegen_operation(node) do |type, lhs, rhs|
        case type
        when .unsigned?
          LibC.LLVMBuildICmp(@builder, LibC::LLVMIntPredicate::IntUGT, lhs, rhs, "")
        when .integer?
          LibC.LLVMBuildICmp(@builder, LibC::LLVMIntPredicate::IntSGT, lhs, rhs, "")
        when .float?
          LibC.LLVMBuildFCmp(@builder, LibC::LLVMRealPredicate::RealOGT, lhs, rhs, "")
        else
          raise "unreachable"
        end
      end
    end

    private def codegen_greater_than_or_equal_to(node : AST::Binary)
      codegen_operation(node) do |type, lhs, rhs|
        case type
        when .unsigned?
          LibC.LLVMBuildICmp(@builder, LibC::LLVMIntPredicate::IntUGE, lhs, rhs, "")
        when .integer?
          LibC.LLVMBuildICmp(@builder, LibC::LLVMIntPredicate::IntSGE, lhs, rhs, "")
        when .float?
          LibC.LLVMBuildFCmp(@builder, LibC::LLVMRealPredicate::RealOGE, lhs, rhs, "")
        else
          raise "unreachable"
        end
      end
    end

    # logical and with automatic skip of RHS if LHS is falsy
    private def codegen_boolean_and(node : AST::Binary)
      lhs = build_condition(node.lhs)

      entry = LibC.LLVMGetInsertBlock(@builder)
      parent_block = LibC.LLVMGetBasicBlockParent(entry)
      rhs_block = LibC.LLVMAppendBasicBlockInContext(@context, parent_block, "rhs_and")
      merge_block = LibC.LLVMAppendBasicBlockInContext(@context, parent_block, "merge_and")

      # declare conditional branching: execute RHS if LHS was *truthy*
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

      phi
    end

    # logical or with automatic skip of RHS if LHS is truthy
    private def codegen_boolean_or(node : AST::Binary)
      lhs = build_condition(node.lhs)

      entry = LibC.LLVMGetInsertBlock(@builder)
      parent_block = LibC.LLVMGetBasicBlockParent(entry)
      rhs_block = LibC.LLVMAppendBasicBlockInContext(@context, parent_block, "rhs_or")
      merge_block = LibC.LLVMAppendBasicBlockInContext(@context, parent_block, "merge_or")

      # declare conditional branching: execute RHS if LHS was *falsy*
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

      phi
    end

    def codegen(node : AST::Unary) : LibC::LLVMValueRef
      case node.operator
      when "-" then codegen_negation(node)
      when "!" then codegen_not(node)
      when "~" then codegen_bitwise_not(node)
      else unsupported_operation!(node)
      end
    end

    private def codegen_negation(node : AST::Unary)
      codegen_operation(node) do |type, expression|
        case type
        when .integer?
          LibC.LLVMBuildNeg(@builder, expression, "")
        when .float?
          LibC.LLVMBuildFNeg(@builder, expression, "")
        else
          raise "unreachable"
        end
      end
    end

    private def codegen_not(node : AST::Unary)
      codegen_operation(node) do |type, expression|
        case type
        when .bool?
          bool_true = LibC.LLVMConstInt(llvm_type("bool"), 1, 0)
          LibC.LLVMBuildICmp(@builder, LibC::LLVMIntPredicate::IntNE, expression, bool_true, "")
        #when .pointer?
          # TODO: NULL pointer
        else
          # other types are always truthy, so !truthy is always false
          LibC.LLVMConstInt(llvm_type("bool"), 0, 0)
        end
      end
    end

    private def codegen_bitwise_not(node : AST::Unary)
      codegen_operation(node) do |type, expression|
        if type.integer?
          LibC.LLVMBuildNot(@builder, expression, "")
        end
      end
    end

    private def codegen_operation(node : AST::Binary)
      if node.lhs.type == node.rhs.type
        lhs = codegen(node.lhs)
        rhs = codegen(node.rhs)

        @debug.emit_location(node)

        if result = yield node.lhs.type, lhs, rhs
          return result
        end
      end
      unsupported_operation!(node)
    end

    private def codegen_operation(node : AST::Unary)
      expression = codegen(node.expression)
      @debug.emit_location(node)

      if result = yield node.expression.type, expression
        result
      else
        unsupported_operation!(node)
      end
    end

    private def unsupported_operation!(node : AST::Binary)
      raise CodegenError.new("unsupported #{node.lhs.type} #{node.operator} #{node.rhs.type} binary operation")
    end

    private def unsupported_operation!(node : AST::Unary)
      raise CodegenError.new("unsupported #{node.operator}#{node.expression.type} unary operation")
    end
  end
end
