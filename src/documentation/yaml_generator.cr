require "yaml"

module Runic
  class Documentation
    struct YAMLGenerator < Generator
      def generate(file : String, functions : Array(AST::Prototype))
        output = File.basename(file, ".runic") + ".yaml"

        document(output) do |yaml|
          yaml.scalar "functions"
          yaml.sequence do
            functions.each do |proto|
              generate(yaml, proto)
            end
          end
        end
      end

      private def document(output)
        path = File.join(@output, output)

        File.open(path, "w") do |file|
          YAML.build(file) do |yaml|
            yaml.mapping { yield yaml }
          end
        end
      end

      private def generate(yaml : YAML::Builder, proto : AST::Prototype)
        yaml.mapping do
          yaml.scalar "name"
          yaml.scalar proto.name

          yaml.scalar "arguments"
          yaml.sequence do
            proto.args.each do |arg|
              yaml.mapping do
                yaml.scalar arg.name
                yaml.scalar arg.type.to_s
              end
            end
          end

          yaml.scalar "return"
          yaml.scalar proto.type.to_s

          yaml.scalar "location"
          yaml.scalar proto.location.to_s

          yaml.scalar "documentation"
          yaml.scalar proto.documentation
        end
      end
    end
  end
end
