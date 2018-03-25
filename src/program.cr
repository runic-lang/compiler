require "./ast"

module Runic
  class Program
    getter constants
    getter externs
    getter structs
    getter functions

    def initialize
      @constants = {} of String => AST::ConstantDefinition
      @externs = {} of String => AST::Prototype
      @structs = {} of String => AST::Struct

      # TODO: functions should be an Array(AST::Function)
      @functions = {} of String => AST::Function
    end

    def each
      @constants.each { |_, node| yield node }
      @externs.each { |_, node| yield node }
      @structs.each { |_, node| yield node }
      @functions.each { |_, node| yield node }
    end

    def register(node : AST::ConstantDefinition) : Nil
      if previous = @constants[node.name]?
        raise ConflictError.new("can't redefine constant #{node.name}", previous.location, node.location)
      end
      @constants[node.name] = node
    end

    def register(node : AST::Prototype) : Nil
      if previous = @externs[node.name]?
        return if node.matches?(previous)
        raise ConflictError.new("prototype #{node} doesn't match previous definition", previous.location, node.location)
      end
      @externs[node.name] = node
    end

    # Merely replaces the previous function definition, without validating the
    # new definition against the previous definition (number of args, arg types
    # and return type.
    #
    # TODO: function overloads + overwrite previous definition if it matches the
    #       new definition.
    def register(node : AST::Function) : Nil
      if previous = @functions[node.name]?
        unless node.matches?(previous)
          raise ConflictError.new("function overloads aren't supported (yet)", previous.location, node.location)
        end
      end

      # @functions << node
      @functions[node.name] = node
    end

    def register(node : AST::Struct) : Nil
      if st = @structs[node.name]?
        # st.merge(node)
      else
        @structs[node.name] = node
      end
    end

    # :nodoc:
    def register(node : AST::Node) : Nil
      # raise "Program#register(#{node.class.name}) should be unreachable"
    end

    # TODO: search struct constants first
    def resolve(node : AST::Constant) : AST::ConstantDefinition
      if const = @constants[node.name]?
        const #.lhs.as(AST::Constant)
      else
        raise SemanticError.new("undefined constant #{node.name}", node)
      end
    end

    def resolve(node : AST::Call) : AST::Function | AST::Prototype
      fn = if receiver = node.receiver
             resolve_type(receiver).methods.find { |m| m.name == node.callee }
           else
             @functions[node.callee]?
           end
      if fn
        fn
      elsif prototype = @externs[node.callee]?
        return prototype
      else
        raise SemanticError.new("undefined method #{node}", node)
      end
    end

    private def resolve_type(node : AST::Node) : AST::Struct
      @structs[node.type.name]? || raise SemanticError.new("undefined struct #{node.type.name}", node)
    end
  end
end
