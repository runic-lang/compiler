require "minitest/autorun"
require "../src/target"

module Runic
  class TargetTest < Minitest::Test
    def test_parses_x86_architectures
      target = Target.new("i386-unknown-linux-gnu")
      assert_equal "i386", target.architecture
      assert_includes target.to_flags, "X86"

      target = Target.new("i486-unknown-linux-gnu")
      assert_equal "i486", target.architecture
      assert_includes target.to_flags, "X86"

      target = Target.new("i586-unknown-linux-gnu")
      assert_equal "i586", target.architecture
      assert_includes target.to_flags, "X86"

      target = Target.new("i686-unknown-linux-gnu")
      assert_equal "i686", target.architecture
      assert_includes target.to_flags, "X86"

      target = Target.new("x86_64-unknown-linux-gnu")
      assert_equal "x86_64", target.architecture
      assert_includes target.to_flags, "X86_64"

      target = Target.new("amd64-unknown-linux-gnu")
      assert_equal "amd64", target.architecture
      assert_includes target.to_flags, "X86_64"
    end

    def test_parses_arm_architectures
      target = Target.new("arm-unknown-linux-gnu")
      assert_equal "arm", target.architecture
      assert_includes target.to_flags, "ARM"

      target = Target.new("armv7-unknown-linux-gnu")
      assert_equal "armv7", target.architecture
      assert_includes target.to_flags, "ARM"
      assert_includes target.to_flags, "ARMV7"

      target = Target.new("aarch64-unknown-linux-gnu")
      assert_equal "aarch64", target.architecture
      assert_includes target.to_flags, "AARCH64"

      target = Target.new("arm64-apple-ios")
      assert_equal "arm64", target.architecture
      assert_includes target.to_flags, "AARCH64"
    end

    def test_enables_fpu_for_arm_targets
      # not enabled for soft-float environment:
      target = Target.new("arm-linux-gnueabi")
      refute_includes target.features, "+vfp2"

      target = Target.new("arm-linux-musleabi")
      refute_includes target.features, "+vfp2"

      # enabled for harf-float environments:
      target = Target.new("arm-linux-gnueabihf")
      assert_includes target.features, "+vfp2"

      target = Target.new("armv6z-linux-musleabihf")
      assert_includes target.features, "+vfp2"

      target = Target.new("arm-linux-androideabihf")
      assert_includes target.features, "+vfp2"

      # not enabled if CPU is specified (LLVM will select better FPU):
      target = Target.new("armv6z-linux-gnueabihf", "arm1176jzf-s")
      refute_includes target.features, "+vfp2"

      # not enabled if an FPU is specified:
      target = Target.new("armv6z-linux-gnueabihf", "", "+vfp4")
      refute_includes target.features, "+vfp2"
      assert_includes target.features, "+vfp4"
    end

    def test_parses_linux_targets
      target = Target.new("i386-pc-linux-gnu")
      assert_equal "linux", target.system
      assert_equal "gnu", target.environment
      assert_includes target.to_flags, "LINUX"
      assert_includes target.to_flags, "GNU"

      target = Target.new("x86_64-unknown-linux-gnu")
      assert_equal "linux", target.system
      assert_equal "gnu", target.environment
      assert_includes target.to_flags, "LINUX"
      assert_includes target.to_flags, "GNU"

      target = Target.new("arm-linux-musleabi")
      assert_equal "linux", target.system
      assert_equal "musleabi", target.environment
      assert_includes target.to_flags, "LINUX"
      assert_includes target.to_flags, "MUSL"
      assert_includes target.to_flags, "MUSLEABI"

      target = Target.new("arm-linux-musleabihf")
      assert_equal "linux", target.system
      assert_equal "musleabihf", target.environment
      assert_includes target.to_flags, "ARMHF"
      assert_includes target.to_flags, "LINUX"
      assert_includes target.to_flags, "MUSL"
      assert_includes target.to_flags, "MUSLEABIHF"

      target = Target.new("armv7-unknown-linux-gnueabi")
      assert_equal "linux", target.system
      assert_equal "gnueabi", target.environment
      assert_includes target.to_flags, "LINUX"
      assert_includes target.to_flags, "GNU"
      assert_includes target.to_flags, "GNUEABI"

      target = Target.new("arm-unknown-linux-gnueabihf")
      assert_equal "linux", target.system
      assert_equal "gnueabihf", target.environment
      assert_includes target.to_flags, "ARMHF"
      assert_includes target.to_flags, "LINUX"
      assert_includes target.to_flags, "GNU"
      assert_includes target.to_flags, "GNUEABIHF"

      target = Target.new("aarch64-unknown-linux-gnu")
      assert_equal "linux", target.system
      assert_equal "gnu", target.environment
      assert_includes target.to_flags, "LINUX"
      assert_includes target.to_flags, "GNU"
    end

    def test_parses_android_targets
      target = Target.new("arm64-unknown-linux-android")
      assert_equal "linux", target.system
      assert_equal "android", target.environment
      assert_includes target.to_flags, "LINUX"
      assert_includes target.to_flags, "ANDROID"

      target = Target.new("armv7-unknown-linux-androideabi")
      assert_equal "linux", target.system
      assert_equal "androideabi", target.environment
      assert_includes target.to_flags, "LINUX"
      assert_includes target.to_flags, "ANDROID"
      assert_includes target.to_flags, "ANDROIDEABI"
    end

    def test_parses_darwin_targets
      target = Target.new("i686-apple-macosx10.9")
      assert_equal "darwin", target.system
      assert_equal "10.9", target.version

      target = Target.new("x86_64-apple-darwin9")
      assert_equal "darwin", target.system
      assert_equal "9", target.version

      target = Target.new("armv7-apple-ios")
      assert_equal "ios", target.system
      assert_includes target.to_flags, "IOS"
      assert_includes target.to_flags, "DARWIN"
    end

    def test_parses_openbsd_targets
      target = Target.new("amd64-openbsd6.2")
      assert_equal "openbsd", target.system
      assert_equal "6.2", target.version
      assert_empty target.environment

      target = Target.new("i686-unknown-openbsd6.1")
      assert_equal "openbsd", target.system
      assert_equal "6.1", target.version
      assert_empty target.environment
    end

    def test_parses_freebsd_targets
      target = Target.new("i686-freebsd11.1")
      assert_equal "freebsd", target.system
      assert_equal "11.1", target.version
      assert_empty target.environment

      target = Target.new("x86_64-unknown-freebsd10.3")
      assert_equal "freebsd", target.system
      assert_equal "10.3", target.version
      assert_empty target.environment
    end

    def test_parses_windows_targets
      target = Target.new("i686-pc-windows-msvc")
      assert_equal "windows", target.system
      assert_equal "msvc", target.environment
      assert_includes target.to_flags, "WINDOWS"
      assert_includes target.to_flags, "MSVC"
      assert_includes target.to_flags, "WIN32"

      target = Target.new("i586-pc-windows-gnu")
      assert_equal "windows", target.system
      assert_equal "gnu", target.environment
      assert_includes target.to_flags, "WINDOWS"
      assert_includes target.to_flags, "GNU"
      assert_includes target.to_flags, "WIN32"

      target = Target.new("x86_64-windows-cygnus")
      assert_equal "windows", target.system
      assert_equal "cygnus", target.environment
      assert_includes target.to_flags, "WINDOWS"
      assert_includes target.to_flags, "CYGNUS"
      assert_includes target.to_flags, "UNIX"
    end
  end
end
