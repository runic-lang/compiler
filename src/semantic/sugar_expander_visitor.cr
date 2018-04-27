require "./visitor"

module Runic
  class Semantic
    class SugarExpanderVisitor < Visitor
      # Expands assignment operators such as `a += 1` to `a = a + 1`.
      #
      # FIXME: only valid because only variables are assignable, but later more
      #        complex expressions may be assigned a value, so the expansion
      #        should save the expression to a temporary variable (unless it's a
      #        simple case).
      def visit(node : AST::Assignment) : Nil
        super

        unless node.operator == "="
          operator = node.operator.chomp('=')
          node.operator = "="
          node.rhs = AST::Binary.new(operator, node.lhs.dup, node.rhs, node.location)
        end
      end

      # If the function has a *receiver*, inject it has the first argument of
      # the method call, so it will become *self*.
      def visit(node : AST::Call) : Nil
        super

      # FIXME: `self` is actually a `Pointer<T>` not a `T` for non primitive structs!
        if slf = node.receiver
          node.args.unshift(slf)
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

      # Injects *self* as first argument of struct methods.
      def visit(node : AST::Struct) : Nil
        node.methods.each do |n|
          # FIXME: `self` is actually a `Pointer<T>` not a `T` for non primitive structs!
          n.args.unshift(AST::Argument.new("self", Type.new(node.name), nil, n.location))
          visit(n)
        end
      end
    end
  end
end
