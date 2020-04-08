require "./functions"

module Runic
  class Codegen
    # Returns the LLVM definition of a LLVM intrinsic for the given name and
    # overloads. Declares the LLVM definition automatically.
    #
    # ```
    # intrinsic("llvm.floor", Type.new("f32"))   # => searches llvm.floor.f32
    # ```
    protected def llvm_intrinsic(name : String, *types : Type)
      overload_types = types.map do |type|
        case type.name
        when "i8", "u8" then "i8"
        when "i16", "u16" then "i16"
        when "i32", "u32" then "i32"
        when "i64", "u64" then "i64"
        when "i128", "u128" then "i128"
        when "f32" then "f32"
        when "f64" then "f64"
        else raise CodegenError.new("unsupported overload type '#{type}' for '#{name}' intrinsic")
       end
      end

      overload_name = String.build do |str|
        str << "llvm."
        str << name
        overload_types.each do |type|
          str << '.'
          type.to_s(str)
        end
      end

      if func = LibC.LLVMGetNamedFunction(@module, overload_name)
        func
      else
        declare_llvm_intrinsic(overload_name)
      end
    end

    private def declare_llvm_intrinsic(name : String) : LibC::LLVMValueRef
      case name
      when "llvm.floor.f32",
           "llvm.ceil.f32",
           "llvm.trunc.f32"
        declare_llvm_intrinsic_function(name, "f32", "f32")

      when "llvm.floor.f64",
           "llvm.ceil.f64",
           "llvm.trunc.f64"
        declare_llvm_intrinsic_function(name, "f64", "f64")

      when "llvm.pow.f32"
        declare_llvm_intrinsic_function(name, "f32", "f32", "f32")

      when "llvm.pow.f64"
        declare_llvm_intrinsic_function(name, "f64", "f64", "f64")

      else
        raise CodegenError.new("intrinsic '#{name}': no such definition")
      end
    end

    private def declare_llvm_intrinsic_function(name : String, type : String, *args : String) : LibC::LLVMValueRef
      param_types = args.map { |arg| llvm_type(arg) }.to_a
      return_type = llvm_type(type)
      func_type = LibC.LLVMFunctionType(return_type, param_types, param_types.size, 0)
      func = LibC.LLVMAddFunction(@module, name, func_type)
      LibC.LLVMSetLinkage(func, EXTERN_LINKAGE)
      func
    end

    protected def builtin_cast_to_unsigned(variable_name, src_type, dst_type)
      value = LibC.LLVMBuildLoad(@builder, @scope.get(variable_name), variable_name)

      case src_type
      when .unsigned?
        if src_type.bits < dst_type.bits
          LibC.LLVMBuildZExt(@builder, value, llvm_type(dst_type), "")
        else
          LibC.LLVMBuildTrunc(@builder, value, llvm_type(dst_type), "")
        end
      when .integer?
        if src_type.bits < dst_type.bits
          LibC.LLVMBuildSExt(@builder, value, llvm_type(dst_type), "")
        else
          LibC.LLVMBuildTrunc(@builder, value, llvm_type(dst_type), "")
        end
      when .float?
        LibC.LLVMBuildFPToUI(@builder, value, llvm_type(dst_type), "")
      else
        raise "unreachable"
      end
    end

    protected def builtin_cast_to_signed(variable_name, src_type, dst_type)
      value = LibC.LLVMBuildLoad(@builder, @scope.get(variable_name), variable_name)

      case src_type
      when .unsigned?
        if src_type.bits < dst_type.bits
          LibC.LLVMBuildZExt(@builder, value, llvm_type(dst_type), "")
        else
          LibC.LLVMBuildTrunc(@builder, value, llvm_type(dst_type), "")
        end
      when .integer?
        if src_type.bits < dst_type.bits
          LibC.LLVMBuildSExt(@builder, value, llvm_type(dst_type), "")
        else
          LibC.LLVMBuildTrunc(@builder, value, llvm_type(dst_type), "")
        end
      when .float?
        LibC.LLVMBuildFPToSI(@builder, value, llvm_type(dst_type), "")
      else
        raise "unreachable"
      end
    end

    protected def builtin_cast_to_float(variable_name, src_type, dst_type)
      value = LibC.LLVMBuildLoad(@builder, @scope.get(variable_name), variable_name)

      case src_type
      when .unsigned?
        LibC.LLVMBuildUIToFP(@builder, value, llvm_type(dst_type), "")
      when .integer?
        LibC.LLVMBuildSIToFP(@builder, value, llvm_type(dst_type), "")
      when .float?
        if src_type.bits < dst_type.bits
          LibC.LLVMBuildFPExt(@builder, value, llvm_type(dst_type), "")
        else
          LibC.LLVMBuildFPTrunc(@builder, value, llvm_type(dst_type), "")
        end
      else
        raise "unreachable"
      end
    end

    protected def builtin_div(lhs_name, rhs_name, type)
      lhs = LibC.LLVMBuildLoad(@builder, @scope.get(lhs_name), lhs_name)
      rhs = LibC.LLVMBuildLoad(@builder, @scope.get(rhs_name), rhs_name)

      case type
      when .unsigned?
        LibC.LLVMBuildUDiv(@builder, lhs, rhs, "")
      when .integer?
        LibC.LLVMBuildSDiv(@builder, lhs, rhs, "")
      when .float?
        LibC.LLVMBuildFDiv(@builder, lhs, rhs, "")
      else
        raise "unreachable"
      end
    end

    protected def builtin_floor(variable_name, type)
      value = LibC.LLVMBuildLoad(@builder, @scope.get(variable_name), variable_name)
      func = llvm_intrinsic("floor", type)
      LibC.LLVMBuildCall(@builder, func, [value], 1, "")
    end

    protected def builtin_ceil(variable_name, type)
      value = LibC.LLVMBuildLoad(@builder, @scope.get(variable_name), variable_name)
      func = llvm_intrinsic("ceil", type)
      LibC.LLVMBuildCall(@builder, func, [value], 1, "")
    end

    protected def builtin_truncate(variable_name, type)
      value = LibC.LLVMBuildLoad(@builder, @scope.get(variable_name), variable_name)
      func = llvm_intrinsic("trunc", type)
      LibC.LLVMBuildCall(@builder, func, [value], 1, "")
    end
  end
end
