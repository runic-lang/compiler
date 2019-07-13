require "./cli"
require "./config"

module Runic
  def self.process_options(args)
    if args.empty?
      print_help_message
      exit 0
    end

    cli = Runic::CLI.new

    cli.parse do |arg|
      case arg
      when "--version", "version"
        cli.report_version("runic")
        exit 0
      when "--help"
        print_help_message
        exit 0
      when "help"
        if command = cli.consume?
          open_manpage(aliased(command))
        else
          print_help_message
          exit 0
        end
      else
        if arg.starts_with?('-')
          cli.unknown_option!
        else
          return {aliased(arg), cli.remaining_arguments}
        end
      end
    end

    raise "unreachable"
  end

  private def self.aliased(command)
    case command
    when "c" then "compile"
    when "i" then "interactive"
    when "doc" then "documentation"
    else command
    end
  end

  def self.print_help_message
    STDERR.puts <<-EOF
    usage : runic [--version] [--help]

    Some available commands are:
       c[ompile]         Compiles runic source into .o object files (or .ll LLVM IR)
       i[nteractive]     Starts an interactive session
       doc[umentation]   Generates documentation

    You may type 'runic help <command>' to read about a specific command.
    EOF
  end
end

command, args = Runic.process_options(ARGV)
executable = File.join(Runic.libexec, "runic-#{command}")

if File.exists?(executable)
  Process.exec(executable, args, env: {
    "RUNIC_ROOT" => Runic.root,
    "PATH" => ":#{ENV["PATH"]}",
  })
else
  abort "runic : '#{command}' is not a runic command. See 'runic help'."
end
