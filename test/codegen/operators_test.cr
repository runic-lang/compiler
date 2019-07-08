require "./test_helper"

class Runic::Codegen::OperatorsTest < Runic::CodegenTest
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
    {% for b in %w(8 16 32 64 128) %}
      assert_op 123_i{{b.id}}, "100_i{{b.id}} + 23_i{{b.id}}"
      assert_op 255_u{{b.id}}, "200_u{{b.id}} + 55_u{{b.id}}"
    {% end %}

    assert_op 123_f32, "100_f32 + 23_f32"
    assert_op 123_f64, "100_f64 + 23_f64"
  end

  def test_wrapping_addition
    assert_op -128_i8, "127_i8 + 1_i8"
    assert_op -32768_i16, "32767_i16 + 1_i16"
    assert_op -2147483648_i32, "2147483647_i32 + 1_i32"
    assert_op -9223372036854775808_i64, "9223372036854775807_i64 + 1_i64"
    #assert_op -170141183460469231731687303715884105728_i128, "170141183460469231731687303715884105727_i128 + 1_i128"

    assert_op 0_u8, "255_u8 + 1_u8"
    assert_op 0_u16, "65535_u16 + 1_u16"
    assert_op 0_u32, "4294967295_u32 + 1_u32"
    assert_op 0_u64, "18446744073709551615_u64 + 1_u64"
    assert_op 0_u128, "340282366920938463463374607431768211455_u128 + 1_u128"
  end

  def test_substration
    {% for b in %w(8 16 32 64 128) %}
      assert_op 77_u{{b.id}}, "100_u{{b.id}} - 23_u{{b.id}}"
      assert_op 145_u{{b.id}}, "200_u{{b.id}} - 55_u{{b.id}}"
    {% end %}

    assert_op 77_f32, "100_f32 - 23_f32"
    assert_op 77_f64, "100_f64 - 23_f64"
  end

  def test_wrapping_substraction
    assert_op 127_i8, "-128_i8 - 1_i8"
    assert_op 32767_i16, "-32768_i16 - 1_i16"
    assert_op 2147483647_i32, "-2147483648_i32 - 1_i32"
    assert_op 9223372036854775807_i64, "-9223372036854775808_i64 - 1_i64"
    #assert_op 170141183460469231731687303715884105727_i128, "-170141183460469231731687303715884105728_i128 - 1_i128"

    assert_op 255_u8, "0_u8 - 1_u8"
    assert_op 65535_u16, "0_u16 - 1_u16"
    assert_op 4294967295_u32, "0_u32 - 1_u32"
    assert_op 18446744073709551615_u64, "0_u64 - 1_u64"
    #assert_op 340282366920938463463374607431768211455_u128, "0_u128 - 1_u128"
  end

  def test_multiplication
    {% for b in %w(8 16 32 64 128) %}
      assert_op 100_i{{b.id}}, "50_i{{b.id}} * 2_i{{b.id}}"
      assert_op 100_u{{b.id}}, "50_u{{b.id}} * 2_u{{b.id}}"
    {% end %}

    assert_op 200_f32, "100_f32 * 2_f32"
    assert_op 2300_f64, "23_f64 * 100_f64"
  end

  def test_wrapping_multiplication
    assert_op -2_i8, "127_i8 * 2_i8"
    assert_op -2_i16, "32767_i16 * 2_i16"
    assert_op -2_i32, "2147483647_i32 * 2_i32"
    assert_op -2_i64, "9223372036854775807_i64 * 2_i64"
    #assert_op -2_i128, "170141183460469231731687303715884105727_i128 * 2_i128"

    assert_op 254_u8, "255_u8 * 2_u8"
    assert_op 65534_u16, "65535_u16 * 2_u16"
    assert_op 4294967294_u32, "4294967295_u32 * 2_u32"
    assert_op 18446744073709551614_u64, "18446744073709551615_u64 * 2_u64"
    #assert_op 340282366920938463463374607431768211454_u128, "340282366920938463463374607431768211455_u128 * 2_u128"
  end

  def test_float_division
    {% for b in %w(8 16 32 64 128) %}
      assert_op 2.5_f64, "5_i{{b.id}} / 2_i{{b.id}}"
      assert_op 2.5_f64, "5_u{{b.id}} / 2_u{{b.id}}"
    {% end %}

    assert_op 2.5_f32, "5_f32 / 2_f32"
    assert_op 2.5_f64, "5_f64 / 2_f64"
  end

  def test_floor_division
    {% for b in %w(8 16 32 64 128) %}
      assert_op UInt{{b.id}}.new(1), "7_u{{b.id}} // 4_u{{b.id}}"

      assert_op Int{{b.id}}.new(1), "7_i{{b.id}} // 4_i{{b.id}}"
      assert_op Int{{b.id}}.new(-1), "7_i{{b.id}} // -4_i{{b.id}}"
      assert_op Int{{b.id}}.new(-2), "-7_i{{b.id}} // 4_i{{b.id}}"
      assert_op Int{{b.id}}.new(2), "-7_i{{b.id}} // -4_i{{b.id}}"
    {% end %}

    {% for b in %w(32 64) %}
      assert_op 1_f{{b.id}}, "7_f{{b.id}} // 4_f{{b.id}}"
      assert_op -1_f{{b.id}}, "7_f{{b.id}} // -4_f{{b.id}}"
      assert_op -2_f{{b.id}}, "-7_f{{b.id}} // 4_f{{b.id}}"
      assert_op 2_f{{b.id}}, "-7_f{{b.id}} // -4_f{{b.id}}"
    {% end %}
  end

  def test_remainder
    {% for b in %w(8 16 32 64 128) %}
      assert_op 4_i{{b.id}}, "9_i{{b.id}} % 5_i{{b.id}}"
      assert_op 4_u{{b.id}}, "9_u{{b.id}} % 5_u{{b.id}}"
    {% end %}

    assert_op 3_f32, "9_f32 % 6_f32"
    assert_op 4_f64, "9_f64 % 5_f64"
  end

  def test_abs
    {% for b in %w(8 16 32 64 128) %}
      assert_op 9_i{{b.id}}, "9_i{{b.id}}.abs"
      assert_op 9_i{{b.id}}, "-9_i{{b.id}}.abs"
    {% end %}

    assert_op 9_f32, "9_f32.abs"
    assert_op 9_f32, "-9_f32.abs"
    assert_op 9_f64, "9_f64.abs"
    assert_op 9_f64, "-9_f64.abs"
  end

  def test_floor_remainder
    {% for b in %w(8 16 32 64 128) %}
      assert_op 3_u{{b.id}}, "7_u{{b.id}} %% 4_u{{b.id}}"

      assert_op 3_i{{b.id}}, "7_i{{b.id}} %% 4_i{{b.id}}"
      assert_op 1_i{{b.id}}, "-7_i{{b.id}} %% 4_i{{b.id}}"
      assert_op 3_i{{b.id}}, "7_i{{b.id}} %% -4_i{{b.id}}"
      assert_op 1_i{{b.id}}, "-7_i{{b.id}} %% -4_i{{b.id}}"
    {% end %}

    {% for b in %w(32 64) %}
      assert_op 3_f{{b.id}}, "7_f{{b.id}} %% 4_f{{b.id}}"
      assert_op 1_f{{b.id}}, "-7_f{{b.id}} %% 4_f{{b.id}}"
      assert_op 3_f{{b.id}}, "7_f{{b.id}} %% -4_f{{b.id}}"
      assert_op 1_f{{b.id}}, "-7_f{{b.id}} %% -4_f{{b.id}}"
    {% end %}
  end

  def test_exponentiation
    {% for b in %w(8 16 32 64 128) %}
      # b**0 always returns 1
      assert_op 1_i{{b.id}}, "2_i{{b.id}} ** 0_i{{b.id}}"
      assert_op 1_u{{b.id}}, "2_u{{b.id}} ** 0_u{{b.id}}"

      # b**n
      assert_op 64_i{{b.id}}, "2_i{{b.id}} ** 6_i{{b.id}}"
      assert_op 128_u{{b.id}}, "2_u{{b.id}} ** 7_u{{b.id}}"
    {% end %}

    assert_op 512_f32, "2_f32 ** 9_f32"
    assert_op 512_f64, "2_f64 ** 9_f64"
  end

  def test_wrapping_exponentiation
    assert_op -128_i8, "2_i8 ** 7_i8"
    assert_op -32768_i16, "2_i16 ** 15_i16"
    assert_op -2147483648_i32, "2i32 ** 31_i32"
    assert_op -9223372036854775808_i64, "2_i64 ** 63_i64"
    #assert_op -170141183460469231731687303715884105728_i128, "2_i128 ** 127_i128"

    {% for b in %w(8 16 32 64 128) %}
      assert_op 0_u{{b.id}}, "2_u{{b.id}} ** {{b.id}}_u{{b.id}}"
    {% end %}
  end

  def test_bitwise_shift_left
    {% for b in %w(8 16 32 64 128) %}
      assert_op 12_i{{b.id}}, "3_i{{b.id}} << 2_i{{b.id}}"
      assert_op 12_u{{b.id}}, "3_u{{b.id}} << 2_u{{b.id}}"
    {% end %}

    assert_op -4_i8, "127_i8 << 2_i8"
    assert_op -4_i16, "32767_i16 << 2_i16"
    assert_op -4_i32, "2147483647_i32 << 2_i32"
    assert_op -4_i64, "9223372036854775807_i64 << 2_i64"
    #assert_op -4_i128, "170141183460469231731687303715884105727_i128 << 2_i128"

    assert_op 252_u8, "255_u8 << 2_u8"
    assert_op 65532_u16, "65535_u16 << 2_u16"
    assert_op 4294967292_u32, "4294967295_u32 << 2_u32"
    assert_op 18446744073709551612_u64, "18446744073709551615_u64 << 2_u64"
    #assert_op 340282366920938463463374607431768211452_u128, "340282366920938463463374607431768211455_u128 << 1_u128"
  end

  def test_bitwise_shift_right
    {% for b in %w(8 16 32 64 128) %}
      # signed integers use arithmethic shift right
      assert_op 2_i{{b.id}}, "8_i{{b.id}} >> 2_i{{b.id}}"

      # unsigned integers use logical shift right
      assert_op 2_u{{b.id}}, "8_u{{b.id}} >> 2_u{{b.id}}"
    {% end %}
  end

  def test_bitwise_not
    assert_op -121_i8, "~120_i8"
    assert_op -121_i16, "~120_i16"
    assert_op -121_i32, "~120_i32"
    assert_op -121_i64, "~120_i64"
    #assert_op -121_i128, "~120_i128"

    assert_op 135_u8, "~120_u8"
    assert_op 65415_u16, "~120_u16"
    assert_op 4294967175_u32, "~120_u32"
    assert_op 18446744073709551495_u64, "~120_u64"
    #assert_op 340282366920938463463374607431768211335_u128, "~120_u128"
  end

  def test_bitwise_and
    {% for b in %w(8 16 32 64 128) %}
      assert_op 1_i{{b.id}}, "1_i{{b.id}} & 3_i{{b.id}}"
      assert_op 1_u{{b.id}}, "1_u{{b.id}} & 3_u{{b.id}}"
    {% end %}
  end

  def test_bitwise_or
    {% for b in %w(8 16 32 64 128) %}
      assert_op 3_i{{b.id}}, "1_i{{b.id}} | 2_i{{b.id}}"
      assert_op 3_u{{b.id}}, "1_u{{b.id}} | 2_u{{b.id}}"
    {% end %}
  end

  def test_bitwise_xor
    {% for b in %w(8 16 32 64 128) %}
      assert_op 2_i{{b.id}}, "1_i{{b.id}} ^ 3_i{{b.id}}"
      assert_op 2_u{{b.id}}, "1_u{{b.id}} ^ 3_u{{b.id}}"
    {% end %}
  end

  def test_equality
    {% for b in %w(8 16 32 64 128) %}
      assert_op true, "1_i{{b.id}} == 1_i{{b.id}}"
      assert_op false, "1_i{{b.id}} == 2_i{{b.id}}"
      assert_op true, "1_u{{b.id}} == 1_u{{b.id}}"
      assert_op false, "1_u{{b.id}} == 2_u{{b.id}}"
    {% end %}

    assert_op true, "2.0_f32 == 2_f32"
    assert_op true, "2_f64 == 2.0_f64"

    assert_op false, "2.0_f32 == 2.1_f32"
    assert_op false, "2_f64 == 3_f64"
  end

  def test_inequality
    {% for b in %w(8 16 32 64 128) %}
      assert_op false, "1_i{{b.id}} != 1_i{{b.id}}"
      assert_op true, "1_i{{b.id}} != 2_i{{b.id}}"
      assert_op false, "1_u{{b.id}} != 1_u{{b.id}}"
      assert_op true, "1_u{{b.id}} != 2_u{{b.id}}"
    {% end %}

    assert_op false, "2.0_f32 != 2_f32"
    assert_op false, "2_f64 != 2.0_f64"

    assert_op true, "2.0_f32 != 2.1_f32"
    assert_op true, "2_f64 != 3_f64"
  end

  def test_lower_than
    {% for b in %w(8 16 32 64 128) %}
      assert_op false, "1_i{{b.id}} < 1_i{{b.id}}"
      assert_op true, "1_i{{b.id}} < 2_i{{b.id}}"
      assert_op false, "1_u{{b.id}} < 1_u{{b.id}}"
      assert_op true, "1_u{{b.id}} < 2_u{{b.id}}"
    {% end %}

    assert_op false, "2.0_f32 < 2_f32"
    assert_op false, "2_f64 < 2.0_f64"

    assert_op true, "2.0_f32 < 2.1_f32"
    assert_op true, "2_f64 < 3_f64"
  end

  def test_lower_than_or_equal
    {% for b in %w(8 16 32 64 128) %}
      assert_op false, "2_i{{b.id}} <= 1_i{{b.id}}"
      assert_op true, "1_i{{b.id}} <= 1_i{{b.id}}"
      assert_op true, "1_i{{b.id}} <= 2_i{{b.id}}"
      assert_op false, "2_u{{b.id}} <= 1_u{{b.id}}"
      assert_op true, "1_u{{b.id}} <= 1_u{{b.id}}"
      assert_op true, "1_u{{b.id}} <= 2_u{{b.id}}"
    {% end %}

    assert_op false, "3.0_f32 <= 2_f32"
    assert_op false, "3_f64 <= 2.0_f64"

    assert_op true, "2.0_f32 <= 2_f32"
    assert_op true, "2_f64 <= 2.0_f64"

    assert_op true, "2.0_f32 <= 2.1_f32"
    assert_op true, "2_f64 <= 3_f64"
  end

  def test_greater_than
    {% for b in %w(8 16 32 64 128) %}
      assert_op false, "1_i{{b.id}} > 1_i{{b.id}}"
      assert_op true, "2_i{{b.id}} > 1_i{{b.id}}"
      assert_op false, "1_u{{b.id}} > 1_u{{b.id}}"
      assert_op true, "2_u{{b.id}} > 1_u{{b.id}}"
    {% end %}

    assert_op false, "2.0_f32 > 2_f32"
    assert_op false, "2_f64 > 2.0_f64"

    assert_op true, "2.1_f32 > 2.0_f32"
    assert_op true, "3_f64 > 2_f64"
  end

  def test_greater_than_or_equal
    {% for b in %w(8 16 32 64 128) %}
      assert_op true, "2_i{{b.id}} >= 1_i{{b.id}}"
      assert_op true, "1_i{{b.id}} >= 1_i{{b.id}}"
      assert_op false, "1_i{{b.id}} >= 2_i{{b.id}}"
      assert_op true, "2_u{{b.id}} >= 1_u{{b.id}}"
      assert_op true, "1_u{{b.id}} >= 1_u{{b.id}}"
      assert_op false, "1_u{{b.id}} >= 2_u{{b.id}}"
    {% end %}

    assert_op true, "3.0_f32 >= 2_f32"
    assert_op true, "3_f64 >= 2.0_f64"

    assert_op true, "2.0_f32 >= 2_f32"
    assert_op true, "2_f64 >= 2.0_f64"

    assert_op false, "2.0_f32 >= 2.1_f32"
    assert_op false, "2_f64 >= 3_f64"
  end

  def test_starship
    {% for b in %w(8 16 32 64) %}
      assert_op -1, "1_i{{b.id}} <=> 2_i{{b.id}}"
      assert_op 0, "2_i{{b.id}} <=> 2_i{{b.id}}"
      assert_op 1, "3_i{{b.id}} <=> 2_i{{b.id}}"

      assert_op -1, "1_u{{b.id}} <=> 2_u{{b.id}}"
      assert_op 0, "2_u{{b.id}} <=> 2_u{{b.id}}"
      assert_op 1, "3_u{{b.id}} <=> 2_u{{b.id}}"
    {% end %}
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
end
