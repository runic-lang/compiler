require "./ast"
require "./errors"
require "./lexer"

module Runic
  struct Parser
    @token : Token?
    @previous_token : Token?

    def initialize(@lexer : Lexer, @top_level_expressions = false)
    end

    def parse
      while ast = self.next
        yield ast
      end
    end

    def next
      loop do
        case peek.type
        when :eof
          return
        when :identifier
          case peek.value
          when "def"
            return parse_definition
          when "extern"
            return parse_extern
          else
            return parse_top_level_expression
          end
        when :linefeed
          skip
        else
          return parse_top_level_expression
        end
      end
    end

    private def parse_definition
      consume # def
      location = peek.location
      name = consume_prototype_name
      args = consume_def_args

      if peek.value == ":"
        return_type = consume_type
      end

      prototype = AST::Prototype.new(name, args, return_type, location)
      body = [] of AST::Node

      until peek.value == "end"
        if peek.type == :linefeed
          consume
        else
          body << parse_expression
        end
      end
      consume # end

      AST::Function.new(prototype, body, location)
    end

    private def consume_type
      consume if peek.value == ":"
      case type = expect(:identifier).value
      when "int"
        "int32"
      when "float"
        "float64"
      else
        type
      end
    end

    private def parse_extern
      consume # extern
      location = peek.location
      name = consume_prototype_name
      args = consume_extern_args

      if peek.value == ":"
        return_type = consume_type
      end
      AST::Prototype.new(name, args, return_type || "void", location)
    end

    private def consume_prototype_name
      String.build do |str|
        loop do
          break if %w{( :}.includes?(peek.value) || %i(eof linefeed).includes?(peek.type)
          str << consume.value
        end
      end
    end

    private def consume_def_args
      consume_args do
        arg_name = expect(:identifier).value
        expect ":"
        {arg_name, consume_type}
      end
    end

    private def consume_extern_args
      index = 0
      consume_args do
        arg_name = expect(:identifier).value

        if peek.value == ":"
          {arg_name, consume_type}
        else
          {"x#{index += 1}", arg_name}
        end
      end
    end

    private def consume_args
      args = [] of AST::Variable

      if peek.type == :linefeed
        consume
        return args
      end

      if peek.value == ":" || peek.type == :eof
        return args
      end

      expect "("

      if peek.value == ")"
        consume
      else
        loop do
          location = peek.location
          arg_name, arg_type = yield

          arg = AST::Variable.new(arg_name, location)
          arg.type = arg_type if arg_type
          args << arg

          case peek.value
          when ")"
            consume
            break
          when ","
            consume
          end
        end
      end

      args
    end

    private def parse_top_level_expression
      unless @top_level_expressions
        raise SyntaxError.new("unexpected top level expression", peek.location)
      end
      parse_expression
    end

    private def parse_expression
      lhs = parse_unary
      parse_binary_operator_rhs(0, lhs)
    end

    private def parse_binary_operator_rhs(expression_precedence, lhs)
      loop do
        token_precedence = OPERATORS.precedence(peek.value)

        if token_precedence < expression_precedence
          return lhs
        end

        binary_operator = consume

        # NOTE: other LHS nodes may be assignable
        if binary_operator.assignment? && !lhs.is_a?(AST::Variable)
          raise SyntaxError.new("only variables may be assigned a value", binary_operator.location)
        end

        rhs = parse_unary
        next_precedence = OPERATORS.precedence(peek.value)

        if token_precedence < next_precedence
          rhs = parse_binary_operator_rhs(token_precedence + 1, rhs)
        end

        lhs = AST::Binary.new(binary_operator, lhs, rhs)
      end
    end

    private def parse_unary
      if peek.operator?
        if OPERATORS::UNARY.includes?(peek.value)
          operator = consume
          expression = parse_unary

          # number sign: -1, +1.2
          case expression
          when AST::Integer, AST::Float
            case operator.value
            when "+", "-"
              expression.sign = operator.value
              return expression
            end
          end

          # unary expression: -foo, ~123, ...
          AST::Unary.new(operator, expression)
        else
          raise SyntaxError.new("unexpected operator #{peek.value.inspect}", peek.location)
        end
      else
        parse_primary
      end
    end

    private def parse_primary
      case peek.type
      #when :if
      #  parse_if_expression
      #when :unless
      #  parse_unless_expression
      #when :case
      #  parse_case_expression
      #when :while
      #  parse_while_expression
      #when :until
      #  parse_until_expression
      when :integer
        AST::Integer.new(consume)
      when :float
        AST::Float.new(consume)
      when :identifier
        case peek.value
        when "true", "false"
          AST::Boolean.new(consume)
        #when "nil"
        #  AST::Nil.new(consume)
        else
          parse_identifier_expression
        end
      when :mark
        if peek.value == "("
          parse_parenthesis_expression
        else
          raise SyntaxError.new("expected expression but got #{peek.value.inspect}", peek.location)
        end
      when :linefeed
        skip
        parse_primary
      else
        raise SyntaxError.new("expected expression but got #{peek.type.inspect}", peek.location)
      end
    end

    private def parse_parenthesis_expression
      skip # (
      node = parse_expression
      expect ")"
      node
    end

    private def parse_identifier_expression
      identifier = consume

      # TODO: allow paren-less function calls
      unless peek.value == "("
        return AST::Variable.new(identifier)
      end

      consume # (
      args = [] of AST::Node

      unless peek.value == ")"
        loop do
          args << parse_expression
          break if peek.value == ")"
          expect ","
        end
      end

      consume # )
      AST::Call.new(identifier, args)
    end

    private def expect(type : Symbol)
      if peek.type == type
        consume
      else
        raise SyntaxError.new("expected #{type} but got #{peek.type}", peek.location)
      end
    end

    private def expect(value : String)
      if peek.value == value
        consume
      else
        raise SyntaxError.new("expected #{value} but got #{peek.value}", peek.location)
      end
    end

    private def consume
      if token = @token
        @previous_token, @token = @token, nil
        token
      else
        @previous_token = nil
        @lexer.next
      end
    end

    private def skip : Nil
      consume
    end

    # Peeks the next token, skipping comment tokens.
    #
    # TODO: memoize the previous token, including comment —it may be documentation.
    private def peek
      @token ||= loop do
        token = @lexer.next
        break token unless token.type == :comment
      end
    end
  end
end
