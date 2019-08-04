module Runic
  class Codegen
    def codegen(node : AST::Struct) : LibC::LLVMValueRef
      type = build_llvm_struct(node.name)
      elements = node.variables.map { |t| llvm_type(t) }
      packed = node.attribute?("packed") ? 1 : 0
      LibC.LLVMStructSetBody(type, elements, elements.size, packed)

      node.variables.each { |ivar| @ivars << ivar.name }
      node.methods.each { |fn| codegen(fn) }

      @ivars.clear
      llvm_void_value
    end

    def codegen(node : AST::InstanceVariable) : LibC::LLVMValueRef
      LibC.LLVMBuildLoad(@builder, build_ivar(node.name), "")
    end

    def build_ivar(name : String) : LibC::LLVMValueRef
      if slf_ptr = @scope.get("self")
        if index = @ivars.index(name)
          slf = LibC.LLVMBuildLoad(@builder, slf_ptr, "")
          LibC.LLVMBuildStructGEP(@builder, slf, index, "")
        else
          raise CodegenError.new("undefined instance variable @#{name}")
        end
      else
        raise CodegenError.new("can't access instance variable in non struct-method")
      end
    end
  end
end
