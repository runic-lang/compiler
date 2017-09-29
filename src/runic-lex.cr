require "./lexer"
require "./version"

module Runic
  module Command
    struct Lex
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
    STDERR.puts "<todo: lex command help message>"
    exit 0
  else
    if arg.starts_with?('-')
      abort "Unknown option: #{arg}"
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
    abort "fatal : no such file or directory '#{filename}'"
  end
else
  abort "fatal : you may only specify one file to parse."
end
