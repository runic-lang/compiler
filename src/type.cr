module Runic
  struct Type
    include Comparable(Type)

    getter name : String
    delegate :inspect, to: name

    # :nodoc:
    def self.new(type : Type) : Type
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

    def <=>(other : Type)
      bits <=> other.bits
    end

    def ==(other : Type)
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

    def pointer?
      name.ends_with?('*')
    end

    def pointee_type
      raise "BUG: #{self} isn't a pointer type!" unless pointer?
      Type.new(name[0..-2])
    end

    def to_s(io : IO)
      io << name
    end
  end
end
