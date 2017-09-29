module Runic
  class Documentation
    abstract struct Generator
      def initialize(@output : String)
      end

      abstract def generate(file : String, functions : Array(AST::Prototype)) : Nil
    end
  end
end
