require "./test_helper"

module Runic
  class ParserTest < Minitest::Test
    def test_booleans
      assert_expression AST::Boolean, "true"
      assert_expression AST::Boolean, "false"
    end

    def test_integers
      assert_expression AST::Integer, "123"
      assert_expression AST::Integer, "123129871928718729172"

      assert_type "i32", "2147483647"
      assert_type "i32", "-2147483648"
      assert_type "i64", "9223372036854775807"
      assert_type "i64", "-9223372036854775808"
      assert_type "i128", "170141183460469231731687303715884105727"
      assert_type "i128", "-170141183460469231731687303715884105728"

      assert_type "u32", "0xf000_0000"
      assert_type "u64", "0xffff_ffff_FFFF_ffff"
      assert_type "u128", "0x000F_ffff_ffff_ffff_ffff"
      assert_type "u128", "0xFFFF_ffff_ffff_ffff_ffff_ffff_ffff_ffff"

      assert_type "u32", "0b#{"1" * 32}"
      assert_type "u32", "0b#{"0" * 32}_1111"
      assert_type "u64", "0b#{"1" * 64}"
      assert_type "u128", "0b#{"1" * 128}"
    end

    #def test_validates_integer_fit_representation_size
    #  # unsigned hexadecimal / binary representations can't have a sign:
    #  assert_raises(SyntaxError) { lex("-0xff").next }
    #  assert_raises(SyntaxError) { lex("-0b01").next }

    #  # hexadecimal / binary representations may be signed if specified (if value fits):
    #  assert_type "i32", "-0b01_i"
    #  assert_type "i32", "-0x7f_i"

    #  # value doesn't fit:
    #  assert_raises(SyntaxError) { lex("0x1_ff_u8").next }
    #  assert_raises(SyntaxError) { lex("0x1_ffff_u16").next }
    #  assert_raises(SyntaxError) { lex("0x1_ffff_ffff_u32").next }
    #  assert_raises(SyntaxError) { lex("0x1_ffff_ffff_ffff_ffff_u64").next }
    #  assert_raises(SyntaxError) { lex("0x1_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_u128").next }

    #  assert_raises(SyntaxError) { lex("0xff_i8").next }
    #  assert_raises(SyntaxError) { lex("0xffff_i16").next }
    #  assert_raises(SyntaxError) { lex("0xffff_ffff_i32").next }
    #  assert_raises(SyntaxError) { lex("0xffff_ffff_ffff_ffff_i64").next }
    #  assert_raises(SyntaxError) { lex("0xffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_i128").next }
    #end

    def test_floats
      assert_expression AST::Float, "1.0"
      assert_expression AST::Float, "1.129182"
      assert_expression AST::Float, "1e7"
    end

    def test_variables
      assert_expression AST::Variable, "a"
      assert_expression AST::Variable, "foo_bar"
    end

    def test_unary_operators
      OPERATORS::UNARY.each do |operator|
        assert_expression AST::Unary, "#{operator}foo"
        assert_expression AST::Unary, "#{operator}\nfoo"
      end
      assert_expression AST::Integer, "+123"
      assert_expression AST::Integer, "-123"
      assert_expression AST::Float, "+123.02"
      assert_expression AST::Float, "-123.02"

      assert_expression AST::Unary, "- -123"
      assert_expression AST::Unary, "-(-123)"
    end

    def test_binary_operators
      OPERATORS::BINARY.each do |operator|
        assert_expression AST::Binary, "1 #{operator} 2"
        assert_expression AST::Binary, "1 #{operator}\n2"

        # some binary operators like + and - are also unary operators
        unless OPERATORS::UNARY.includes?(operator)
          assert_raises(SyntaxError) { parse_all("1\n#{operator}2") }
        end
      end
    end

    def test_logical_operators
      OPERATORS::LOGICAL.each do |operator|
        assert_expression AST::Binary, "1 #{operator} 2"
        assert_expression AST::Binary, "1 #{operator}\n2"
        assert_raises(SyntaxError) { parse_all("1\n#{operator}2") }
      end
    end

    def test_assignment_operators
      OPERATORS::ASSIGNMENT.each do |operator|
        assert_expression AST::Binary, "a #{operator} 2"
        assert_expression AST::Binary, "a #{operator}\n2"
        assert_raises(SyntaxError) { parser("1 #{operator} 2").next }
        assert_raises(SyntaxError) { parse_all("a\n#{operator}2") }
      end
    end

    def test_skips_comments
      assert_expression AST::Boolean, "# foo\ntrue"
      assert_expression AST::Boolean, "# foo\n\n# bar\ntrue"
    end

    def test_externs
      assert_expression AST::Prototype, "extern foo(i32) : void"
      assert_expression AST::Prototype, "extern foo() : void"
      assert_expression AST::Prototype, "extern foo : void"
      assert_expression AST::Prototype, "extern foo"
      assert_expression AST::Prototype, "extern llvm.sadd.with.overflow.i32(int, int) : int"

      node = parser("extern foo(i32, i64, f32) : float").next.as(AST::Prototype)
      assert_equal "foo", node.name
      assert_equal "f64", node.type.name
      assert_equal ["x1", "x2", "x3"], node.args.map(&.name)
      assert_equal ["i32", "i64", "f32"], node.args.map(&.type.name)

      parse_each("extern foo : void; extern bar : f32") do |node|
        assert AST::Prototype === node
      end
    end

    def test_defs
      assert_expression AST::Function, "def foo() : int; end"
      assert_expression AST::Function, "def foo : float; end"
      assert_expression AST::Function, "def foo; end"
      assert_expression AST::Function, "def foo(a : int) : void; end"

      node = parser("def bar(a : int, b : u64, c : f64); a + b + c; end").next.as(AST::Function)
      assert_equal "bar", node.name
      assert_nil node.type? # need semantic analysis to determine the return type
      assert_equal ["a", "b", "c"], node.args.map(&.name)
      assert_equal ["i32", "u64", "f64"], node.args.map(&.type.name)

      parse_each("def foo; 1 + 2; end; def bar; 3 * 4; end") do |node|
        assert AST::Function === node
      end
    end

    def test_calls
      assert_expression AST::Call, "foo()"
      assert_expression AST::Call, "foo(1.2)"
      assert_expression AST::Call, "bar(1, 2, abc)"
      assert_expression AST::Call, "bar(1, foo(1), 2)"

      node = parser("bar(1, 2)").next.as(AST::Call)
      assert_equal "bar", node.callee
      assert_equal 2, node.args.size
    end

    private def assert_expression(klass, source, file = __FILE__, line = __LINE__)
      node = parser(source).next
      assert klass === node, -> { "expected #{klass} but got #{node.class}" }, file, line
    end

    private def assert_type(expected, source, file = __FILE__, line = __LINE__)
      node = parser(source).next.not_nil!
      assert expected == node.type.name, -> { "expected #{expected} but got #{node.type}" }, file, line
    end
  end
end
