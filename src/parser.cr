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
        when :keyword
          case peek.value
          when "def"
            return parse_definition
          when "extern"
            return parse_extern
          else
            return parse_top_level_expression if @top_level_expressions
            raise SyntaxError.new("unexpected #{peek.value.inspect} keyword", peek.location)
          end
        when :linefeed
          skip
        else
          if @top_level_expressions
            return parse_top_level_expression
          elsif peek.type == :identifier
            return parse_constant_assignment
          end
        end
      end
    end

    private def parse_documentation
      if (token = @previous_token) && token.type == :comment
        token.value
      else
        ""
      end
    end

    private def parse_definition
      documentation = parse_documentation

      location = consume.location # def
      name = consume_prototype_name
      args = consume_def_args

      if peek.value == ":"
        return_type = consume_type
      end

      prototype = AST::Prototype.new(name, args, return_type, documentation, location)
      body = parse_body("end")
      consume # end

      AST::Function.new(prototype, body, location)
    end

    private def parse_body(*stops)
      body = [] of AST::Node

      until stops.includes?(peek.value)
        if peek.type == :linefeed
          consume
        else
          body << parse_expression
        end
      end

      body
    end

    private def consume_type
      consume if peek.value == ":"
      case type = expect(:identifier).value
      when "int"
        "i32"
      when "uint"
        "u32"
      when "float"
        "f64"
      else
        type
      end
    end

    private def parse_extern
      documentation = parse_documentation

      consume # extern
      location = peek.location
      name = consume_prototype_name
      args = consume_extern_args

      if peek.value == ":"
        return_type = consume_type
      end
      AST::Prototype.new(name, args, return_type || "void", documentation, location)
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

    private def parse_constant_assignment
      unless peek.value =~ /^[A-Z_][A-Z0-9_]*$/
        raise SyntaxError.new("expected constant but got identifier #{peek.value.inspect}", peek.location)
      end

      lhs = AST::Constant.new(consume)
      op = expect("=")

      while peek.type == :whitespace
        skip
      end
      rhs = parse_literal do
        raise SyntaxError.new("expected literal but got #{peek.type.inspect}", peek.location)
      end

      AST::Binary.new(op.value, lhs, rhs, op.location)
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

        if binary_operator.assignment?
          # TODO: detect whether we are in a dynamic context to forbid constant definitions
          unless lhs.is_a?(AST::Variable) || (@top_level_expressions && lhs.is_a?(AST::Constant))
            raise SyntaxError.new("only variables may be assigned a value in a dynamic context", binary_operator.location)
          end
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
            unless expression.sign
              case operator.value
              when "+", "-"
                expression.sign = operator.value
                return expression
              end
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
      when :mark
        if peek.value == "("
          parse_parenthesis_expression
        else
          raise SyntaxError.new("expected expression but got #{peek.value.inspect}", peek.location)
        end
      when :linefeed
        skip
        parse_primary
      when :identifier
        parse_literal { parse_identifier_expression }
      when :keyword
        case peek.value
        when "if"
          parse_if_expression
        when "unless"
          parse_unless_expression
        #when "case"
        #  parse_case_expression
        #when "while"
        #  parse_while_expression
        #when "until"
        #  parse_until_expression
        else
          raise SyntaxError.new("expected expression but got #{peek.value.inspect} keyword", peek.location)
        end
      else
        parse_literal do
          raise SyntaxError.new("expected expression but got #{peek.type.inspect}", peek.location)
        end
      end
    end

    private def parse_literal
      case peek.type
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
        when /^[A-Z_][A-Z0-9_]*$/
          AST::Constant.new(consume)
        else
          yield
        end
      when :keyword
        raise SyntaxError.new("expected literal but got #{peek.value.inspect} keyword", peek.location)
      else
        yield
      end
    end

    private def parse_parenthesis_expression
      skip # (
      node = parse_expression
      expect ")"
      node
    end

    # Parses either a variable accessor, or a function call if immediately
    # followed by an opening parenthesis.
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

    private def parse_if_expression
      location = consume.location # if

      condition = parse_expression
      body = parse_body("end", "else")

      if peek.value == "else"
        consume # else
        alternative = parse_body("end")
      end
      consume # end

      AST::If.new(condition, body, alternative, location)
    end

    private def parse_unless_expression
      location = consume.location # unless

      condition = parse_expression
      body = parse_body("end")
      consume # end

      AST::Unless.new(condition, body, location)
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

    protected def consume
      if token = @token
        @previous_token, @token = @token, nil
        token
      else
        @previous_token = nil
        @lexer.next
      end
    end

    protected def skip : Nil
      consume
    end

    # Peeks the next token, skipping comment tokens (but still memorizing
    # comments as previous token, for documentation purposes).
    protected def peek
      @token ||= loop do
        token = @lexer.next

        if token.type == :comment
          @previous_token = token
        else
          break token
        end
      end
    end
  end
end
