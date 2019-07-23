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

    def codegen(node : AST::StringLiteral) : LibC::LLVMValueRef
      @debug.emit_location(node)

      if st = @program.structs["String"]?
        if fn = st.method("initialize")
          if func = LibC.LLVMGetNamedFunction(@module, fn.symbol_name)
            slf = LibC.LLVMBuildAlloca(@builder, llvm_type("String"), "")
            args = [
              slf,
              LibC.LLVMBuildGlobalStringPtr(@builder, node.value, ""),   # ptr
              LibC.LLVMConstInt(llvm_type("i32"), node.bytesize, false), # bytesize TODO: uint (should be arch-dependent)
            ]
            LibC.LLVMBuildCall(@builder, func, args, args.size, "")
            return LibC.LLVMBuildLoad(@builder, slf, "")
          end
        end
      end

      raise CodegenError.new("undefined function 'String::initialize'")
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

    def codegen(node : AST::ConstantDefinition) : LibC::LLVMValueRef
      codegen(node.value).tap do |value|
        if @constant_values[node.name]?
          raise CodegenError.new("constant #{node.name} has already been initialized")
        end
        @constant_values[node.name] = value
      end
    end

    def codegen(node : AST::Alloca) : LibC::LLVMValueRef
      @debug.emit_location(node)
      LibC.LLVMBuildAlloca(@builder, llvm_type(node.type), "")
    end
  end
end
