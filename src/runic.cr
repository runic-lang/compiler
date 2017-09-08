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
          STDERR.puts "Unknown option: #{arg}"
          exit 1
        else
          return {arg, args[(index + 1)..-1]}
        end
      end
    end

    raise "unreachable"
  end

  def self.print_help_message
    STDERR.puts <<-EOF
    usage : runic [--version] [--help]

    Some available commands are:
       lex   Lexes source then prints tokens
       ast   Parses source then prints AST
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
  STDERR.puts "runic : '#{command}' is not a runic command. See 'runic help'."
end
