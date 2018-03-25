require "./lexer"
require "./parser"
require "./semantic"
require "./documentation/generator"

module Runic
  class Documentation
    def initialize(@sources : Array(String))
      @program = Program.new
    end

    def generate(generator : Generator)
      parse
      generator.generate(@program)
    end

    def parse
      @sources.each do |source|
        if Dir.exists?(source)
          search_directory(source)
        elsif File.exists?(source)
          parse(source)
        else
          # STDERR.puts "ERROR: no such file or directory '#{source}'."
        end
      end

      Semantic.analyze(@program)
    end

    private def search_directory(path : String)
      Dir.open(path) do |dir|
        dir.each_child do |filename|
          if Dir.exists?(filename)
            search_directory File.join(path, filename)
          elsif filename.ends_with?(".runic")
            parse File.join(path, filename)
          else
            # STDERR.puts "WARN: skipping '#{filename}' in '#{path}'"
          end
        end
      end
    end

    private def parse(path : String)
      # STDERR.puts "parsing #{path}"

      File.open(path) do |file|
        lexer = Lexer.new(file, path)
        parser = Parser.new(lexer)
        parser.parse { |node| @program.register(node) }
      end
    end
  end
end
