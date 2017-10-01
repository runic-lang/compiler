module Runic
  module INTRINSICS
    BOOLS = %w(bool)
    SIGNED = %w(int long int8 int16 int32 int64 int128)
    UNSIGNED = %w(uint ulong uint8 uint16 uint32 uint64 uint128)
    INTEGERS = SIGNED + UNSIGNED
    FLOATS = %w(float32 float64) # float16, float32, float128

    # Resolves the return type of a binary expression, depending on the operator
    # and both LHS and RHS types.
    def self.resolve(operator : String, lhs : Type, rhs : Type)
      case operator
      when "/", "/="
        # float division always evaluates to a floating point
        if lhs.integer?
          if rhs.float?
            rhs
          elsif rhs.integer?
            "float64"
          end
        elsif lhs.float?
          lhs
        end
      else
        # LHS is significant unless RHS is a floating point
        if lhs.integer?
          rhs.float? ? rhs : lhs
        elsif lhs.float?
          lhs
        end
      end
    end

    # :nodoc:
    def self.resolve(operator : String, lhs, rhs) : Nil
    end

    # Resolves the return type of an unary expression.
    def self.resolve(operator, expression)
      case operator
      when "!"
        "bool"
      when "~"
        expression if INTEGERS.includes?(expression)
      else
        expression
      end
    end
  end

  module OPERATORS
    # TODO: typeof and sizeof are unary operators
    UNARY = %w(~ ! + -)
    ASSIGNMENT = %w(= += -= *= **= /= //= %= &= &&= |= ||= ^= <<= >>=)
    LOGICAL = %w(== != <=> < <= > >= || &&)
    BINARY = %w(+ - * ** / // % & | ^ << >>)
    ALL = (UNARY + ASSIGNMENT + LOGICAL + BINARY).uniq

    def self.precedence(operator)
      case operator
      when "="   then 5
      when "+="  then 5
      when "-="  then 5
      when "*="  then 5
      when "**=" then 5
      when "/="  then 5
      when "//=" then 5
      when "%="  then 5
      when "&="  then 5
      when "&&=" then 5
      when "|="  then 5
      when "||=" then 5
      when "^="  then 5
      when "<<=" then 5
      when ">>=" then 5

      when "||"  then 10
      when "&&"  then 12
      when "|"   then 14
      when "^"   then 16
      when "&"   then 18

      when "=="  then 20
      when "!="  then 20
      when "<=>" then 20

      when "<"   then 30
      when "<="  then 30
      when ">"   then 30
      when ">="  then 30

      when "<<"  then 40
      when ">>"  then 40

      when "+"   then 50
      when "-"   then 50

      when "*"   then 60
      when "/"   then 60
      when "//"  then 60
      when "%"   then 60

      when "**"  then 70

      # always break on unknown token
      else            -1
      end
    end
  end
end
