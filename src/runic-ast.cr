require "./parser"
require "./semantic"
require "./version"

module Runic
  module Command
    struct AST
      {% for option in %w(semantic location) %}
        def self.{{option.id}}
          @@{{option.id}} || false
        end

        def self.{{option.id}}=(@@{{option.id}} : Bool)
        end
      {% end %}

      @semantic : Semantic?
      @location : Bool

      def initialize(source : IO, file : String, semantic = AST.semantic, @location = AST.location)
        lexer = Lexer.new(source, file)
        @parser = Parser.new(lexer, top_level_expressions: true)
        @nested = 0
        @semantic = Semantic.new if semantic
      end

      def run
        while node = @parser.next
          @semantic.try(&.visit(node))
          to_h(node)
        end
      end

      def to_h(node : Runic::AST::Integer)
        print "- integer: #{node.sign}#{node.value}#{to_options(node)}"
      end

      def to_h(node : Runic::AST::Float)
        print "- float: #{node.sign}#{node.value}#{to_options(node)}"
      end

      def to_h(node : Runic::AST::Boolean)
        print "- boolean: #{node.value}#{to_options(node)}"
      end

      def to_h(node : Runic::AST::Variable)
        print "- variable: #{node.name}#{to_options(node)}"
      end

      def to_h(node : Runic::AST::Constant)
        print "- constant: #{node.name}#{to_options(node)}"
      end

      def to_h(node : Runic::AST::Binary)
        print "- binary: #{node.operator}#{to_options(node)}"
        print "  lhs:"
        nested { to_h(node.lhs) }
        print "  rhs:"
        nested { to_h(node.rhs) }
      end

      def to_h(node : Runic::AST::Unary)
        print "- unary: #{node.operator}#{to_options(node)}"
        nested { to_h(node.expression) }
      end

      def to_h(node : Runic::AST::Prototype)
        args = node.args.map { |arg| "#{arg.name} : #{arg.type}" }.join(", ")
        print "- extern #{node.name}(#{args}) : #{node.type}#{to_options(node, type: false)}"
      end

      def to_h(node : Runic::AST::Function)
        args = node.args.map { |arg| "#{arg.name} : #{arg.type?}" }.join(", ")
        print "- def #{node.name}(#{args}) : #{node.type?}#{to_options(node, type: false)}"
        print "  body:"
        nested do
          node.body.each { |n| to_h(n) }
        end
      end

      def to_h(node : Runic::AST::Call)
        print "- call #{node.callee}#{to_options(node)}"
        print "  args:"
        nested do
          node.args.each do |arg|
            to_h(arg)
          end
        end
      end

      def to_options(node : Runic::AST::Node, type = true)
        String.build do |str|
          if type && @semantic
            str << " ("
            (node.type? || "??").to_s(str)
            str << ')'
          end
          if @location
            str << " at "
            node.location.to_s(str)
          end
        end
      end

      def print(string)
        @nested.times { ::print ' ' }
        ::puts string
      end

      def nested
        @nested += 4
        yield
      ensure
        @nested -= 4
      end
    end
  end
end

filenames = [] of String

ARGV.each_with_index do |arg|
  case arg
  when "--version", "version"
    puts "runic-ast version #{Runic.version_string}"
    exit 0
  when "--help", "help"
    STDERR.puts "<todo: ast command help message>"
    exit 0
  when "--semantic"
    Runic::Command::AST.semantic = true
  when "--location"
    Runic::Command::AST.location = true
  else
    if arg.starts_with?('-')
      abort "Unknown option: #{arg}"
    else
      filenames << arg
    end
  end
end

case filenames.size
when 0
  STDERR.puts "reading from stdin..."
  Runic::Command::AST.new(STDIN, "<stdin>").run
when 1
  filename = filenames.first

  if File.exists?(filename)
    File.open(filename, "r") do |io|
      Runic::Command::AST.new(io, filename).run
    end
  else
    abort "fatal : no such file or directory '#{filename}'."
  end
else
  abort "fatal : you may only specify one file to parse."
end
