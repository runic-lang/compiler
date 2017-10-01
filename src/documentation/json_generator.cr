require "json"

module Runic
  class Documentation
    struct JSONGenerator < Generator
      def generate(file : String, functions : Array(AST::Prototype))
        output = File.basename(file, ".runic") + ".json"

        document(output) do |json|
          json.scalar "functions"
          json.array do
            functions.each do |proto|
              generate(json, proto)
            end
          end
        end
      end

      private def document(output)
        path = File.join(@output, output)

        File.open(path, "w") do |file|
          JSON.build(file) do |json|
            json.object { yield json }
          end
        end
      end

      private def generate(json : JSON::Builder, proto : AST::Prototype)
        json.object do
          json.scalar "name"
          json.scalar proto.name

          json.scalar "arguments"
          json.array do
            proto.args.each do |arg|
              json.object do
                json.scalar arg.name
                json.scalar arg.type.to_s
              end
            end
          end

          json.scalar "return"
          json.scalar proto.type.to_s

          json.scalar "location"
          json.scalar proto.location.to_s

          json.scalar "documentation"
          json.scalar proto.documentation
        end
      end
    end
  end
end
