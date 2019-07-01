require "./visitor"

module Runic
  class Semantic
    class NamespaceVisitor < Visitor
      # Expands name of sub-modules and structs to have an absolute path;
      # recursively visits modules; registers sub-structs.
      def visit(node : AST::Module) : Nil
        node.modules.each do |mod|
          mod.name = "#{node.name}::#{mod.name}"
          visit(mod)
        end

        node.structs.each do |st|
          st.name = "#{node.name}::#{st.name}"
          visit(st)
          @program.register(st)
        end
      end

      # Expands name of struct methods to have an absolute path; injects `self`
      # variable as first method argument.
      def visit(node : AST::Struct) : Nil
        node.methods.each do |fn|
          fn.prototype.name = "#{node.name}::#{fn.prototype.name}"
        end
      end
    end
  end
end
