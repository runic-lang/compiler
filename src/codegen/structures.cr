module Runic
  class Codegen
    def codegen(node : AST::Struct) : LibC::LLVMValueRef
      node.methods.each { |fn| codegen(fn) }
      llvm_void_value
    end

    def codegen(node : AST::InstanceVariable) : LibC::LLVMValueRef
      raise CodegenError.new("BUG: no codegen for instance variable accessor")
    end
  end
end
