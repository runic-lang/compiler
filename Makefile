.POSIX:
.SUFFIXES:

CRYSTAL = crystal
LLVM_CONFIG = llvm-config-6.0
C2CR = CFLAGS=`$(LLVM_CONFIG) --cflags` lib/clang/bin/c2cr

COMMON_SOURCES = src/version.cr src/config.cr
LEXER_SOURCES = $(COMMON_SOURCES) src/definitions.cr src/errors.cr src/lexer.cr src/location.cr src/token.cr
PARSER_SOURCES = $(LEXER_SOURCES) src/parser.cr src/ast.cr src/type.cr src/program.cr
SEMANTIC_SOURCES = $(PARSER_SOURCES) src/semantic.cr src/semantic/*.cr
LLVM_SOURCES = libllvm src/llvm.cr src/c/llvm.cr src/ext/llvm/di_builder.o src/ext/llvm/di_builder.cr
CODEGEN_SOURCES = $(SEMANTIC_SOURCES) src/codegen.cr src/codegen/*.cr $(LLVM_SOURCES)
DOCUMENTATION_SOURCES = $(SEMANTIC_SOURCES) src/documentation.cr src/documentation/*.cr

COMMANDS = bin/runic
COMMANDS += libexec/runic-ast
COMMANDS += libexec/runic-compile
COMMANDS += libexec/runic-documentation
COMMANDS += libexec/runic-interactive
COMMANDS += libexec/runic-lex

all: $(COMMANDS) doc

dist: doc .phony
	mkdir -p dist/doc
	cp -r VERSION doc/man1 dist/doc
	cd dist && ln -sf ../src .
	cd dist && make -f ../Makefile CRFLAGS=--release $(COMMANDS)
	rm dist/src
	mkdir dist/src && cp src/intrinsics.runic dist/src/

bin/runic: src/runic.cr $(COMMON_SOURCES)
	@mkdir -p bin
	$(CRYSTAL) build -o bin/runic src/runic.cr src/version.cr $(CRFLAGS)

libexec/runic-lex: src/runic-lex.cr $(LEXER_SOURCES)
	@mkdir -p libexec
	$(CRYSTAL) build -o libexec/runic-lex src/runic-lex.cr $(CRFLAGS)

libexec/runic-ast: src/runic-ast.cr $(SEMANTIC_SOURCES)
	@mkdir -p libexec
	$(CRYSTAL) build -o libexec/runic-ast src/runic-ast.cr $(CRFLAGS)

libexec/runic-compile: src/runic-compile.cr $(CODEGEN_SOURCES)
	@mkdir -p libexec
	$(CRYSTAL) build -o libexec/runic-compile src/runic-compile.cr $(CRFLAGS)

libexec/runic-interactive: src/runic-interactive.cr $(CODEGEN_SOURCES)
	@mkdir -p libexec
	$(CRYSTAL) build -o libexec/runic-interactive src/runic-interactive.cr $(CRFLAGS)

libexec/runic-documentation: src/runic-documentation.cr $(DOCUMENTATION_SOURCES)
	@mkdir -p libexec
	$(CRYSTAL) build -o libexec/runic-documentation src/runic-documentation.cr $(CRFLAGS)

doc: .phony
	cd doc && make

libllvm: lib/clang/bin/c2cr
	@mkdir -p src/c/llvm/transforms
	$(C2CR) --remove-enum-prefix=LLVM --remove-enum-suffix llvm-c/Core.h > src/c/llvm/core.cr
	$(C2CR) --remove-enum-prefix=LLVM --remove-enum-suffix llvm-c/ErrorHandling.h > src/c/llvm/error_handling.cr
	$(C2CR) --remove-enum-prefix=LLVM --remove-enum-suffix llvm-c/ExecutionEngine.h > src/c/llvm/execution_engine.cr
	$(C2CR) --remove-enum-prefix=LLVM --remove-enum-suffix llvm-c/Target.h > src/c/llvm/target.cr
	$(C2CR) --remove-enum-prefix=LLVM --remove-enum-suffix llvm-c/TargetMachine.h > src/c/llvm/target_machine.cr
	$(C2CR) --remove-enum-prefix=LLVM --remove-enum-suffix llvm-c/Transforms/Scalar.h > src/c/llvm/transforms/scalar.cr
	$(C2CR) --remove-enum-prefix=LLVM --remove-enum-suffix llvm-c/Types.h > src/c/llvm/types.cr

lib/clang/bin/c2cr: .phony
	cd lib/clang && make

src/ext/llvm/%.o: src/ext/llvm/%.cc
	cd src/ext && make

clean: .phony
	rm -rf $(COMMANDS) dist src/c/llvm
	cd src/ext && make clean
	cd doc && make clean

test: .phony
	$(CRYSTAL) run `find test -iname "*_test.cr"` -- --verbose

.phony:
