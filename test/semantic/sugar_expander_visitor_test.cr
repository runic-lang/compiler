require "../test_helper"

module Runic
  class Semantic
    class SugarExpanderVisitorTest < Minitest::Test
      def test_expands_assignment_operators
        node = visit("a += 1").as(AST::Assignment)

        assert_equal "=", node.operator
        assert_equal "a", node.lhs.as(AST::Variable).name

        subnode = node.rhs.as(AST::Binary)
        assert_equal "+", subnode.operator
        assert_equal "a", subnode.lhs.as(AST::Variable).name
        assert_equal "1", subnode.rhs.as(AST::Integer).value
      end

      def test_expands_assignment_operators_recursively
        node = visit("a += (b *= 1)").as(AST::Assignment)

        assert_equal "=", node.operator
        assert_equal "a", node.lhs.as(AST::Variable).name

        add = node.rhs.as(AST::Binary)
        assert_equal "+", add.operator
        assert_equal "a", add.lhs.as(AST::Variable).name

        assign = add.rhs.as(AST::Assignment)
        assert_equal "=", assign.operator
        assert_equal "b", assign.lhs.as(AST::Variable).name

        mul = assign.rhs.as(AST::Binary)
        assert_equal "*", mul.operator
        assert_equal "b", mul.lhs.as(AST::Variable).name
        assert_equal "1", mul.rhs.as(AST::Integer).value
      end

      def test_injects_self_as_first_arg_to_struct_methods
        node = visit <<-RUNIC
        struct User
          def age(since : i32)
          end
        end
        RUNIC

        fn = node.as(AST::Struct).methods.first
        assert_equal 2, fn.args.size
        assert_equal "self", fn.args[0].name
        assert_equal "since", fn.args[1].name
        assert_equal Type.new("User*"), fn.args[0].type
        assert_equal Type.new("i32"), fn.args[1].type
      end

      protected def visitors
        @visitor ||= [SugarExpanderVisitor.new(program)]
      end
    end
  end
end
