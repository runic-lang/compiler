require "./ast"

module Runic
  class Program
    REQUIRE_PATH = [Dir.current]

    getter requires
    getter constants
    getter externs
    getter structs
    getter functions

    def initialize
      @requires = [] of String
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

    def resolve_require(node : AST::Require, relative_path : String? = nil) : String?
      path = node.path

      if path.starts_with?("/")
        raise SemanticError.new("can't require absolute file #{path}", node)
      end

      unless path.ends_with?(".runic")
        path = "#{path}.runic"
      end

      if path.starts_with?("./") || path.starts_with?("../")
        relative_path ||= File.dirname(node.location.file)
        path = File.expand_path(path, relative_path)
      elsif found = search_require_path(path)
        path = found
      else
        raise SemanticError.new("can't find #{path}", node)
      end

      unless File.exists?(path)
        raise SemanticError.new("can't find #{path}", node)
      end

      return if @requires.includes?(path)
      @requires << path

      path
    end

    private def search_require_path(name : String) : String?
      REQUIRE_PATH.each do |require_path|
        path = File.join(require_path, name)
        return path if File.exists?(path)
      end
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
    # and return type).
    #
    # TODO: function overloads + overwrite previous definition if it matches the
    #       new definition.
    def register(node : AST::Function) : Nil
      if previous = @functions[node.name]?
        unless node.matches?(previous)
          raise ConflictError.new("function overloads aren't supported (yet)", previous.location, node.location)
        end
      end

      @functions[node.name] = node

      #@functions.each_with_index do |previous, index|
      #  if previous.name == node.name && node.matches?(previous)
      #    @functions[index] = node
      #    return
      #  end
      #end
      #@functions << node
    end

    def register(node : AST::Struct) : Nil
      if st = @structs[node.name]?
        raise "FATAL: struct #{node.name} has already been registered"
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
      function =
        if receiver = node.receiver
          resolve_type(receiver).method(node)
        else
          @functions[node.callee]?
        end

      if function
        function
      elsif prototype = @externs[node.callee]?
        prototype
      else
        raise SemanticError.new("undefined method #{node}", node)
      end
    end

    def resolve(node : AST::Binary) : AST::Function
      if function = resolve_type(node.lhs).operator(node)
        function
      else
        raise SemanticError.new("undefined operator #{node.lhs.type}##{node.operator}(#{node.rhs.type})", node)
      end
    end

    def resolve(node : AST::Unary) : AST::Function
      if function = resolve_type(node.expression).operator(node)
        function
      else
        raise SemanticError.new("undefined operator #{node.expression.type}##{node.operator}", node)
      end
    end

    private def resolve_type(node : AST::Node) : AST::Struct
      if st = @structs[node.type.name]?
        st
      else
        raise SemanticError.new("undefined struct #{node.type.name}", node)
      end
    end
  end
end
