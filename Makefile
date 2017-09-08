COMMON_SOURCES = src/version.cr
LEXER_SOURCES = $(COMMON_SOURCES) src/definitions.cr src/errors.cr src/lexer.cr src/location.cr src/token.cr
PARSER_SOURCES = $(LEXER_SOURCES) src/parser.cr src/ast.cr
SEMANTIC_SOURCES = $(PARSER_SOURCES) src/semantic.cr src/semantic/*.cr

.PHONY: dist clean test

all: bin/runic libexec/runic-lex libexec/runic-ast

dist:
	mkdir -p dist
	cp VERSION dist/
	cd dist && ln -sf ../src .
	cd dist && make -f ../Makefile CRFLAGS=--release
	rm dist/src

bin/runic: src/runic.cr $(COMMON_SOURCES)
	@mkdir -p bin
	crystal build -o bin/runic src/runic.cr src/version.cr $(CRFLAGS)

libexec/runic-lex: src/commands/lex.cr $(LEXER_SOURCES)
	@mkdir -p libexec
	crystal build -o libexec/runic-lex src/commands/lex.cr $(CRFLAGS)

libexec/runic-ast: src/commands/ast.cr $(SEMANTIC_SOURCES)
	@mkdir -p libexec
	crystal build -o libexec/runic-ast src/commands/ast.cr $(CRFLAGS)

clean:
	rm -rf bin/runic libexec/runic-lex libexec/runic-ast dist

test:
	crystal run `find test -iname "*_test.cr"` -- --verbose
