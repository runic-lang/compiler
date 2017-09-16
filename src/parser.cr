require "./ast"
require "./errors"
require "./lexer"

module Runic
  struct Parser
    @token : Token?
    @previous_token : Token?

    def initialize(@lexer : Lexer)
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
        #when :identifier
        #  case peek.value
        #  when "def"
        #    return parse_definition
        #  when "fun"
        #    return parse_extern
        #  else
        #    return parse_top_level_expression
        #  end
        when :linefeed
          skip
        else
          return parse_top_level_expression
        end
      end
    end

    # private def parse_definition
    # end

    # private def parse_extern
    # end

    # private def parse_prototype
    # end

    private def parse_top_level_expression
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
          AST::Variable.new(consume)
        end
      #when :string
      #  parse_identifier_expression
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
