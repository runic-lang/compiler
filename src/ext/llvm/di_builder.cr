@[Link(ldflags: "#{__DIR__}/di_builder.o")]
lib LibC
  LLVM_DEBUG_METADATA_VERSION = 3

  enum LLVMDIFlags
    FlagZero                = 0
    FlagPrivate             = 1
    FlagProtected           = 2
    FlagPublic              = 3
    FlagFwdDecl             = 1 << 2
    FlagAppleBlock          = 1 << 3
    FlagBlockByrefStruct    = 1 << 4
    FlagVirtual             = 1 << 5
    FlagArtificial          = 1 << 6
    FlagExplicit            = 1 << 7
    FlagPrototyped          = 1 << 8
    FlagObjcClassComplete   = 1 << 9
    FlagObjectPointer       = 1 << 10
    FlagVector              = 1 << 11
    FlagStaticMember        = 1 << 12
    FlagLValueReference     = 1 << 13
    FlagRValueReference     = 1 << 14
    FlagReserved            = 1 << 15
    FlagSingleInheritance   = 1 << 16
    FlagMultipleInheritance = 2 << 16
    FlagVirtualInheritance  = 3 << 16
    FlagIntroducedVirtual   = 1 << 18
    FlagBitField            = 1 << 19
    FlagNoReturn            = 1 << 20
    FlagMainSubprogram      = 1 << 21
    FlagIndirectVirtualBase = (1 << 2) | (1 << 5)
  end

  enum LLVMModFlagBehavior
    Error = 1
    Warning = 2
    Require = 3
    Override = 4
    Append = 5
    AppendUnique = 6
    Max = 7
  end

  fun LLVMCreateDIBuilder(LLVMModuleRef) : LLVMDIBuilderRef
  fun LLVMDIBuilderFinalize(LLVMDIBuilderRef) : Void
  fun LLVMDIBuilderCreateFile(LLVMDIBuilderRef, Char*, Char*) : LLVMMetadataRef
  fun LLVMDIBuilderCreateCompileUnit(LLVMDIBuilderRef, UInt, Char*, Char*, Char*, Int, Char*, UInt) : LLVMMetadataRef
  fun LLVMDIBuilderCreateFunction(LLVMDIBuilderRef, LLVMMetadataRef, Char*,
                                  Char*, LLVMMetadataRef, UInt, LLVMMetadataRef,
                                  Bool, Bool, UInt, LLVMDIFlags, Bool, LLVMValueRef) : LLVMMetadataRef
  fun LLVMDIBuilderCreateLexicalBlock(LLVMDIBuilderRef, LLVMMetadataRef, LLVMMetadataRef, UInt, UInt) : LLVMMetadataRef
  fun LLVMDIBuilderCreateBasicType(LLVMDIBuilderRef, Char*, UInt64, UInt64, UInt) : LLVMMetadataRef
  fun LLVMDIBuilderGetOrCreateTypeArray(LLVMDIBuilderRef, LLVMMetadataRef*, UInt) : LLVMMetadataRef
  fun LLVMDIBuilderGetOrCreateArray(LLVMDIBuilderRef, LLVMMetadataRef*, UInt) : LLVMMetadataRef
  fun LLVMDIBuilderCreateSubroutineType(LLVMDIBuilderRef, LLVMMetadataRef, LLVMMetadataRef) : LLVMMetadataRef
  fun LLVMDIBuilderCreateAutoVariable( LLVMDIBuilderRef, LLVMMetadataRef, Char*,
                                      LLVMMetadataRef, UInt, LLVMMetadataRef,
                                      Int, LLVMDIFlags, UInt32) : LLVMMetadataRef
  fun LLVMDIBuilderCreateParameterVariable( LLVMDIBuilderRef, LLVMMetadataRef,
                                           Char*, UInt, LLVMMetadataRef, UInt,
                                           LLVMMetadataRef, Int, LLVMDIFlags) : LLVMMetadataRef
  fun LLVMDIBuilderInsertDeclareAtEnd(LLVMDIBuilderRef, LLVMValueRef, LLVMMetadataRef, LLVMMetadataRef, LLVMValueRef, LLVMBasicBlockRef) : LLVMValueRef
  fun LLVMDIBuilderCreateExpression(LLVMDIBuilderRef, Int64*, SizeT) : LLVMMetadataRef
  fun LLVMDIBuilderCreateEnumerationType( LLVMDIBuilderRef, LLVMMetadataRef, Char*, LLVMMetadataRef, UInt, UInt64, UInt64, LLVMMetadataRef, LLVMMetadataRef) : LLVMMetadataRef
  fun LLVMDIBuilderCreateEnumerator(LLVMDIBuilderRef, Char*, Int64) : LLVMMetadataRef
  fun LLVMDIBuilderCreateStructType(LLVMDIBuilderRef, LLVMMetadataRef, Char*,
                                    LLVMMetadataRef, UInt, UInt64, UInt64, LLVMDIFlags, LLVMMetadataRef, LLVMMetadataRef) : LLVMMetadataRef
  fun LLVMDIBuilderCreateReplaceableCompositeType(LLVMDIBuilderRef, LLVMMetadataRef, Char*, LLVMMetadataRef, UInt) : LLVMMetadataRef
  fun LLVMDIBuilderReplaceTemporary(LLVMDIBuilderRef, LLVMMetadataRef, LLVMMetadataRef) : Void
  fun LLVMDIBuilderCreateMemberType(LLVMDIBuilderRef, LLVMMetadataRef, Char*,
                                    LLVMMetadataRef, UInt, UInt64, UInt64,
                                    UInt64, LLVMDIFlags, LLVMMetadataRef) : LLVMMetadataRef
  fun LLVMDIBuilderCreatePointerType(LLVMDIBuilderRef, LLVMMetadataRef, UInt64, UInt64, Char*) : LLVMMetadataRef
  fun LLVMTemporaryMDNode(LLVMContextRef, LLVMMetadataRef*, UInt) : LLVMMetadataRef
  fun LLVMMetadataReplaceAllUsesWith(LLVMMetadataRef, LLVMMetadataRef) : Void
  fun LLVMSetCurrentDebugLocation2(LLVMBuilderRef, UInt, UInt, LLVMMetadataRef, LLVMMetadataRef) : Void
end
