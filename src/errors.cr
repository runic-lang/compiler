module Runic
  class Error < Exception
  end

  class SyntaxError < Error
    getter location : Location

    def initialize(message, @location)
      super "#{message} at #{@location}"
    end
  end

  class SemanticError < Error
    getter location : Location

    def initialize(message, @location)
      super "#{message} at #{@location}"
    end
  end

  class CompileError < Error
    getter location : Location

    def initialize(message, @location)
      super "#{message} at #{@location}"
    end
  end

  class CodegenError < Error
  end
end
