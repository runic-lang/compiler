require "./test_helper"

module Runic
  class ProgramTest < Minitest::Test
    def test_register_constants
      node = register("FOO = 1").as(AST::ConstantDefinition)
      assert_same node, program.resolve(AST::Constant.new("FOO", location))
    end

    private def register(source)
      parse_each(source, top_level_expressions: false) do |node|
        program.register(node)
        return node
      end
    end

    private def location
      Location.new("MEMORY")
    end
  end
end
