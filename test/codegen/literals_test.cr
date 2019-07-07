require "./test_helper"

class Runic::Codegen::LiteralsTest < Runic::CodegenTest
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

  def test_variables
    assert_equal 123.5, execute("a = 123.5; a")
    assert_equal 9801391209182, execute("foo = 9801391209182; foo")
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
end
