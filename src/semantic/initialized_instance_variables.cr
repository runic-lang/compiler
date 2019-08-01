require "../ast"
#require "../errors"

module Runic
  class Semantic
    class InitializedInstanceVariables
      @struct : AST::Struct?
      @initializer : AST::Function?

      def initialize
        @tree = Array(Array(Set(AST::InstanceVariable))).new
      end

      # Returns the instance variable definition of the visited struct. Raises a
      # SemanticError exception if the instance variable is undefined or
      # uninitialized.
      def [](node : AST::InstanceVariable) : AST::InstanceVariable
        if ivar = @struct.as(AST::Struct).variables.find { |v| v.name == node.name }
          ivar
        else
          raise SemanticError.new("undefined instance variable '@#{node.name}'", node.location)
        end
      end

      def initialized?(ivar : AST::InstanceVariable) : Bool
        unless @initializer
          # not an initialize method? ivars are always initialized
          return true
        end

        # inside initialize methods, ivars may only be initialized in the
        # current branch or a parent branch:
        @tree.reverse_each do |branches|
          return true if branches.last.includes?(ivar)
        end

        false
      end

      def visit(node : AST::Struct) : Nil
        original, @struct = @struct, node
        begin
          yield
        ensure
          @struct = original
        end
      end

      def visit_initializer(@initializer) : Nil
        push
        add_branch
        yield
        verify
      ensure
        @initializer = nil
        @tree.clear
      end

      private def enabled?
        !@initializer.nil?
      end

      # Called before each control flow node. Creates a new scope to collect
      # assigned variables:
      def push
        return unless enabled?
        @tree << Array(Set(AST::InstanceVariable)).new
      end

      # Called before each branch of a control flow node. Creates a new list to
      # collect assigned variables for the current branch:
      def add_branch : Nil
        return unless enabled?
        @tree.last << Set(AST::InstanceVariable).new
      end

      # Called whenever an ivar is assigned. Collects the assignment into the
      # current branch (i.e. last branch of last scope).
      def assigned(ivar : AST::InstanceVariable) : Nil
        return unless enabled?
        @tree.last.last << ivar
      end

      # Called after all branches of a control flow node have been visited.
      # Collects ivars assigned in all branches and adds them to the last branch
      # of the previous scope:
      def collect : Nil
        return unless enabled?

        branches = @tree.pop
        branch = @tree.last.last

        ivars = branches.reduce { |a, e| a & e }
        branch.concat(ivars)
      end

      # Called after all branches of a control flow node (end) have been
      # visited. Collects ivars assigned in all branches and adds them to the
      # last branch of the previous scope:
      def reset : Nil
        return unless enabled?
        @tree.pop
      end

      private def verify
        initialized_ivars = @tree.first.last
        st = @struct.as(AST::Struct)
        initializer = @initializer.as(AST::Function)

        st.variables.each do |ivar|
          next if initialized_ivars.includes?(ivar)
          raise SemanticError.new("instance variable '@#{ivar.name}' of struct #{st.name} isn't always initialized", initializer.location)
        end
      end
    end
  end
end
