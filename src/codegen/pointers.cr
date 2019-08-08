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
        # must store the expression in an alloca to pass its value by reference;
        # this should only happen to pass 'self' in expressions such as `"hello".to_unsafe`
        value = codegen(node.pointee)

        @debug.emit_location(node)
        alloca = LibC.LLVMBuildAlloca(@builder, llvm_type(node.pointee.type), "")
        LibC.LLVMBuildStore(@builder, value, alloca)
        alloca

        #raise "BUG: unknown reference pointee #{pointee.class.name} (only variables and allocas are supported)"
      end
    end

    def codegen(node : AST::Dereference) : LibC::LLVMValueRef
      pointer = codegen(node.pointee)

      @debug.emit_location(node)
      LibC.LLVMBuildLoad(@builder, pointer, "")
    end
  end
end
