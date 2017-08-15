module Runic
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
