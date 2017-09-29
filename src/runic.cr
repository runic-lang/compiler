require "./version"

module Runic
  def self.root
    File.expand_path("../..", Process.executable_path.not_nil!)
  end

  def self.libexec
    File.join(root, "libexec")
  end

  def self.process_options(args)
    if args.empty?
      print_help_message
      exit 0
    end

    args.each_with_index do |arg, index|
      case arg
      when "--version", "version"
        puts "runic version #{version_string}"
        exit 0
      when "--help", "help"
        print_help_message
        exit 0
      else
        if arg.starts_with?('-')
          abort "Unknown option: #{arg}"
        else
          return {aliased(arg), args[(index + 1)..-1]}
        end
      end
    end

    raise "unreachable"
  end

  private def self.aliased(command)
    case command
    when "c" then "compile"
    when "i" then "interactive"
    else command
    end
  end

  def self.print_help_message
    STDERR.puts <<-EOF
    usage : runic [--version] [--help]

    Some available commands are:
       compile       Compiles runic source into .o object files (or .ll LLVM IR)
       interactive   Runs an interactive session
       lex           Lexes source then prints tokens
       ast           Parses source then prints AST
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
