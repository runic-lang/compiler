require "./cli"
require "./lexer"
require "./parser"
require "./semantic"
require "./codegen"
require "./config"

module Runic
  module Command
    class Interactive
      def initialize(corelib : String?, @debug = false, optimize = true)
        LLVM.init_native
        LLVM.init_global_pass_registry if optimize

        @lexer = Lexer.new(STDIN, "stdin", interactive: true)
        @parser = Parser.new(@lexer, top_level_expressions: true, interactive: true)
        @program = Program.new
        @semantic = Semantic.new(@program)
        @generator = Codegen.new(@program, debug: DebugLevel::None, optimize: optimize)

        if corelib
          @program.require(corelib)
          @semantic.visit(@program)
          @program.each { |node| @generator.codegen(node) }
        end
      end

      def main_loop : Nil
        loop do
          print ">> "
          handle
        end
      end

      private def handle : Nil
        token = @parser.peek

        begin
          case token.type
          when :eof
            exit 0
          when :linefeed
            @parser.skip
            return
          when :keyword
            case token.value
            when "def"
              handle_definition
            when "extern"
              handle_extern
            when "require"
              handle_require
            else
              handle_top_level_expression
            end
          else
            handle_top_level_expression
          end
        rescue error : SyntaxError
          error.pretty_report(STDOUT, source: false)
          return
        rescue error : SemanticError
          error.pretty_report(STDOUT, source: false)
          return
        rescue ex
          @parser.skip
          puts "ERROR: #{ex.message}"
          ex.backtrace.each { |line| puts(line) }
        end

        # skip trailing linefeed
        if @parser.peek.type == :linefeed
          @parser.skip
        end
      end

      def handle_require : Nil
        if @program.require(@parser.next.as(AST::Require), Dir.current)
          @semantic.visit(@program)
          @program.each { |node| @generator.codegen(node) }
          puts "=> true"
        else
          puts "=> false"
        end
      end

      def handle_extern : Nil
        node = @parser.next.not_nil!
        @semantic.visit(node)
        debug @generator.codegen(node)
      end

      def handle_definition : Nil
        node = @parser.next.not_nil!
        @semantic.visit(node)
        debug @generator.codegen(node)
      end

      def handle_top_level_expression : Nil
        node = @parser.next.not_nil!
        @semantic.visit(node)

        func = @generator.codegen(wrap_expression(node))
        debug func

        begin
          case node.type.name
          when "bool"
            result = @generator.execute(Bool, func)

          when "i8"
            result = @generator.execute(Int8, func)
          when "i16"
            result = @generator.execute(Int16, func)
          when "i32"
            result = @generator.execute(Int32, func)
          when "i64"
            result = @generator.execute(Int64, func)

          when "u8"
            result = @generator.execute(UInt8, func)
          when "u16"
            result = @generator.execute(UInt16, func)
          when "u32"
            result = @generator.execute(UInt32, func)
          when "u64"
            result = @generator.execute(UInt64, func)

          when "f32"
            result = @generator.execute(Float32, func)
          when "f64"
            result = @generator.execute(Float64, func)

          when "String"
            result = @generator.execute(String, func)

          else
            puts "WARNING: unsupported return type '#{node.type}' (yet)"
            return
          end
          print "=> "
          puts result.inspect
        ensure
          LibC.LLVMDeleteFunction(func)
        end
      end

      private def wrap_expression(node : AST::Node)
        prototype = AST::Prototype.new("__anon_expr", [] of AST::Argument, node.type, "", node.location)
        body = AST::Body.new([node] of AST::Node, node.location)
        AST::Function.new(prototype, [] of String, body, node.location)
      end

      private def debug(value)
        return unless @debug
        STDERR.puts @generator.emit_llvm(value)
      end
    end
  end
end

debug = false
optimize = true
corelib = Runic.corelib

cli = Runic::CLI.new
cli.parse do |arg|
  case arg
  when "--corelib"
    corelib = cli.argument_value("--corelib")
  when "--no-corelib"
    corelib = nil
  when "--debug"
    debug = true
  when "--no-optimize"
    optimize = false
  when "--version"
    cli.report_version("runic-interactive")
  when "--help"
    Runic.open_manpage("interactive")
  else
    cli.unknown_option!
  end
end

Runic::Command::Interactive.new(corelib, debug, optimize).main_loop
