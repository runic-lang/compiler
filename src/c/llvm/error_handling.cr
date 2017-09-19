lib LibC
  alias LLVMFatalErrorHandler = (Char*) -> Void*
  fun LLVMInstallFatalErrorHandler(LLVMFatalErrorHandler) : Void
  fun LLVMResetFatalErrorHandler() : Void
  fun LLVMEnablePrettyStackTrace() : Void
end
