require "./test_helper"
require "../src/codegen"

LLVM.init_native

module Runic
  class CodegenTest < Minitest::Test
    def test_booleans
      assert_equal true, execute("true")
      assert_equal false, execute("false")
    end

    def test_integers
      assert_equal 1, execute("1")
      assert_equal 120918209182128, execute("120918209182128")
      assert_equal Int32::MIN, execute(Int32::MIN.to_s)
      assert_equal UInt64::MAX, execute("#{UInt64::MAX}_u64")
    end

    def test_floats
      assert_equal 1.0, execute("1.0")
      assert_equal -2.0, execute("-2.0")
      assert_equal -12345.6789012345, execute("-12345.6789012345")
      assert_equal 12345.6789012345, execute("12345.6789012345")
    end

    def test_variables
      assert_equal 123.5, execute("a = 123.5; a")
      assert_equal 9801391209182, execute("foo = 9801391209182; foo")
    end

    def test_negation
      assert_op -1, "-(1)"
      assert_op 1, "- -1"

      assert_op -345, "a = 345; -a"
      assert_op 123, "a = -123; -a"

      assert_op -3.5, "a = 3.5; -a"
      assert_op 1.3, "a = -1.3; -a"
    end

    def test_not
      assert_op true, "!false"
      assert_op false, "!true"
      assert_op true, "!!true"

      assert_op false, "!0"
      assert_op false, "!1"
      assert_op false, "!1.0"

      assert_op true, "!!0.0"
      assert_op true, "!!1.0"
      assert_op true, "!!1.0"
    end

    def test_addition
      # same types
      assert_op 123_i8, "100_i8 + 23_i8"
      assert_op 123_i16, "100_i16 + 23_i16"
      assert_op 123_i32, "100_i32 + 23_i32"
      assert_op 123_i64, "100_i64 + 23_i64"
      # assert_op 123_i128, "100_i128 + 23_i128"

      assert_op 255_u8, "200_u8 + 55_u8"
      assert_op 125_u16, "100_u16 + 25_u16"
      assert_op 125_u32, "100_u32 + 25_u32"
      assert_op 125_u64, "100_u64 + 25_u64"
      # assert_op 125_u128, "100_u128 + 25_u128"

      assert_op 123_f32, "100_f32 + 23_f32"
      assert_op 123_f64, "100_f64 + 23_f64"

      # LHS is significant
      assert_op 378_i32, "255 + 123_i8"
      assert_op -33_i8, "123_i8 + 100"
      assert_op 378_i32, "255 + 123_i64"
      assert_op 378_i64, "255_i64 + 123"

      # float is always significant
      assert_op 3_f64, "1.0 + 2"
      assert_op 3_f64, "1 + 2.0"
      assert_op 3_f32, "1.0_f32 + 2"
      assert_op 3_f32, "1 + 2.0_f32"

      assert_op 3_f64, "1.0 + 2.0_f32"
      assert_op 3_f32, "1_f32 + 2.0"

      assert_op -4_f32, "1 + -5.0_f32"
      assert_op -3_f32, "-5 + 2.0_f32"
    end

    def test_substraction
      # same types
      assert_op 77_i8, "100_i8 - 23_i8"
      assert_op 77_i16, "100_i16 - 23_i16"
      assert_op 77_i32, "100_i32 - 23_i32"
      assert_op -77_i64, "23_i64 - 100_i64"
      # assert_op 77_i128, "100_i128 - 23_i128"

      assert_op 145_u8, "200_u8 - 55_u8"
      assert_op 75_u16, "100_u16 - 25_u16"
      assert_op 75_u32, "100_u32 - 25_u32"
      assert_op 18446744073709551566_u64, "25_u64 - 75_u64"
      # assert_op 75_u128, "100_u128 - 25_u128"

      assert_op 77_f32, "100_f32 - 23_f32"
      assert_op 77_f64, "100_f64 - 23_f64"
      assert_op -77.5_f64, "23_f64 - 100.5"

      # LHS is significant
      assert_op 132_i32, "255 - 123_i8"
      assert_op 33_i8, "123_i8 - 90"
      assert_op 132_i32, "255 - 123_i64"
      assert_op -132_i64, "123_i64 - 255"

      # float is always significant
      assert_op -1_f64, "1.0 - 2"
      assert_op 3_f64, "1.0 - -2"
      assert_op -1_f32, "1.0_f32 - 2"

      assert_op 1_f64, "2.0 - 1.0_f32"
      assert_op -2_f32, "1_f32 - 3.0"

      assert_op -1_f64, "1 - 2.0"
      assert_op -3_f64, "-1 - 2.0"
      assert_op -1_f32, "1 - 2.0_f32"
      assert_op 2147483645_f64, "#{Int32::MAX} - 2.0"
    end

    def test_multiplication
      # same types
      assert_op 100_i8, "50_i8 * 2_i8"
      assert_op 200_i16, "100_i16 * 2_i16"
      assert_op 200_i32, "100_i32 * 2_i32"
      assert_op 2300_i64, "23_i64 * 100_i64"
      #assert_op 2300_i128, "23_i128 * 100_i128"

      assert_op 100_u8, "50_u8 * 2_u8"
      assert_op 200_u16, "100_u16 * 2_u16"
      assert_op 200_u32, "100_u32 * 2_u32"
      assert_op 2500_u64, "25_u64 * 100_u64"
      # assert_op 2500_u128, "100_u128 * 25_u128"

      assert_op 200_f32, "100_f32 * 2_f32"
      assert_op 200_f64, "100_f64 * 2_f64"
      assert_op -2311.5_f64, "-23_f64 * 100.5"

      # LHS is significant
      assert_op 765_i32, "255 * 3_i16"
      assert_op 246_u8, "123_u8 * 2"
      assert_op 510_i32, "255 * 2_i64"
      assert_op -246_i64, "123_i64 * -2"

      # float is always significant
      assert_op 2_f64, "1.0 * 2"
      assert_op -2_f64, "1.0 * -2"
      assert_op 2_f32, "1.0_f32 * 2"

      assert_op 2_f64, "2.0 * 1.0_f32"
      assert_op 3_f32, "1_f32 * 3.0"

      assert_op 2_f64, "1 * 2.0"
      assert_op -2_f64, "-1 * 2.0"
      assert_op 2_f32, "1 * 2.0_f32"
      assert_op 4294967294_f64, "#{Int32::MAX} * 2.0"
    end

    def test_float_division
      # always returns a floating point
      assert_op  2.5_f64, "5 / 2"
      assert_op -2.5_f64, "-5 / 2"
      assert_op  2.5_f64, "5 / 2.0"

      # float is always significant
      assert_op  2.5_f32, "5 / 2.0_f32"
      assert_op  2.5_f64, "5.0 / 2"
      assert_op  2.5_f64, "5.0 / 2.0"
      assert_op -2.5_f64, "-5.0 / 2.0"
      assert_op -2.5_f64, "-5.0 / 2.0_f32"
      assert_op -2.5_f32, "-5.0_f32 / 2.0"
    end

    def test_floor_division
      assert_op  2_i32, "5 // 2"
      assert_op -2_i32, "-5 // 2"

      assert_op  2_f64, "5.0 // 2.0"
      assert_op -3_f64, "-5.0 // 2.0"

      assert_op  2_f32, "5.0_f32 // 2_f32"
      assert_op  2_f32, "5.0_f32 // 2"

      assert_op  2_f32, "5.0_f32 // 2.0"
    end

    def test_modulo
      assert_op 0_i8,  "9_i8 % 3_i8"
      assert_op 1_i16, "9_i16 % 4_i16"
      assert_op 3_i32, "9 % 6"
      assert_op 4_i64, "9_i64 % 5_i64"

      # float is always significant
      assert_op 1_f64, "9.0 % 4.0"
      assert_op 1_f64, "9.0 % 4_f32"
      assert_op 1_f32, "9_f32 % 4.0"
      assert_op 1_f64, "9.0 % 4"
      assert_op 1_f32, "9_f32 % 4"
      assert_op 1_f64, "9 % 4.0"
      assert_op 1_f32, "9 % 4_f32"
    end

    def test_integer_overflow
      assert_op Int8::MIN, "#{Int8::MAX}_i8 + 1"
      assert_op Int8::MAX, "#{Int8::MIN}_i8 - 1"
      assert_op Int16::MIN, "#{Int16::MAX}_i16 + 1"
      assert_op Int16::MAX, "#{Int16::MIN}_i16 - 1"
      assert_op Int32::MIN, "#{Int32::MAX}_i32 + 1"
      assert_op Int32::MAX, "#{Int32::MIN}_i32 - 1"
      assert_op Int64::MIN, "#{Int64::MAX}_i64 + 1"
      assert_op Int64::MAX, "#{Int64::MIN}_i64 - 1"

      assert_op UInt8::MIN, "#{UInt8::MAX}_u8 + 1"
      assert_op UInt8::MAX, "#{UInt8::MIN}_u8 - 1"
      assert_op UInt16::MIN, "#{UInt16::MAX}_u16 + 1"
      assert_op UInt16::MAX, "#{UInt16::MIN}_u16 - 1"
      assert_op UInt32::MIN, "#{UInt32::MAX}_u32 + 1"
      assert_op UInt32::MAX, "#{UInt32::MIN}_u32 - 1"
      assert_op UInt64::MIN, "#{UInt64::MAX}_u64 + 1"
      assert_op UInt64::MAX, "#{UInt64::MIN}_u64 - 1"
    end

    def test_bitwise_shift_left
      assert_op 0xfe_u8, "0x7f_u8 << 1"
      assert_op 0xf00_u32, "0x0f << 8"
      assert_op 1020, "255 << 2"
    end

    def test_bitwise_shift_right
      assert_op 0x7f_u8, "0xff_u8 >> 1"
      assert_op 0xf_u32, "0xf00 >> 8"
      assert_op 0x7f, "255 >> 1"
    end

    def test_bitwise_not
      assert_op 0b1111_0010_u8, "~0b0000_1101_u8"
      assert_op 0x8000_000f_u32, "~0x7fff_fff0"
    end

    def test_bitwise_and
      assert_op 0x08_u8, "0x0f_u8 & 0x78"
      assert_op 0x08_u32, "0x0f & 0x78"
    end

    def test_bitwise_or
      assert_op 0xff_u8, "0x0f_u8 | 0xf0"
      assert_op 0x7f_u32, "0x0f | 0x78"
    end

    def test_bitwise_xor
      assert_op 0xff_u8, "0x0f_u8 ^ 0xf0"
      assert_op 0x77_u32, "0x0f ^ 0x78"
    end

    def test_equality
      assert_op true, "1 == 1"
      assert_op false, "1 == 2"

      assert_op true, "2.0 == 2.0"
      assert_op false, "2.0 == 2.1"

      assert_op true, "2.0_f32 == 2"
      assert_op false, "2.0 == 2.1_f32"

      assert_op true, "2 == 2_f64"
      assert_op false, "2 == 3_f64"
    end

    def test_inequality
      assert_op false, "1 != 1"
      assert_op true, "1 != 2"

      assert_op false, "2.0 != 2.0"
      assert_op true, "2.0 != 2.1"

      assert_op false, "2.0_f32 != 2"
      assert_op true, "2.0 != 2.1_f32"

      assert_op false, "2 != 2_f64"
      assert_op true, "2 != 3_f64"
    end

    def test_lower_than
      assert_op true, "1 < 2"
      assert_op false, "1 < 1"
      assert_op false, "2 < 1"

      assert_op true, "1_i64 < 2_i16"
      assert_op false, "2_i8 < 1_i64"

      assert_op true, "1_u64 < 2_u32"
      assert_op false, "2_u8 < 1_u64"

      assert_op true, "1.0 < 2.0"
      assert_op false, "1.0 < 1.0"
      assert_op false, "2.0 < 1_f32"

      assert_op true, "1.0 < 2"
      assert_op false, "1 < 1.0"
      assert_op false, "2.0 < 1"
    end

    def test_lower_than_or_equal
      assert_op true, "1 <= 2"
      assert_op true, "1 <= 1"
      assert_op false, "2 <= 1"

      assert_op true, "1_i64 <= 2_i16"
      assert_op false, "2_i8 <= 1_i64"

      assert_op true, "1_u64 <= 2_u32"
      assert_op false, "2_u8 <= 1_u64"

      assert_op true, "1.0 <= 2.0"
      assert_op true, "1.0 <= 1.0"
      assert_op false, "2.0 <= 1_f32"

      assert_op true, "1.0 <= 2"
      assert_op true, "1 <= 1.0"
      assert_op false, "2.0 <= 1"
    end

    def test_greater_than
      assert_op false, "1 > 2"
      assert_op false, "1 > 1"
      assert_op true, "2 > 1"

      assert_op false, "1_i64 > 2_i16"
      assert_op true, "2_i8 > 1_i64"

      assert_op false, "1_u64 > 2_u32"
      assert_op true, "2_u8 > 1_u64"

      assert_op false, "1.0 > 2.0"
      assert_op false, "1.0 > 1.0"
      assert_op true, "2.0 > 1_f32"

      assert_op false, "1.0 > 2"
      assert_op false, "1 > 1.0"
      assert_op true, "2.0 > 1"
    end

    def test_greater_than_or_equal
      assert_op false, "1 >= 2"
      assert_op true, "1 >= 1"
      assert_op true, "2 >= 1"

      assert_op false, "1_i64 >= 2_i16"
      assert_op true, "2_i8 >= 1_i64"

      assert_op false, "1_u64 >= 2_u32"
      assert_op true, "2_u8 >= 1_u64"

      assert_op false, "1.0 >= 2.0"
      assert_op true, "1.0 >= 1.0"
      assert_op true, "2.0 >= 1_f32"

      assert_op false, "1.0 >= 2"
      assert_op true, "1 >= 1.0"
      assert_op true, "2.0 >= 1"
    end

    def test_compare
      skip "TODO: missing codegen for <=> operator"
    end

    def test_logical_and
      assert_op true, "true && true"
      assert_op false, "true && false"
      assert_op false, "false && true"
      assert_op false, "false && false"
    end

    def test_logical_or
      assert_op true, "true || true"
      assert_op true, "true || false"
      assert_op true, "false || true"
      assert_op false, "false || false"
    end

    protected def assert_op(expected, source, file = __FILE__, line = __LINE__)
      actual = execute(source)
      assert_equal expected, actual, nil, file, line
      assert expected.class === actual, "Expected #{expected.class.name} but got #{actual.class.name}", file, line
    end

    def test_function_definition
      source = <<-RUNIC
      def runic_add(a : int, b : int)
        a + b
      end
      runic_add(1, 2)
      RUNIC
      assert_equal 3, execute(source)
    end

    def test_constant_definition
      source = <<-RUNIC
      INCREMENT = 1

      def increment(a : int)
        a + INCREMENT
      end

      increment(10)
      RUNIC
      assert_equal 11, execute(source)
    end

    def test_if_expression
      assert_equal 20, execute <<-RUNIC
      def foo(a : int)
        if a > 10
          a - 2
        else
          a + 1
        end
      end
      foo(1) + foo(20)
      RUNIC

      assert_equal 19, execute <<-RUNIC
      def foo(a : int)
        if a > 10
          a = a - 2
        end
        a
      end
      foo(1) + foo(20)
      RUNIC
    end

    def test_shadows_variable_for_scope_duration
      # mutates 'a' (i32) with no local shadow (of type)
      assert_equal 10, execute <<-RUNIC
      a = 2
      if a < 10; a = 10; end
      a
      RUNIC

      # shadows 'a' (i32) as f64 for the duration of the then block,
      # then restores the original 'a' (i32) afterward
      assert_equal 2, execute <<-RUNIC
      a = 2
      if a < 10; a = 10.0; end
      a
      RUNIC
    end

    def test_unless_expression
      assert_equal 22, execute <<-RUNIC
      def foo(a : int)
        unless a > 10
          a = a + 1
        end
        a
      end
      foo(1) + foo(20)
      RUNIC
    end

    def test_while_expression
      assert_equal 10, execute <<-RUNIC
      def foo(a : int)
        while a < 10
          a = a + 1
        end
        a
      end
      foo(1)
      RUNIC
    end

    def test_until_expression
      assert_equal 0, execute <<-RUNIC
      def foo(a : int)
        until a == 0
          a = a - 1
        end
        a
      end
      foo(10)
      RUNIC
    end

    def test_case_expression
      assert_equal 25, execute <<-RUNIC
      def foo(a : int)
        case a
        when 1, 2
          a + 1
        when 3
          a + 2
        when 4, 5, 6
          a + 3
        else
          a
        end
      end
      foo(10) + foo(1) + foo(3) + foo(5)
      RUNIC
    end

    protected def execute(source : String)
      prototype = AST::Prototype.new("__anon_expr", [] of AST::Argument, nil, "", Location.new("<test>"))
      body = AST::Body.new([] of AST::Node, Location.new("<test>"))
      main = AST::Function.new(prototype, [] of String, body, Location.new("<test>"))

      functions = [] of AST::Function

      generator = Codegen.new(debug: DebugLevel::None, optimize: true)
      parse_each(intrinsics) { |node| generator.codegen(node) }

      parse_each(source) do |node|
        if node.is_a?(AST::Function)
          program.register(node)
        elsif node.is_a?(AST::ConstantDefinition)
          program.register(node)
        else
          main.body << node
        end
      end
      semantic.visit(main)

      program.each do |node|
        semantic.visit(node)
        generator.codegen(node)
      end
      func = generator.codegen(main)

      begin
        case main.type.name
        when "bool" then return generator.execute(true, func)
        when "i8" then return generator.execute(1_i8, func)
        when "i16" then return generator.execute(1_i16, func)
        when "i32" then return generator.execute(1_i32, func)
        when "i64" then return generator.execute(1_i64, func)
        when "u8" then return generator.execute(1_u8, func)
        when "u16" then return generator.execute(1_u16, func)
        when "u32" then return generator.execute(1_u32, func)
        when "u64" then return generator.execute(1_u64, func)
        when "f32" then return generator.execute(1_f32, func)
        when "f64" then return generator.execute(1_f64, func)
        else raise "unsupported return type '#{main.type}' (yet)"
        end
      ensure
        LibC.LLVMDeleteFunction(func)
      end
    end

    private def semantic
      @semantic ||= Semantic.new(program)
    end

    private def program
      @program ||= Program.new
    end

    private def intrinsics
      @@intrinsics ||= File.read(File.expand_path("../src/intrinsics.runic", __DIR__))
    end
  end
end
