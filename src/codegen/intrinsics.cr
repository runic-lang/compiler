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
      when "llvm.floor.f32"
        declare_llvm_intrinsic_function(name, "f32", "f32")
      when "llvm.floor.f64"
        declare_llvm_intrinsic_function(name, "f64", "f64")
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
  end
end
