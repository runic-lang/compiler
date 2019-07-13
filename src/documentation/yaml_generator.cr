require "yaml"

module Runic
  class Documentation
    struct YAMLGenerator < Generator
      def generate(program : Program)
        document do |yaml|
          # TODO: constants
          # TODO: externs

          yaml.scalar "functions"
          program.functions.each do |_, node|
            generate(yaml, node)
          end

          yaml.scalar "structs"
          yaml.sequence do
            program.structs.each do |_, node|
              generate(yaml, node)
            end
          end
        end
      end

      private def document
        File.open(File.join(@output, "index.yaml"), "w") do |file|
          YAML.build(file) do |yaml|
            yaml.mapping { yield yaml }
          end
        end
      end

      private def generate(yaml : YAML::Builder, node : AST::Struct)
        yaml.mapping do
          yaml.scalar "name"
          yaml.scalar node.name

          sequence(yaml, "attributes", node.attributes) do |name|
            yaml.scalar name
          end

          sequence(yaml, "methods", node.methods) do |fn|
            generate(yaml, fn)
          end

          yaml.scalar "location"
          yaml.scalar node.location.to_s

          yaml.scalar "documentation"
          yaml.scalar node.documentation
        end
      end

      private def generate(yaml : YAML::Builder, fn : AST::Function)
        yaml.mapping do
          yaml.scalar "name"
          yaml.scalar fn.original_name

          sequence(yaml, "attributes", fn.attributes) do |name|
            yaml.scalar name
          end

          sequence(yaml, "arguments", fn.args) do |arg, index|
            next if index == 0 && arg.name == "self"
            yaml.mapping do
              yaml.scalar arg.name
              yaml.scalar arg.type.to_s
            end
          end

          yaml.scalar "return"
          yaml.scalar fn.type.to_s

          yaml.scalar "location"
          yaml.scalar fn.location.to_s

          yaml.scalar "documentation"
          yaml.scalar fn.prototype.documentation
        end
      end

      private def sequence(yaml : YAML::Builder, name, sequence : Enumerable)
        yaml.scalar name
        yaml.sequence do
          sequence.each_with_index do |value, index|
            yield value, index
          end
        end
      end
    end
  end
end
