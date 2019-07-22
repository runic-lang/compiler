require "minitest/autorun"
require "../src/mangler"

module Runic
  class ManglerTest < Minitest::Test
    def test_mangle_global_functions
      assert_mangle "_Z5myFunv", "myFun"
      assert_mangle "_Z5myFunb", "myFun", ["bool"]
      assert_mangle "_Z5myFunasixn", "myFun", ["i8", "i16", "i32", "i64", "i128"]
      assert_mangle "_Z5myFunhtjyo", "myFun", ["u8", "u16", "u32", "u64", "u128"]
      assert_mangle "_Z5myFunfd", "myFun", ["f32", "f64"]
      assert_mangle "_Z5myFuni6MyType9OtherType", "myFun", ["i32", "MyType", "OtherType"]
      assert_mangle "_Z9incrementPix", "increment", ["i32*", "i64"]
    end

    def test_mangle_namespaced_functions
      assert_mangle "_ZN2NS5myFunEv", "NS::myFun"
      assert_mangle "_ZN2NS5myFunEfd", "NS::myFun", ["f32", "f64"]
      assert_mangle "_ZN2NS5myFunEN2NS6MyTypeE", "NS::myFun", ["NS::MyType"]
      assert_mangle "_ZN4Some6Nested3funEiN2NS6MyTypeEj", "Some::Nested::fun", ["i32", "NS::MyType", "u32"]
    end

    def test_mangle_operators
      assert_mangle "_ZN3i32plEii", "i32::+", ["i32", "i32"]
      assert_mangle "_ZN3i32geEii", "i32::>=", ["i32", "i32"]
      assert_mangle "_ZN4i128ltEni", "i128::<", ["i128", "i32"]
      #assert_mangle "_ZN3Sys4FilenwEv", "Sys::File::new"
    end

    def assert_mangle(expected, fn_name, fn_args = [] of String)
      location = Location.new("")
      args = fn_args.map { |type| AST::Argument.new("", Type.new(type), nil, location) }
      prototype = AST::Prototype.new(fn_name, args, "void", "", location)
      assert_equal expected, Mangler.mangle(prototype)
    end
  end
end
