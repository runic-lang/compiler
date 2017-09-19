lib LibC
  alias LLVMBool = Int
  type LLVMOpaqueMemoryBuffer = Void
  alias LLVMMemoryBufferRef = LLVMOpaqueMemoryBuffer*
  type LLVMOpaqueContext = Void
  alias LLVMContextRef = LLVMOpaqueContext*
  type LLVMOpaqueModule = Void
  alias LLVMModuleRef = LLVMOpaqueModule*
  type LLVMOpaqueType = Void
  alias LLVMTypeRef = LLVMOpaqueType*
  type LLVMOpaqueValue = Void
  alias LLVMValueRef = LLVMOpaqueValue*
  type LLVMOpaqueBasicBlock = Void
  alias LLVMBasicBlockRef = LLVMOpaqueBasicBlock*
  type LLVMOpaqueMetadata = Void
  alias LLVMMetadataRef = LLVMOpaqueMetadata*
  type LLVMOpaqueBuilder = Void
  alias LLVMBuilderRef = LLVMOpaqueBuilder*
  type LLVMOpaqueDIBuilder = Void
  alias LLVMDIBuilderRef = LLVMOpaqueDIBuilder*
  type LLVMOpaqueModuleProvider = Void
  alias LLVMModuleProviderRef = LLVMOpaqueModuleProvider*
  type LLVMOpaquePassManager = Void
  alias LLVMPassManagerRef = LLVMOpaquePassManager*
  type LLVMOpaquePassRegistry = Void
  alias LLVMPassRegistryRef = LLVMOpaquePassRegistry*
  type LLVMOpaqueUse = Void
  alias LLVMUseRef = LLVMOpaqueUse*
  type LLVMOpaqueAttributeRef = Void
  alias LLVMAttributeRef = LLVMOpaqueAttributeRef*
  type LLVMOpaqueDiagnosticInfo = Void
  alias LLVMDiagnosticInfoRef = LLVMOpaqueDiagnosticInfo*
end
