lib LibC
  enum LLVMOpcode : UInt
    LLVMRet = 1
    LLVMBr = 2
    LLVMSwitch = 3
    LLVMIndirectBr = 4
    LLVMInvoke = 5
    LLVMUnreachable = 7
    LLVMAdd = 8
    LLVMFAdd = 9
    LLVMSub = 10
    LLVMFSub = 11
    LLVMMul = 12
    LLVMFMul = 13
    LLVMUDiv = 14
    LLVMSDiv = 15
    LLVMFDiv = 16
    LLVMURem = 17
    LLVMSRem = 18
    LLVMFRem = 19
    LLVMShl = 20
    LLVMLShr = 21
    LLVMAShr = 22
    LLVMAnd = 23
    LLVMOr = 24
    LLVMXor = 25
    LLVMAlloca = 26
    LLVMLoad = 27
    LLVMStore = 28
    LLVMGetElementPtr = 29
    LLVMTrunc = 30
    LLVMZExt = 31
    LLVMSExt = 32
    LLVMFPToUI = 33
    LLVMFPToSI = 34
    LLVMUIToFP = 35
    LLVMSIToFP = 36
    LLVMFPTrunc = 37
    LLVMFPExt = 38
    LLVMPtrToInt = 39
    LLVMIntToPtr = 40
    LLVMBitCast = 41
    LLVMAddrSpaceCast = 60
    LLVMICmp = 42
    LLVMFCmp = 43
    LLVMPHI = 44
    LLVMCall = 45
    LLVMSelect = 46
    LLVMUserOp1 = 47
    LLVMUserOp2 = 48
    LLVMVAArg = 49
    LLVMExtractElement = 50
    LLVMInsertElement = 51
    LLVMShuffleVector = 52
    LLVMExtractValue = 53
    LLVMInsertValue = 54
    LLVMFence = 55
    LLVMAtomicCmpXchg = 56
    LLVMAtomicRMW = 57
    LLVMResume = 58
    LLVMLandingPad = 59
    LLVMCleanupRet = 61
    LLVMCatchRet = 62
    LLVMCatchPad = 63
    LLVMCleanupPad = 64
    LLVMCatchSwitch = 65
  end
  enum LLVMTypeKind : UInt
    LLVMVoidTypeKind = 0
    LLVMHalfTypeKind = 1
    LLVMFloatTypeKind = 2
    LLVMDoubleTypeKind = 3
    LLVMX86_FP80TypeKind = 4
    LLVMFP128TypeKind = 5
    LLVMPPC_FP128TypeKind = 6
    LLVMLabelTypeKind = 7
    LLVMIntegerTypeKind = 8
    LLVMFunctionTypeKind = 9
    LLVMStructTypeKind = 10
    LLVMArrayTypeKind = 11
    LLVMPointerTypeKind = 12
    LLVMVectorTypeKind = 13
    LLVMMetadataTypeKind = 14
    LLVMX86_MMXTypeKind = 15
    LLVMTokenTypeKind = 16
  end
  enum LLVMLinkage : UInt
    LLVMExternalLinkage = 0
    LLVMAvailableExternallyLinkage = 1
    LLVMLinkOnceAnyLinkage = 2
    LLVMLinkOnceODRLinkage = 3
    LLVMLinkOnceODRAutoHideLinkage = 4
    LLVMWeakAnyLinkage = 5
    LLVMWeakODRLinkage = 6
    LLVMAppendingLinkage = 7
    LLVMInternalLinkage = 8
    LLVMPrivateLinkage = 9
    LLVMDLLImportLinkage = 10
    LLVMDLLExportLinkage = 11
    LLVMExternalWeakLinkage = 12
    LLVMGhostLinkage = 13
    LLVMCommonLinkage = 14
    LLVMLinkerPrivateLinkage = 15
    LLVMLinkerPrivateWeakLinkage = 16
  end
  enum LLVMVisibility : UInt
    LLVMDefaultVisibility = 0
    LLVMHiddenVisibility = 1
    LLVMProtectedVisibility = 2
  end
  enum LLVMDLLStorageClass : UInt
    LLVMDefaultStorageClass = 0
    LLVMDLLImportStorageClass = 1
    LLVMDLLExportStorageClass = 2
  end
  enum LLVMCallConv : UInt
    LLVMCCallConv = 0
    LLVMFastCallConv = 8
    LLVMColdCallConv = 9
    LLVMWebKitJSCallConv = 12
    LLVMAnyRegCallConv = 13
    LLVMX86StdcallCallConv = 64
    LLVMX86FastcallCallConv = 65
  end
  enum LLVMValueKind : UInt
    LLVMArgumentValueKind = 0
    LLVMBasicBlockValueKind = 1
    LLVMMemoryUseValueKind = 2
    LLVMMemoryDefValueKind = 3
    LLVMMemoryPhiValueKind = 4
    LLVMFunctionValueKind = 5
    LLVMGlobalAliasValueKind = 6
    LLVMGlobalIFuncValueKind = 7
    LLVMGlobalVariableValueKind = 8
    LLVMBlockAddressValueKind = 9
    LLVMConstantExprValueKind = 10
    LLVMConstantArrayValueKind = 11
    LLVMConstantStructValueKind = 12
    LLVMConstantVectorValueKind = 13
    LLVMUndefValueValueKind = 14
    LLVMConstantAggregateZeroValueKind = 15
    LLVMConstantDataArrayValueKind = 16
    LLVMConstantDataVectorValueKind = 17
    LLVMConstantIntValueKind = 18
    LLVMConstantFPValueKind = 19
    LLVMConstantPointerNullValueKind = 20
    LLVMConstantTokenNoneValueKind = 21
    LLVMMetadataAsValueValueKind = 22
    LLVMInlineAsmValueKind = 23
    LLVMInstructionValueKind = 24
  end
  enum LLVMIntPredicate : UInt
    LLVMIntEQ = 32
    LLVMIntNE = 33
    LLVMIntUGT = 34
    LLVMIntUGE = 35
    LLVMIntULT = 36
    LLVMIntULE = 37
    LLVMIntSGT = 38
    LLVMIntSGE = 39
    LLVMIntSLT = 40
    LLVMIntSLE = 41
  end
  enum LLVMRealPredicate : UInt
    LLVMRealPredicateFalse = 0
    LLVMRealOEQ = 1
    LLVMRealOGT = 2
    LLVMRealOGE = 3
    LLVMRealOLT = 4
    LLVMRealOLE = 5
    LLVMRealONE = 6
    LLVMRealORD = 7
    LLVMRealUNO = 8
    LLVMRealUEQ = 9
    LLVMRealUGT = 10
    LLVMRealUGE = 11
    LLVMRealULT = 12
    LLVMRealULE = 13
    LLVMRealUNE = 14
    LLVMRealPredicateTrue = 15
  end
  enum LLVMLandingPadClauseTy : UInt
    LLVMLandingPadCatch = 0
    LLVMLandingPadFilter = 1
  end
  enum LLVMThreadLocalMode : UInt
    LLVMNotThreadLocal = 0
    LLVMGeneralDynamicTLSModel = 1
    LLVMLocalDynamicTLSModel = 2
    LLVMInitialExecTLSModel = 3
    LLVMLocalExecTLSModel = 4
  end
  enum LLVMAtomicOrdering : UInt
    LLVMAtomicOrderingNotAtomic = 0
    LLVMAtomicOrderingUnordered = 1
    LLVMAtomicOrderingMonotonic = 2
    LLVMAtomicOrderingAcquire = 4
    LLVMAtomicOrderingRelease = 5
    LLVMAtomicOrderingAcquireRelease = 6
    LLVMAtomicOrderingSequentiallyConsistent = 7
  end
  enum LLVMAtomicRMWBinOp : UInt
    LLVMAtomicRMWBinOpXchg = 0
    LLVMAtomicRMWBinOpAdd = 1
    LLVMAtomicRMWBinOpSub = 2
    LLVMAtomicRMWBinOpAnd = 3
    LLVMAtomicRMWBinOpNand = 4
    LLVMAtomicRMWBinOpOr = 5
    LLVMAtomicRMWBinOpXor = 6
    LLVMAtomicRMWBinOpMax = 7
    LLVMAtomicRMWBinOpMin = 8
    LLVMAtomicRMWBinOpUMax = 9
    LLVMAtomicRMWBinOpUMin = 10
  end
  enum LLVMDiagnosticSeverity : UInt
    LLVMDSError = 0
    LLVMDSWarning = 1
    LLVMDSRemark = 2
    LLVMDSNote = 3
  end
  alias LLVMAttributeIndex = UInt
  fun LLVMInitializeCore(LLVMPassRegistryRef) : Void
  fun LLVMShutdown() : Void
  fun LLVMCreateMessage(Char*) : Char*
  fun LLVMDisposeMessage(Char*) : Void
  alias LLVMDiagnosticHandler = (LLVMDiagnosticInfoRef, Void*) -> Void
  alias LLVMYieldCallback = (LLVMContextRef, Void*) -> Void
  fun LLVMContextCreate() : LLVMContextRef
  fun LLVMGetGlobalContext() : LLVMContextRef
  fun LLVMContextSetDiagnosticHandler(LLVMContextRef, LLVMDiagnosticHandler, Void*) : Void
  fun LLVMContextGetDiagnosticHandler(LLVMContextRef) : LLVMDiagnosticHandler
  fun LLVMContextGetDiagnosticContext(LLVMContextRef) : Void*
  fun LLVMContextSetYieldCallback(LLVMContextRef, LLVMYieldCallback, Void*) : Void
  fun LLVMContextDispose(LLVMContextRef) : Void
  fun LLVMGetDiagInfoDescription(LLVMDiagnosticInfoRef) : Char*
  fun LLVMGetDiagInfoSeverity(LLVMDiagnosticInfoRef) : LLVMDiagnosticSeverity
  fun LLVMGetMDKindIDInContext(LLVMContextRef, Char*, UInt) : UInt
  fun LLVMGetMDKindID(Char*, UInt) : UInt
  fun LLVMGetEnumAttributeKindForName(Char*, Int) : UInt
  fun LLVMGetLastEnumAttributeKind() : UInt
  fun LLVMCreateEnumAttribute(LLVMContextRef, UInt, UInt64) : LLVMAttributeRef
  fun LLVMGetEnumAttributeKind(LLVMAttributeRef) : UInt
  fun LLVMGetEnumAttributeValue(LLVMAttributeRef) : UInt64
  fun LLVMCreateStringAttribute(LLVMContextRef, Char*, UInt, Char*, UInt) : LLVMAttributeRef
  fun LLVMGetStringAttributeKind(LLVMAttributeRef, UInt*) : Char*
  fun LLVMGetStringAttributeValue(LLVMAttributeRef, UInt*) : Char*
  fun LLVMIsEnumAttribute(LLVMAttributeRef) : LLVMBool
  fun LLVMIsStringAttribute(LLVMAttributeRef) : LLVMBool
  fun LLVMModuleCreateWithName(Char*) : LLVMModuleRef
  fun LLVMModuleCreateWithNameInContext(Char*, LLVMContextRef) : LLVMModuleRef
  fun LLVMCloneModule(LLVMModuleRef) : LLVMModuleRef
  fun LLVMDisposeModule(LLVMModuleRef) : Void
  fun LLVMGetModuleIdentifier(LLVMModuleRef, Int*) : Char*
  fun LLVMSetModuleIdentifier(LLVMModuleRef, Char*, Int) : Void
  fun LLVMGetDataLayoutStr(LLVMModuleRef) : Char*
  fun LLVMGetDataLayout(LLVMModuleRef) : Char*
  fun LLVMSetDataLayout(LLVMModuleRef, Char*) : Void
  fun LLVMGetTarget(LLVMModuleRef) : Char*
  fun LLVMSetTarget(LLVMModuleRef, Char*) : Void
  fun LLVMDumpModule(LLVMModuleRef) : Void
  fun LLVMPrintModuleToFile(LLVMModuleRef, Char*, Char**) : LLVMBool
  fun LLVMPrintModuleToString(LLVMModuleRef) : Char*
  fun LLVMSetModuleInlineAsm(LLVMModuleRef, Char*) : Void
  fun LLVMGetModuleContext(LLVMModuleRef) : LLVMContextRef
  fun LLVMGetTypeByName(LLVMModuleRef, Char*) : LLVMTypeRef
  fun LLVMGetNamedMetadataNumOperands(LLVMModuleRef, Char*) : UInt
  fun LLVMGetNamedMetadataOperands(LLVMModuleRef, Char*, LLVMOpaqueValue**) : Void
  fun LLVMAddNamedMetadataOperand(LLVMModuleRef, Char*, LLVMValueRef) : Void
  fun LLVMAddFunction(LLVMModuleRef, Char*, LLVMTypeRef) : LLVMValueRef
  fun LLVMGetNamedFunction(LLVMModuleRef, Char*) : LLVMValueRef
  fun LLVMGetFirstFunction(LLVMModuleRef) : LLVMValueRef
  fun LLVMGetLastFunction(LLVMModuleRef) : LLVMValueRef
  fun LLVMGetNextFunction(LLVMValueRef) : LLVMValueRef
  fun LLVMGetPreviousFunction(LLVMValueRef) : LLVMValueRef
  fun LLVMGetTypeKind(LLVMTypeRef) : LLVMTypeKind
  fun LLVMTypeIsSized(LLVMTypeRef) : LLVMBool
  fun LLVMGetTypeContext(LLVMTypeRef) : LLVMContextRef
  fun LLVMDumpType(LLVMTypeRef) : Void
  fun LLVMPrintTypeToString(LLVMTypeRef) : Char*
  fun LLVMInt1TypeInContext(LLVMContextRef) : LLVMTypeRef
  fun LLVMInt8TypeInContext(LLVMContextRef) : LLVMTypeRef
  fun LLVMInt16TypeInContext(LLVMContextRef) : LLVMTypeRef
  fun LLVMInt32TypeInContext(LLVMContextRef) : LLVMTypeRef
  fun LLVMInt64TypeInContext(LLVMContextRef) : LLVMTypeRef
  fun LLVMInt128TypeInContext(LLVMContextRef) : LLVMTypeRef
  fun LLVMIntTypeInContext(LLVMContextRef, UInt) : LLVMTypeRef
  fun LLVMInt1Type() : LLVMTypeRef
  fun LLVMInt8Type() : LLVMTypeRef
  fun LLVMInt16Type() : LLVMTypeRef
  fun LLVMInt32Type() : LLVMTypeRef
  fun LLVMInt64Type() : LLVMTypeRef
  fun LLVMInt128Type() : LLVMTypeRef
  fun LLVMIntType(UInt) : LLVMTypeRef
  fun LLVMGetIntTypeWidth(LLVMTypeRef) : UInt
  fun LLVMHalfTypeInContext(LLVMContextRef) : LLVMTypeRef
  fun LLVMFloatTypeInContext(LLVMContextRef) : LLVMTypeRef
  fun LLVMDoubleTypeInContext(LLVMContextRef) : LLVMTypeRef
  fun LLVMX86FP80TypeInContext(LLVMContextRef) : LLVMTypeRef
  fun LLVMFP128TypeInContext(LLVMContextRef) : LLVMTypeRef
  fun LLVMPPCFP128TypeInContext(LLVMContextRef) : LLVMTypeRef
  fun LLVMHalfType() : LLVMTypeRef
  fun LLVMFloatType() : LLVMTypeRef
  fun LLVMDoubleType() : LLVMTypeRef
  fun LLVMX86FP80Type() : LLVMTypeRef
  fun LLVMFP128Type() : LLVMTypeRef
  fun LLVMPPCFP128Type() : LLVMTypeRef
  fun LLVMFunctionType(LLVMTypeRef, LLVMOpaqueType**, UInt, LLVMBool) : LLVMTypeRef
  fun LLVMIsFunctionVarArg(LLVMTypeRef) : LLVMBool
  fun LLVMGetReturnType(LLVMTypeRef) : LLVMTypeRef
  fun LLVMCountParamTypes(LLVMTypeRef) : UInt
  fun LLVMGetParamTypes(LLVMTypeRef, LLVMOpaqueType**) : Void
  fun LLVMStructTypeInContext(LLVMContextRef, LLVMOpaqueType**, UInt, LLVMBool) : LLVMTypeRef
  fun LLVMStructType(LLVMOpaqueType**, UInt, LLVMBool) : LLVMTypeRef
  fun LLVMStructCreateNamed(LLVMContextRef, Char*) : LLVMTypeRef
  fun LLVMGetStructName(LLVMTypeRef) : Char*
  fun LLVMStructSetBody(LLVMTypeRef, LLVMOpaqueType**, UInt, LLVMBool) : Void
  fun LLVMCountStructElementTypes(LLVMTypeRef) : UInt
  fun LLVMGetStructElementTypes(LLVMTypeRef, LLVMOpaqueType**) : Void
  fun LLVMStructGetTypeAtIndex(LLVMTypeRef, UInt) : LLVMTypeRef
  fun LLVMIsPackedStruct(LLVMTypeRef) : LLVMBool
  fun LLVMIsOpaqueStruct(LLVMTypeRef) : LLVMBool
  fun LLVMGetElementType(LLVMTypeRef) : LLVMTypeRef
  fun LLVMGetSubtypes(LLVMTypeRef, LLVMOpaqueType**) : Void
  fun LLVMGetNumContainedTypes(LLVMTypeRef) : UInt
  fun LLVMArrayType(LLVMTypeRef, UInt) : LLVMTypeRef
  fun LLVMGetArrayLength(LLVMTypeRef) : UInt
  fun LLVMPointerType(LLVMTypeRef, UInt) : LLVMTypeRef
  fun LLVMGetPointerAddressSpace(LLVMTypeRef) : UInt
  fun LLVMVectorType(LLVMTypeRef, UInt) : LLVMTypeRef
  fun LLVMGetVectorSize(LLVMTypeRef) : UInt
  fun LLVMVoidTypeInContext(LLVMContextRef) : LLVMTypeRef
  fun LLVMLabelTypeInContext(LLVMContextRef) : LLVMTypeRef
  fun LLVMX86MMXTypeInContext(LLVMContextRef) : LLVMTypeRef
  fun LLVMVoidType() : LLVMTypeRef
  fun LLVMLabelType() : LLVMTypeRef
  fun LLVMX86MMXType() : LLVMTypeRef
  fun LLVMTypeOf(LLVMValueRef) : LLVMTypeRef
  fun LLVMGetValueKind(LLVMValueRef) : LLVMValueKind
  fun LLVMGetValueName(LLVMValueRef) : Char*
  fun LLVMSetValueName(LLVMValueRef, Char*) : Void
  fun LLVMDumpValue(LLVMValueRef) : Void
  fun LLVMPrintValueToString(LLVMValueRef) : Char*
  fun LLVMReplaceAllUsesWith(LLVMValueRef, LLVMValueRef) : Void
  fun LLVMIsConstant(LLVMValueRef) : LLVMBool
  fun LLVMIsUndef(LLVMValueRef) : LLVMBool
  fun LLVMIsAArgument(LLVMValueRef) : LLVMValueRef
  fun LLVMIsABasicBlock(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAInlineAsm(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAUser(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAConstant(LLVMValueRef) : LLVMValueRef
  fun LLVMIsABlockAddress(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAConstantAggregateZero(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAConstantArray(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAConstantDataSequential(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAConstantDataArray(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAConstantDataVector(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAConstantExpr(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAConstantFP(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAConstantInt(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAConstantPointerNull(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAConstantStruct(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAConstantTokenNone(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAConstantVector(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAGlobalValue(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAGlobalAlias(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAGlobalObject(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAFunction(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAGlobalVariable(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAUndefValue(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAInstruction(LLVMValueRef) : LLVMValueRef
  fun LLVMIsABinaryOperator(LLVMValueRef) : LLVMValueRef
  fun LLVMIsACallInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAIntrinsicInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsADbgInfoIntrinsic(LLVMValueRef) : LLVMValueRef
  fun LLVMIsADbgDeclareInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAMemIntrinsic(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAMemCpyInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAMemMoveInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAMemSetInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsACmpInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAFCmpInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAICmpInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAExtractElementInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAGetElementPtrInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAInsertElementInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAInsertValueInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsALandingPadInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAPHINode(LLVMValueRef) : LLVMValueRef
  fun LLVMIsASelectInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAShuffleVectorInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAStoreInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsATerminatorInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsABranchInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAIndirectBrInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAInvokeInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAReturnInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsASwitchInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAUnreachableInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAResumeInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsACleanupReturnInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsACatchReturnInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAFuncletPadInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsACatchPadInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsACleanupPadInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAUnaryInstruction(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAAllocaInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsACastInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAAddrSpaceCastInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsABitCastInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAFPExtInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAFPToSIInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAFPToUIInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAFPTruncInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAIntToPtrInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAPtrToIntInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsASExtInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsASIToFPInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsATruncInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAUIToFPInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAZExtInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAExtractValueInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsALoadInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAVAArgInst(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAMDNode(LLVMValueRef) : LLVMValueRef
  fun LLVMIsAMDString(LLVMValueRef) : LLVMValueRef
  fun LLVMGetFirstUse(LLVMValueRef) : LLVMUseRef
  fun LLVMGetNextUse(LLVMUseRef) : LLVMUseRef
  fun LLVMGetUser(LLVMUseRef) : LLVMValueRef
  fun LLVMGetUsedValue(LLVMUseRef) : LLVMValueRef
  fun LLVMGetOperand(LLVMValueRef, UInt) : LLVMValueRef
  fun LLVMGetOperandUse(LLVMValueRef, UInt) : LLVMUseRef
  fun LLVMSetOperand(LLVMValueRef, UInt, LLVMValueRef) : Void
  fun LLVMGetNumOperands(LLVMValueRef) : Int
  fun LLVMConstNull(LLVMTypeRef) : LLVMValueRef
  fun LLVMConstAllOnes(LLVMTypeRef) : LLVMValueRef
  fun LLVMGetUndef(LLVMTypeRef) : LLVMValueRef
  fun LLVMIsNull(LLVMValueRef) : LLVMBool
  fun LLVMConstPointerNull(LLVMTypeRef) : LLVMValueRef
  fun LLVMConstInt(LLVMTypeRef, ULongLong, LLVMBool) : LLVMValueRef
  fun LLVMConstIntOfArbitraryPrecision(LLVMTypeRef, UInt, ULong*) : LLVMValueRef
  fun LLVMConstIntOfString(LLVMTypeRef, Char*, UInt8) : LLVMValueRef
  fun LLVMConstIntOfStringAndSize(LLVMTypeRef, Char*, UInt, UInt8) : LLVMValueRef
  fun LLVMConstReal(LLVMTypeRef, Double) : LLVMValueRef
  fun LLVMConstRealOfString(LLVMTypeRef, Char*) : LLVMValueRef
  fun LLVMConstRealOfStringAndSize(LLVMTypeRef, Char*, UInt) : LLVMValueRef
  fun LLVMConstIntGetZExtValue(LLVMValueRef) : ULongLong
  fun LLVMConstIntGetSExtValue(LLVMValueRef) : LongLong
  fun LLVMConstRealGetDouble(LLVMValueRef, Int*) : Double
  fun LLVMConstStringInContext(LLVMContextRef, Char*, UInt, LLVMBool) : LLVMValueRef
  fun LLVMConstString(Char*, UInt, LLVMBool) : LLVMValueRef
  fun LLVMIsConstantString(LLVMValueRef) : LLVMBool
  fun LLVMGetAsString(LLVMValueRef, Int*) : Char*
  fun LLVMConstStructInContext(LLVMContextRef, LLVMOpaqueValue**, UInt, LLVMBool) : LLVMValueRef
  fun LLVMConstStruct(LLVMOpaqueValue**, UInt, LLVMBool) : LLVMValueRef
  fun LLVMConstArray(LLVMTypeRef, LLVMOpaqueValue**, UInt) : LLVMValueRef
  fun LLVMConstNamedStruct(LLVMTypeRef, LLVMOpaqueValue**, UInt) : LLVMValueRef
  fun LLVMGetElementAsConstant(LLVMValueRef, UInt) : LLVMValueRef
  fun LLVMConstVector(LLVMOpaqueValue**, UInt) : LLVMValueRef
  fun LLVMGetConstOpcode(LLVMValueRef) : LLVMOpcode
  fun LLVMAlignOf(LLVMTypeRef) : LLVMValueRef
  fun LLVMSizeOf(LLVMTypeRef) : LLVMValueRef
  fun LLVMConstNeg(LLVMValueRef) : LLVMValueRef
  fun LLVMConstNSWNeg(LLVMValueRef) : LLVMValueRef
  fun LLVMConstNUWNeg(LLVMValueRef) : LLVMValueRef
  fun LLVMConstFNeg(LLVMValueRef) : LLVMValueRef
  fun LLVMConstNot(LLVMValueRef) : LLVMValueRef
  fun LLVMConstAdd(LLVMValueRef, LLVMValueRef) : LLVMValueRef
  fun LLVMConstNSWAdd(LLVMValueRef, LLVMValueRef) : LLVMValueRef
  fun LLVMConstNUWAdd(LLVMValueRef, LLVMValueRef) : LLVMValueRef
  fun LLVMConstFAdd(LLVMValueRef, LLVMValueRef) : LLVMValueRef
  fun LLVMConstSub(LLVMValueRef, LLVMValueRef) : LLVMValueRef
  fun LLVMConstNSWSub(LLVMValueRef, LLVMValueRef) : LLVMValueRef
  fun LLVMConstNUWSub(LLVMValueRef, LLVMValueRef) : LLVMValueRef
  fun LLVMConstFSub(LLVMValueRef, LLVMValueRef) : LLVMValueRef
  fun LLVMConstMul(LLVMValueRef, LLVMValueRef) : LLVMValueRef
  fun LLVMConstNSWMul(LLVMValueRef, LLVMValueRef) : LLVMValueRef
  fun LLVMConstNUWMul(LLVMValueRef, LLVMValueRef) : LLVMValueRef
  fun LLVMConstFMul(LLVMValueRef, LLVMValueRef) : LLVMValueRef
  fun LLVMConstUDiv(LLVMValueRef, LLVMValueRef) : LLVMValueRef
  fun LLVMConstExactUDiv(LLVMValueRef, LLVMValueRef) : LLVMValueRef
  fun LLVMConstSDiv(LLVMValueRef, LLVMValueRef) : LLVMValueRef
  fun LLVMConstExactSDiv(LLVMValueRef, LLVMValueRef) : LLVMValueRef
  fun LLVMConstFDiv(LLVMValueRef, LLVMValueRef) : LLVMValueRef
  fun LLVMConstURem(LLVMValueRef, LLVMValueRef) : LLVMValueRef
  fun LLVMConstSRem(LLVMValueRef, LLVMValueRef) : LLVMValueRef
  fun LLVMConstFRem(LLVMValueRef, LLVMValueRef) : LLVMValueRef
  fun LLVMConstAnd(LLVMValueRef, LLVMValueRef) : LLVMValueRef
  fun LLVMConstOr(LLVMValueRef, LLVMValueRef) : LLVMValueRef
  fun LLVMConstXor(LLVMValueRef, LLVMValueRef) : LLVMValueRef
  fun LLVMConstICmp(LLVMIntPredicate, LLVMValueRef, LLVMValueRef) : LLVMValueRef
  fun LLVMConstFCmp(LLVMRealPredicate, LLVMValueRef, LLVMValueRef) : LLVMValueRef
  fun LLVMConstShl(LLVMValueRef, LLVMValueRef) : LLVMValueRef
  fun LLVMConstLShr(LLVMValueRef, LLVMValueRef) : LLVMValueRef
  fun LLVMConstAShr(LLVMValueRef, LLVMValueRef) : LLVMValueRef
  fun LLVMConstGEP(LLVMValueRef, LLVMOpaqueValue**, UInt) : LLVMValueRef
  fun LLVMConstInBoundsGEP(LLVMValueRef, LLVMOpaqueValue**, UInt) : LLVMValueRef
  fun LLVMConstTrunc(LLVMValueRef, LLVMTypeRef) : LLVMValueRef
  fun LLVMConstSExt(LLVMValueRef, LLVMTypeRef) : LLVMValueRef
  fun LLVMConstZExt(LLVMValueRef, LLVMTypeRef) : LLVMValueRef
  fun LLVMConstFPTrunc(LLVMValueRef, LLVMTypeRef) : LLVMValueRef
  fun LLVMConstFPExt(LLVMValueRef, LLVMTypeRef) : LLVMValueRef
  fun LLVMConstUIToFP(LLVMValueRef, LLVMTypeRef) : LLVMValueRef
  fun LLVMConstSIToFP(LLVMValueRef, LLVMTypeRef) : LLVMValueRef
  fun LLVMConstFPToUI(LLVMValueRef, LLVMTypeRef) : LLVMValueRef
  fun LLVMConstFPToSI(LLVMValueRef, LLVMTypeRef) : LLVMValueRef
  fun LLVMConstPtrToInt(LLVMValueRef, LLVMTypeRef) : LLVMValueRef
  fun LLVMConstIntToPtr(LLVMValueRef, LLVMTypeRef) : LLVMValueRef
  fun LLVMConstBitCast(LLVMValueRef, LLVMTypeRef) : LLVMValueRef
  fun LLVMConstAddrSpaceCast(LLVMValueRef, LLVMTypeRef) : LLVMValueRef
  fun LLVMConstZExtOrBitCast(LLVMValueRef, LLVMTypeRef) : LLVMValueRef
  fun LLVMConstSExtOrBitCast(LLVMValueRef, LLVMTypeRef) : LLVMValueRef
  fun LLVMConstTruncOrBitCast(LLVMValueRef, LLVMTypeRef) : LLVMValueRef
  fun LLVMConstPointerCast(LLVMValueRef, LLVMTypeRef) : LLVMValueRef
  fun LLVMConstIntCast(LLVMValueRef, LLVMTypeRef, LLVMBool) : LLVMValueRef
  fun LLVMConstFPCast(LLVMValueRef, LLVMTypeRef) : LLVMValueRef
  fun LLVMConstSelect(LLVMValueRef, LLVMValueRef, LLVMValueRef) : LLVMValueRef
  fun LLVMConstExtractElement(LLVMValueRef, LLVMValueRef) : LLVMValueRef
  fun LLVMConstInsertElement(LLVMValueRef, LLVMValueRef, LLVMValueRef) : LLVMValueRef
  fun LLVMConstShuffleVector(LLVMValueRef, LLVMValueRef, LLVMValueRef) : LLVMValueRef
  fun LLVMConstExtractValue(LLVMValueRef, UInt*, UInt) : LLVMValueRef
  fun LLVMConstInsertValue(LLVMValueRef, LLVMValueRef, UInt*, UInt) : LLVMValueRef
  fun LLVMConstInlineAsm(LLVMTypeRef, Char*, Char*, LLVMBool, LLVMBool) : LLVMValueRef
  fun LLVMBlockAddress(LLVMValueRef, LLVMBasicBlockRef) : LLVMValueRef
  fun LLVMGetGlobalParent(LLVMValueRef) : LLVMModuleRef
  fun LLVMIsDeclaration(LLVMValueRef) : LLVMBool
  fun LLVMGetLinkage(LLVMValueRef) : LLVMLinkage
  fun LLVMSetLinkage(LLVMValueRef, LLVMLinkage) : Void
  fun LLVMGetSection(LLVMValueRef) : Char*
  fun LLVMSetSection(LLVMValueRef, Char*) : Void
  fun LLVMGetVisibility(LLVMValueRef) : LLVMVisibility
  fun LLVMSetVisibility(LLVMValueRef, LLVMVisibility) : Void
  fun LLVMGetDLLStorageClass(LLVMValueRef) : LLVMDLLStorageClass
  fun LLVMSetDLLStorageClass(LLVMValueRef, LLVMDLLStorageClass) : Void
  fun LLVMHasUnnamedAddr(LLVMValueRef) : LLVMBool
  fun LLVMSetUnnamedAddr(LLVMValueRef, LLVMBool) : Void
  fun LLVMGetAlignment(LLVMValueRef) : UInt
  fun LLVMSetAlignment(LLVMValueRef, UInt) : Void
  fun LLVMAddGlobal(LLVMModuleRef, LLVMTypeRef, Char*) : LLVMValueRef
  fun LLVMAddGlobalInAddressSpace(LLVMModuleRef, LLVMTypeRef, Char*, UInt) : LLVMValueRef
  fun LLVMGetNamedGlobal(LLVMModuleRef, Char*) : LLVMValueRef
  fun LLVMGetFirstGlobal(LLVMModuleRef) : LLVMValueRef
  fun LLVMGetLastGlobal(LLVMModuleRef) : LLVMValueRef
  fun LLVMGetNextGlobal(LLVMValueRef) : LLVMValueRef
  fun LLVMGetPreviousGlobal(LLVMValueRef) : LLVMValueRef
  fun LLVMDeleteGlobal(LLVMValueRef) : Void
  fun LLVMGetInitializer(LLVMValueRef) : LLVMValueRef
  fun LLVMSetInitializer(LLVMValueRef, LLVMValueRef) : Void
  fun LLVMIsThreadLocal(LLVMValueRef) : LLVMBool
  fun LLVMSetThreadLocal(LLVMValueRef, LLVMBool) : Void
  fun LLVMIsGlobalConstant(LLVMValueRef) : LLVMBool
  fun LLVMSetGlobalConstant(LLVMValueRef, LLVMBool) : Void
  fun LLVMGetThreadLocalMode(LLVMValueRef) : LLVMThreadLocalMode
  fun LLVMSetThreadLocalMode(LLVMValueRef, LLVMThreadLocalMode) : Void
  fun LLVMIsExternallyInitialized(LLVMValueRef) : LLVMBool
  fun LLVMSetExternallyInitialized(LLVMValueRef, LLVMBool) : Void
  fun LLVMAddAlias(LLVMModuleRef, LLVMTypeRef, LLVMValueRef, Char*) : LLVMValueRef
  fun LLVMDeleteFunction(LLVMValueRef) : Void
  fun LLVMHasPersonalityFn(LLVMValueRef) : LLVMBool
  fun LLVMGetPersonalityFn(LLVMValueRef) : LLVMValueRef
  fun LLVMSetPersonalityFn(LLVMValueRef, LLVMValueRef) : Void
  fun LLVMGetIntrinsicID(LLVMValueRef) : UInt
  fun LLVMGetFunctionCallConv(LLVMValueRef) : UInt
  fun LLVMSetFunctionCallConv(LLVMValueRef, UInt) : Void
  fun LLVMGetGC(LLVMValueRef) : Char*
  fun LLVMSetGC(LLVMValueRef, Char*) : Void
  fun LLVMAddAttributeAtIndex(LLVMValueRef, LLVMAttributeIndex, LLVMAttributeRef) : Void
  fun LLVMGetAttributeCountAtIndex(LLVMValueRef, LLVMAttributeIndex) : UInt
  fun LLVMGetAttributesAtIndex(LLVMValueRef, LLVMAttributeIndex, LLVMOpaqueAttributeRef**) : Void
  fun LLVMGetEnumAttributeAtIndex(LLVMValueRef, LLVMAttributeIndex, UInt) : LLVMAttributeRef
  fun LLVMGetStringAttributeAtIndex(LLVMValueRef, LLVMAttributeIndex, Char*, UInt) : LLVMAttributeRef
  fun LLVMRemoveEnumAttributeAtIndex(LLVMValueRef, LLVMAttributeIndex, UInt) : Void
  fun LLVMRemoveStringAttributeAtIndex(LLVMValueRef, LLVMAttributeIndex, Char*, UInt) : Void
  fun LLVMAddTargetDependentFunctionAttr(LLVMValueRef, Char*, Char*) : Void
  fun LLVMCountParams(LLVMValueRef) : UInt
  fun LLVMGetParams(LLVMValueRef, LLVMOpaqueValue**) : Void
  fun LLVMGetParam(LLVMValueRef, UInt) : LLVMValueRef
  fun LLVMGetParamParent(LLVMValueRef) : LLVMValueRef
  fun LLVMGetFirstParam(LLVMValueRef) : LLVMValueRef
  fun LLVMGetLastParam(LLVMValueRef) : LLVMValueRef
  fun LLVMGetNextParam(LLVMValueRef) : LLVMValueRef
  fun LLVMGetPreviousParam(LLVMValueRef) : LLVMValueRef
  fun LLVMSetParamAlignment(LLVMValueRef, UInt) : Void
  fun LLVMMDStringInContext(LLVMContextRef, Char*, UInt) : LLVMValueRef
  fun LLVMMDString(Char*, UInt) : LLVMValueRef
  fun LLVMMDNodeInContext(LLVMContextRef, LLVMOpaqueValue**, UInt) : LLVMValueRef
  fun LLVMMDNode(LLVMOpaqueValue**, UInt) : LLVMValueRef
  fun LLVMMetadataAsValue(LLVMContextRef, LLVMMetadataRef) : LLVMValueRef
  fun LLVMValueAsMetadata(LLVMValueRef) : LLVMMetadataRef
  fun LLVMGetMDString(LLVMValueRef, UInt*) : Char*
  fun LLVMGetMDNodeNumOperands(LLVMValueRef) : UInt
  fun LLVMGetMDNodeOperands(LLVMValueRef, LLVMOpaqueValue**) : Void
  fun LLVMBasicBlockAsValue(LLVMBasicBlockRef) : LLVMValueRef
  fun LLVMValueIsBasicBlock(LLVMValueRef) : LLVMBool
  fun LLVMValueAsBasicBlock(LLVMValueRef) : LLVMBasicBlockRef
  fun LLVMGetBasicBlockName(LLVMBasicBlockRef) : Char*
  fun LLVMGetBasicBlockParent(LLVMBasicBlockRef) : LLVMValueRef
  fun LLVMGetBasicBlockTerminator(LLVMBasicBlockRef) : LLVMValueRef
  fun LLVMCountBasicBlocks(LLVMValueRef) : UInt
  fun LLVMGetBasicBlocks(LLVMValueRef, LLVMOpaqueBasicBlock**) : Void
  fun LLVMGetFirstBasicBlock(LLVMValueRef) : LLVMBasicBlockRef
  fun LLVMGetLastBasicBlock(LLVMValueRef) : LLVMBasicBlockRef
  fun LLVMGetNextBasicBlock(LLVMBasicBlockRef) : LLVMBasicBlockRef
  fun LLVMGetPreviousBasicBlock(LLVMBasicBlockRef) : LLVMBasicBlockRef
  fun LLVMGetEntryBasicBlock(LLVMValueRef) : LLVMBasicBlockRef
  fun LLVMAppendBasicBlockInContext(LLVMContextRef, LLVMValueRef, Char*) : LLVMBasicBlockRef
  fun LLVMAppendBasicBlock(LLVMValueRef, Char*) : LLVMBasicBlockRef
  fun LLVMInsertBasicBlockInContext(LLVMContextRef, LLVMBasicBlockRef, Char*) : LLVMBasicBlockRef
  fun LLVMInsertBasicBlock(LLVMBasicBlockRef, Char*) : LLVMBasicBlockRef
  fun LLVMDeleteBasicBlock(LLVMBasicBlockRef) : Void
  fun LLVMRemoveBasicBlockFromParent(LLVMBasicBlockRef) : Void
  fun LLVMMoveBasicBlockBefore(LLVMBasicBlockRef, LLVMBasicBlockRef) : Void
  fun LLVMMoveBasicBlockAfter(LLVMBasicBlockRef, LLVMBasicBlockRef) : Void
  fun LLVMGetFirstInstruction(LLVMBasicBlockRef) : LLVMValueRef
  fun LLVMGetLastInstruction(LLVMBasicBlockRef) : LLVMValueRef
  fun LLVMHasMetadata(LLVMValueRef) : Int
  fun LLVMGetMetadata(LLVMValueRef, UInt) : LLVMValueRef
  fun LLVMSetMetadata(LLVMValueRef, UInt, LLVMValueRef) : Void
  fun LLVMGetInstructionParent(LLVMValueRef) : LLVMBasicBlockRef
  fun LLVMGetNextInstruction(LLVMValueRef) : LLVMValueRef
  fun LLVMGetPreviousInstruction(LLVMValueRef) : LLVMValueRef
  fun LLVMInstructionRemoveFromParent(LLVMValueRef) : Void
  fun LLVMInstructionEraseFromParent(LLVMValueRef) : Void
  fun LLVMGetInstructionOpcode(LLVMValueRef) : LLVMOpcode
  fun LLVMGetICmpPredicate(LLVMValueRef) : LLVMIntPredicate
  fun LLVMGetFCmpPredicate(LLVMValueRef) : LLVMRealPredicate
  fun LLVMInstructionClone(LLVMValueRef) : LLVMValueRef
  fun LLVMGetNumArgOperands(LLVMValueRef) : UInt
  fun LLVMSetInstructionCallConv(LLVMValueRef, UInt) : Void
  fun LLVMGetInstructionCallConv(LLVMValueRef) : UInt
  fun LLVMSetInstrParamAlignment(LLVMValueRef, UInt, UInt) : Void
  fun LLVMAddCallSiteAttribute(LLVMValueRef, LLVMAttributeIndex, LLVMAttributeRef) : Void
  fun LLVMGetCallSiteAttributeCount(LLVMValueRef, LLVMAttributeIndex) : UInt
  fun LLVMGetCallSiteAttributes(LLVMValueRef, LLVMAttributeIndex, LLVMOpaqueAttributeRef**) : Void
  fun LLVMGetCallSiteEnumAttribute(LLVMValueRef, LLVMAttributeIndex, UInt) : LLVMAttributeRef
  fun LLVMGetCallSiteStringAttribute(LLVMValueRef, LLVMAttributeIndex, Char*, UInt) : LLVMAttributeRef
  fun LLVMRemoveCallSiteEnumAttribute(LLVMValueRef, LLVMAttributeIndex, UInt) : Void
  fun LLVMRemoveCallSiteStringAttribute(LLVMValueRef, LLVMAttributeIndex, Char*, UInt) : Void
  fun LLVMGetCalledValue(LLVMValueRef) : LLVMValueRef
  fun LLVMIsTailCall(LLVMValueRef) : LLVMBool
  fun LLVMSetTailCall(LLVMValueRef, LLVMBool) : Void
  fun LLVMGetNormalDest(LLVMValueRef) : LLVMBasicBlockRef
  fun LLVMGetUnwindDest(LLVMValueRef) : LLVMBasicBlockRef
  fun LLVMSetNormalDest(LLVMValueRef, LLVMBasicBlockRef) : Void
  fun LLVMSetUnwindDest(LLVMValueRef, LLVMBasicBlockRef) : Void
  fun LLVMGetNumSuccessors(LLVMValueRef) : UInt
  fun LLVMGetSuccessor(LLVMValueRef, UInt) : LLVMBasicBlockRef
  fun LLVMSetSuccessor(LLVMValueRef, UInt, LLVMBasicBlockRef) : Void
  fun LLVMIsConditional(LLVMValueRef) : LLVMBool
  fun LLVMGetCondition(LLVMValueRef) : LLVMValueRef
  fun LLVMSetCondition(LLVMValueRef, LLVMValueRef) : Void
  fun LLVMGetSwitchDefaultDest(LLVMValueRef) : LLVMBasicBlockRef
  fun LLVMGetAllocatedType(LLVMValueRef) : LLVMTypeRef
  fun LLVMIsInBounds(LLVMValueRef) : LLVMBool
  fun LLVMSetIsInBounds(LLVMValueRef, LLVMBool) : Void
  fun LLVMAddIncoming(LLVMValueRef, LLVMOpaqueValue**, LLVMOpaqueBasicBlock**, UInt) : Void
  fun LLVMCountIncoming(LLVMValueRef) : UInt
  fun LLVMGetIncomingValue(LLVMValueRef, UInt) : LLVMValueRef
  fun LLVMGetIncomingBlock(LLVMValueRef, UInt) : LLVMBasicBlockRef
  fun LLVMGetNumIndices(LLVMValueRef) : UInt
  fun LLVMGetIndices(LLVMValueRef) : UInt*
  fun LLVMCreateBuilderInContext(LLVMContextRef) : LLVMBuilderRef
  fun LLVMCreateBuilder() : LLVMBuilderRef
  fun LLVMPositionBuilder(LLVMBuilderRef, LLVMBasicBlockRef, LLVMValueRef) : Void
  fun LLVMPositionBuilderBefore(LLVMBuilderRef, LLVMValueRef) : Void
  fun LLVMPositionBuilderAtEnd(LLVMBuilderRef, LLVMBasicBlockRef) : Void
  fun LLVMGetInsertBlock(LLVMBuilderRef) : LLVMBasicBlockRef
  fun LLVMClearInsertionPosition(LLVMBuilderRef) : Void
  fun LLVMInsertIntoBuilder(LLVMBuilderRef, LLVMValueRef) : Void
  fun LLVMInsertIntoBuilderWithName(LLVMBuilderRef, LLVMValueRef, Char*) : Void
  fun LLVMDisposeBuilder(LLVMBuilderRef) : Void
  fun LLVMSetCurrentDebugLocation(LLVMBuilderRef, LLVMValueRef) : Void
  fun LLVMGetCurrentDebugLocation(LLVMBuilderRef) : LLVMValueRef
  fun LLVMSetInstDebugLocation(LLVMBuilderRef, LLVMValueRef) : Void
  fun LLVMBuildRetVoid(LLVMBuilderRef) : LLVMValueRef
  fun LLVMBuildRet(LLVMBuilderRef, LLVMValueRef) : LLVMValueRef
  fun LLVMBuildAggregateRet(LLVMBuilderRef, LLVMOpaqueValue**, UInt) : LLVMValueRef
  fun LLVMBuildBr(LLVMBuilderRef, LLVMBasicBlockRef) : LLVMValueRef
  fun LLVMBuildCondBr(LLVMBuilderRef, LLVMValueRef, LLVMBasicBlockRef, LLVMBasicBlockRef) : LLVMValueRef
  fun LLVMBuildSwitch(LLVMBuilderRef, LLVMValueRef, LLVMBasicBlockRef, UInt) : LLVMValueRef
  fun LLVMBuildIndirectBr(LLVMBuilderRef, LLVMValueRef, UInt) : LLVMValueRef
  fun LLVMBuildInvoke(LLVMBuilderRef, LLVMValueRef, LLVMOpaqueValue**, UInt, LLVMBasicBlockRef, LLVMBasicBlockRef, Char*) : LLVMValueRef
  fun LLVMBuildLandingPad(LLVMBuilderRef, LLVMTypeRef, LLVMValueRef, UInt, Char*) : LLVMValueRef
  fun LLVMBuildResume(LLVMBuilderRef, LLVMValueRef) : LLVMValueRef
  fun LLVMBuildUnreachable(LLVMBuilderRef) : LLVMValueRef
  fun LLVMAddCase(LLVMValueRef, LLVMValueRef, LLVMBasicBlockRef) : Void
  fun LLVMAddDestination(LLVMValueRef, LLVMBasicBlockRef) : Void
  fun LLVMGetNumClauses(LLVMValueRef) : UInt
  fun LLVMGetClause(LLVMValueRef, UInt) : LLVMValueRef
  fun LLVMAddClause(LLVMValueRef, LLVMValueRef) : Void
  fun LLVMIsCleanup(LLVMValueRef) : LLVMBool
  fun LLVMSetCleanup(LLVMValueRef, LLVMBool) : Void
  fun LLVMBuildAdd(LLVMBuilderRef, LLVMValueRef, LLVMValueRef, Char*) : LLVMValueRef
  fun LLVMBuildNSWAdd(LLVMBuilderRef, LLVMValueRef, LLVMValueRef, Char*) : LLVMValueRef
  fun LLVMBuildNUWAdd(LLVMBuilderRef, LLVMValueRef, LLVMValueRef, Char*) : LLVMValueRef
  fun LLVMBuildFAdd(LLVMBuilderRef, LLVMValueRef, LLVMValueRef, Char*) : LLVMValueRef
  fun LLVMBuildSub(LLVMBuilderRef, LLVMValueRef, LLVMValueRef, Char*) : LLVMValueRef
  fun LLVMBuildNSWSub(LLVMBuilderRef, LLVMValueRef, LLVMValueRef, Char*) : LLVMValueRef
  fun LLVMBuildNUWSub(LLVMBuilderRef, LLVMValueRef, LLVMValueRef, Char*) : LLVMValueRef
  fun LLVMBuildFSub(LLVMBuilderRef, LLVMValueRef, LLVMValueRef, Char*) : LLVMValueRef
  fun LLVMBuildMul(LLVMBuilderRef, LLVMValueRef, LLVMValueRef, Char*) : LLVMValueRef
  fun LLVMBuildNSWMul(LLVMBuilderRef, LLVMValueRef, LLVMValueRef, Char*) : LLVMValueRef
  fun LLVMBuildNUWMul(LLVMBuilderRef, LLVMValueRef, LLVMValueRef, Char*) : LLVMValueRef
  fun LLVMBuildFMul(LLVMBuilderRef, LLVMValueRef, LLVMValueRef, Char*) : LLVMValueRef
  fun LLVMBuildUDiv(LLVMBuilderRef, LLVMValueRef, LLVMValueRef, Char*) : LLVMValueRef
  fun LLVMBuildExactUDiv(LLVMBuilderRef, LLVMValueRef, LLVMValueRef, Char*) : LLVMValueRef
  fun LLVMBuildSDiv(LLVMBuilderRef, LLVMValueRef, LLVMValueRef, Char*) : LLVMValueRef
  fun LLVMBuildExactSDiv(LLVMBuilderRef, LLVMValueRef, LLVMValueRef, Char*) : LLVMValueRef
  fun LLVMBuildFDiv(LLVMBuilderRef, LLVMValueRef, LLVMValueRef, Char*) : LLVMValueRef
  fun LLVMBuildURem(LLVMBuilderRef, LLVMValueRef, LLVMValueRef, Char*) : LLVMValueRef
  fun LLVMBuildSRem(LLVMBuilderRef, LLVMValueRef, LLVMValueRef, Char*) : LLVMValueRef
  fun LLVMBuildFRem(LLVMBuilderRef, LLVMValueRef, LLVMValueRef, Char*) : LLVMValueRef
  fun LLVMBuildShl(LLVMBuilderRef, LLVMValueRef, LLVMValueRef, Char*) : LLVMValueRef
  fun LLVMBuildLShr(LLVMBuilderRef, LLVMValueRef, LLVMValueRef, Char*) : LLVMValueRef
  fun LLVMBuildAShr(LLVMBuilderRef, LLVMValueRef, LLVMValueRef, Char*) : LLVMValueRef
  fun LLVMBuildAnd(LLVMBuilderRef, LLVMValueRef, LLVMValueRef, Char*) : LLVMValueRef
  fun LLVMBuildOr(LLVMBuilderRef, LLVMValueRef, LLVMValueRef, Char*) : LLVMValueRef
  fun LLVMBuildXor(LLVMBuilderRef, LLVMValueRef, LLVMValueRef, Char*) : LLVMValueRef
  fun LLVMBuildBinOp(LLVMBuilderRef, LLVMOpcode, LLVMValueRef, LLVMValueRef, Char*) : LLVMValueRef
  fun LLVMBuildNeg(LLVMBuilderRef, LLVMValueRef, Char*) : LLVMValueRef
  fun LLVMBuildNSWNeg(LLVMBuilderRef, LLVMValueRef, Char*) : LLVMValueRef
  fun LLVMBuildNUWNeg(LLVMBuilderRef, LLVMValueRef, Char*) : LLVMValueRef
  fun LLVMBuildFNeg(LLVMBuilderRef, LLVMValueRef, Char*) : LLVMValueRef
  fun LLVMBuildNot(LLVMBuilderRef, LLVMValueRef, Char*) : LLVMValueRef
  fun LLVMBuildMalloc(LLVMBuilderRef, LLVMTypeRef, Char*) : LLVMValueRef
  fun LLVMBuildArrayMalloc(LLVMBuilderRef, LLVMTypeRef, LLVMValueRef, Char*) : LLVMValueRef
  fun LLVMBuildAlloca(LLVMBuilderRef, LLVMTypeRef, Char*) : LLVMValueRef
  fun LLVMBuildArrayAlloca(LLVMBuilderRef, LLVMTypeRef, LLVMValueRef, Char*) : LLVMValueRef
  fun LLVMBuildFree(LLVMBuilderRef, LLVMValueRef) : LLVMValueRef
  fun LLVMBuildLoad(LLVMBuilderRef, LLVMValueRef, Char*) : LLVMValueRef
  fun LLVMBuildStore(LLVMBuilderRef, LLVMValueRef, LLVMValueRef) : LLVMValueRef
  fun LLVMBuildGEP(LLVMBuilderRef, LLVMValueRef, LLVMOpaqueValue**, UInt, Char*) : LLVMValueRef
  fun LLVMBuildInBoundsGEP(LLVMBuilderRef, LLVMValueRef, LLVMOpaqueValue**, UInt, Char*) : LLVMValueRef
  fun LLVMBuildStructGEP(LLVMBuilderRef, LLVMValueRef, UInt, Char*) : LLVMValueRef
  fun LLVMBuildGlobalString(LLVMBuilderRef, Char*, Char*) : LLVMValueRef
  fun LLVMBuildGlobalStringPtr(LLVMBuilderRef, Char*, Char*) : LLVMValueRef
  fun LLVMGetVolatile(LLVMValueRef) : LLVMBool
  fun LLVMSetVolatile(LLVMValueRef, LLVMBool) : Void
  fun LLVMGetOrdering(LLVMValueRef) : LLVMAtomicOrdering
  fun LLVMSetOrdering(LLVMValueRef, LLVMAtomicOrdering) : Void
  fun LLVMBuildTrunc(LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, Char*) : LLVMValueRef
  fun LLVMBuildZExt(LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, Char*) : LLVMValueRef
  fun LLVMBuildSExt(LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, Char*) : LLVMValueRef
  fun LLVMBuildFPToUI(LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, Char*) : LLVMValueRef
  fun LLVMBuildFPToSI(LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, Char*) : LLVMValueRef
  fun LLVMBuildUIToFP(LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, Char*) : LLVMValueRef
  fun LLVMBuildSIToFP(LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, Char*) : LLVMValueRef
  fun LLVMBuildFPTrunc(LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, Char*) : LLVMValueRef
  fun LLVMBuildFPExt(LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, Char*) : LLVMValueRef
  fun LLVMBuildPtrToInt(LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, Char*) : LLVMValueRef
  fun LLVMBuildIntToPtr(LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, Char*) : LLVMValueRef
  fun LLVMBuildBitCast(LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, Char*) : LLVMValueRef
  fun LLVMBuildAddrSpaceCast(LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, Char*) : LLVMValueRef
  fun LLVMBuildZExtOrBitCast(LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, Char*) : LLVMValueRef
  fun LLVMBuildSExtOrBitCast(LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, Char*) : LLVMValueRef
  fun LLVMBuildTruncOrBitCast(LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, Char*) : LLVMValueRef
  fun LLVMBuildCast(LLVMBuilderRef, LLVMOpcode, LLVMValueRef, LLVMTypeRef, Char*) : LLVMValueRef
  fun LLVMBuildPointerCast(LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, Char*) : LLVMValueRef
  fun LLVMBuildIntCast(LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, Char*) : LLVMValueRef
  fun LLVMBuildFPCast(LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, Char*) : LLVMValueRef
  fun LLVMBuildICmp(LLVMBuilderRef, LLVMIntPredicate, LLVMValueRef, LLVMValueRef, Char*) : LLVMValueRef
  fun LLVMBuildFCmp(LLVMBuilderRef, LLVMRealPredicate, LLVMValueRef, LLVMValueRef, Char*) : LLVMValueRef
  fun LLVMBuildPhi(LLVMBuilderRef, LLVMTypeRef, Char*) : LLVMValueRef
  fun LLVMBuildCall(LLVMBuilderRef, LLVMValueRef, LLVMOpaqueValue**, UInt, Char*) : LLVMValueRef
  fun LLVMBuildSelect(LLVMBuilderRef, LLVMValueRef, LLVMValueRef, LLVMValueRef, Char*) : LLVMValueRef
  fun LLVMBuildVAArg(LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, Char*) : LLVMValueRef
  fun LLVMBuildExtractElement(LLVMBuilderRef, LLVMValueRef, LLVMValueRef, Char*) : LLVMValueRef
  fun LLVMBuildInsertElement(LLVMBuilderRef, LLVMValueRef, LLVMValueRef, LLVMValueRef, Char*) : LLVMValueRef
  fun LLVMBuildShuffleVector(LLVMBuilderRef, LLVMValueRef, LLVMValueRef, LLVMValueRef, Char*) : LLVMValueRef
  fun LLVMBuildExtractValue(LLVMBuilderRef, LLVMValueRef, UInt, Char*) : LLVMValueRef
  fun LLVMBuildInsertValue(LLVMBuilderRef, LLVMValueRef, LLVMValueRef, UInt, Char*) : LLVMValueRef
  fun LLVMBuildIsNull(LLVMBuilderRef, LLVMValueRef, Char*) : LLVMValueRef
  fun LLVMBuildIsNotNull(LLVMBuilderRef, LLVMValueRef, Char*) : LLVMValueRef
  fun LLVMBuildPtrDiff(LLVMBuilderRef, LLVMValueRef, LLVMValueRef, Char*) : LLVMValueRef
  fun LLVMBuildFence(LLVMBuilderRef, LLVMAtomicOrdering, LLVMBool, Char*) : LLVMValueRef
  fun LLVMBuildAtomicRMW(LLVMBuilderRef, LLVMAtomicRMWBinOp, LLVMValueRef, LLVMValueRef, LLVMAtomicOrdering, LLVMBool) : LLVMValueRef
  fun LLVMBuildAtomicCmpXchg(LLVMBuilderRef, LLVMValueRef, LLVMValueRef, LLVMValueRef, LLVMAtomicOrdering, LLVMAtomicOrdering, LLVMBool) : LLVMValueRef
  fun LLVMIsAtomicSingleThread(LLVMValueRef) : LLVMBool
  fun LLVMSetAtomicSingleThread(LLVMValueRef, LLVMBool) : Void
  fun LLVMGetCmpXchgSuccessOrdering(LLVMValueRef) : LLVMAtomicOrdering
  fun LLVMSetCmpXchgSuccessOrdering(LLVMValueRef, LLVMAtomicOrdering) : Void
  fun LLVMGetCmpXchgFailureOrdering(LLVMValueRef) : LLVMAtomicOrdering
  fun LLVMSetCmpXchgFailureOrdering(LLVMValueRef, LLVMAtomicOrdering) : Void
  fun LLVMCreateModuleProviderForExistingModule(LLVMModuleRef) : LLVMModuleProviderRef
  fun LLVMDisposeModuleProvider(LLVMModuleProviderRef) : Void
  fun LLVMCreateMemoryBufferWithContentsOfFile(Char*, LLVMOpaqueMemoryBuffer**, Char**) : LLVMBool
  fun LLVMCreateMemoryBufferWithSTDIN(LLVMOpaqueMemoryBuffer**, Char**) : LLVMBool
  fun LLVMCreateMemoryBufferWithMemoryRange(Char*, Int, Char*, LLVMBool) : LLVMMemoryBufferRef
  fun LLVMCreateMemoryBufferWithMemoryRangeCopy(Char*, Int, Char*) : LLVMMemoryBufferRef
  fun LLVMGetBufferStart(LLVMMemoryBufferRef) : Char*
  fun LLVMGetBufferSize(LLVMMemoryBufferRef) : Int
  fun LLVMDisposeMemoryBuffer(LLVMMemoryBufferRef) : Void
  fun LLVMGetGlobalPassRegistry() : LLVMPassRegistryRef
  fun LLVMCreatePassManager() : LLVMPassManagerRef
  fun LLVMCreateFunctionPassManagerForModule(LLVMModuleRef) : LLVMPassManagerRef
  fun LLVMCreateFunctionPassManager(LLVMModuleProviderRef) : LLVMPassManagerRef
  fun LLVMRunPassManager(LLVMPassManagerRef, LLVMModuleRef) : LLVMBool
  fun LLVMInitializeFunctionPassManager(LLVMPassManagerRef) : LLVMBool
  fun LLVMRunFunctionPassManager(LLVMPassManagerRef, LLVMValueRef) : LLVMBool
  fun LLVMFinalizeFunctionPassManager(LLVMPassManagerRef) : LLVMBool
  fun LLVMDisposePassManager(LLVMPassManagerRef) : Void
  fun LLVMStartMultithreaded() : LLVMBool
  fun LLVMStopMultithreaded() : Void
  fun LLVMIsMultithreaded() : LLVMBool
end
