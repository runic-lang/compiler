require "./definitions"
require "./errors"
require "./location"
require "./token"

module Runic
  struct Lexer
    NUMBER_SUFFIXES = {
      "l"    => "long",
      "ul"   => "ulong",
      "i"    => "i32",
      "u"    => "u32",
      "i8"   => "i8",
      "u8"   => "u8",
      "i16"  => "i16",
      "u16"  => "u16",
      "i32"  => "i32",
      "u32"  => "u32",
      "i64"  => "i64",
      "u64"  => "u64",
      "i128" => "i128",
      "u128" => "u128",
      "f"    => "f64",
      "f16"  => "f16",
      "f32"  => "f32",
      "f64"  => "f64",
    }

    KEYWORDS = %w(
      alias
      case
      class
      def
      do
      if
      else
      elsif
      end
      extern
      match
      module
      mutable
      private
      protected
      public
      struct
      then
      unless
      until
      when
      while
    )

    @char : Char?

    def initialize(@source : IO, file = "MEMORY", @interactive = false)
      @location = Location.new(file, line: 1, column: 1)
    end

    def next
      skip_space

      char = peek_char
      location = @location

      case char
      when nil
        Token.new(:eof, "", location)
      when .ascii_letter?
        identifier = consume_identifier
        if KEYWORDS.includes?(identifier)
          Token.new(:keyword, identifier, location)
        else
          Token.new(:identifier, identifier, location)
        end
      when .number?
        value, type = consume_number, consume_optional_number_suffix
        if type.try(&.starts_with?("f")) ||
            value.includes?('.') ||
            (!value.starts_with?('0') && value.includes?('e'))
          Token.new(:float, value, location, type)
        else
          Token.new(:integer, value, location, type)
        end
      when '~', '!', '+', '-', '*', '/', '<', '>', '=', '%', '&', '|', '^'
        Token.new(:operator, consume_operator, location)
      when '.', ',', ':', '(', ')', '{', '}', '[', ']'
        Token.new(:mark, consume.to_s, location)
      when '\n', ';'
        if @interactive
          # interactive mode: skip linefeed immediately, don't wait for
          # potential future linefeeds:
          skip
        else
          # compile mode: group has many linefeeds as possible:
          skip_whitespace
        end
        Token.new(:linefeed, "", location)
      when '#'
        Token.new(:comment, consume_comment, location)
      else
        raise SyntaxError.new("unexpected character #{char.inspect}", location)
      end
    end

    # Picks next char once, the location is already pointing to this char, so
    # it's not updated.
    private def peek_char
      @char ||= @source.read_char
    end

    # Picks the previously peeked character and consumes it or directly consumes
    # a char from the source. Since the char is consumed the location is updated
    # to point to the next char.
    private def consume
      if char = @char
        @char = nil
      else
        char = @source.read_char
      end

      if char == '\n'
        @location.increment_line
      else
        @location.increment_column
      end

      char
    end

    # Consumes the previously peeked char or consumes a char from the source,
    # discarding the char altogether. The location is updated to point to the
    # next char.
    private def skip : Nil
      consume
    end

    private def consume_identifier
      consume_while { |c| c.ascii_alphanumeric? || c == '_' }
    end

    private def consume_number
      String.build do |str|
        if peek_char == '0'
          location = @location
          consume

          case peek_char
          when 'x'
            consume_hexadecimal_number(str)
          when 'o'
            consume_octal_number(str)
          when 'b'
            consume_binary_number(str)
          else
            if peek_char.nil? || !('0'..'9').includes?(peek_char.not_nil!)
              str << '0'
            end
            consume_decimal_number(str)
          end
        else
          consume_decimal_number(str)
        end
      end
    end

    private def consume_hexadecimal_number(str)
      str << '0'
      str << consume # x
      consume_number_while(str) do |char|
        case char
        when '0'..'9', 'a'..'f', 'A'..'F'
          str << consume
        end
      end
      raise SyntaxError.new("expected hexadecimal number", @location) if str.bytesize == 2
    end

    private def consume_octal_number(str)
      str << '0'
      str << consume # o
      consume_number_while(str) do |char|
        case char
        when '0'..'7'
          str << consume
        end
      end
      raise SyntaxError.new("expected octal number", @location) if str.bytesize == 2
    end

    private def consume_binary_number(str)
      str << '0'
      str << consume # b
      consume_number_while(str) do |char|
        case char
        when '0', '1'
          str << consume
        end
      end
      raise SyntaxError.new("expected binary number", @location) if str.bytesize == 2
    end

    private def consume_decimal_number(str)
      found_dot = 0
      found_exp = 0

      consume_number_while(str) do |char|
        if found_dot == 1
          if char.number?
            found_dot += 1
          else
            raise SyntaxError.new("unexpected character: #{char}", @location)
          end
        end

        if found_exp > 0
          found_exp += 1
        end

        case char
        when .number?
          str << consume
        when '.'
          if found_dot == 0
            found_dot += 1
            str << consume
          else
            # method call / field accessor (maybe)
            break
          end
        when 'e', 'E'
          if found_exp == 0
            found_exp += 1
            str << consume
          else
            raise SyntaxError.new("unexpected character: #{char}", @location)
          end
        when '-', '+'
          if found_exp == 2
            # exponential sign
            str << consume
          else
            # operator
            break
          end
        end
      end
    end

    private def consume_number_while(str)
      significant = false

      while char = peek_char
        if char == '0' && !significant
          # skip leading zero
          skip
          next
        end

        if yield(char)
          significant = true
          next
        end

        case char
        when '_'
          skip
        when 'i', 'u', 'l', 'f'
          break
        else
          break if terminated_number?
          raise SyntaxError.new("unexpected character: #{char}", @location)
        end
      end
    end

    private def consume_optional_number_suffix
      case peek_char
      when 'i', 'u', 'l', 'f'
        location = @location

        suffix = String.build do |str|
          str << consume
          while char = peek_char
            case char
            when '1', '2', '3', '4', '6', '8', 'l'
              str << consume
            else
              break if terminated_number?
              raise SyntaxError.new("unexpected character #{char}", @location)
            end
          end
        end

        NUMBER_SUFFIXES[suffix]? ||
          raise SyntaxError.new("invalid type suffix: #{suffix}", location)
      end
    end

    private def terminated_number?
      case peek_char
      when nil
        true
      when '.', '=', '~', '!', '+', '-', '*', '/', '%', '&', '|', '^', '<', '>', ')', ';', ',', .ascii_whitespace?
        true
      else
        false
      end
    end

    private def consume_comment
      leading_indent = 0

      String.build do |str|
        loop do |i|
          skip # '#'

          if i == 0
            # count leading whitespace and skip it
            while peek_char.try(&.ascii_whitespace?)
              skip
              leading_indent += 1
            end
          else
            # skip leading whitespace
            leading_indent.times do
              if peek_char.try(&.ascii_whitespace?)
                skip
              else
                break
              end
            end
          end

          consume_until(str) { |c| c == '\n' || c == '\r' || c.nil? }
          break if peek_char.nil?

          consume # '\n' '\r'
          skip_space

          # multiline comment?
          if peek_char == '#'
            str << '\n'
          else
            break
          end
        end
      end
    end

    private def consume_operator
      location = @location

      operator = String.build do |str|
        char = consume
        str << char

        loop do
          case peek_char
          when '+', '-', '*', '/', '<', '>', '=', '%', '^', '&', '|'
            str << (char = consume)
          else
            break
          end
        end
      end

      unless OPERATORS::ALL.includes?(operator)
        raise SyntaxError.new("invalid operator #{operator}", location)
      end

      operator
    end

    private def consume_while
      String.build do |str|
        consume_while(str) { |c| yield c }
      end
    end

    private def consume_while(str)
      loop do
        char = peek_char
        if char && yield(char)
          str << consume
        else
          break
        end
      end
    end

    private def consume_until(str)
      consume_while(str) { |char| !yield char }
    end

    private def skip_whitespace
      while char = peek_char
        break unless char.ascii_whitespace? || char == ';'
        skip
      end
    end

    private def skip_space
      while peek_char == ' '
        skip
      end
    end
  end
end
