module Runic
  class Codegen
    def codegen(node : AST::If) : LibC::LLVMValueRef
      @debug.emit_location(node)

      entry_block = LibC.LLVMGetInsertBlock(@builder)
      parent_block = LibC.LLVMGetBasicBlockParent(entry_block)
      then_block = LibC.LLVMAppendBasicBlockInContext(@context, parent_block, "then")
      end_block = LibC.LLVMAppendBasicBlockInContext(@context, parent_block, "end")

      count = node.alternative ? 2 : 1
      blocks = Array(LibC::LLVMBasicBlockRef).new(count)
      values = Array(LibC::LLVMValueRef).new(count)

      # then block:
      LibC.LLVMPositionBuilderAtEnd(@builder, then_block)
      values << codegen(node.body)
      blocks << LibC.LLVMGetInsertBlock(@builder)
      LibC.LLVMBuildBr(@builder, end_block)

      # if condition:
      LibC.LLVMPositionBuilderAtEnd(@builder, entry_block)
      condition = build_condition(node.condition)

      if body = node.alternative
        else_block = LibC.LLVMAppendBasicBlockInContext(@context, parent_block, "else")
        LibC.LLVMMoveBasicBlockBefore(else_block, end_block)

        # true -> then, false -> else
        LibC.LLVMBuildCondBr(@builder, condition, then_block, else_block)

        # else block:
        LibC.LLVMPositionBuilderAtEnd(@builder, else_block)
        values << codegen(body)
        blocks << LibC.LLVMGetInsertBlock(@builder)
        LibC.LLVMBuildBr(@builder, end_block)
      else
        # true -> then, false -> end
        LibC.LLVMBuildCondBr(@builder, condition, then_block, end_block)
      end

      # merge block:
      LibC.LLVMPositionBuilderAtEnd(@builder, end_block)

      if node.type == "void"
        # return invalid value (semantic analysis prevents its usage)
        return llvm_void_value
      end

      # return value
      phi = LibC.LLVMBuildPhi(@builder, llvm_type(node), "")
      LibC.LLVMAddIncoming(phi, values, blocks, count)
      phi
    end

    def codegen(node : AST::Unless) : LibC::LLVMValueRef
      @debug.emit_location(node)
      condition = build_condition(node.condition)

      entry_block = LibC.LLVMGetInsertBlock(@builder)
      parent_block = LibC.LLVMGetBasicBlockParent(entry_block)
      then_block = LibC.LLVMAppendBasicBlockInContext(@context, parent_block, "then")
      end_block = LibC.LLVMAppendBasicBlockInContext(@context, parent_block, "end")

      # true -> end, false -> then
      LibC.LLVMBuildCondBr(@builder, condition, end_block, then_block)

      # then block:
      LibC.LLVMPositionBuilderAtEnd(@builder, then_block)
      value = codegen(node.body)
      LibC.LLVMBuildBr(@builder, end_block)

      # merge block:
      LibC.LLVMPositionBuilderAtEnd(@builder, end_block)

      llvm_void_value
    end

    def codegen(node : AST::While) : LibC::LLVMValueRef
      @debug.emit_location(node)

      entry_block = LibC.LLVMGetInsertBlock(@builder)
      parent_block = LibC.LLVMGetBasicBlockParent(entry_block)
      loop_block = LibC.LLVMAppendBasicBlockInContext(@context, parent_block, "while")
      do_block = LibC.LLVMAppendBasicBlockInContext(@context, parent_block, "do")
      end_block = LibC.LLVMAppendBasicBlockInContext(@context, parent_block, "end")

      LibC.LLVMBuildBr(@builder, loop_block)

      # -> loop
      LibC.LLVMPositionBuilderAtEnd(@builder, loop_block)
      condition = build_condition(node.condition)

      # true -> do, false -> end
      LibC.LLVMBuildCondBr(@builder, condition, do_block, end_block)

      # do block:
      LibC.LLVMPositionBuilderAtEnd(@builder, do_block)
      value = codegen(node.body)
      LibC.LLVMBuildBr(@builder, loop_block)

      # merge block:
      LibC.LLVMPositionBuilderAtEnd(@builder, end_block)

      llvm_void_value
    end

    def codegen(node : AST::Until) : LibC::LLVMValueRef
      @debug.emit_location(node)

      entry_block = LibC.LLVMGetInsertBlock(@builder)
      parent_block = LibC.LLVMGetBasicBlockParent(entry_block)
      loop_block = LibC.LLVMAppendBasicBlockInContext(@context, parent_block, "until")
      do_block = LibC.LLVMAppendBasicBlockInContext(@context, parent_block, "do")
      end_block = LibC.LLVMAppendBasicBlockInContext(@context, parent_block, "end")

      LibC.LLVMBuildBr(@builder, loop_block)

      # -> loop
      LibC.LLVMPositionBuilderAtEnd(@builder, loop_block)
      condition = build_condition(node.condition)

      # true -> end, false -> do
      LibC.LLVMBuildCondBr(@builder, condition, end_block, do_block)

      # do block:
      LibC.LLVMPositionBuilderAtEnd(@builder, do_block)
      value = codegen(node.body)
      LibC.LLVMBuildBr(@builder, loop_block)

      # merge block:
      LibC.LLVMPositionBuilderAtEnd(@builder, end_block)

      llvm_void_value
    end

    def codegen(node : AST::Case) : LibC::LLVMValueRef
      @debug.emit_location(node)

      count = node.cases.size + (node.alternative ? 1 : 0)
      blocks = Array(LibC::LLVMBasicBlockRef).new(count)
      values = Array(LibC::LLVMValueRef).new(count)

      entry_block = LibC.LLVMGetInsertBlock(@builder)
      parent_block = LibC.LLVMGetBasicBlockParent(entry_block)
      end_block = LibC.LLVMAppendBasicBlockInContext(@context, parent_block, "end")
      ref_block = end_block

      value = codegen(node.value)

      if body = node.alternative
        else_block = LibC.LLVMAppendBasicBlockInContext(@context, parent_block, "else")
        LibC.LLVMMoveBasicBlockBefore(else_block, end_block)
        ref_block = else_block

        switch = LibC.LLVMBuildSwitch(@builder, value, else_block, count)

        LibC.LLVMPositionBuilderAtEnd(@builder, else_block)
        values << codegen(body)
        blocks << LibC.LLVMGetInsertBlock(@builder)
        LibC.LLVMBuildBr(@builder, end_block)
      else
        switch = LibC.LLVMBuildSwitch(@builder, value, end_block, count)
      end

      node.cases.each do |n|
        when_block = LibC.LLVMAppendBasicBlockInContext(@context, parent_block, "when")
        LibC.LLVMMoveBasicBlockBefore(when_block, ref_block)

        LibC.LLVMPositionBuilderAtEnd(@builder, when_block)
        values << codegen(n.body)
        blocks << LibC.LLVMGetInsertBlock(@builder)
        LibC.LLVMBuildBr(@builder, end_block)

        n.conditions.each do |condition|
          LibC.LLVMAddCase(switch, codegen(condition), when_block)
        end
      end

      LibC.LLVMPositionBuilderAtEnd(@builder, end_block)

      if node.type == "void"
        return llvm_void_value
      end

      phi = LibC.LLVMBuildPhi(@builder, llvm_type(node), "")
      LibC.LLVMAddIncoming(phi, values, blocks, count)
      phi
    end

    def codegen(node : AST::When) : LibC::LLVMValueRef
      raise CodegenError.new("#{node.class.name} can't be generated directly")
    end
  end
end
