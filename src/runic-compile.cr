require "./compiler"
require "./config"

filenames = [
  File.expand_path("../../src/intrinsics.runic", Process.executable_path)
]
output = nil
target_triple = nil
cpu = "generic"
features = ""
opt_level = LibC::LLVMCodeGenOptLevel::CodeGenLevelDefault
debug = Runic::DebugLevel::Default
emit = "object"

macro argument_value(var, name)
  if idx = ARGV[i].index('=')
    {{var}} = ARGV[i][(idx + 1)..-1]
  elsif value = ARGV[i += 1]?
    {{var}} = value unless value.starts_with?('-')
  else
    abort "fatal : missing value for {{name.id}}"
  end
end

i = -1
while arg = ARGV[i += 1]?
  case arg
  when "-o", "--output"
    argument_value(output, "--output")
  when .starts_with?("--target")
    argument_value(target_triple, "--target")
  when .starts_with?("--cpu")
    argument_value(cpu, "--cpu")
  when .starts_with?("--features")
    argument_value(features, "--features")
  when "-O0"
    opt_level = LibC::LLVMCodeGenOptLevel::CodeGenLevelNone
  when "-O1"
    opt_level = LibC::LLVMCodeGenOptLevel::CodeGenLevelLess
  when "-O", "-O2"
    opt_level = LibC::LLVMCodeGenOptLevel::CodeGenLevelDefault
  when "-O3"
    opt_level = LibC::LLVMCodeGenOptLevel::CodeGenLevelAggressive
  when "-g", "--debug"
    debug = Runic::DebugLevel::Full
  when "--no-debug"
    debug = Runic::DebugLevel::None
  when .starts_with?("--emit")
    argument_value(emit, "--emit")
  when "--help"
    Runic.open_manpage("compile")
  else
    if arg.starts_with?('-')
      abort "Unknown option: #{arg}"
    else
      filenames << arg
    end
  end
end

begin
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
        abort "fatal : no such file or directory '#{filename}'."
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
      abort "Unknown emit option '#{emit}'."
    end
  else
    abort "fatal : no input file."
  end

  rescue error : Runic::SyntaxError
    error.pretty_report(STDERR)

  rescue error : Runic::SemanticError
    error.pretty_report(STDERR)

  # rescue error : Runic::CodegenError
end
