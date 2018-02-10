require "./ast"

module Runic
  class Error < Exception
  end

  class SyntaxError < Error
    getter location : Location

    def self.new(message, node : AST::Node)
      new(message, node.location)
    end

    def initialize(message, @location)
      super "#{message} at #{@location}"
    end
  end

  class SemanticError < Error
    getter location : Location

    def self.new(message, node : AST::Node)
      new(message, node.location)
    end

    def initialize(message, @location)
      super "#{message} at #{@location}"
    end
  end

  class CodegenError < Error
  end
end
