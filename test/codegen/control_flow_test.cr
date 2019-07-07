require "./test_helper"

class Runic::Codegen::ControlFlowTest < Runic::CodegenTest
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
end
