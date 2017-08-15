require "./definitions"

module Runic
  struct Token
    getter type : Symbol
    getter value : String
    getter location : Location
    getter literal_type : String?

    def initialize(@type, @value, @location, @literal_type = nil)
    end

    {% for type in %i(eof identifier float integer operator call linefeed comment) %}
      def {{type.id}}?
        @type == {{type}}
      end
    {% end %}

    def assignment?
      operator? && OPERATORS::ASSIGNMENT.includes?(value)
    end

    def inspect(io)
      value.to_s(io)
      io << ' '
      type.inspect(io)
      io << ' '
      location.to_s(io)

      if literal_type
        io << " ("
        literal_type.to_s(io)
        io << ')'
      end
    end
  end
end
