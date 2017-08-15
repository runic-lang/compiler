module Runic
  class SyntaxError < Exception
    getter location : Location

    def initialize(message, @location)
      super "#{message} at #{@location}"
    end
  end
end
