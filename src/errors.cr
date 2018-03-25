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

  class ConflictError < Error
    getter original_location : Location
    getter location : Location

    def initialize(message, @original_location, @location)
      super "#{message} at #{@location} (previous at #{@original_location})"
    end
  end
end
