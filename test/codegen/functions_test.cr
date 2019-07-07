require "./test_helper"

class Runic::Codegen::FunctionsTest < Runic::CodegenTest
  def test_function_definition
    source = <<-RUNIC
    def runic_add(a : int, b : int)
      a + b
    end
    runic_add(1, 2)
    RUNIC
    assert_equal 3, execute(source)
  end
end
