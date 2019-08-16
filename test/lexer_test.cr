require "./test_helper"

module Runic
  class LexerTest < Minitest::Test
    def test_eof
      assert_tokens [:eof, :eof], ""
    end

    def test_linefeeds_and_semicolons
      assert_tokens [:linefeed], "\n"
      assert_tokens [:semicolon], ";"
      assert_tokens [:semicolon, :eof], ";\n;\n\n"
      assert_tokens [:linefeed, :semicolon, :eof], "\n;\n;"
      assert_tokens [:identifier, :linefeed, :identifier, :linefeed, :eof], "a\nb\n"
      assert_tokens [:identifier, :linefeed, :identifier, :semicolon, :eof], "a \n  \n   c ;"
    end

    def test_identifiers
      source = "foo bar Baz BAZ fOo"
      assert_tokens [:identifier, :identifier, :identifier, :identifier, :identifier], source
      assert_tokens ["foo", "bar", "Baz", "BAZ", "fOo"], source
    end

    def test_keywords
      Lexer::KEYWORDS.each do |keyword|
        assert_tokens [:keyword], keyword
        assert_tokens [keyword], keyword
      end
    end

    def test_kwargs
      source = "value: BY: SomethinG:"
      assert_tokens [:kwarg, :kwarg, :kwarg], source
      assert_tokens ["value", "BY", "SomethinG"], source
    end

    def test_decimal_integer_literals
      assert_next :integer, "0"
      assert_next :integer, "1"
      assert_next :integer, "2147483647" # i32
      assert_next :integer, "18446744073709551615" # u64
      assert_next :integer, "340282366920938463463374607431768211455" # u128
      assert_next :integer, "115792089237316195423570985008687907853269984665640564039457584007913129639935" # u256
      assert_next :integer, "2147483", "2_14_7_483" # i32
      assert_next :integer, "2147483647", "2_147_483_647" # i32
      assert_next :integer, "18446744073709551615", "18_446_744_073_709_551_615" # u64
    end

    def test_hexadecimal_integer_literals
      assert_next :integer, "0x1"
      assert_next :integer, "0xdeadBEEF"
      assert_next :integer, "0x1234567890abcdef", "0x1234_5678_90a_bcd_e_f"
      assert_raises(SyntaxError) { lex("0xG").next }
    end

    def test_octal_integer_literals
      assert_next :integer, "0o1"
      assert_next :integer, "0o12345670"
      assert_next :integer, "0o12345670", "0o123_4_56_7_0"
      assert_raises(SyntaxError) { lex("0o8").next }
      assert_raises(SyntaxError) { lex("0oa").next }
    end

    def test_binary_integer_literals
      assert_next :integer, "0b1"
      assert_next :integer, "0b11110001"
      assert_next :integer, "0b11110001", "0b1111_000_1"
      assert_raises(SyntaxError) { lex("0b2").next }
      assert_raises(SyntaxError) { lex("0ba").next }
    end

    def test_float_literals
      assert_next :float, "0.0"
      assert_next :float, "1.0"
      assert_next :float, "8171.29732"
      assert_next :float, "2147.000001", "2_147.000_001" # i32
      assert_tokens ["123.456", ".", "789"], "123.456.789"
      assert_tokens ["123.456", ".", "abs"], "123.456.abs"
      assert_tokens ["123", ".", "abs"], "123.abs"
    end

    def test_exponential_float_literals
      assert_next :float, "10e7"
      assert_next :float, "10e-7"
      assert_next :float, "123.456e+721"
      assert_raises(SyntaxError) { lex("1e-7e9").next }
    end

    def test_skips_leading_zeros
      assert_next :integer, "12", "000012"
      assert_next :integer, "0xF0", "0x0000F0"
      assert_next :integer, "0b101", "0b0000101"
      assert_next :integer, "0o170", "0o0000170"
      assert_next :float, "12.001", "0012.001"
    end

    def test_number_type_suffixes
      Lexer::NUMBER_SUFFIXES.each do |suffix, type|
        assert_equal type, lex("1#{suffix}").next.literal_type
        assert_equal type, lex("1_#{suffix}").next.literal_type
      end
      assert_raises(SyntaxError) { lex("1gh").next }
      assert_raises(SyntaxError) { lex("1_i98").next }
    end

    def test_binary_operators
      %w(+ - * ** / // << >> % %% ^ & | || &&).each do |op|
        assert_tokens ["1", op, "2"], "1 #{op} 2"
        assert_tokens ["1", op, "2"], "1 #{op} 2"
        assert_tokens ["a", op, "b"], "a#{op}b"
        assert_tokens ["1", "#{op}=", "2"], "1 #{op}= 2"
        assert_tokens ["1", "#{op}=", "2"], "1#{op}=2"
        assert_tokens ["a", "#{op}=", "b"], "a#{op}=b"
      end
    end

    def test_logical_operators
      %w(< <= == >= > <=>).each do |op|
        assert_tokens ["1", op, "2"], "1 #{op} 2"
        assert_tokens ["1", op, "2"], "1#{op}2"
        assert_tokens ["a", op, "b"], "a#{op}b"
      end
    end

    def test_parenthesis
      assert_tokens ["(", "1", ")"], "(1)"
      assert_tokens ["(", "1", "+", "2", ")"], "( 1  + 2 )"
    end

    def test_token_location
      lexer = lex("foo += 12\nbar = foo * (12 + foo) \n  \n foo + bar")

      assert_location({1, 1}, lexer.next)  # foo
      assert_location({1, 5}, lexer.next)  # +=
      assert_location({1, 8}, lexer.next)  # 12
      assert_location({1, 10}, lexer.next) # \n

      assert_location({2, 1}, lexer.next)  # bar
      assert_location({2, 5}, lexer.next)  # =
      assert_location({2, 7}, lexer.next)  # foo
      assert_location({2, 11}, lexer.next) # *
      assert_location({2, 13}, lexer.next) # (
      assert_location({2, 14}, lexer.next) # 12
      assert_location({2, 17}, lexer.next) # +
      assert_location({2, 19}, lexer.next) # foo
      assert_location({2, 22}, lexer.next) # )
      assert_location({2, 24}, lexer.next) # \n

      assert_location({4, 2}, lexer.next)  # foo
      assert_location({4, 6}, lexer.next)  # +
      assert_location({4, 8}, lexer.next)  # bar
    end

    def test_invalid_operators
      assert_raises(SyntaxError) { lex("==>").next }
      assert_raises(SyntaxError) { lex("<<<==").next }
      assert_raises(SyntaxError) { lex("<>=&|^").next }
    end

    def test_unary_operators
      assert_tokens ["~", "1"], "~1"
      assert_tokens ["~", "123"], "~ 123"
      assert_tokens ["!", "true"], "!true"
      assert_tokens ["!", "false"], "! false"
      assert_tokens ["!", "!", "false"], "!!false"
      assert_tokens ["!", "!", "false"], "! ! false"
      assert_tokens ["true", "&&", "!", "false"], "true && !false"
      assert_tokens ["true", "&&", "!", "false"], "true&&!false"
    end

    def test_operators_on_exponential_literals
      assert_tokens ["1e7", "-", "9"], "1e7-9"
      assert_tokens ["1e-7", "-", "9"], "1e-7-9"
      assert_tokens ["1e+7", "+", "9"], "1e+7+9"
      assert_tokens ["1e+7", "+", "9e-10", "+", "1.0"], "1e+7+9e-10+1.0"

      assert_tokens [:integer, :identifier], "1 e7"
      assert_tokens ["1", "e7"], "1 e7"
    end

    def test_comments
      assert_next :comment, "foobar", "#foobar"
      assert_next :comment, "foobar", "   # foobar"
      assert_next :comment, "foo\nbar\nbaz", "# foo\n# bar\n# baz"
      assert_next :comment, "foo\nbar  \n  baz", "# foo\n    # bar  \n#   baz"
    end

    def test_strings
      assert_next :string, "foobar", %("foobar")
      assert_next :string, "keeps \escapes", %("keeps \\escapes")

      assert_next :string, "keeps line\n feed characters\r\n",
        %("keeps line\n feed characters\r\n")

      assert_next :string, "transforms escaped line\n characters\r\n",
        %("transforms escaped line\\n characters\\r\\n")

      assert_next :string, "transforms \\backslashes\\",
        %("transforms \\\\backslashes\\\\")

      assert_next :string, %(nested "quotes"), %("nested \\"quotes\\"")

      ex = assert_raises(SyntaxError) { lex(%("unterminated)).next }
      assert_match "unterminated string literal", ex.message

      {
        {"a",  0x07}, # bell (BEL)
        {"b",  0x08}, # backspace (BS)
        {"e",  0x1B}, # escape (ESC)
        {"f",  0x0C}, # form feed (FF)
        {"n",  0x0A}, # newline (LF)
        {"r",  0x0D}, # carriage return (CR)
        {"t",  0x09}, # horizontal tab (TAB)
        {"v",  0x0B}, # vertical tab (VT)
        {"\\", 0x5C}, # backslash
        {"'",  0x27}, # single quote
        {"\"", 0x22}, # double quote
      }.each do |(char, codepoint)|
        assert_next :string, codepoint.unsafe_chr.to_s, "\"\\#{char}\""
      end

      # octal codepoints:
      (0o0..0o777).each do |ord|
        if ord < 8
          assert_next :string, ord.unsafe_chr.to_s, %("\\0#{ord.to_s(8)}")
          assert_next :string, ord.unsafe_chr.to_s, %("\\00#{ord.to_s(8)}")
        end
        assert_next :string, ord.unsafe_chr.to_s, %("\\#{ord.to_s(8)}")
      end

      # hexadecimal codepoints:
      (0x0..0xff).each do |ord|
        if ord < 16
          assert_next :string, ord.unsafe_chr.to_s, %("\\x0#{ord.to_s(16)}")
        end
        assert_next :string, ord.unsafe_chr.to_s, %("\\x#{ord.to_s(16)}")
      end

      # unicode codepoints:
      assert_next :string, "\u0000", %("\\u0")
      assert_next :string, "\u0000", %("\\u00")
      assert_next :string, "\u0000", %("\\u000")
      assert_next :string, "\u0000", %("\\u0000")
      assert_next :string, "\u0000", %("\\u00000")
      assert_next :string, "\u0000", %("\\u000000")
      assert_next :string, "\u{10ffff}", %("\\u10ffff")
      assert_next :string, "\u{10ffff}", %("\\u10FFFF")
      assert_next :string, "\u{0 1 12 123 123a 123af}", %("\\u{0 01 012 0123 0123a 0123AF}")
    end

    def test_attributes
      assert_next :attribute, "primitive", "#[primitive]\n"
      assert_next :attribute, "noreturn", "#[noreturn]\n"

      ex = assert_raises(SyntaxError) { lex("#[noreturn]").next }
      assert_match "expected linefeed after attribute declaration", ex.message
    end

    def test_attributes_after_comment
      assert_tokens [:comment, :attribute, :attribute],
        "# some multiline\n # documentation\n#[primitive]\n#[noreturn]\n"

      assert_next :comment, "some multiline\ndocumentation",
        "# some multiline\n # documentation\n#[primitive]\n"

      assert_next :comment, "some multiline\ndocumentation\n\n",
        "# some multiline\n # documentation\n#\n#\n#[primitive]\n"
    end

    def test_mark
      ["(", ")", "[", "]", "{", "}", "."].each do |mark|
        assert_next :mark, mark
      end
    end

    def test_instance_variables
      assert_next :ivar, "value", "@value"
      assert_next :ivar, "foo", "@foo"
    end

    private def assert_next(type, value, source = value, file = __FILE__, line = __LINE__)
      token = lex(source).next
      assert_equal type, token.type, nil, file, line
      assert_equal value, token.value, nil, file, line
    end

    private def assert_tokens(tokens : Array(Symbol), source, file = __FILE__, line = __LINE__)
      lexer = lex(source)
      assert_equal tokens, tokens.size.times.map { lexer.next.type }.to_a, nil, file, line
    end

    private def assert_tokens(tokens : Array(String), source, file = __FILE__, line = __LINE__)
      lexer = lex(source)
      assert_equal tokens, tokens.size.times.map { lexer.next.value }.to_a, nil, file, line
    end

    private def assert_location(position, token, file = __FILE__, line = __LINE__)
      assert_equal position, {token.location.line, token.location.column}, nil, file, line
    end
  end
end
