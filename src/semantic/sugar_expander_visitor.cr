require "./visitor"

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

      # Recursively expands the name of nested modules and structs to include
      # the module name.
      def visit(node : AST::Module) : Nil
        node.modules.each do |n|
          n.name = "#{node.name}::#{n.name}"
          visit(n)
        end

        node.structs.each do |n|
          n.name = "#{node.name}::#{n.name}"
          visit(n)
        end
      end

      # Injects `self` as first method argument.
      def visit(node : AST::Struct) : Nil
        node.methods.each do |fn|
          fn.args.unshift(AST::Argument.new("self", Type.new(node.name), nil, fn.location))
        end
      end

      # Other nodes don't need to be visited.
      #
      # FIXME: actually subnodes should be visited!
      def visit(node : AST::Node) : Nil
      end
    end
  end
end
