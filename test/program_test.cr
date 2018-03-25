require "./test_helper"

module Runic
  class ProgramTest < Minitest::Test
    def test_register_constants
      node = register("FOO = 1").as(AST::Binary)
      assert_same node, program.resolve(AST::Constant.new("FOO", location))
    end

    private def register(source)
      parse_each("FOO = 1") do |node|
        program.register(node)
        return node
      end
    end

    private def program
      @program ||= Program.new
    end

    private def location
      Location.new("MEMORY")
    end
  end
end
