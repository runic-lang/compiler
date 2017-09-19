lib LibC
  type LLVMOpaqueTargetMachine = Void
  alias LLVMTargetMachineRef = LLVMOpaqueTargetMachine*
  type LLVMTarget = Void
  alias LLVMTargetRef = LLVMTarget*
  enum LLVMCodeGenOptLevel : UInt
    LLVMCodeGenLevelNone = 0
    LLVMCodeGenLevelLess = 1
    LLVMCodeGenLevelDefault = 2
    LLVMCodeGenLevelAggressive = 3
  end
  enum LLVMRelocMode : UInt
    LLVMRelocDefault = 0
    LLVMRelocStatic = 1
    LLVMRelocPIC = 2
    LLVMRelocDynamicNoPic = 3
  end
  enum LLVMCodeModel : UInt
    LLVMCodeModelDefault = 0
    LLVMCodeModelJITDefault = 1
    LLVMCodeModelSmall = 2
    LLVMCodeModelKernel = 3
    LLVMCodeModelMedium = 4
    LLVMCodeModelLarge = 5
  end
  enum LLVMCodeGenFileType : UInt
    LLVMAssemblyFile = 0
    LLVMObjectFile = 1
  end
  fun LLVMGetFirstTarget() : LLVMTargetRef
  fun LLVMGetNextTarget(LLVMTargetRef) : LLVMTargetRef
  fun LLVMGetTargetFromName(Char*) : LLVMTargetRef
  fun LLVMGetTargetFromTriple(Char*, LLVMTarget**, Char**) : LLVMBool
  fun LLVMGetTargetName(LLVMTargetRef) : Char*
  fun LLVMGetTargetDescription(LLVMTargetRef) : Char*
  fun LLVMTargetHasJIT(LLVMTargetRef) : LLVMBool
  fun LLVMTargetHasTargetMachine(LLVMTargetRef) : LLVMBool
  fun LLVMTargetHasAsmBackend(LLVMTargetRef) : LLVMBool
  fun LLVMCreateTargetMachine(LLVMTargetRef, Char*, Char*, Char*, LLVMCodeGenOptLevel, LLVMRelocMode, LLVMCodeModel) : LLVMTargetMachineRef
  fun LLVMDisposeTargetMachine(LLVMTargetMachineRef) : Void
  fun LLVMGetTargetMachineTarget(LLVMTargetMachineRef) : LLVMTargetRef
  fun LLVMGetTargetMachineTriple(LLVMTargetMachineRef) : Char*
  fun LLVMGetTargetMachineCPU(LLVMTargetMachineRef) : Char*
  fun LLVMGetTargetMachineFeatureString(LLVMTargetMachineRef) : Char*
  fun LLVMCreateTargetDataLayout(LLVMTargetMachineRef) : LLVMTargetDataRef
  fun LLVMSetTargetMachineAsmVerbosity(LLVMTargetMachineRef, LLVMBool) : Void
  fun LLVMTargetMachineEmitToFile(LLVMTargetMachineRef, LLVMModuleRef, Char*, LLVMCodeGenFileType, Char**) : LLVMBool
  fun LLVMTargetMachineEmitToMemoryBuffer(LLVMTargetMachineRef, LLVMModuleRef, LLVMCodeGenFileType, Char**, LLVMOpaqueMemoryBuffer**) : LLVMBool
  fun LLVMGetDefaultTargetTriple() : Char*
  fun LLVMAddAnalysisPasses(LLVMTargetMachineRef, LLVMPassManagerRef) : Void
end
