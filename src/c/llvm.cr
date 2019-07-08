@[Link(ldflags: "`llvm-config-8 --cxxflags --ldflags --libs --system-libs`")]
@[Link("stdc++")]
lib LibC
  {% if flag?(:aarch64) || flag?(:x86_64) %}
    alias UintptrT = UInt64
  {% elsif flag?(:i686) || flag?(:arm) %}
    alias UintptrT = UInt32
  {% else %}
    {% raise "unsupported target" %}
  {% end %}

  alias Uint64T = UInt64

  {% begin %}
    LLVM_AVAILABLE_TARGETS = {{ `llvm-config-8 --targets-built`.stringify.chomp.split(' ') }}
  {% end %}

  {% for target in LLVM_AVAILABLE_TARGETS %}
    fun LLVMInitialize{{target.id}}TargetInfo() : Void
    fun LLVMInitialize{{target.id}}Target() : Void
    fun LLVMInitialize{{target.id}}TargetMC() : Void
    fun LLVMInitialize{{target.id}}AsmPrinter() : Void
    fun LLVMInitialize{{target.id}}AsmParser() : Void
  {% end %}

  # FIXME: not generated automatically by c2cr (?)
  alias LLVMModuleFlagEntry = LLVMOpaqueModuleFlagEntry
  alias LLVMValueMetadataEntry = LLVMOpaqueValueMetadataEntry
  LLVMAttributeReturnIndex = 0_u32
  LLVMAttributeFunctionIndex = ~0_u32
end

require "./llvm/analysis"
require "./llvm/types"
require "./llvm/core"
require "./llvm/error_handling"
require "./llvm/execution_engine"
require "./llvm/initialization"
require "./llvm/target"
require "./llvm/target_machine"
require "./llvm/transforms/ipo"
require "./llvm/transforms/pass_manager_builder"
require "./llvm/transforms/scalar"
require "./llvm/transforms/utils"
