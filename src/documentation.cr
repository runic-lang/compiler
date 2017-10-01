require "./lexer"
require "./parser"
require "./semantic"
require "./documentation/generator"

module Runic
  class Documentation
    def initialize(@sources : Array(String))
      @semantic = Semantic.new
      @functions = Hash(String, Array(AST::Prototype)).new
    end

    def generate(generator : Generator)
      parse

      @functions.each do |file, functions|
        generator.generate(file, functions)
      end
    end

    def parse
      @sources.each do |source|
        if Dir.exists?(source)
          search_directory(source)
        elsif File.exists?(source)
          parse(source)
        else
          STDERR.puts "ERROR: no such file or directory '#{source}'."
        end
      end
    end

    private def search_directory(path : String)
      Dir.open(path) do |dir|
        {% if Dir.methods.any?(&.name.==("each".id)) %}
          dir.each do |filename|
            next if filename == "." || filename == ".."
            __search_directory(path, filename)
          end
        {% else %}
          dir.each_child do |filename|
            __search_directory(path, filename)
          end
        {% end %}
      end
    end

    private def __search_directory(path, filename)
      if Dir.exists?(filename)
        search_directory File.join(path, filename)
      elsif filename.ends_with?(".runic")
        parse File.join(path, filename)
      else
        # STDERR.puts "WARN: skipping '#{filename}' in '#{path}'"
      end
    end

    private def parse(path : String)
      # STDERR.puts "parsing #{path}"

      File.open(path) do |file|
        lexer = Lexer.new(file, path)
        parser = Parser.new(lexer)

        parser.parse do |node|
          @semantic.visit(node)
          collect(path, node)
        end
      end
    end

    private def collect(path : String, node : AST::Function)
      @functions[path] ||= [] of AST::Prototype
      @functions[path] << node.prototype
    end

    # private def collect(node : AST::Prototype)
    #   @externs[path] ||= [] of AST::Prototype
    #   @externs[path] << node.prototype
    # end

    private def collect(path : String, node : AST::Node)
    end
  end
end
