require "../semantic"

module Runic
  class Semantic
    class SugarExpanderVisitor < Visitor
      # Expands assignment operators such as `a += 1` to `a = a + 1`.
      #
      # NOTE: only valid because only variables are assignable, but later more
      #       complex expressions may be assigned a value, so the expansion
      #       should save the expression to a temporary variable.
      def visit(node : AST::Binary) : Nil
        visit(node.lhs)
        visit(node.rhs)

        if node.assignment? && node.operator != "="
          operator = node.operator.chomp('=')
          node.operator = "="
          node.rhs = AST::Binary.new(operator, node.lhs.dup, node.rhs, node.location)
        end
      end

      # Other nodes don't need to be visited.
      def visit(node : AST::Node) : Nil
      end
    end
  end
end
