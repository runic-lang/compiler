require "../semantic"

module Runic
  class Semantic
    # Type semantic analyzer.
    #
    # Recursively visits each an AST node, typing all expressions when possible,
    # raising a `SemanticError` when an expression type can't be inferred, or
    # there is a type mismatch, or a number literal doesn't fit into its defined
    # or inferred type, ...
    class TypeVisitor < Visitor
      def initialize
        @named_variables = {} of String => AST::Variable
      end

      # Validates that the integer literal's type fits its definition or its
      # declared type, an unsigned literal has a negative sign, ...
      def visit(node : AST::Integer) : Nil
        if node.negative && (type = node.type?)
          if type.starts_with?('u')
            raise SemanticError.new("invalid negative value -#{node.value} for #{type}", node.location)
          end
        end
        if node.valid_type_definition?
          return
        elsif type = node.type?
          raise SemanticError.new("integer '#{node.value}' is larger than maximum #{type}", node.location)
        else
          raise SemanticError.new("integer '#{node.value}' is larger than maximum int128", node.location)
        end
      end

      # Makes sure the variable has been defined, accessing the previously
      # memorized assignment, making sure the variable refers to the latest
      # variable type if it was previously shadowed.
      def visit(node : AST::Variable) : Nil
        if named_var = @named_variables[node.name]?
          node.shadow = named_var.shadow
          node.type = named_var.type unless node.type?
        else
          raise SemanticError.new("variable '#{node.name}' has no type", node.location)
        end
      end

      # Visits the sub-expressions, then types the binary expression.
      #
      # In case of an assignment, only the righ-hand-side sub-expression is
      # visited, and the left-hand-side variable's type will be defined and
      # memorized for the current scope. The visitor will the know the type of a
      # variable when it's accessed later on.
      #
      # Variables will be shadowed with a temporary variable when their type
      # changes in the current scope, so `a = 1; a += 2.0` is valid and `a`
      # is first inferred as an `int` then shadowed as a `float64`; further
      # accesses to `a` will refer to the `float64` variable.
      def visit(node : AST::Binary) : Nil
        lhs, rhs = node.lhs, node.rhs

        if node.assignment?
          # make sure RHS is typed
          visit(rhs)

          # type LHS from RHS
          lhs = lhs.as(AST::Variable)
          lhs.type = rhs.type

          if named_var = @named_variables[lhs.name]?
            if named_var.type == lhs.type
              # make sure to refer to the variable (or its shadow)
              visit(lhs)
            else
              # shadow the variable
              name = lhs.name
              lhs.shadow = named_var.shadow + 1
              @named_variables[name] = lhs
            end
          else
            # memorize the variable (so we know its type later)
            @named_variables[lhs.name] = lhs
          end
        else
          # make sure LHS and RHS are typed
          visit(lhs)
          visit(rhs)
        end

        # type the binary expression
        unless node.type?
          raise SemanticError.new("invalid operation: #{lhs.type?} #{node.operator} #{rhs.type?}", node.location)
        end
      end

      # Visits the sub-expression, then types the unary expression.
      def visit(node : AST::Unary) : Nil
        visit(node.expression)

        unless node.type?
          raise SemanticError.new("invalid #{node.operator}#{node.expression.type}", node.location)
        end
      end

      # Other nodes don't need to be visited (e.g. boolean literals).
      def visit(node : AST::Node) : Nil
      end
    end
  end
end
