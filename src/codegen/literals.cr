require "../codegen"

module Runic
  class Codegen
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
      if alloca = @scope.get(node.name)
        @debug.emit_location(node)
        LibC.LLVMBuildLoad(@builder, alloca, node.name)
      else
        raise CodegenError.new("using variable before definition: #{node.name}")
      end
    end

    def codegen(node : AST::Constant) : LibC::LLVMValueRef
      if value = @constant_values[node.name]?
        @debug.emit_location(node)
        value
      else
        raise CodegenError.new("using constant before definition: #{node.name}")
      end
    end
  end
end
