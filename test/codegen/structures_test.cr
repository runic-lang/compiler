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

      def x; @x; end
      def y; @y; end
    end

    a = Point(2, 1)
    b = Point(1, 3)
    a.x + b.y
    RUNIC
  end

  def test_byval
    assert_equal 1, execute(<<-RUNIC)
    struct Foo
      @value : i32

      def initialize(value : i32)
        @value = value
      end

      def value
        @value
      end

      def set(value : i32)
        @value = value
      end
    end

    def get(foo : Foo) : i32
      foo.value
    end

    def set(foo : Foo, value : i32) : i32
      foo.set(value)
    end

    foo = Foo(1) # init foo value to 1
    set(foo, 2)  # passes byval, so mutates a copy of foo
    get(foo)     # returns foo's value (1)
    RUNIC
  end

  def test_sret
    assert_equal 21, execute(<<-RUNIC)
    struct Vec2
      @x : i64
      @y : i64
      @z : i64

      def initialize(x : i64, y : i64, z : i64)
        @x = x
        @y = y
        @z = z
      end

      def x; @x; end
      def y; @y; end
      def z; @z; end

      def add(other : Vec2)
        Vec2(@x + other.x, @y + other.y, @z + other.z)
      end
    end

    a = Vec2(1, 2, 3)
    b = Vec2(4, 5, 6)
    c = a.add(b)
    c.x + c.y + c.z
    RUNIC
  end

  def test_operator_methods
    assert_equal 21, execute(<<-RUNIC)
    struct Vec2
      @x : i64
      @y : i64
      @z : i64

      def initialize(x : i64, y : i64, z : i64)
        @x = x
        @y = y
        @z = z
      end

      def x; @x; end
      def y; @y; end
      def z; @z; end

      def +(other : Vec2)
        Vec2(@x + other.x, @y + other.y, @z + other.z)
      end
    end

    a = Vec2(1, 2, 3)
    b = Vec2(4, 5, 6)
    c = a + b
    c.x + c.y + c.z
    RUNIC
  end

  def test_setter_methods
    assert_equal 321, execute(<<-RUNIC)
    struct Bar
      @value : i32

      def initialize(value : i32)
        @value = value
      end

      def value
        @value
      end

      def value=(value : i32)
        @value = value
      end
    end

    bar = Bar(123)
    bar.value = 321
    bar.value
    RUNIC
  end
end
