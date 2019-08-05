require "./test_helper"

class Runic::Codegen::StructuresTest < Runic::CodegenTest
  def test_stack_constructor
    assert_equal 5, execute(<<-RUNIC)
    struct Point
      @x : i32
      @y : i32

      def initialize(x : i32, y : i32)
        @x = x
        @y = y
      end

      def x
        @x
      end

      def y
        @y
      end
    end

    a = Point(2, 1)
    b = Point(1, 3)
    a.x + b.y
    RUNIC
  end

  def test_byval
    assert_equal 0, execute(<<-RUNIC)
    struct Foo
      @value : i32

      def initialize(value : i32)
        @value = value
      end

      def value
        @value
      end
    end

    def get(foo : Foo) : i32
      foo.value
    end

    foo = Foo(0)
    get(foo)
    RUNIC
  end

  def test_sret
    skip
  end
end
