lib LibC
  enum LLVMVerifierFailureAction : UInt
    LLVMAbortProcessAction = 0
    LLVMPrintMessageAction = 1
    LLVMReturnStatusAction = 2
  end
  fun LLVMVerifyModule(LLVMModuleRef, LLVMVerifierFailureAction, Char**) : LLVMBool
  fun LLVMVerifyFunction(LLVMValueRef, LLVMVerifierFailureAction) : LLVMBool
  fun LLVMViewFunctionCFG(LLVMValueRef) : Void
  fun LLVMViewFunctionCFGOnly(LLVMValueRef) : Void
end
