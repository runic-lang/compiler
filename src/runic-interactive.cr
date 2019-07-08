require "./lexer"
require "./parser"
require "./semantic"
require "./codegen"
require "./config"

module Runic
  module Command
    class Interactive
      def initialize(@debug = false, optimize = true)
        LLVM.init_native
        LLVM.init_global_pass_registry if optimize

        @lexer = Lexer.new(STDIN, "stdin", interactive: true)
        @parser = Parser.new(@lexer, top_level_expressions: true, interactive: true)
        @program = Program.new
        @semantic = Semantic.new(@program)
        @generator = Codegen.new(debug: DebugLevel::None, optimize: optimize)
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
        ret = self.require(@parser.next.as(AST::Require), Dir.current)
        print "=> "
        puts ret.inspect
      end

      protected def require(node : AST::Require, relative_path : String? = nil) : Bool
        path = @program.resolve_require(node, relative_path)
        return false unless path

        File.open(path, "r") do |file|
          lexer = Lexer.new(file, path, interactive: false)
          parser = Parser.new(lexer, top_level_expressions: false)

          while node = parser.next
            case node
            when AST::Require
              self.require(node)
            else
              @semantic.visit(node)
              @program.register(node)
              debug @generator.codegen(node)
            end
          end
        end

        true
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
            result = @generator.execute(true, func)

          when "i8"
            result = @generator.execute(1_i8, func)
          when "i16"
            result = @generator.execute(1_i16, func)
          when "i32"
            result = @generator.execute(1_i32, func)
          when "i64"
            result = @generator.execute(1_i64, func)

          when "u8"
            result = @generator.execute(1_u8, func)
          when "u16"
            result = @generator.execute(1_u16, func)
          when "u32"
            result = @generator.execute(1_u32, func)
          when "u64"
            result = @generator.execute(1_u64, func)

          when "f32"
            result = @generator.execute(1_f32, func)
          when "f64"
            result = @generator.execute(1_f64, func)

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

i = -1
while arg = ARGV[i += 1]?
  case arg
  when "--debug"
    debug = true
  when "--no-optimize"
    optimize = false
  when "--help"
    Runic.open_manpage("interactive")
  else
    abort "Unknown option: #{arg}"
  end
end

Runic::Command::Interactive.new(debug, optimize).main_loop
