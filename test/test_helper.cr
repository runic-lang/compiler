require "minitest/autorun"
require "../src/lexer"
require "../src/parser"
require "../src/semantic"

class Minitest::Test
  protected def visit(source)
    parse_each(source) do |node|
      visitor.visit(node)
      return node
    end
    raise "unreachable"
  end

  protected def visitor
    raise "ERROR: #{self.class.name}#visitor must be implemented."
  end

  protected def parse_each(source)
    parser(source).parse { |node| yield node }
  end

  protected def parse_all(source)
    parser(source).parse {}
  end

  protected def parser(source)
    Runic::Parser.new(lex(source), top_level_expressions: true)
  end

  protected def lex(source)
    Runic::Lexer.new(IO::Memory.new(source))
  end
end
