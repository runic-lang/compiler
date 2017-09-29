module Runic
  struct Location
    getter file : String
    getter line : Int32
    getter column : Int32

    def initialize(@file, @line = 1, @column = 1)
    end

    def increment_line : Nil
      @line += 1
      @column = 1
    end

    def increment_column : Nil
      @column += 1
    end

    def to_s(io : IO)
      io << file
      io << ':'
      line.to_s(io)
      io << ':'
      column.to_s(io)
    end
  end
end
