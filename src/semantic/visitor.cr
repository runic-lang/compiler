require "../semantic"

module Runic
  class Semantic
    abstract class Visitor
      def initialize(@program : Program)
      end

      abstract def visit(node)
    end
  end
end
