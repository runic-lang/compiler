lib LibC
  enum LLVMByteOrdering : UInt
    LLVMBigEndian = 0
    LLVMLittleEndian = 1
  end
  type LLVMOpaqueTargetData = Void
  alias LLVMTargetDataRef = LLVMOpaqueTargetData*
  type LLVMOpaqueTargetLibraryInfotData = Void
  alias LLVMTargetLibraryInfoRef = LLVMOpaqueTargetLibraryInfotData*
  fun LLVMInitializeAllTargetInfos() : Void
  fun LLVMInitializeAllTargets() : Void
  fun LLVMInitializeAllTargetMCs() : Void
  fun LLVMInitializeAllAsmPrinters() : Void
  fun LLVMInitializeAllAsmParsers() : Void
  fun LLVMInitializeAllDisassemblers() : Void
  fun LLVMInitializeNativeTarget() : LLVMBool
  fun LLVMInitializeNativeAsmParser() : LLVMBool
  fun LLVMInitializeNativeAsmPrinter() : LLVMBool
  fun LLVMInitializeNativeDisassembler() : LLVMBool
  fun LLVMGetModuleDataLayout(LLVMModuleRef) : LLVMTargetDataRef
  fun LLVMSetModuleDataLayout(LLVMModuleRef, LLVMTargetDataRef) : Void
  fun LLVMCreateTargetData(Char*) : LLVMTargetDataRef
  fun LLVMDisposeTargetData(LLVMTargetDataRef) : Void
  fun LLVMAddTargetLibraryInfo(LLVMTargetLibraryInfoRef, LLVMPassManagerRef) : Void
  fun LLVMCopyStringRepOfTargetData(LLVMTargetDataRef) : Char*
  fun LLVMByteOrder(LLVMTargetDataRef) : LLVMByteOrdering
  fun LLVMPointerSize(LLVMTargetDataRef) : UInt
  fun LLVMPointerSizeForAS(LLVMTargetDataRef, UInt) : UInt
  fun LLVMIntPtrType(LLVMTargetDataRef) : LLVMTypeRef
  fun LLVMIntPtrTypeForAS(LLVMTargetDataRef, UInt) : LLVMTypeRef
  fun LLVMIntPtrTypeInContext(LLVMContextRef, LLVMTargetDataRef) : LLVMTypeRef
  fun LLVMIntPtrTypeForASInContext(LLVMContextRef, LLVMTargetDataRef, UInt) : LLVMTypeRef
  fun LLVMSizeOfTypeInBits(LLVMTargetDataRef, LLVMTypeRef) : ULongLong
  fun LLVMStoreSizeOfType(LLVMTargetDataRef, LLVMTypeRef) : ULongLong
  fun LLVMABISizeOfType(LLVMTargetDataRef, LLVMTypeRef) : ULongLong
  fun LLVMABIAlignmentOfType(LLVMTargetDataRef, LLVMTypeRef) : UInt
  fun LLVMCallFrameAlignmentOfType(LLVMTargetDataRef, LLVMTypeRef) : UInt
  fun LLVMPreferredAlignmentOfType(LLVMTargetDataRef, LLVMTypeRef) : UInt
  fun LLVMPreferredAlignmentOfGlobal(LLVMTargetDataRef, LLVMValueRef) : UInt
  fun LLVMElementAtOffset(LLVMTargetDataRef, LLVMTypeRef, ULongLong) : UInt
  fun LLVMOffsetOfElement(LLVMTargetDataRef, LLVMTypeRef, UInt) : ULongLong
end
