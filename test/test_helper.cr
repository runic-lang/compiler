require "minitest/autorun"
require "../src/lexer"
require "../src/parser"
require "../src/program"
require "../src/semantic"

class Minitest::Test
  protected def visit(source)
    parse_each(source) do |node|
      visitors.each(&.visit(node))
      return node
    end
    raise "unreachable"
  end

  protected def visitors
    raise "ERROR: #{self.class.name}#visitors must be implemented."
  end

  protected def require_corelib
    self.require(File.expand_path("../corelib/corelib", __DIR__))
    Runic::Semantic.analyze(program)
  end

  protected def require(path)
    path += ".runic" unless path.ends_with?(".runic")
    File.open(path, "r") do |io|
      parser(io, top_level_expressions: false).parse do |node|
        case node
        when Runic::AST::Require
          if require_path = program.resolve_require(node, File.dirname(path))
            self.require(require_path)
          end
        else
          program.register(node)
        end
      end
    end
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

  protected def lex(source : String)
    Runic::Lexer.new(IO::Memory.new(source))
  end

  protected def lex(io : IO)
    Runic::Lexer.new(io)
  end

  protected def program
    @program ||= Runic::Program.new
  end
end
