require "./c/llvm"

module LLVM
  {% begin %}
    {% for target in LibC::LLVM_AVAILABLE_TARGETS %}
      @@init_{{target.id}} = false
    {% end %}
  {% end %}

  macro llvm_init(arch)
    {% if LibC::LLVM_AVAILABLE_TARGETS.any?(&.starts_with?(arch.stringify)) %}
      return if @@init_{{arch.id}}
      @@init_{{arch.id}} = true
      LibC.LLVMInitialize{{arch.id}}TargetInfo()
      LibC.LLVMInitialize{{arch.id}}Target()
      LibC.LLVMInitialize{{arch.id}}TargetMC()
      LibC.LLVMInitialize{{arch.id}}AsmPrinter()
      LibC.LLVMInitialize{{arch.id}}AsmParser()
    {% else %}
      raise "LLVM was built without the {{arch.id}} arch"
    {% end %}
  end

  def self.init_native : Nil
    init String.new(LibC.LLVMGetDefaultTargetTriple)
    LibC.LLVMLinkInMCJIT()
  end

  def self.init(triple : String) : Nil
    arch = triple.split('-').first

    case arch.downcase
    when "amd64", /i.86/, "x86_64"
      llvm_init X86
    when .starts_with?("aarch64")
      llvm_init AArch64
    when .starts_with?("arm")
      llvm_init ARM
    when .starts_with?("mips")
      llvm_init Mips
    when .starts_with?("ppc")
      llvm_init PowerPC
    when .starts_with?("sparcs")
      llvm_init Sparc
    else
      # shut up, crystal
    end
  end

  def self.init_global_pass_registry
    registry = LibC.LLVMGetGlobalPassRegistry()
    LibC.LLVMInitializeCore(registry)
    LibC.LLVMInitializeTransformUtils(registry)
    LibC.LLVMInitializeScalarOpts(registry)
    LibC.LLVMInitializeObjCARCOpts(registry)
    LibC.LLVMInitializeVectorization(registry)
    LibC.LLVMInitializeInstCombine(registry)
    LibC.LLVMInitializeAggressiveInstCombiner(registry)
    LibC.LLVMInitializeIPO(registry)
    LibC.LLVMInitializeInstrumentation(registry)
    LibC.LLVMInitializeAnalysis(registry)
    LibC.LLVMInitializeIPA(registry)
    LibC.LLVMInitializeCodeGen(registry)
    LibC.LLVMInitializeTarget(registry)
  end
end
