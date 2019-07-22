require "../codegen"

module Runic
  class Codegen
    def codegen(node : AST::Reference) : LibC::LLVMValueRef
      raise CodegenError.new("pointer reference isn't implemented (yet)")
    end

    def codegen(node : AST::Dereference) : LibC::LLVMValueRef
      raise CodegenError.new("pointer dereference isn't implemented (yet)")
    end
  end
end
