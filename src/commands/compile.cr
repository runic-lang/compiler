require "../compiler"
require "../version"

module Runic
  module Command
    module Compile
      def self.print_help_message
        STDERR.puts "<todo: compile command help message>"
      end
    end
  end
end

filenames = [
  File.expand_path("../../src/intrinsics.runic", Process.executable_path)
]
output = nil
target_triple = nil
cpu = "generic"
features = ""
opt_level = LibC::LLVMCodeGenOptLevel::LLVMCodeGenLevelDefault
debug = Runic::DebugLevel::Default
emit = "object"

macro next_argument(name)
  if idx = ARGV[i].index('=')
    return ARGV[i][(idx + 1)..-1]
  elsif value = ARGV[i += 1]?
    return value unless value.starts_with?('-')
  end

  STDERR.puts "fatal: missing value for {{name.id}}"
  exit 1
end

i = -1
while arg = ARGV[i += 1]?
  case arg
  when "-o", "--output"
    output = next_argument("--output")
  when .starts_with?("--target")
    target_triple = next_argument("--target")
  when .starts_with?("--cpu")
    cpu = next_argument("--cpu")
  when .starts_with?("--features")
    features = next_argument("--features")
  when "-O0"
    opt_level = LibC::LLVMCodeGenOptLevel::LLVMCodeGenLevelNone
  when "-O1"
    opt_level = LibC::LLVMCodeGenOptLevel::LLVMCodeGenLevelLess
  when "-O2"
    opt_level = LibC::LLVMCodeGenOptLevel::LLVMCodeGenLevelDefault
  when "-O3"
    opt_level = LibC::LLVMCodeGenOptLevel::LLVMCodeGenLevelAggressive
  when "--debug"
    debug = Runic::DebugLevel::Full
  when "--no-debug"
    debug = Runic::DebugLevel::None
  when .starts_with?("--emit")
    emit = next_argument("--emit")
  when "--version", "version"
    puts "runic-compile version #{Runic.version_string}"
    exit 0
  when "--help", "help"
    Runic::Command::Compile.print_help_message
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

if filenames.size > 1
  compiler = Runic::Compiler.new(
    target_triple,
    cpu: cpu,
    features: features,
    opt_level: opt_level,
    debug: debug
  )

  filenames.each do |filename|
    if File.exists?(filename)
      File.open(filename, "r") do |io|
        compiler.parse(io, filename)
      end
    else
      STDERR.puts "fatal: no such file or directory '#{filename}'."
      exit 1
    end
  end

  case emit
  when "object"
    output ||= File.basename(filenames[1], File.extname(filenames[1])) + ".o"
    compiler.emit_object(output)
  when "llvm"
    output ||= File.basename(filenames[1], File.extname(filenames[1])) + ".ll"
    compiler.emit_llvm(output)
  else
    raise "unreachable"
  end
else
  STDERR.puts "fatal: no input file."
  exit 1
end
