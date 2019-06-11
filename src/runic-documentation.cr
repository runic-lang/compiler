require "./config"
require "./documentation"
require "./documentation/html_generator"
require "./documentation/json_generator"
require "./documentation/yaml_generator"

output = "doc"
sources = [] of String
format = "html"

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
  when "-o", .starts_with?("--output")
    argument_value(output, "--output")
  when "-f", .starts_with?("--format")
    argument_value(format, "--format")
  when "--help"
    Runic.open_manpage("documentation")
  else
    if arg.starts_with?('-')
      abort "Unknown option: #{arg}"
    else
      sources << arg
    end
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
  abort "fatal : unsupported format '#{format}'"
end

begin
  rdoc = Runic::Documentation.new(sources)
  rdoc.generate(generator_class.new(output))
rescue error : Runic::SyntaxError
  error.pretty_report(STDERR)
rescue error : Runic::SemanticError
  error.pretty_report(STDERR)
end
