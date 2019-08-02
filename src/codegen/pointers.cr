require "../codegen"

module Runic
  class Codegen
    def codegen(node : AST::Reference) : LibC::LLVMValueRef
      case pointee = node.pointee
      when AST::Variable
        if alloca = @scope.get(pointee.name)
          alloca
        else
          raise CodegenError.new("using variable before definition: #{pointee.name}")
        end
      when AST::Alloca
        codegen(node.pointee)
      else
        raise "BUG: unknown reference pointee #{pointee.class.name} (only variables an allocas are supported)"
      end
    end

    def codegen(node : AST::Dereference) : LibC::LLVMValueRef
      pointer = codegen(node.pointee)

      @debug.emit_location(node)
      LibC.LLVMBuildLoad(@builder, pointer, "")
    end
  end
end
