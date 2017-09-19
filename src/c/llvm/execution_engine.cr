lib LibC
  fun LLVMLinkInMCJIT() : Void
  fun LLVMLinkInInterpreter() : Void
  type LLVMOpaqueGenericValue = Void
  alias LLVMGenericValueRef = LLVMOpaqueGenericValue*
  type LLVMOpaqueExecutionEngine = Void
  alias LLVMExecutionEngineRef = LLVMOpaqueExecutionEngine*
  type LLVMOpaqueMCJITMemoryManager = Void
  alias LLVMMCJITMemoryManagerRef = LLVMOpaqueMCJITMemoryManager*
  struct LLVMMCJITCompilerOptions
    opt_level : UInt
    code_model : LLVMCodeModel
    no_frame_pointer_elim : LLVMBool
    enable_fast_i_sel : LLVMBool
    mcjmm : LLVMMCJITMemoryManagerRef
  end
  fun LLVMCreateGenericValueOfInt(LLVMTypeRef, ULongLong, LLVMBool) : LLVMGenericValueRef
  fun LLVMCreateGenericValueOfPointer(Void*) : LLVMGenericValueRef
  fun LLVMCreateGenericValueOfFloat(LLVMTypeRef, Double) : LLVMGenericValueRef
  fun LLVMGenericValueIntWidth(LLVMGenericValueRef) : UInt
  fun LLVMGenericValueToInt(LLVMGenericValueRef, LLVMBool) : ULongLong
  fun LLVMGenericValueToPointer(LLVMGenericValueRef) : Void*
  fun LLVMGenericValueToFloat(LLVMTypeRef, LLVMGenericValueRef) : Double
  fun LLVMDisposeGenericValue(LLVMGenericValueRef) : Void
  fun LLVMCreateExecutionEngineForModule(LLVMOpaqueExecutionEngine**, LLVMModuleRef, Char**) : LLVMBool
  fun LLVMCreateInterpreterForModule(LLVMOpaqueExecutionEngine**, LLVMModuleRef, Char**) : LLVMBool
  fun LLVMCreateJITCompilerForModule(LLVMOpaqueExecutionEngine**, LLVMModuleRef, UInt, Char**) : LLVMBool
  fun LLVMInitializeMCJITCompilerOptions(LLVMMCJITCompilerOptions*, Int) : Void
  fun LLVMCreateMCJITCompilerForModule(LLVMOpaqueExecutionEngine**, LLVMModuleRef, LLVMMCJITCompilerOptions*, Int, Char**) : LLVMBool
  fun LLVMDisposeExecutionEngine(LLVMExecutionEngineRef) : Void
  fun LLVMRunStaticConstructors(LLVMExecutionEngineRef) : Void
  fun LLVMRunStaticDestructors(LLVMExecutionEngineRef) : Void
  fun LLVMRunFunctionAsMain(LLVMExecutionEngineRef, LLVMValueRef, UInt, Char**, Char**) : Int
  fun LLVMRunFunction(LLVMExecutionEngineRef, LLVMValueRef, UInt, LLVMOpaqueGenericValue**) : LLVMGenericValueRef
  fun LLVMFreeMachineCodeForFunction(LLVMExecutionEngineRef, LLVMValueRef) : Void
  fun LLVMAddModule(LLVMExecutionEngineRef, LLVMModuleRef) : Void
  fun LLVMRemoveModule(LLVMExecutionEngineRef, LLVMModuleRef, LLVMOpaqueModule**, Char**) : LLVMBool
  fun LLVMFindFunction(LLVMExecutionEngineRef, Char*, LLVMOpaqueValue**) : LLVMBool
  fun LLVMRecompileAndRelinkFunction(LLVMExecutionEngineRef, LLVMValueRef) : Void*
  fun LLVMGetExecutionEngineTargetData(LLVMExecutionEngineRef) : LLVMTargetDataRef
  fun LLVMGetExecutionEngineTargetMachine(LLVMExecutionEngineRef) : LLVMTargetMachineRef
  fun LLVMAddGlobalMapping(LLVMExecutionEngineRef, LLVMValueRef, Void*) : Void
  fun LLVMGetPointerToGlobal(LLVMExecutionEngineRef, LLVMValueRef) : Void*
  fun LLVMGetGlobalValueAddress(LLVMExecutionEngineRef, Char*) : UInt64
  fun LLVMGetFunctionAddress(LLVMExecutionEngineRef, Char*) : UInt64
  alias LLVMMemoryManagerAllocateCodeSectionCallback = (UInt8, Void*, UintptrT, UInt, UInt) -> Char*
  alias LLVMMemoryManagerAllocateDataSectionCallback = (UInt8, Void*, UintptrT, UInt, UInt, Char*) -> Int
  alias LLVMMemoryManagerFinalizeMemoryCallback = (LLVMBool, Void*) -> Char**
  alias LLVMMemoryManagerDestroyCallback = (Void*) -> Void*
  fun LLVMCreateSimpleMCJITMemoryManager(Void*, LLVMMemoryManagerAllocateCodeSectionCallback, LLVMMemoryManagerAllocateDataSectionCallback, LLVMMemoryManagerFinalizeMemoryCallback, LLVMMemoryManagerDestroyCallback) : LLVMMCJITMemoryManagerRef
  fun LLVMDisposeMCJITMemoryManager(LLVMMCJITMemoryManagerRef) : Void
end
