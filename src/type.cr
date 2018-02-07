module Runic
  struct Type
    include Comparable(Type)

    getter name : String
    delegate :inspect, to: name

    # :nodoc:
    def self.new(type : self) : self
      type
    end

    def initialize(@name : String)
    end

    def bits
      if float? || integer?
        name[1..-1].to_i
      elsif bool?
        1
      else
        raise "unknown type size: '#{name}'"
      end
    end

    def <=>(other : self)
      bits <=> other.bits
    end

    def ==(other : self)
      name == other.name
    end

    def ==(other : String)
      name == other
    end

    def primitive?
      void? || bool? || integer? || unsigned? || float?
    end

    def void?
      name == "void"
    end

    def bool?
      name == "bool"
    end

    def integer?
      INTRINSICS::INTEGERS.includes?(name)
    end

    def unsigned?
      INTRINSICS::UNSIGNED.includes?(name)
    end

    def signed?
      INTRINSICS::SIGNED.includes?(name)
    end

    def float?
      INTRINSICS::FLOATS.includes?(name)
    end

    def number?
      integer? || float?
    end

    def to_s(io : IO)
      #case name
      #when "i32"
      #  io << "int"
      #when "u32"
      #  io << "uint"
      #when "f64"
      #  io << "float"
      #else
        io << name
      #end
    end
  end
end
