require "./compiler"
require "./config"

filenames = [] of String
output = nil
target_triple = nil
cpu = "generic"
features = ""
opt_level = LibC::LLVMCodeGenOptLevel::CodeGenLevelDefault
debug = Runic::DebugLevel::Default
emit = "object"
corelib = Runic.corelib

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
  when .starts_with?("--corelib")
    argument_value(corelib, "--corelib")
    corelib = nil if corelib = "none"
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
  if filenames.empty?
    abort "fatal : no input file."
  end

  filename = filenames.first

  compiler = Runic::Compiler.new(
    target_triple,
    cpu: cpu,
    features: features,
    opt_level: opt_level,
    debug: debug
  )

  if corelib
    corelib = "#{corelib}.runic" unless corelib.ends_with?(".runic")
    compiler.parse(corelib)
  end

  filenames.each do |filename|
    if File.exists?(filename)
      compiler.parse(filename)
    else
      abort "fatal : no such file or directory '#{filename}'."
    end
  end

  compiler.analyze
  compiler.codegen(filename)

  case emit
  when "object"
    output ||= File.basename(filename, File.extname(filename)) + ".o"
    compiler.emit_object(output)
  when "llvm"
    output ||= File.basename(filename, File.extname(filename)) + ".ll"
    compiler.emit_llvm(output)
  else
    abort "Unknown emit option '#{emit}'."
  end

  rescue error : Runic::SyntaxError
    error.pretty_report(STDERR)

  rescue error : Runic::SemanticError
    error.pretty_report(STDERR)

  # rescue error : Runic::CodegenError
end
