require "./cli"
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

cli = Runic::CLI.new
cli.parse do |arg|
  case arg
  when "-o", "--output"
    output = cli.argument_value("--output")
  when .starts_with?("--target")
    target_triple = cli.argument_value("--target")
  when .starts_with?("--cpu")
    cpu = cli.argument_value("--cpu")
  when .starts_with?("--features")
    features = cli.argument_value("--features")
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
    emit = cli.argument_value("--emit")
  when .starts_with?("--corelib")
    corelib = cli.argument_value("--corelib")
  when .starts_with?("--no-corelib")
    corelib = nil
  when "--version", "version"
    cli.report_version("runic-compile")
  when "--help"
    Runic.open_manpage("compile")
  else
    filenames << cli.filename
  end
end

begin
  if filenames.empty?
    cli.fatal "no input file."
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
      cli.fatal "no such file or directory '#{filename}'."
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
