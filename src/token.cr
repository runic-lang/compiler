require "./definitions"

module Runic
  struct Token
    getter type : Symbol
    getter value : String
    getter location : Location
    getter literal_type : String?

    def initialize(@type, @value, @location, @literal_type = nil)
    end

    {% for type in %i(
       attribute
       call
       comment
       eof
       float
       identifier
       integer
       ivar
       keyword
       linefeed
       operator
       semicolon
     ) %}
      def {{type.id}}?
        @type == {{type}}
      end
    {% end %}

    def assignment?
      operator? && OPERATORS::ASSIGNMENT.includes?(value)
    end

    def to_s(io)
      case type
      when :attribute
        io << "#["
        value.to_s(io)
        io << ']'
      when :call
        super
      when :comment
        io << "comment"
      when :eof
        io << "EOF"
      when :float, :identifier, :integer, :keyword
        value.inspect(io)
      when :ivar
        io << '@'
        value.to_s(io)
      when :linefeed
        io << "LF"
      when :operator
        io << value
      when :semicolon
        io << value
      else
        super
      end
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
