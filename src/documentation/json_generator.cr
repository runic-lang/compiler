require "json"

module Runic
  class Documentation
    struct JSONGenerator < Generator
      def generate(program : Program)
        document do |json|
          # TODO: constants
          # TODO: externs

          json.scalar "functions"
          program.functions.each do |_, node|
            generate(json, node)
          end

          json.scalar "structs"
          program.structs.each do |_, node|
            generate(json, node)
          end
        end
      end

      private def document
        File.open(File.join(@output, "index.json"), "w") do |file|
          JSON.build(file) do |json|
            json.object { yield json }
          end
        end
      end

      private def generate(json : JSON::Builder, node : AST::Struct)
        json.object do
          json.scalar "name"
          json.scalar node.name

          array(json, "attributes", node.attributes) do |attribute|
            json.scalar attribute
          end

          array(json, "methods", node.methods) do |fn|
            generate(json, fn)
          end

          json.scalar "location"
          json.scalar node.location.to_s

          json.scalar "documentation"
          json.scalar node.documentation
        end
      end

      private def generate(json : JSON::Builder, fn : AST::Function)
        json.object do
          json.scalar "name"
          json.scalar fn.original_name

          array(json, "arguments", fn.args) do |arg, index|
            next if index == 0 && arg.name == "self"
            json.object do
              json.scalar arg.name
              json.scalar arg.type.to_s
            end
          end

          json.scalar "return"
          json.scalar fn.type.to_s

          json.scalar "location"
          json.scalar fn.location.to_s

          json.scalar "documentation"
          json.scalar fn.prototype.documentation
        end
      end

      private def array(json : JSON::Builder, name, array : Enumerable)
        json.scalar name
        json.array do
          array.each_with_index do |value, index|
            yield value, index
          end
        end
      end
    end
  end
end
