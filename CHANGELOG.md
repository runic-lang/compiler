# CHANGELOG

## UNRELEASED

Initial development:
- Lexer: tokenizes numbers, operators, comments, ...
- Parser: parses literals, variables, unary and binary expressions
- Semantic analyzer: types all expressions of the AST
- Initial tools:
  - `runic lex` to lex a source file and print tokens
  - `runic ast` to parse a source file and print the AST
