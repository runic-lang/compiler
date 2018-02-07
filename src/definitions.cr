module Runic
  module INTRINSICS
    BOOLS = %w(bool)
    SIGNED = %w(int long i8 i16 i32 i64 i128)
    UNSIGNED = %w(uint ulong u8 u16 u32 u64 u128)
    INTEGERS = SIGNED + UNSIGNED
    FLOATS = %w(float f32 f64) # f16, f128

    # Resolves the return type of a binary expression, depending on the operator
    # and both LHS and RHS types.
    #
    # NOTE: shall eventually be removed when types can be defined automatically,
    #       functions accept overloads, explicit type casts, ...
    def self.resolve(operator : String, lty : Type, rty : Type)
      case operator
      when "/", "/="
        # float division always evaluates to a floating point
        if lty.integer?
          if rty.float?
            rty
          elsif rty.integer?
            "f64"
          end
        elsif lty.float?
          lty
        end
      when "==", "!=", "||", "&&"
        "bool"
      when "<", "<=", ">", ">="
        if (lty.float? && rty.number?) ||
            (lty.number? && rty.float?) ||
            (lty.unsigned? && rty.unsigned?) ||
            (lty.signed? && rty.signed?)
          "bool"
        end
      when "<=>"
        if (lty.float? && rty.number?) ||
            (lty.number? && rty.float?) ||
            (lty.unsigned? && rty.unsigned?) ||
            (lty.signed? && rty.signed?)
          "i32"
        end
      when "&", "|", "^", "<<", ">>"
        # bitwise operators are only valid on integers
        if lty.integer? && rty.integer?
          lty
        end
      else
        # LHS is significant unless RHS is a floating point
        if lty.integer?
          rty.float? ? rty : lty
        elsif lty.float?
          lty
        end
      end
    end

    # Resolves the return type of an unary expression.
    def self.resolve(operator : String, ety : Type)
      case operator
      when "!"
        "bool"
      when "~"
        ety if INTEGERS.includes?(ety.name)
      when "-", "+"
        ety if ety.integer? || ety.float?
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
