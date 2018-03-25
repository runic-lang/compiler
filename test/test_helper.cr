require "minitest/autorun"
require "../src/lexer"
require "../src/parser"
require "../src/program"
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

  protected def parse_each(source, top_level_expressions = true)
    parser(source, top_level_expressions).parse do |node|
      yield node
    end
  end

  protected def parse_all(source, top_level_expressions = true)
    parser(source, top_level_expressions).parse do |node|
      program.register(node)
    end
  end

  protected def parser(source, top_level_expressions = true)
    Runic::Parser.new(lex(source), top_level_expressions)
  end

  protected def lex(source)
    Runic::Lexer.new(IO::Memory.new(source))
  end

  protected def program
    @program ||= Runic::Program.new
  end
end
