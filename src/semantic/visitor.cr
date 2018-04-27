require "../semantic"

module Runic
  class Semantic
    abstract class Visitor
      def initialize(@program : Program)
      end

      def visit(node : AST::Literal) : Nil
      end

      def visit(node : AST::Constant) : Nil
      end

      def visit(node : AST::ConstantDefinition) : Nil
        visit(node.value)
      end

      def visit(node : AST::Variable) : Nil
      end

      def visit(node : AST::InstanceVariable) : Nil
      end

      def visit(node : AST::Reference) : Nil
        visit(node.pointee)
      end

      def visit(node : AST::Dereference) : Nil
        visit(node.pointee)
      end

      def visit(node : AST::Argument) : Nil
        if n = node.default
          visit(n)
        end
      end

      def visit(node : AST::Assignment) : Nil
        visit(node.lhs)
        visit(node.rhs)
      end

      def visit(node : AST::Binary) : Nil
        visit(node.lhs)
        visit(node.rhs)
      end

      def visit(node : AST::Unary) : Nil
        visit(node.expression)
      end

      def visit(node : AST::Call) : Nil
        if n = node.receiver
          visit(n)
        end

        visit(node.args)
        node.kwargs.each_value { |n| visit(n) }
      end

      def visit(node : AST::If) : Nil
        visit(node.condition)
        visit(node.body)

        if n = node.alternative
          visit(n)
        end
      end

      def visit(node : AST::Unless) : Nil
        visit(node.condition)
        visit(node.body)
      end

      def visit(node : AST::While) : Nil
        visit(node.condition)
        visit(node.body)
      end

      def visit(node : AST::Until) : Nil
        visit(node.condition)
        visit(node.body)
      end

      def visit(node : AST::Case) : Nil
        visit(node.cases)

        if n = node.alternative
          visit(n)
        end
      end

      def visit(node : AST::When) : Nil
        visit(node.conditions)
        visit(node.body)
      end

      def visit(node : AST::Body) : Nil
        visit(node.expressions)
      end

      def visit(node : AST::Prototype) : Nil
        visit(node.args)
      end

      def visit(node : AST::Function) : Nil
        visit(node.args)
        visit(node.body)
      end

      def visit(node : AST::Module) : Nil
        visit(node.modules)
        visit(node.structs)
      end

      def visit(node : AST::Require) : Nil
      end

      def visit(node : AST::Struct) : Nil
        #visit(node.variables)
        visit(node.methods)
      end

      def visit(nodes : Array(AST::Node)) : Nil
        nodes.each { |n| visit(n) }
      end
    end
  end
end
