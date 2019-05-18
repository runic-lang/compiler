require "./visitor"
require "../scope"

module Runic
  class Semantic
    # Type semantic analyzer.
    #
    # Recursively visits each an AST node, typing all expressions when possible,
    # raising a `SemanticError` when an expression type can't be inferred, or
    # there is a type mismatch, or a number literal doesn't fit into its defined
    # or inferred type, ...
    #
    # FIXME: detect recursive and circular calls
    class TypeVisitor < Visitor
      def initialize(@program : Program)
        @scope = Scope(AST::Variable).new
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

      def visit(node : AST::Argument) : Nil
        if default = node.default
          cast_literal(node, default)

          unless node.type == default.type
            raise SemanticError.new("default argument type mismatch: expected #{node.type} but got #{default.type}", default.location)
          end
        end
        @scope.set(node.name, node)
      end

      # Tries to cast a literal so it matches a variable type.
      private def cast_literal(variable, literal)
        if variable.type == literal.type
          return
        end

        case variable.type
        when .integer?
          if literal.type.integer?
            literal.type = variable.type

            unless literal.as(AST::Integer).valid_type_definition?
              raise SemanticError.new("can't cast #{literal.value} to #{variable.type}", literal.location)
            end
          end
        when .float?
          if literal.type.number?
            literal.type = variable.type
          end
        end
      end

      # Makes sure the variable has been defined, accessing the previously
      # memorized assignment, making sure the variable refers to the latest
      # variable type if it was previously shadowed.
      def visit(node : AST::Variable) : Nil
        if named_var = @scope.get(node.name)
          node.shadow = named_var.shadow
          node.type = named_var.type unless node.type?
        else
          raise SemanticError.new("variable '#{node.name}' has no type", node.location)
        end
      end

      # Makes sure the constant has been defined, accessing the previously
      # memorized assignment.
      def visit(node : AST::Constant) : Nil
        const = @program.resolve(node)
        visit(const.value)

        if type = const.type?
          node.type = type
        else
          raise SemanticError.new("constant '#{node.name}' has no type", node.location)
        end
      end

      # Makes sure the constant value has been typed (a constant may reference
      # another constant).
      def visit(node : AST::ConstantDefinition) : Nil
        visit(node.value)
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

          case lhs
          when AST::Variable
            # type LHS from RHS
            lhs.type = rhs.type

            if named_var = @scope.get(lhs.name)
              if named_var.type == lhs.type
                # make sure to refer to the variable (or its shadow)
                visit(lhs)
              else
                # shadow the variable
                name = lhs.name
                lhs.shadow = named_var.shadow + 1
                @scope.set(name, lhs)
              end
            else
              # memorize the variable (so we know its type later)
              @scope.set(lhs.name, lhs)
            end
          else
            raise SemanticError.new("invalid operation: only variables and constants may be assigned a value", lhs.location)
          end
        else
          # make sure LHS and RHS are typed
          visit(lhs)
          visit(rhs)
        end

        # type the binary expression, TODO: resolve type using corelib:
        # node.type = @program.resolve(node).type
        unless node.type?
          raise SemanticError.new("invalid operation: #{lhs.type?} ##{node.operator} ##{rhs.type?}", node.location)
        end
      end

      # Visits the sub-expression, then types the unary expression.
      def visit(node : AST::Unary) : Nil
        # make sure the expression is typed
        visit(node.expression)

        # type the unary expression, TODO: resolve type using corelib
        #node.type = @program.resolve(node).type
        unless node.type?
          raise SemanticError.new("invalid #{node.operator}#{node.expression.type}", node.location)
        end
      end

      # Makes sure the prototype is fully typed (arguments, return type).
      # Verifies that the definition matches any previous definition (forward
      # declaration, redefinition). Eventually memoizes the prototype
      # definition, overwriting any previous definition.
      def visit(node : AST::Prototype) : Nil
        return if node.visited?

        node.args.each do |arg|
          unless arg.type?
            raise SemanticError.new("argument '#{arg.name}' in function '#{node.name}' has no type", node.location)
          end
        end

        unless node.type?
          raise SemanticError.new("function '#{node.name}' has no return type", node.location)
        end
      end

      # Creates a new scope to hold local variables, initialized to the function
      # arguments. Visits the body, determining the actual return type.
      # Types the function if it wasn't, otherwise ensures the return type
      # matches the definition. Eventually visits the prototype to be memoized.
      def visit(node : AST::Function) : Nil
        return if node.visited?

        @scope.push(:function) do
          node.args.each do |arg|
            visit(arg)
          end

          visit(node.body, :function)
        end

        if node.attribute?("primitive")
          unless node.prototype.type?
            raise SemanticError.new("primitive function '#{node.name}' must specify a return type!", node.location)
          end
        else
          ret_type = node.body.type? || "void"
          if type = node.type?
            unless type == "void" || type == ret_type
              raise SemanticError.new("function '#{node.name}' must return #{type} but returns #{ret_type}", node.location)
            end
            node.prototype.type = type
          elsif ret_type
            node.type = ret_type
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
        if slf = node.receiver
          node.args.unshift(slf)
        end
        node.args.each { |arg| visit(arg) }

        fn_or_prototype = @program.resolve(node)
        visit(fn_or_prototype)

        case fn_or_prototype
        when AST::Function
          prototype = fn_or_prototype.prototype
        when AST::Prototype
          prototype = fn_or_prototype
        else
          raise "FATAL: expected AST::Function or AST::Prototype but got #{fn_or_prototype.class.name}"
        end

        # validate arg count:
        actual = node.args.size + node.kwargs.size
        arg_count = prototype.arg_count

        unless arg_count.includes?(actual)
          expected = arg_count.begin == arg_count.end ? arg_count.begin : arg_count
          message = "wrong number of arguments for '#{prototype.name}' (given #{actual}, expected #{expected})"
          raise SemanticError.new(message, (node.args.first? || node).location)
        end

        # insert named args:
        unless node.kwargs.empty?
          prototype.args.each_with_index do |arg, i|
            unless node.args[i]?
              if kwarg = node.kwargs[arg.name]?
                node.args << kwarg
              else
                raise SemanticError.new("missing argument '#{arg.name}' for '#{prototype.name}'", node.location)
              end
            end
          end
        end

        # validate arg types (+ set defaults):
        prototype.args.each_with_index do |expected, i|
          if arg = node.args[i]?
            if arg.is_a?(AST::Literal)
              cast_literal(expected, arg)
            end
            unless arg.type == expected.type
              message = "wrong type for argument '#{expected.name}' of function '#{prototype.name}' (given #{arg.type}, expected #{expected.type})"
              raise SemanticError.new(message, arg.location)
            end
          elsif default = expected.default
            node.args << default
          else
            raise "unreachable"
          end
        end

        node.prototype = prototype
        node.type = prototype.type
      end

      # Makes sure to visit inner nodes (condition, body, alternate body if
      # present), then tries to type the expression, which requires an alternate
      # body and both the body and the alternate one to evaluate to the same
      # type, otherwise the returned type is left undefined.
      #
      # TODO: return a nilable type if there is no alternate branch.
      def visit(node : AST::If) : Nil
        visit_condition(node.condition)
        visit(node.body, :if)

        if alt_body = node.alternative
          visit(alt_body, :if)

          if (then_type = node.body.type?) && (else_type = alt_body.type?)
            if then_type == else_type
              node.type = then_type
              return
            end
          end
        end

        node.type = "void"
      end

      # Visits inner nodes (condition, body). The returned type is always void.
      #
      # TODO: return a nilable type.
      def visit(node : AST::Unless) : Nil
        visit_condition(node.condition)
        visit(node.body, :unless)
        node.type = "void"
      end

      def visit(node : AST::While) : Nil
        visit_condition(node.condition)
        visit(node.body, :while)
      end

      def visit(node : AST::Until) : Nil
        visit_condition(node.condition)
        visit(node.body, :until)
      end

      def visit(node : AST::Case) : Nil
        visit_condition(node.value)
        node.cases.each { |n| visit(n) }

        if body = node.alternative
          visit(body, :case)

          if type = body.type?
            if node.cases.all? { |n| n.type == type }
              node.type = type
              return
            end
          end
        end

        node.type = "void"
      end

      def visit(node : AST::When) : Nil
        node.conditions.each { |n| visit_condition(n) }
        visit(node.body, :case)
      end

      # These nodes don't need to be visited.
      def visit(node : AST::Boolean | AST::Float | AST::Module) : Nil
      end

      # Simple helper to visit bodies (functions, ifs, ...).
      def visit(body : AST::Body, name : Symbol) : Nil
        @scope.push(name) do
          body.expressions.each { |node| visit(node) }
        end
      end

      def visit(body : AST::Body) : Nil
        raise "unreachable"
      end

      # Visits struct methods (once).
      def visit(node : AST::Struct) : Nil
        return if node.visited?

        @scope.push(:struct) do
          node.methods.each { |fn| visit(fn) }
        end
      end

      private def visit_condition(node : AST::Node) : Nil
        visit(node)

        if node.type == "void"
          raise SemanticError.new("void value isn't ignored as it ought to be", node)
        end
      end
    end
  end
end
