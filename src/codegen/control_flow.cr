module Runic
  class Codegen
    def codegen(node : AST::If) : LibC::LLVMValueRef
      @debug.emit_location(node)
      condition = build_condition(node.condition)

      entry = LibC.LLVMGetInsertBlock(@builder)
      parent_block = LibC.LLVMGetBasicBlockParent(entry)
      then_block = LibC.LLVMAppendBasicBlockInContext(@context, parent_block, "then")
      end_block = LibC.LLVMAppendBasicBlockInContext(@context, parent_block, "end")

      blocks = [then_block]
      values = [] of LibC::LLVMValueRef

      # then block:
      LibC.LLVMPositionBuilderAtEnd(@builder, then_block)
      values << codegen(node.body)
      LibC.LLVMBuildBr(@builder, end_block)
      LibC.LLVMPositionBuilderAtEnd(@builder, entry)

      if body = node.alternative
        else_block = LibC.LLVMAppendBasicBlockInContext(@context, parent_block, "else")
        LibC.LLVMMoveBasicBlockBefore(else_block, end_block)
        blocks << else_block

        # true -> then, false -> else
        LibC.LLVMBuildCondBr(@builder, condition, then_block, else_block)

        # else block:
        LibC.LLVMPositionBuilderAtEnd(@builder, else_block)
        values << codegen(body)
        LibC.LLVMBuildBr(@builder, end_block)
      else
        # true -> then, false -> end
        LibC.LLVMBuildCondBr(@builder, condition, then_block, end_block)
      end

      # merge block:
      LibC.LLVMPositionBuilderAtEnd(@builder, end_block)

      if node.type == "void"
        # return invalid value (semantic analysis prevents it)
        return llvm_void_value
      end

      # return a value:
      unless values.size == blocks.size
        raise CodegenError.new("ERROR: #{values.inspect}.size != #{blocks.inspect}.size")
      end
      phi = LibC.LLVMBuildPhi(@builder, llvm_type(node), "")
      LibC.LLVMAddIncoming(phi, values, blocks, blocks.size)
      phi
    end

    def codegen(node : AST::Unless) : LibC::LLVMValueRef
      @debug.emit_location(node)
      condition = build_condition(node.condition)

      entry = LibC.LLVMGetInsertBlock(@builder)
      parent_block = LibC.LLVMGetBasicBlockParent(entry)
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

      entry = LibC.LLVMGetInsertBlock(@builder)
      parent_block = LibC.LLVMGetBasicBlockParent(entry)
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

      entry = LibC.LLVMGetInsertBlock(@builder)
      parent_block = LibC.LLVMGetBasicBlockParent(entry)
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

      count = node.cases.size
      blocks = Array(LibC::LLVMBasicBlockRef).new(count)
      values = Array(LibC::LLVMValueRef).new(count)

      entry = LibC.LLVMGetInsertBlock(@builder)
      parent_block = LibC.LLVMGetBasicBlockParent(entry)
      end_block = LibC.LLVMAppendBasicBlockInContext(@context, parent_block, "end")

      value = codegen(node.value)

      if body = node.alternative
        else_block = LibC.LLVMAppendBasicBlockInContext(@context, parent_block, "else")
        LibC.LLVMPositionBuilderAtEnd(@builder, else_block)
        else_value = codegen(body)
        LibC.LLVMBuildBr(@builder, end_block)

        LibC.LLVMPositionBuilderAtEnd(@builder, entry)
        switch = LibC.LLVMBuildSwitch(@builder, value, else_block, count)
      else
        switch = LibC.LLVMBuildSwitch(@builder, value, end_block, count)
      end

      node.cases.each do |n|
        block = LibC.LLVMAppendBasicBlockInContext(@context, parent_block, "when")
        LibC.LLVMMoveBasicBlockBefore(block, end_block)
        blocks << block

        LibC.LLVMPositionBuilderAtEnd(@builder, block)
        values << codegen(n.body)
        LibC.LLVMBuildBr(@builder, end_block)

        n.conditions.each do |condition|
          LibC.LLVMAddCase(switch, codegen(condition), block)
        end
      end

      LibC.LLVMPositionBuilderAtEnd(@builder, end_block)

      if else_block
        LibC.LLVMMoveBasicBlockBefore(else_block, end_block)
        blocks << else_block
        values << else_value.not_nil!
        count += 1
      end

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
