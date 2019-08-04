require "./cli"
require "./config"
require "./documentation"
require "./documentation/html_generator"
require "./documentation/json_generator"
require "./documentation/yaml_generator"

output = "doc"
sources = [] of String
format = "html"

cli = Runic::CLI.new
cli.parse do |arg|
  case arg
  when "-o", .starts_with?("--output")
    output = cli.argument_value("--output")
  when "-f", .starts_with?("--format")
    format = cli.argument_value("--format")
  when "--version"
    cli.report_version("runic-documentation")
  when "--help"
    Runic.open_manpage("documentation")
  else
    sources << cli.filename
  end
end

if sources.empty?
  sources << "src"
end

case format
when "html"
  generator_class = Runic::Documentation::HTMLGenerator
when "yaml"
  generator_class = Runic::Documentation::YAMLGenerator
when "json"
  generator_class = Runic::Documentation::JSONGenerator
else
  cli.fatal "unsupported format '#{format}'"
end

begin
  rdoc = Runic::Documentation.new(sources)
  rdoc.generate(generator_class.new(output))
rescue error : Runic::SyntaxError
  error.pretty_report(STDERR)
  exit 1
rescue error : Runic::SemanticError
  error.pretty_report(STDERR)
  exit 1
end
