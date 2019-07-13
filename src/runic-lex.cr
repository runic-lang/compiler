require "./cli"
require "./lexer"

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

cli = Runic::CLI.new
cli.parse do |arg|
  case arg
  when "--version", "version"
    cli.report_version("runic-lex")
  when "--help", "help"
    STDERR.puts "<todo: lex command help message>"
    exit 0
  else
    filenames << cli.filename
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
    cli.fatal "no such file or directory '#{filename}'"
  end
else
  cli.fatal "you may only specify one file to parse."
end
