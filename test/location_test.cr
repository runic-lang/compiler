require "minitest/autorun"
require "../src/location"

module Runic
  class LocationTest < Minitest::Test
    def test_new
      location = Location.new("/path/to/some/file.runic")
      assert_equal "/path/to/some/file.runic", location.file
      assert_equal 1, location.line
      assert_equal 1, location.column

      location.increment_column
      assert_equal 1, location.line
      assert_equal 2, location.column

      location.increment_column
      location.increment_column
      assert_equal 1, location.line
      assert_equal 4, location.column

      location.increment_line
      assert_equal 2, location.line
      assert_equal 1, location.column

      location.increment_line
      location.increment_line
      assert_equal 4, location.line
      assert_equal 1, location.column
    end
  end
end
