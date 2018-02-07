require "../semantic"

module Runic
  class Semantic
    # Type semantic analyzer.
    #
    # Recursively visits each an AST node, typing all expressions when possible,
    # raising a `SemanticError` when an expression type can't be inferred, or
    # there is a type mismatch, or a number literal doesn't fit into its defined
    # or inferred type, ...
    #
    # TODO: Requires prototypes to be forward declared before they're called.
    # We could consider:
    # - collecting prototype definitions (even incomplete) while parsing;
    # - building a dependency tree of functions (maybe types, later);
    # - forward visit/type functions as they are used;
    # - warning: recursive calls (foo calls itself);
    # - warning: circular calls (foo calls bar that calls foo)
    class TypeVisitor < Visitor
      def initialize
        @named_variables = {} of String => AST::Variable
        @prototypes = {} of String => AST::Prototype
      end

      # Validates that the integer literal's type fits its definition or its
      # declared type, an unsigned literal has a negative sign, ...
      def visit(node : AST::Integer) : Nil
        if node.negative && (type = node.type?)
          if type.unsigned?
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
      # memorized for the current scope. The visitor will know the type of a
      # variable when it's accessed later on.
      #
      # Variables will be shadowed with a temporary variable when their type
      # changes in the current scope, so `a = 1; a += 2.0` is valid and `a`
      # is first inferred as an `i32` then shadowed as a `f64`; further
      # accesses to `a` will refer to the `f64` variable.
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

      # Makes sure the prototype is fully typed (arguments, return type).
      # Verifies that the definition matches any previous definition (forward
      # declaration, redefinition). Eventually memoizes the prototype
      # definition, overwriting any previous definition.
      def visit(node : AST::Prototype) : Nil
        node.args.each do |arg|
          unless arg.type?
            raise SemanticError.new("argument '#{arg.name}' in function '#{node.name}' has no type", node.location)
          end
        end

        unless node.type?
          raise SemanticError.new("function '#{node.name}' has no return type", node.location)
        end

        if previous = @prototypes[node.name]?
          unless node.type == previous.type && node.args.map(&.type) == previous.args.map(&.type)
            raise SemanticError.new("function '#{node.name}' doesn't match previous definition", node.location)
          end
        end

        @prototypes[node.name] = node
      end

      # Creates a new scope to hold local variables, initialized to the function
      # arguments. Visits the body, determining the actual return type.
      # Eventually types the function if it wasn't, or verifies the return type
      # matches the definition. Eventually visits the prototype to be memoized.
      def visit(node : AST::Function) : Nil
        new_scope do
          node.args.each do |arg|
            @named_variables[arg.name] = arg
          end

          node.body.each do |n|
            visit(n)
          end

          ret_type = node.body.last?.try(&.type?)

          if type = node.type?
            unless type == ret_type
              message = "function '#{node.name}' must return #{type} but returns #{ret_type}"
              raise SemanticError.new(message, node.location)
            end
          end

          if ret_type
            node.type ||= ret_type
            node.prototype.type = ret_type
          end
        end

        visit(node.prototype)
      end

      # Visits passed arguments, so they're typed. Makes sure that a prototype
      # has been defined for the called function (extern or def), then verifies
      # that passed arguments match the prototype (same number of arguments,
      # same types). Eventually types the expression.
      def visit(node : AST::Call) : Nil
        node.args.each { |arg| visit(arg) }

        unless prototype = @prototypes[node.callee]?
          raise SemanticError.new("undefined function '#{node.callee}'", node.location)
        end

        unless node.args.size == prototype.args.size
          message = "function '#{node.callee}' expects #{prototype.args.size} arguments but got #{node.args.size}"
          raise SemanticError.new(message, node.args.first.location)
        end

        node.args.each_with_index do |arg, i|
          expected = prototype.args[i]
          unless arg.type == expected.type
            message = "argument '#{expected.name}' of function '#{prototype.name}' expects #{expected.type} but got #{arg.type}"
            raise SemanticError.new(message, arg.location)
          end
        end

        node.type = prototype.type
      end

      # Other nodes don't need to be visited (e.g. boolean literals).
      def visit(node : AST::Node) : Nil
      end

      private def new_scope
        original = @named_variables.dup
        begin
          @named_variables = {} of String => AST::Variable
          yield
        ensure
          @named_variables = original
        end
      end
    end
  end
end
