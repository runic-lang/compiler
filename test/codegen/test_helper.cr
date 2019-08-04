require "../test_helper"
require "../../src/codegen"

LLVM.init_native

module Runic
  class CodegenTest < Minitest::Test
    def setup
      require_corelib
    end

    protected def execute(source : String)
      # function to wrap the expression(s)
      prototype = AST::Prototype.new("__anon_expr", [] of AST::Argument, nil, "", Location.new("<test>"))
      body = AST::Body.new([] of AST::Node, Location.new("<test>"))
      main = AST::Function.new(prototype, [] of String, body, Location.new("<test>"))

      # parse + analysis + codegen of expression(s)
      parse_each(source) do |node|
        case node
        when AST::ConstantDefinition, AST::Function, AST::Struct
          program.register(node)
        else
          main.body << node
          next
        end

        semantic.visit(node)
        generator.codegen(node)
      end

      # analysis + codegen wrap function
      semantic.visit(main)
      func = generator.codegen(main)

      # JIT execution + return primitive result
      begin
        case main.type.name
        when "bool" then return generator.execute(true, func)
        when "i8" then return generator.execute(1_i8, func)
        when "i16" then return generator.execute(1_i16, func)
        when "i32" then return generator.execute(1_i32, func)
        when "i64" then return generator.execute(1_i64, func)
        when "i128" then return generator.execute(1_i128, func)
        when "u8" then return generator.execute(1_u8, func)
        when "u16" then return generator.execute(1_u16, func)
        when "u32" then return generator.execute(1_u32, func)
        when "u64" then return generator.execute(1_u64, func)
        when "u128" then return generator.execute(1_u128, func)
        when "f32" then return generator.execute(1_f32, func)
        when "f64" then return generator.execute(1_f64, func)
        else raise "unsupported return type '#{main.type}' (yet)"
        end
      ensure
        # clear the wrap function from JIT execution
        LibC.LLVMDeleteFunction(func)
      end
    end

    private def program
      @program ||= Program.new
    end

    private def semantic
      @semantic ||= Semantic.new(program)
    end

    private def generator
      @codegen ||= Codegen.new(debug: DebugLevel::None, optimize: true)
    end

    private def require_corelib
      super
      program.each { |node| generator.codegen(node) }
    end
  end
end
