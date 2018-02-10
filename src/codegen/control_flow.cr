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
  end
end
