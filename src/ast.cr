require "./location"

module Runic
  module AST
    module Literal
    end

    abstract class Node
      getter location : Location
      @type : String?

      def initialize(@location)
      end

      def type?
        @type ||= resolve_type
      end

      def type
        @type ||= resolve_type.not_nil!
      end

      private abstract def resolve_type : String
    end

    abstract class Number < Node
      include Literal

      getter value : String
      property sign : String?

      def self.new(token : Token, type = token.literal_type)
        new(token.value, token.location, type)
      end

      def initialize(@value, @location, @type = nil)
        @negative = false
      end

      def type?
        @type ||= resolve_type
      end

      def type=(@type : String)
      end

      def negative
        sign == "-"
      end
    end

    class Integer < Number
      # MAX_UINT32 = "4294967295"
      # MAX_UINT64 = "18446744073709551615"
      # MAX_UINT128 = "340282366920938463463374607431768211455"

      MIN_INT32 = "2147483648"
      MAX_INT32 = "2147483647"
      MIN_INT64 = "9223372036854775808"
      MAX_INT64 = "9223372036854775807"
      MIN_INT128 = "170141183460469231731687303715884105728"
      MAX_INT128 = "170141183460469231731687303715884105727"

      MIN_OCTAL_INT32 = "0o20000000000"
      MAX_OCTAL_INT32 = "0o17777777777"
      MIN_OCTAL_INT64 = "0o1000000000000000000000"
      MAX_OCTAL_INT64 = "0o777777777777777777777"
      MIN_OCTAL_INT128 = "0o2000000000000000000000000000000000000000000"
      MAX_OCTAL_INT128 = "0o1777777777777777777777777777777777777777777"

      private def resolve_type
        case @value
        when .starts_with?("0x") then resolve_hexadecimal_type
        when .starts_with?("0b") then resolve_binary_type
        when .starts_with?("0o") then resolve_octal_type
        else                          resolve_decimal_type
        end
      end

      private def resolve_hexadecimal_type
        if @value.size <= 10
          "uint"
        elsif @value.size <= 18
          "uint64"
        elsif @value.size <= 34
          "uint128"
        end
      end

      private def resolve_binary_type
        if @value.size <= 34
          "uint"
        elsif @value.size <= 66
          "uint64"
        elsif @value.size <= 130
          "uint128"
        end
      end

      private def resolve_octal_type
        if compare(negative ? MIN_OCTAL_INT32 : MAX_OCTAL_INT32)
          "int"
        elsif compare(negative ? MIN_OCTAL_INT64 : MAX_OCTAL_INT64)
          "int64"
        elsif compare(negative ? MIN_OCTAL_INT128 : MAX_OCTAL_INT128)
          "int128"
        end
      end

      private def resolve_decimal_type
        if compare(negative ? MIN_INT32 : MAX_INT32)
          "int"
        elsif compare(negative ? MIN_INT64 : MAX_INT64)
          "int64"
        elsif compare(negative ? MIN_INT128 : MAX_INT128)
          "int128"
        end
      end

      private def compare(other)
        @value.size < other.size ||
          (@value.size == other.size && @value <= other)
      end
    end

    class Float < Number
      private def resolve_type
        "float64"
      end
    end

    class Boolean < Node
      include Literal

      getter value : String

      def self.new(token : Token)
        new(token.value, token.location)
      end

      def initialize(@value, @location)
      end

      private def resolve_type
        "bool"
      end
    end

    class Variable < Node
      @name : String
      property shadow : Int32

      def self.new(token : Token)
        new(token.value, token.location)
      end

      def initialize(@name, @location)
        @shadow = 0
      end

      def name
        if shadow > 0
          "__runic_shadow_#{@name}#{@shadow}"
        else
          @name
        end
      end

      def original_name
        @name
      end

      def type=(@type : String)
      end

      private def resolve_type
        # can't be determined
      end
    end

    class Binary < Node
      getter operator : String
      getter lhs : Node
      getter rhs : Node

      def self.new(token : Token, lhs, rhs)
        new(token.value, lhs, rhs, token.location)
      end

      def initialize(@operator, @lhs, @rhs, @location)
      end

      def assignment?
        OPERATORS::ASSIGNMENT.includes?(operator)
      end

      private def resolve_type
        INTRINSICS.resolve(operator, lhs.type?, rhs.type?)
      end
    end

    class Unary < Node
      getter operator : String
      getter expression : Node

      def self.new(token : Token, expression)
        new(token.value, expression, token.location)
      end

      def initialize(@operator, @expression, @location)
      end

      private def resolve_type
        INTRINSICS.resolve(operator, expression.type)
      end
    end
  end
end
