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

    def test_constant_assignments
      assert_expression AST::ConstantDefinition, "FOO = 1"
      assert_expression AST::ConstantDefinition, "BAR = 1.0"
      assert_expression AST::ConstantDefinition, "FOOBAR = FOO"

      node = parser("FOO = 1").next.as(AST::ConstantDefinition)
      assert_equal "FOO", node.name
      assert AST::Integer === node.value

      assert_raises(SyntaxError) do
        parser("def foo; FOO = 1; end", top_level_expressions: false).next
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

      source = <<-RUNIC
      def bar(

        a : int

        ,

         b : float

      )
      end
      RUNIC
      node = parser(source).next.as(AST::Function)
      assert_equal ["a", "b"], node.args.map(&.name)
      assert_equal ["i32", "f64"], node.args.map(&.type.name)
    end

    def test_default_arguments
      node = parser("def bar(a = 0, b = 123_f32, c : f64 = 456); a; end").next.as(AST::Function)
      a, b, c = node.args

      assert_equal "a", a.name
      assert a.default
      assert_equal "i32", a.type.name
      assert_equal "0", a.default.as(AST::Number).try(&.value)

      assert_equal "b", b.name
      assert b.default
      assert_equal "f32", b.type.name
      assert_equal "123", b.default.as(AST::Number).try(&.value)

      assert_equal "c", c.name
      assert c.default
      assert_equal "f64", c.type.name
      assert_equal "456", c.default.as(AST::Number).try(&.value)

      ex = assert_raises(SyntaxError) do
        parser("def bar(a = value); end").next
      end
      assert_match "expected literal", ex.message

      ex = assert_raises(SyntaxError) do
        parser("def foo(a : int, b : f64, c = 0, d); end)").next
      end
      assert_match "argument 'd' must have a default value", ex.message
    end

    def test_calls
      assert_expression AST::Call, "foo()"
      assert_expression AST::Call, "foo(1.2)"
      assert_expression AST::Call, "bar(1, 2, abc)"
      assert_expression AST::Call, "bar(1, foo(1), 2)"

      node = parser("bar(1, 2)").next.as(AST::Call)
      assert_equal "bar", node.callee
      assert_equal 2, node.args.size

      source = <<-RUNIC
      bar(

        1

        ,

         b:

         4

      )
      RUNIC
      node = parser(source).next.as(AST::Call)
      assert_equal ["1"], node.args.map(&.as(AST::Literal).value)
      assert_equal ["b"], node.kwargs.keys
      assert_equal ["4"], node.kwargs.values.map(&.as(AST::Literal).value)
    end

    def test_keyword_arguments
      node = assert_expression(AST::Call, "foo(1, 2)").as(AST::Call)
      assert_empty node.kwargs
      assert_equal ["1", "2"], node.args.map(&.as(AST::Literal).value)

      node = assert_expression(AST::Call, "foo(1, to: 2)").as(AST::Call)
      assert_equal ["to"], node.kwargs.keys
      assert_equal ["2"], node.kwargs.values.map(&.as(AST::Literal).value)
      assert_equal ["1"], node.args.map(&.as(AST::Literal).value)

      node = assert_expression(AST::Call, "foo(by: 1, to: 2)").as(AST::Call)
      assert_equal ["by", "to"], node.kwargs.keys
      assert_equal ["1", "2"], node.kwargs.values.map(&.as(AST::Literal).value)
      assert_empty node.args

      node = assert_expression(AST::Call, "foo(to: 2, by: 1)").as(AST::Call)
      assert_equal ["to", "by"], node.kwargs.keys
      assert_equal ["2", "1"], node.kwargs.values.map(&.as(AST::Literal).value)
      assert_empty node.args

      ex = assert_raises(SyntaxError) { parser("foo(by: 1, 2)").next }
      assert_match "expected named argument", ex.message

      ex = assert_raises(SyntaxError) { parser("foo(1, to: 1, to: 2)").next }
      assert_match "duplicated named argument", ex.message
    end

    def test_ifs
      node = assert_expression AST::If, "if test; end"
      assert_empty node.body
      assert_nil node.alternative

      node = assert_expression AST::If, <<-RUNIC
      if test
        something()
        more()
        again()
      end
      RUNIC
      assert_equal 3, node.body.size
      assert_nil node.alternative

      node = assert_expression AST::If, <<-RUNIC
      if a < 10 || b > 10
        foo()
      else
        more()
        bar()
      end
      RUNIC
      assert_equal 1, node.body.size
      assert_equal 2, node.alternative.try(&.size)

      node = assert_expression AST::If, <<-RUNIC
      if (

      a < 10 ||

        b > 10

      ) &&

      c > 5

        foo()
      end
      RUNIC
      assert_equal 1, node.body.size
      assert AST::Call === node.body[0]
    end

    def test_unless
      node = assert_expression AST::Unless, "unless true; end"
      assert_empty node.as(AST::Unless).body

      node = assert_expression AST::Unless, <<-RUNIC
      unless a < 10 || b > 10
        foo()
        bar()
      end
      RUNIC
      assert_equal 2, node.as(AST::Unless).body.size
    end

    def test_while
      node = assert_expression AST::While, "while true; end"
      assert_empty node.as(AST::While).body

      node = assert_expression AST::While, <<-RUNIC
      while a < 10 || b > 10
        foo()
        bar()
      end
      RUNIC
      assert_equal 2, node.as(AST::While).body.size
    end

    def test_until
      node = assert_expression AST::Until, "until true; end"
      assert_empty node.as(AST::Until).body

      node = assert_expression AST::Until, <<-RUNIC
      until a < 10 || b > 10
        foo()
        bar()
      end
      RUNIC
      assert_equal 2, node.as(AST::Until).body.size
    end

    def test_case
      node = assert_expression AST::Case, "case a; when 1; end"
      assert_nil node.as(AST::Case).alternative
      assert_equal 1, node.as(AST::Case).cases.size
      assert_equal 1, node.as(AST::Case).cases.first.conditions.size
      assert_empty node.as(AST::Case).cases.first.body

      node = assert_expression AST::Case, <<-RUNIC
      case foo(a, b + 10)
      when 1
        foo()
      when 2, 3, 4
        foo()
        bar()
      else
        bar()
      end
      RUNIC
      assert node.as(AST::Case).alternative
      assert_equal 1, node.as(AST::Case).alternative.try(&.size)
      assert_equal 2, node.as(AST::Case).cases.size
      assert_equal 3, node.as(AST::Case).cases[1].conditions.size

      assert_raises(SyntaxError) { parser("case a; end").next }

      source = <<-RUNIC
      case foo

      when 1,

      2,
        3

          foo

      when 4, 5,


        6 then baz

      when 7,
        8 then
          baz
      end
      RUNIC
      node = parser(source).next.as(AST::Case)
      assert_equal 3, node.cases.size
      assert_equal %w(1 2 3), node.cases[0].conditions.map(&.as(AST::Literal).value)
      assert_equal %w(4 5 6), node.cases[1].conditions.map(&.as(AST::Literal).value)
      assert_equal %w(7 8), node.cases[2].conditions.map(&.as(AST::Literal).value)
    end

    def test_struct
      node = assert_expression(AST::Struct, "#[primitive]\nstruct int32\nend").as(AST::Struct)
      assert_equal "int32", node.name
      assert_equal ["primitive"], node.attributes
      assert_empty node.methods
      assert_empty node.prototypes
      assert_empty node.documentation
      assert_equal node.location, node.locations.first
    end

    def test_struct_documentation_and_attributes
      source = <<-RUNIC
      # Docs for the `bool` primitive type.
      #[primitive]
      struct bool
      end
      RUNIC
      node = assert_expression(AST::Struct, source).as(AST::Struct)
      assert_equal "bool", node.name
      assert_equal ["primitive"], node.attributes
      assert_equal "Docs for the `bool` primitive type.", node.documentation
    end

    def test_struct_methods
      source =  <<-RUNIC
      #[primitive]
      struct int64
        def add(other : int64)
          self + other
        end

        def sub(other : int64)
          self - other
        end
      end
      RUNIC
      node = assert_expression(AST::Struct, source).as(AST::Struct)
      assert_equal 2, node.methods.size
      assert_equal ["add", "sub"], node.methods.map(&.name).sort
      assert_empty node.prototypes # populated by semantic analysis
    end

    private def assert_expression(klass : T.class, source, file = __FILE__, line = __LINE__) forall T
      node = parser(source).next
      assert klass === node, -> { "expected #{klass} but got #{node.class}" }, file, line
      node.as(T)
    end

    private def assert_type(expected, source, file = __FILE__, line = __LINE__)
      node = parser(source).next.not_nil!
      assert expected == node.type.name, -> { "expected #{expected} but got #{node.type}" }, file, line
    end
  end
end
