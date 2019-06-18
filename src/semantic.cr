require "./ast"
require "./program"
require "./semantic/*"

module Runic
  class Semantic
    DEFAULT_VISITORS = [
      SugarExpanderVisitor,
      NamespaceVisitor,
      TypeVisitor,
    ]

    def self.analyze(program : Program, visitors = DEFAULT_VISITORS) : Semantic
      new(program, DEFAULT_VISITORS).tap do |semantic|
        semantic.visit(program)
      end
    end

    @visitors : Array(Visitor)

    def initialize(program : Program, visitors = DEFAULT_VISITORS)
      @visitors = visitors.map { |klass| klass.new(program).as(Visitor) }
    end

    # Visits all nodes from a program, one visitor at a time, each visitor
    # walking as much of the AST as needed.
    def visit(program : Program)
      @visitors.each do |visitor|
        program.each { |node| visitor.visit(node) }
      end
    end

    # Visits the node with each visitor. Should be used for interactive modes,
    # where expressions are parsed and visited immediately.
    def visit(node : AST::Node) : Nil
      @visitors.each(&.visit(node))
    end
  end
end
