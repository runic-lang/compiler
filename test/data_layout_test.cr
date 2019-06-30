require "./test_helper"
require "../src/data_layout"

module Runic
  class DataLayoutTest < Minitest::Test
    def test_x86_64_linux_gnu
      layout = DataLayout.parse("e-m:e-i64:64-f80:128-n8:16:32:64-S128")
      assert layout.little_endian?
      assert layout.mangling.elf?
      assert_equal DataLayout::PointerAlign.new(0, 8, 8, 8, 8), layout.pointer_align
      assert_equal DataLayout::Align.new(:integer, 8, 1, 1), layout.alignment(:integer, 8)
      assert_equal DataLayout::Align.new(:integer, 16, 2, 2), layout.alignment(:integer, 16)
      assert_equal DataLayout::Align.new(:integer, 32, 4, 4), layout.alignment(:integer, 32)
      assert_equal DataLayout::Align.new(:integer, 64, 8, 8), layout.alignment(:integer, 64)
      assert_equal DataLayout::Align.new(:float, 80, 16, 16), layout.alignment(:float, 80)
      assert_equal [8, 16, 32, 64], layout.native_integers
      assert_equal 16, layout.stack_natural_align
    end

    def test_x86_64_macosx_darwin
      layout = DataLayout.parse("e-m:o-i64:64-f80:128-n8:16:32:64-S128")
      assert layout.mangling.mach_o?
    end

    def test_x86_64_windows_win32
      layout = DataLayout.parse("e-m:w-i64:64-f80:128-n8:16:32:64-S128")
      assert layout.mangling.win_coff?
    end

    def test_i686_linux_gnu
      layout = DataLayout.parse("e-m:e-p:32:32-f64:32:64-f80:32-n8:16:32-S128")
      assert layout.mangling.elf?
      assert_equal DataLayout::PointerAlign.new(0, 4, 4, 4, 4), layout.pointer_align
      assert_equal DataLayout::Align.new(:integer, 8, 1, 1), layout.alignment(:integer, 8)
      assert_equal DataLayout::Align.new(:integer, 16, 2, 2), layout.alignment(:integer, 16)
      assert_equal DataLayout::Align.new(:integer, 32, 4, 4), layout.alignment(:integer, 32)
      assert_equal DataLayout::Align.new(:integer, 64, 4, 8), layout.alignment(:integer, 64)
      assert_equal DataLayout::Align.new(:float, 64, 4, 8), layout.alignment(:float, 64)
      assert_equal DataLayout::Align.new(:float, 80, 4, 4), layout.alignment(:float, 80)
      assert_equal [8, 16, 32], layout.native_integers
      assert_equal 16, layout.stack_natural_align
    end

    def test_i686_windows_win32
      layout = DataLayout.parse("e-m:x-p:32:32-i64:64-f80:32-n8:16:32-S32")
      assert layout.mangling.win_coffx86?
      assert_equal DataLayout::PointerAlign.new(0, 4, 4, 4, 4), layout.pointer_align
      assert_equal DataLayout::Align.new(:integer, 8, 1, 1), layout.alignment(:integer, 8)
      assert_equal DataLayout::Align.new(:integer, 16, 2, 2), layout.alignment(:integer, 16)
      assert_equal DataLayout::Align.new(:integer, 32, 4, 4), layout.alignment(:integer, 32)
      assert_equal DataLayout::Align.new(:integer, 64, 8, 8), layout.alignment(:integer, 64)
      assert_equal DataLayout::Align.new(:float, 64, 4, 8), layout.alignment(:float, 64)
      assert_equal DataLayout::Align.new(:float, 80, 4, 4), layout.alignment(:float, 80)
      assert_equal [8, 16, 32], layout.native_integers
      assert_equal 4, layout.stack_natural_align
    end

    def test_arm_linux_gnueabi
      layout = DataLayout.parse("e-m:e-p:32:32-i64:64-v128:64:128-a:0:32-n32-S64")
      assert_equal DataLayout::PointerAlign.new(0, 4, 4, 4, 4), layout.pointer_align
      assert_equal DataLayout::Align.new(:integer, 8, 1, 1), layout.alignment(:integer, 8)
      assert_equal DataLayout::Align.new(:integer, 16, 2, 2), layout.alignment(:integer, 16)
      assert_equal DataLayout::Align.new(:integer, 32, 4, 4), layout.alignment(:integer, 32)
      assert_equal DataLayout::Align.new(:integer, 64, 8, 8), layout.alignment(:integer, 64)
      assert_equal DataLayout::Align.new(:float, 64, 4, 8), layout.alignment(:float, 64)
      assert_equal DataLayout::Align.new(:vector, 128, 8, 16), layout.alignment(:vector, 128)
      assert_equal DataLayout::Align.new(:aggregate, 0, 0, 4), layout.alignment(:aggregate, 0)
      assert_equal [32], layout.native_integers
      assert_equal 8, layout.stack_natural_align
    end

    def test_aarch64_linux_gnu
      layout = DataLayout.parse("e-m:e-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128")
      assert_equal DataLayout::PointerAlign.new(0, 8, 8, 8, 8), layout.pointer_align
      assert_equal DataLayout::Align.new(:integer, 8, 1, 4), layout.alignment(:integer, 8)
      assert_equal DataLayout::Align.new(:integer, 16, 2, 4), layout.alignment(:integer, 16)
      assert_equal DataLayout::Align.new(:integer, 32, 4, 4), layout.alignment(:integer, 32)
      assert_equal DataLayout::Align.new(:integer, 64, 8, 8), layout.alignment(:integer, 64)
      assert_equal DataLayout::Align.new(:integer, 128, 16, 16), layout.alignment(:integer, 128)
      assert_equal DataLayout::Align.new(:float, 64, 4, 8), layout.alignment(:float, 64)
      assert_equal [32, 64], layout.native_integers
      assert_equal 16, layout.stack_natural_align
    end

    def test_mips_linux_gnu
      layout = DataLayout.parse("E-m:m-p:32:32-i8:8:32-i16:16:32-i64:64-n32-S64")
      assert layout.big_endian?
      assert layout.mangling.mips?
      assert_equal DataLayout::PointerAlign.new(0, 4, 4, 4, 4), layout.pointer_align
      assert_equal DataLayout::Align.new(:integer, 8, 1, 4), layout.alignment(:integer, 8)
      assert_equal DataLayout::Align.new(:integer, 16, 2, 4), layout.alignment(:integer, 16)
      assert_equal DataLayout::Align.new(:integer, 32, 4, 4), layout.alignment(:integer, 32)
      assert_equal DataLayout::Align.new(:integer, 64, 8, 8), layout.alignment(:integer, 64)
      assert_equal [32], layout.native_integers
      assert_equal 8, layout.stack_natural_align
    end

    def test_mipsel_linux_gnu
      layout = DataLayout.parse("e-m:m-p:32:32-i8:8:32-i16:16:32-i64:64-n32-S64")
      assert layout.little_endian?
      assert layout.mangling.mips?
    end

    def test_mips64_linux_gnuabi64
      layout = DataLayout.parse("E-m:e-i8:8:32-i16:16:32-i64:64-n32:64-S128")
      assert layout.big_endian?
      assert layout.mangling.elf?
      assert_equal DataLayout::PointerAlign.new(0, 8, 8, 8, 8), layout.pointer_align
      assert_equal DataLayout::Align.new(:integer, 8, 1, 4), layout.alignment(:integer, 8)
      assert_equal DataLayout::Align.new(:integer, 16, 2, 4), layout.alignment(:integer, 16)
      assert_equal DataLayout::Align.new(:integer, 32, 4, 4), layout.alignment(:integer, 32)
      assert_equal DataLayout::Align.new(:integer, 64, 8, 8), layout.alignment(:integer, 64)
      assert_equal [32, 64], layout.native_integers
      assert_equal 16, layout.stack_natural_align
    end
  end
end
