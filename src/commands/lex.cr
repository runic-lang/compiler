require "../lexer"
require "../version"

module Runic
  module Command
    struct Lex
      def self.print_help_message
        STDERR.puts "<todo: lex command help message>"
      end

      def initialize(io, filename)
        @lexer = Runic::Lexer.new(io, filename)
      end

      def run
        loop do
          token = @lexer.next
          break if token.type == :eof
          p token
        end
      end
    end
  end
end

filenames = [] of String

ARGV.each_with_index do |arg|
  case arg
  when "--version", "version"
    puts "runic-lex version #{Runic.version_string}"
    exit 0
  when "--help", "help"
    Runic::Command::Lex.print_help_message
    exit 0
  else
    if arg.starts_with?('-')
      STDERR.puts "Unknown option: #{arg}"
      exit 1
    else
      filenames << arg
    end
  end
end

case filenames.size
when 0
  STDERR.puts "reading from stdin..."
  Runic::Command::Lex.new(STDIN, "<stdin>").run
when 1
  filename = filenames.first

  if File.exists?(filename)
    File.open(filename, "r") do |io|
      Runic::Command::Lex.new(io, filename).run
    end
  else
    STDERR.puts "fatal: no such file or directory '#{filename}'"
    exit 1
  end
else
  STDERR.puts "fatal: you may only specify one file to parse."
  exit 1
end
