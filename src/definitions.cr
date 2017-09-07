module Runic
  module INTRINSICS
    INTEGERS = %w(int uint long ulong int8 uint8 int16 uint16 int32 uint32 int64 uint64 int128 uint128)
    FLOATS = %w(float float16 float32 float64) # float128
    BOOLS = %w(bool)

    # Resolves the return type of a binary expression, depending on the operator
    # and both LHS and RHS types.
    def self.resolve(operator, lhs, rhs)
      case operator
      when "/", "/="
        # float division always evaluates to a floating point
        if INTEGERS.includes?(lhs)
          if FLOATS.includes?(rhs)
            rhs
          elsif INTEGERS.includes?(rhs)
            "float64"
          end
        elsif FLOATS.includes?(lhs)
          lhs
        end
      else
        # LHS is significant unless RHS is a floating point
        if INTEGERS.includes?(lhs)
          FLOATS.includes?(rhs) ? rhs : lhs
        elsif FLOATS.includes?(lhs)
          lhs
        end
      end
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
