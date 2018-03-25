module Runic
  class Codegen
    def codegen(node : AST::Struct) : LibC::LLVMValueRef
      node.methods.each { |fn| codegen(fn) }
      llvm_void_value
    end
  end
end
