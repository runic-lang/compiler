require "./ast"
require "./errors"
require "./lexer"

module Runic
  struct Parser
    @token : Token?
    @previous_token : Token?

    def initialize(@lexer : Lexer, @top_level_expressions = false)
      @attributes = [] of String
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
          when "struct"
            return parse_struct
          when "module"
            return parse_module
          else
            return parse_top_level_expression if @top_level_expressions
            raise SyntaxError.new("unexpected #{peek.value.inspect} keyword", peek.location)
          end
        when :linefeed, :semicolon
          skip_line_terminator
        else
          if @top_level_expressions
            return parse_top_level_expression
          elsif peek.type == :identifier
            return parse_constant_assignment
          end
        end
      end
    end

    private def parse_module
      documentation = consume_documentation

      location = consume.location # module
      name = expect(:identifier).value
      expect_line_terminator

      modules = [] of AST::Module
      structs = [] of AST::Struct

      # TODO: allow reopening modules
      mod = AST::Module.new(name, documentation, location)

      loop do
        case peek.type
        when :keyword
          case peek.value
          when "module"
            mod.modules << parse_module
          when "struct"
            mod.structs << parse_struct
          when "end"
            skip
            return mod
          else
            break
          end
        #when :identifier
        #  mod.constants << parse_constant_assignment
        when :linefeed, :semicolon
          skip_line_terminator
        else
          break
        end
      end

      raise SyntaxError.new("expected module, struct or end but got #{peek}", peek.location)
    end

    private def parse_struct
      attributes = @attributes.dup
      documentation = consume_documentation

      location = consume.location # struct
      name = consume_type
      expect_line_terminator

      # TODO: allow reopening structs
      node = AST::Struct.new(name, attributes, documentation, location)

      loop do
        case peek.type
        when :keyword
          case peek.value
          when "def"
            node.methods << parse_definition
          when "end"
            skip # end
            break
          else
            raise SyntaxError.new("expected 'def' or 'end' but got '#{peek}'", peek.location)
          end
        when :linefeed, :semicolon
          skip_line_terminator
        else
          raise SyntaxError.new("unexpected '#{peek}'", peek.location)
        end
      end

      node
    end

    private def parse_definition
      attributes = @attributes.dup
      documentation = consume_documentation

      location = consume.location # def
      name = consume_prototype_name
      args = consume_def_args

      if peek.value == ":"
        return_type = consume_type
      end

      prototype = AST::Prototype.new(name, args, return_type, documentation, location)
      body = parse_body("end")
      skip # end

      AST::Function.new(prototype, attributes, body, location)
    end

    private def parse_body(*stops, location = peek.location)
      body = [] of AST::Node

      until stops.includes?(peek.value)
        if {:linefeed, :semicolon}.includes?(peek.type)
          skip
        else
          body << parse_statement
        end
      end

      AST::Body.new(body, location)
    end

    private def consume_type
      skip if peek.value == ":"
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

    private def consume_documentation
      if (token = @previous_token) && token.type == :comment
        token.value
      else
        ""
      end
    end

    private def parse_extern
      documentation = consume_documentation
      skip # extern
      location = peek.location
      name = consume_prototype_name
      args = consume_extern_args
      return_type = peek.value == ":" ? consume_type : "void"
      AST::Prototype.new(name, args, return_type, documentation, location)
    end

    private def consume_prototype_name
      String.build do |str|
        loop do
          break if {"(", ":"}.includes?(peek.value) || {:eof, :linefeed, :semicolon}.includes?(peek.type)
          str << consume.value
        end
      end
    end

    private def consume_def_args
      expect_default_value = false

      consume_args do
        location = peek.location
        arg_type = arg_default = nil

        arg_name = expect(:identifier).value

        if peek.value == ":"
          skip # ':'
          arg_type = consume_type
        end

        if peek.value == "="
          skip # '='

          arg_default = parse_literal do
            raise SyntaxError.new("expected literal but got #{peek.type.inspect}", peek.location)
          end

          unless arg_type
            # TODO: postpone to semantic analysis (?)
            arg_type = arg_default.type
          end

          # futher arguments must have a default value
          expect_default_value = true
        end

        if expect_default_value && arg_default.nil?
          raise SyntaxError.new("argument '#{arg_name}' must have a default value", location)
        end
        if arg_type.nil?
          raise SyntaxError.new("argument '#{arg_name}' must have a type or default value", location)
        end

        {arg_name, arg_type, arg_default.as(AST::Literal?)}
      end
    end

    private def consume_extern_args
      index = 0
      consume_args do
        arg_name = expect(:identifier).value

        if peek.value == ":"
          {arg_name, consume_type, nil}
        else
          {"x#{index += 1}", arg_name, nil}
        end
      end
    end

    private def consume_args
      args = [] of AST::Argument

      if {:linefeed, :semicolon}.includes?(peek.type)
        skip_line_terminator
        return args
      end

      if peek.value == ":" || peek.value == "=" || peek.type == :eof
        return args
      end

      expect "("
      skip_linefeed

      if peek.value == ")"
        skip
      else
        loop do
          location = peek.location

          arg_name, arg_type, arg_default = yield
          args << AST::Argument.new(arg_name, arg_type, arg_default, location)

          skip_linefeed

          case peek.value
          when ")"
            skip
            break
          when ","
            skip
            skip_linefeed
          end
        end
      end

      args
    end

    private def parse_constant_assignment
      unless peek.value =~ /^[A-Z_][A-Z0-9_]*$/
        raise SyntaxError.new("expected constant but got identifier #{peek.value.inspect}", peek.location)
      end

      name = consume.value
      op = expect("=")

      while peek.type == :whitespace
        skip
      end
      value = parse_literal do
        raise SyntaxError.new("expected literal but got #{peek.type.inspect}", peek.location)
      end

      AST::ConstantDefinition.new(name, value, op.location)
    end

    private def parse_top_level_expression
      unless @top_level_expressions
        raise SyntaxError.new("unexpected top level expression", peek.location)
      end
      parse_statement
    end

    private def parse_statement
      stmt = parse_expression

      while peek.type == :keyword
        location = peek.location
        body = AST::Body.new([stmt] of AST::Node, stmt.location)

        case peek.value
        when "if"
          skip
          stmt = AST::If.new(parse_expression, body, nil, location)
        when "unless"
          skip
          stmt = AST::Unless.new(parse_expression, body, location)
        when "while"
          skip
          stmt = AST::While.new(parse_expression, body, location)
        when "until"
          skip
          stmt = AST::Until.new(parse_expression, body, location)
        else
          raise SyntaxError.new("expected if, unless, while or until but got #{peek}", location)
        end
      end

      stmt
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
          loop do
            case lhs
            when AST::Variable
              break
            when AST::Constant
              if @top_level_expressions && binary_operator.value == "="
                value = parse_unary
                return AST::ConstantDefinition.new(lhs.name, value, binary_operator.location)
              end
            end
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
        parse_call_expression
      end
    end

    private def parse_call_expression
      expression = parse_primary

      while peek.value == "."
        skip # .
        expression = parse_identifier_expression(expression)
      end

      expression
    end

    private def parse_primary
      case peek.type
      when :mark
        if peek.value == "("
          parse_parenthesis_expression
        else
          raise SyntaxError.new("expected expression but got #{peek.value.inspect}", peek.location)
        end
      when :linefeed, :semicolon
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
        when "case"
          parse_case_expression
        when "while"
          parse_while_expression
        when "until"
          parse_until_expression
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
      skip_linefeed
      node = parse_expression
      skip_linefeed
      expect ")"
      node
    end

    # Parses either a variable accessor, or a function call if immediately
    # followed by an opening parenthesis.
    private def parse_identifier_expression(receiver = nil)
      identifier = consume
      args = [] of AST::Node
      kwargs = {} of String => AST::Node

      unless peek.value == "("
        if receiver
          return AST::Call.new(receiver, identifier, args, kwargs)
        else
          # TODO: allow paren-less function calls (without explicit receiver)
          return AST::Variable.new(identifier)
        end
      end

      expect "("
      skip_linefeed

      unless peek.value == ")"
        loop do
          if peek.type == :kwarg
            raise SyntaxError.new("duplicated named argument '#{peek.value}'", peek.location) if kwargs[peek.value]?
            kwargs[consume.value] = parse_expression
          elsif kwargs.empty?
            args << parse_expression
          else
            raise SyntaxError.new("expected named argument but got #{peek}", peek.location)
          end

          skip_linefeed
          break if peek.value == ")"

          expect ","
          skip_linefeed
        end
      end

      skip # )
      AST::Call.new(receiver, identifier, args, kwargs)
    end

    private def parse_if_expression
      location = consume.location # if

      condition = parse_expression
      body = parse_body("end", "else")

      if peek.value == "else"
        skip # else
        alternative = parse_body("end")
      end
      skip # end

      AST::If.new(condition, body, alternative, location)
    end

    private def parse_unless_expression
      location = consume.location # unless

      condition = parse_expression
      body = parse_body("end")
      skip # end

      AST::Unless.new(condition, body, location)
    end

    private def parse_case_expression
      location = consume.location # case
      value = parse_expression
      skip_line_terminator

      cases = [] of AST::When

      loop do
        when_location = expect_keyword("when").location

        conditions = [] of AST::Node
        loop do
          conditions << parse_expression
          break unless peek.value == ","
          skip # ,
        end

        if {:linefeed, :semicolon}.includes?(peek.type)
          skip
        else
          expect_keyword("then")
        end

        body = parse_body("when", "else", "end")
        cases << AST::When.new(conditions, body, when_location)

        if peek.value == "else" || peek.value == "end"
          break
        end
      end

      if peek.value == "else"
        skip
        alternative = parse_body("end")
      end

      expect_keyword("end")

      AST::Case.new(value, cases, alternative, location)
    end

    private def parse_while_expression
      location = consume.location # while

      condition = parse_expression
      body = parse_body("end")
      skip # end

      AST::While.new(condition, body, location)
    end

    private def parse_until_expression
      location = consume.location # until

      condition = parse_expression
      body = parse_body("end")
      skip # end

      AST::Until.new(condition, body, location)
    end

    private def expect(type : Symbol)
      if peek.type == type
        consume
      else
        raise SyntaxError.new("expected #{type} but got #{peek}", peek.location)
      end
    end

    private def expect(value : String)
      if peek.value == value
        consume
      else
        raise SyntaxError.new("expected #{value} but got #{peek}", peek.location)
      end
    end

    private def expect_keyword(value : String)
      if peek.type == :keyword && peek.value == value
        consume
      else
        raise SyntaxError.new("expected #{value} but got #{peek}", peek.location)
      end
    end

    private def expect_line_terminator
      unless {:linefeed, :semicolon}.includes?(peek.type)
        raise SyntaxError.new("expected LF or ; but got #{peek}", peek.location)
      end
      skip_line_terminator
    end

    private def skip_line_terminator
      while {:linefeed, :semicolon}.includes?(peek.type)
        skip
      end
    end

    private def skip_linefeed
      if peek.type == :linefeed
        skip
      end
    end

    protected def consume
      @attributes.clear

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

        case token.type
        when :comment
          @previous_token = token
        when :attribute
          @attributes << token.value
        else
          break token
        end
      end
    end
  end
end
