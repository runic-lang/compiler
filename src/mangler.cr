require "./ast"

module Runic
  module Mangler
    def self.mangle(fn : AST::Prototype, namespace : String? = nil) : String
      String.build do |str|
        str << "_Z"

        function(fn, str)

        if fn.args.any?
          fn.args.each do |arg|
            type(arg.type, str)
          end
        else
          str << 'v'
        end
      end
    end

    private def self.function(fn, str)
      special(fn.name, str) do |name, str|
        case name
        when "+"   then str << (unary?(fn) ? "ps" : "pl")
        when "-"   then str << (unary?(fn) ? "ng" : "mi")
        when "*"   then str << "ml"
        when "/"   then str << "dv"
        when "%"   then str << "rm"
        when "&"   then str << "an"
        when "|"   then str << "or"
        when "^"   then str << "eo"
        #when "+="  then str << "pL"
        #when "-="  then str << "mI"
        #when "*="  then str << "mL"
        #when "/="  then str << "dV"
        #when "%="  then str << "rM"
        #when "&="  then str << "aN"
        #when "|="  then str << "oR"
        #when "^="  then str << "eO"
        when "<<"  then str << "ls"
        when ">>"  then str << "rs"
        #when "<<=" then str << "lS"
        #when ">>=" then str << "rS"
        when "=="  then str << "eq"
        when "!="  then str << "ne"
        when "<"   then str << "lt"
        when ">"   then str << "gt"
        when "<="  then str << "le"
        when ">="  then str << "ge"
        when "!"   then str << "nt"
        when "&&"  then str << "&&"
        when "||"  then str << "||"
        #when "new" then str << "nw"
        else
          special(name, str)
        end
      end
    end

    private def self.special(name, str)
      special(name, str) do |ns, str|
        str << ns.bytesize
        escape(ns, str)
      end
    end

    private def self.special(name, str, &block) : Nil
      if name.includes?("::")
        str << 'N'
        name.split("::") { |ns| yield ns, str }
        str << 'E'
      else
        yield name, str
      end
    end

    private def self.unary?(fn)
      fn.args.size == 1 && fn.args.first.name == "self"
    end

    # TODO: escape chars that would be invalid symbols
    private def self.escape(name, str) : Nil
      str << name
    end

    private def self.type(type : Type, str : String::Builder) : Nil
      case type.name
      when "void" then str << 'v'
      when "bool" then str << 'b'
      when "i8"   then str << 'a'
      when "u8"   then str << 'h'
      when "i16"  then str << 's'
      when "u16"  then str << 't'
      when "i32"  then str << 'i'
      when "u32"  then str << 'j'
      when "i64"  then str << 'x'
      when "u64"  then str << 'y'
      when "i128" then str << 'n'
      when "u128" then str << 'o'
      when "f32"  then str << 'f'
      when "f64"  then str << 'd'
      #when "f128" then str << 'g'
      #when "..."  then str << 'z'
      else
        special(type.name, str)
      end
    end
  end
end
