require "./codegen"
require "./parser"
require "./semantic"

module Runic
  struct Compiler
    getter target_triple : String
    getter cpu : String
    getter features : String
    @target : LibC::LLVMTargetRef?

    getter opt_level : LibC::LLVMCodeGenOptLevel
    getter reloc_mode : LibC::LLVMRelocMode
    getter code_model : LibC::LLVMCodeModel

    def initialize(
      target_triple = nil,
      @cpu = "generic",
      @features = "",
      @opt_level = LibC::LLVMCodeGenOptLevel::LLVMCodeGenLevelDefault,
      @reloc_mode = LibC::LLVMRelocMode::LLVMRelocPIC,
      @code_model = LibC::LLVMCodeModel::LLVMCodeModelDefault,
      @debug = DebugLevel::Default,
    )
      @target_triple = target_triple ||= String.new(LibC.LLVMGetDefaultTargetTriple())

      @semantic = Semantic.new
      @codegen = Codegen.new(
        debug: @debug,
        optimize: !opt_level.llvm_code_gen_level_none?
      )

      LLVM.init(target_triple)
      @codegen.target_triple = target_triple
      @codegen.data_layout = data_layout
    end

    def parse(io : IO, path : String) : Nil
      lexer = Lexer.new(io, path)
      parser = Parser.new(lexer)

      @codegen.path = path

      parser.parse do |node|
        @semantic.visit(node)
        @codegen.codegen(node)
      end
    end

    def emit_llvm(output : String) : Nil
      @codegen.emit_llvm(output)
    end

    def emit_object(output : String) : Nil
      @codegen.emit_object(target_machine, output)
    end

    def target
      @target ||= begin
        if LibC.LLVMGetTargetFromTriple(target_triple, out target, out err_msg) == 1
          msg = String.new(err_msg)
          LibC.LLVMDisposeMessage(err_msg)
          raise msg
        end
        target
      end
    end

    def target_machine
      @target_machine ||= LibC.LLVMCreateTargetMachine(target, target_triple, cpu, features, opt_level, reloc_mode, code_model)
    end

    def data_layout
      LibC.LLVMCreateTargetDataLayout(target_machine)
    end
  end
end
