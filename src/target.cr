module Runic
  struct Target
    getter triple : String
    getter architecture : String
    getter system : String
    getter version : String
    getter environment : String

    def initialize(triple : String, @cpu = "", @features = "")
      @triple = triple.downcase

      parts = @triple.split('-')
      @architecture = parts[0]

      case parts.size
      when 4
        @system = parts[2]
        @version = ""
        @environment = parts[3]
      when 3
        # NOTE: consider a whitelist (linux, windows, ...)
        if parts[1] == "unknown" || parts[1] == "none" || parts[1] == "apple"
          @system, @version = parse_system(parts[2])
          @environment = ""
        else
          @system = parts[1]
          @version = ""
          @environment = parts[2]
        end
      when 2
        @system, @version = parse_system(parts[1])
        @environment = ""
      else
        raise "unsupported target triple: #{@triple}"
      end
    end

    private def parse_system(string : String)
      index = 0
      string.each_char do |char|
        break unless ('a'..'z').includes?(char)
        index += 1
      end

      system = string[0...index]
      system = "darwin" if system == "macosx"

      {system, string[index..-1]}
    end

    def features
      # Enables conservative FPU for hard-float capable ARM targets (unless
      # CPU or a FPU is already defined:
      if architecture.starts_with?("arm") && environment.ends_with?("eabihf") && @cpu.empty? && !@features.includes?("fp")
        "+vfp2#{@features}"
      else
        @features
      end
    end

    def to_flags
      flags = Set(String).new

      case architecture
      when "amd64", "x86_64"
        flags << "X86_64"
      when "arm64", "aarch64"
        flags << "AARCH64"
      when "i386", "i486", "i586", "i686"
        flags << "X86"
      else
        flags << architecture.upcase

        if architecture.starts_with?("arm")
          flags << "ARM"
          flags << "ARMHF" if environment.ends_with?("eabihf")
        end
      end

      flags << system.upcase
      case system
      when "darwin", "freebsd", "linux", "openbsd"
        flags << "UNIX"
      when "windows"
        flags << "WIN32" if environment == "msvc" || environment == "gnu"
      when "ios"
        flags << "DARWIN"
      end

      unless environment.empty?
        flags << environment.upcase

        case environment
        when .starts_with?("gnu")
          flags << "GNU"
        when .starts_with?("musl")
          flags << "MUSL"
        when .starts_with?("android")
          flags << "ANDROID"
        when "cygnus"
          flags << "UNIX"
        end
      end

      flags
    end
  end
end
