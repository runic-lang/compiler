require "./cli"
require "./config"
require "./parser"
require "./semantic"

module Runic
  module Command
    struct AST
      @semantic : Bool
      @location : Bool

      def initialize(source : IO, @file : String, @semantic : Bool, @location : Bool, corelib : String?)
        @nested = 0
        lexer = Lexer.new(source, @file)
        @program = Program.new
        @parser = Parser.new(lexer, top_level_expressions: true)

        if @semantic && corelib
          @program.require(corelib)
        end
      end

      def run
        while node = @parser.next
          if @semantic && node.is_a?(Runic::AST::Require)
            @program.require(node)
          end
          @program.register(node)
        end

        if @semantic
          Semantic.analyze(@program)
        end

        @program.each do |node|
          if node.location.file == @file
            to_h(node)
          end
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

      def to_h(node : Runic::AST::ConstantDefinition)
        print "- constant: #{node.name}#{to_options(node)}"
        print "  value:"
        nested { to_h(node.value) }
      end

      def to_h(node : Runic::AST::Assignment)
        print "- assignment: #{node.operator}#{to_options(node)}"
        print "  lhs:"
        nested { to_h(node.lhs) }
        print "  rhs:"
        nested { to_h(node.rhs) }
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
        args = node.args
        if node.args.first?.try(&.name) == "self"
          (args = args.dup).shift
        end
        args = args.map { |arg| "#{arg.name} : #{arg.type?}" }
        print "- def #{node.name}(#{args.join(", ")}) : #{node.type?}#{to_options(node, type: false)}", linefeed: node.attributes.empty?
        ::puts " [#{node.attributes.join(", ")}]" unless node.attributes.empty?

        unless node.attributes.includes?("primitive")
          print "  body:"
          nested do
            node.body.each { |n| to_h(n) }
          end
        end
      end

      def to_h(node : Runic::AST::Call)
        print "- call #{node.callee}#{to_options(node)}"
        if receiver = node.receiver
          print "  receiver:"
          nested do
            to_h(receiver)
          end
        end
        print "  args:"
        nested do
          node.args.each_with_index do |arg, index|
            next if node.receiver && index == 0
            to_h(arg)
          end
        end

        unless node.kwargs.empty?
          print "  kwargs:"
          nested do
            node.kwargs.each do |name, arg|
              print "#{name}: "
              to_h(arg)
            end
          end
        end
      end

      def to_h(node : Runic::AST::If)
        print "- if : #{node.type?}#{to_options(node, type: false)}"

        print "  condition:"
        nested do
          to_h(node.condition)
        end

        print "  body:"
        nested do
          node.body.each { |n| to_h(n) }
        end

        print "  alternate:"
        nested do
          node.body.each { |n| to_h(n) }
        end
      end

      def to_h(node : Runic::AST::Unless)
        print "- unless : #{node.type?}#{to_options(node, type: false)}"

        print "  condition:"
        nested do
          to_h(node.condition)
        end

        print "  body:"
        nested do
          node.body.each { |n| to_h(n) }
        end
      end

      def to_h(node : Runic::AST::While)
        print "- while : #{node.type?}#{to_options(node, type: false)}"

        print "  condition:"
        nested do
          to_h(node.condition)
        end

        print "  body:"
        nested do
          node.body.each { |n| to_h(n) }
        end
      end

      def to_h(node : Runic::AST::Until)
        print "- until : #{node.type?}#{to_options(node, type: false)}"

        print "  condition:"
        nested do
          to_h(node.condition)
        end

        print "  body:"
        nested do
          node.body.each { |n| to_h(n) }
        end
      end

      def to_h(node : Runic::AST::Case)
        print "- case : #{node.type?}#{to_options(node, type: false)}"

        print "  value:"
        nested do
          to_h(node.value)
        end

        nested do
          node.cases.each { |n| to_h(n) }
        end

        if body = node.alternative
          print "  else:"
          nested do
            body.each { |n| to_h(n) }
          end
        end
      end

      def to_h(node : Runic::AST::When)
        print "when : #{node.type?}#{to_options(node, type: false)}"

        print "  conditions:"
        nested do
          node.conditions.each { |n| to_h(n) }
        end

        print "  body:"
        nested do
          node.body.each { |n| to_h(n) }
        end
      end

      def to_h(node : Runic::AST::Body)
        node.expressions.each { |n| to_h(n) }
      end

      def to_h(node : Runic::AST::Module)
        print "- module #{node.name}"

        nested do
          node.modules.each { |n| to_h(n) }
        end

        nested do
          node.structs.each { |n| to_h(n) }
        end
      end

      def to_h(node : Runic::AST::Require)
        print "- require #{node.path.inspect}"
      end

      def to_h(node : Runic::AST::Struct)
        print "- struct #{node.name} [#{node.attributes.join(", ")}]"

        #nested do
        #  node.variables.each { |n| to_h(n) }
        #end

        nested do
          node.methods.each { |n| to_h(n) }
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

      def print(string, linefeed = true)
        @nested.times { ::print ' ' }
        if linefeed
          ::puts string
        else
          ::print string
        end
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
semantic = false
location = false
corelib = Runic.corelib

cli = Runic::CLI.new
cli.parse do |arg|
  case arg
  when "--semantic"
    semantic = true
  when "--location"
    location = true
  when "--corelib"
    corelib = cli.argument_value("--corelib")
  when "--no-corelib"
    corelib = nil
  when "--version", "version"
    cli.report_version("runic-ast")
  when "--help"
    STDERR.puts "<todo: ast command help message>"
    exit 0
  else
    filenames << cli.filename
  end
end

case filenames.size
when 0
  ast = Runic::Command::AST.new(STDIN, "<stdin>", semantic, location, corelib)
  STDERR.puts "reading from stdin..."
  ast.run
when 1
  filename = filenames.first

  if File.exists?(filename)
    File.open(filename, "r") do |io|
      Runic::Command::AST.new(io, filename, semantic, location, corelib).run
    rescue error : Runic::SyntaxError
      error.pretty_report(STDERR)
    rescue error : Runic::SemanticError
      error.pretty_report(STDERR)
    end
  else
    cli.fatal "no such file or directory '#{filename}'."
  end
else
  cli.fatal "you may only specify one file to parse."
end
