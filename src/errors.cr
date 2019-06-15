require "colorize"
require "./ast"

module Runic
  class Error < Exception
    def original_message
      @message
    end

    def pretty_report(io : IO, source = false)
      io.print "#{self.class.name[7..-1]}: #{original_message}\n".colorize(:yellow).mode(:bold)
      return unless source

      io.print "\nat #{location}\n\n"

      File.open(location.file) do |source|
        # skip previous lines
        (location.line - 2).times { source.gets }

        # print source line
        prefix = " #{location.line} | "
        io.print prefix.colorize(:dark_gray)
        io.print source.gets(chomp: false)

        # print ^ location pointer
        (prefix.size + location.column - 1).times { io.print ' ' }
        io.print "^\n".colorize(:green).mode(:bold)
        io.print "\n"
      end
    end
  end

  class ParseError < Error
    getter location : Location

    def self.new(message, node : AST::Node)
      new(message, node.location)
    end

    def initialize(@message, @location)
    end

    def message
      "#{@message} at #{@location}"
    end
  end

  class SyntaxError < Error
    getter location : Location

    def self.new(message, node : AST::Node)
      new(message, node.location)
    end

    def initialize(@message, @location)
    end

    def message
      "#{@message} at #{@location}"
    end
  end

  class SemanticError < Error
    getter location : Location

    def self.new(message, node : AST::Node)
      new(message, node.location)
    end

    def initialize(@message, @location)
    end

    def message
      "#{@message} at #{@location}"
    end
  end

  class CodegenError < Error
  end

  class ConflictError < Error
    getter original_location : Location
    getter location : Location

    def initialize(@message, @original_location, @location)
    end

    def message
      "#{@message} at #{@location} (previous at #{@original_location})"
    end
  end
end
