module Runic
  module INTRINSICS
    BOOLS = %w(bool)
    SIGNED = %w(int long i8 i16 i32 i64 i128)
    UNSIGNED = %w(uint ulong u8 u16 u32 u64 u128)
    INTEGERS = SIGNED + UNSIGNED
    FLOATS = %w(float f32 f64) # f16, f80, f128 (?)
  end

  module OPERATORS
    # TODO: typeof and sizeof are unary operators
    UNARY = %w(~ ! + -)
    ASSIGNMENT = %w(= += -= *= **= /= //= %= &= &&= |= ||= ^= <<= >>=)
    LOGICAL = %w(== != <=> < <= > >= || &&)
    BINARY = %w(+ - * ** / // % & | ^ << >>)
    ALL = (UNARY + ASSIGNMENT + LOGICAL + BINARY).uniq

    # Returns the precedence score for an operator. A low value means a lower
    # precedence than a high value.
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

      when "=="  then 20
      when "!="  then 20
      when "<=>" then 20

      when "<"   then 30
      when "<="  then 30
      when ">"   then 30
      when ">="  then 30

      when "|"   then 32
      when "^"   then 32
      when "&"   then 34

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
