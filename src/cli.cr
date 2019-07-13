require "./version"

module Runic
  class CLI
    def initialize
      @filenames = [] of String
      @index = -1
      @argument = ""
    end

    def parse
      while argument = consume?
        @argument = argument
        yield @argument
      end
    end

    def consume?
      ARGV[@index += 1]?
    end

    def remaining_arguments
      ARGV[(@index + 1)..-1]
    end

    def argument_value(name)
      if pos = ARGV[@index].index('=')
        return ARGV[@index][(pos + 1)..-1]
      end

      if value = ARGV[@index += 1]?
        return value unless value.starts_with?('-')
      end

      abort "fatal : missing value for {{name.id}}"
    end

    def filename
      if @argument.starts_with?('-')
        unknown_option!
      else
        @argument
      end
    end

    def unknown_option!
      abort "Unknown option: #{@argument}"
    end

    def report_version(name : String)
      puts "#{name} version #{Runic.version_string}"
      exit 0
    end

    def fatal(message)
      abort "fatal : #{message}"
    end
  end
end
