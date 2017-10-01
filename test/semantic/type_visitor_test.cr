require "../test_helper"

module Runic
  class Semantic
    class TypeVisitorTest < Minitest::Test
      def test_infers_integer_literal_type
        assert_type "int32", visit("1")
        assert_type "int64", visit("1126516251752")
        assert_type "int128", visit("876121246541126516251752")

        assert_type "int32", visit("0o1")
        assert_type "int64", visit("0o777777777777777777777")
        assert_type "int128", visit("0o1777777777777777777777777777777777777777777")

        assert_type "uint32", visit("0xff")
        assert_type "uint64", visit("0x1234567890")
        assert_type "uint128", visit("0x1234567890abcdef01234")

        assert_type "uint32", visit("0b1")
        assert_type "uint64", visit("0b#{"1" * 60}")
        assert_type "uint128", visit("0b#{"1" * 120}")
      end

      def test_validates_integer_literals
        {% for suffix, num in {
            "i8" => "12",
            "i16" => "3276",
            "i32" => "214748364",
            "i64" => "922337203685477580",
            "i128" => "17014118346046923173168730371588410572",
          }
        %}
          visit("{{num.id}}7_{{suffix.id}}")
          visit("-{{num.id}}8_{{suffix.id}}")
          assert_raises(SemanticError) { visit("{{num.id}}8_{{suffix.id}}") }
          assert_raises(SemanticError) { visit("-{{num.id}}9_{{suffix.id}}") }
        {% end %}

        {% for suffix, num in {
            "u8" => "25",
            "u16" => "6553",
            "u32" => "429496729",
            "u64" => "1844674407370955161",
            "u128" => "34028236692093846346337460743176821145",
          }
        %}
          visit("{{num.id}}5_{{suffix.id}}")
          assert_raises(SemanticError) { visit("-1_{{suffix.id}}") }
          assert_raises(SemanticError) { visit("{{num.id}}6_{{suffix.id}}") }
        {% end %}
      end

      def test_recursively_types_binary_expressions
        node = visit("a = 1 * (2 + 4)").as(AST::Binary)
        assert_type "int32", node                          # whole expression
        assert_type "int32", node.lhs                      # variable 'a'
        assert_type "int32", node.rhs                      # value
        assert_type "int32", node.rhs.as(AST::Binary).rhs  # 2 + 4
      end

      def test_shadows_variable_when_its_underlying_type_changes
        visit_each("a = 1; a = a + 2.0; b = a; a = 123_u64") do |node, index|
          case index
          when 0
            assert_type "int32", node
            assert_type "int32", node.as(AST::Binary).lhs    # infers 'a'
          when 1
            assert_type "float64", node
            assert_type "float64", node.as(AST::Binary).lhs  # 'a' is shadowed
          when 2
            assert_type "float64", node
            assert_type "float64", node.as(AST::Binary).rhs  # 'a' refers to the tmp variable (not the shadowed)
          when 3
            assert_type "uint64", node
            assert_type "uint64", node.as(AST::Binary).rhs   # 'a' is shadowed again
          end
        end
      end

      def test_recursively_types_unary_expressions
        node = visit("!!123)")
        assert_type "bool", node
        assert_type "bool", node.as(AST::Unary).expression
      end

      def test_types_calls
        node = visit("def add(a : int, b : float) a + b; end")
        assert_type "float64", node.as(AST::Function)

        node = visit("add(1, add(2, 3.2))")
        assert_type "float64", node
        assert_types ["int32", "float64"], node.as(AST::Call).args
      end

      def test_validates_call_arguments
        visit("def add(a : int, b : float) a + b; end")
        assert_raises(SemanticError) { visit("add(1.0, 2.0)") }
        assert_raises(SemanticError) { visit("add(add(1, 2.0), 2.0)") }
      end

      def test_validates_def_return_type
        ex = assert_raises(SemanticError) { visit("def add(a : int); end") }
        assert_match "has no return type", ex.message

        ex = assert_raises(SemanticError) { visit("def add(a : int) : int; 1.0; end") }
        assert_match "must return int32 but returns float64", ex.message
      end

      def test_validates_previous_definitions
        visit("extern add(a : int, b : float) : float64")
        visit("def add(a : int, b : float); a + b; end")

        # mismatch: return type
        ex = assert_raises(SemanticError) do
          visit("def add(a : int, b : float) : int; a; end")
        end
        assert_match "doesn't match previous definition", ex.message

        # mismatch: arg type
        ex = assert_raises(SemanticError) do
          visit("def add(a : int, b : int) : float64; 1.0_f64; end")
        end
        assert_match "doesn't match previous definition", ex.message

        # mismatch: arg number
        ex = assert_raises(SemanticError) do
          visit("def add(a : int, b : float, c : int8) : float64; b; end")
        end
        assert_match "doesn't match previous definition", ex.message
      end

      private def assert_type(name : String, node : AST::Node)
        assert_equal name, node.type.name
      end

      private def assert_types(names : Array(String), nodes : Array(AST::Node))
        assert_equal names, nodes.map(&.type.name)
      end

      private def visit(source)
        parse(source) do |node|
          visitor.visit(node)
          return node
        end
        raise "unreachable"
      end

      private def visit_each(source)
        index = 0
        parse(source) do |node|
          visitor.visit(node)
          yield node, index
          index += 1
        end
      end

      private def parse(source)
        io = IO::Memory.new(source)
        lexer = Lexer.new(io)
        Parser.new(lexer, top_level_expressions: true).parse { |node| yield node }
      end

      private def visitor
        @visitor ||= TypeVisitor.new
      end
    end
  end
end
