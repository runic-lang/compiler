module Runic
  class DataLayout
    enum Mangling
      None = 0
      ELF
      MachO
      Mips
      WinCOFF
      WinCOFFX86
    end

    enum Endian
      Big
      Little
    end

    enum AlignType
      Integer
      Float
      Vector
      Aggregate
    end

    record Align,
      type : AlignType,
      bit_size : Int32,
      abi_align : Int32,
      pref_align : Int32

    record PointerAlign,
      addr_space : Int32,
      abi_align : Int32,
      pref_align : Int32,
      mem_size : Int32,
      index_size : Int32

    def self.from(_module : LibC::LLVMModuleRef) : self
      ptr = LibC.LLVMGetDataLayoutStr(_module)
      parse(String.new(ptr))
    end

    def self.parse(layout : String) : self
      new.tap(&.parse(layout))
    end

    getter mangling
    getter pointer_align
    getter stack_natural_align
    getter native_integers

    def initialize
      @mangling = Mangling::None
      @endianess = Endian::Little
      @pointer_align = PointerAlign.new(0, 8, 8, 8, 8)
      @stack_natural_align = 0
      @native_integers = [] of Int32

      @alignments = [
        Align.new(AlignType::Integer, 1, 1, 1),    # i1
        Align.new(AlignType::Integer, 8, 1, 1),    # i8
        Align.new(AlignType::Integer, 16, 2, 2),   # i16
        Align.new(AlignType::Integer, 32, 4, 4),   # i32
        Align.new(AlignType::Integer, 64, 4, 8),   # i64
        Align.new(AlignType::Float, 16, 2, 2),     # half
        Align.new(AlignType::Float, 32, 4, 4),     # float
        Align.new(AlignType::Float, 64, 4, 8),     # double
        Align.new(AlignType::Float, 128, 16, 16),  # ppcf128, quad, ...
        Align.new(AlignType::Vector, 64, 8, 8),    # v2i32, v1i64, ...
        Align.new(AlignType::Vector, 128, 16, 16), # v16i8, v8i16, v4i32, ...
        Align.new(AlignType::Aggregate, 0, 0, 8)   # struct
      ]
    end

    def big_endian?
      @endianess.big?
    end

    def little_endian?
      @endianess.little?
    end

    def alignment(type : AlignType, bit_size : Int32) : Align
      align = @alignments.find { |align| align.type == type && align.bit_size == bit_size }
      raise "BUG: missing data layout align for #{type} at #{bit_size} bits" unless align
      align
    end

    def pointer_size_in_bits
      8_u64 * @pointer_align.mem_size
    end

    def parse(str : String) : Nil
      str.split('-') do |element|
        case element[0]
        when 'm'
          parse_mangling(element[2..-1])
        when 'E'
          @endianess = Endian::Big
        when 'e'
          @endianess = Endian::Little
        when 'p'
          parse_pointer_align(element[1..-1])
        when 'i'
          parse_align(AlignType::Integer, element[1..-1])
        when 'f'
          parse_align(AlignType::Float, element[1..-1])
        when 'v'
          parse_align(AlignType::Vector, element[1..-1])
        when 'a'
          parse_align(AlignType::Aggregate, element[1..-1])
        when 'n'
          element[1..-1].split(':') { |s| @native_integers << s.to_i }
        when 'S'
          @stack_natural_align = in_bytes(element[1..-1])
        else
          # shut up, crystal
        end
      end
    end

    private def parse_mangling(value)
      case value
      when "e" then @mangling = Mangling::ELF
      when "o" then @mangling = Mangling::MachO
      when "m" then @mangling = Mangling::Mips
      when "w" then @mangling = Mangling::WinCOFF
      when "x" then @mangling = Mangling::WinCOFFX86
      else          # shut up, crystal
      end
    end

    private def parse_pointer_align(str) : Nil
      values = str.split(':')

      addr_space = values[0].to_i? || 0
      mem_size = in_bytes(values[1])
      abi_align = in_bytes(values[2])

      if s = values[3]?
        pref_align = in_bytes(s)
      else
        pref_align = abi_align
      end

      if s = values[4]?
        index_size = in_bytes(s)
      else
        index_size = mem_size
      end

      @pointer_align = PointerAlign.new(addr_space, mem_size, abi_align, pref_align, index_size)
    end

    private def parse_align(type, str) : Nil
      values = str.split(':')
      size = values[0].to_i? || 0
      abi_align = in_bytes(values[1])

      if s = values[2]?
        pref_align = in_bytes(s)
      else
        pref_align = abi_align
      end

      index, align = find_alignment_lower_bound(type, size)

      if align.type == type && align.bit_size == size
        @alignments[index] = Align.new(type, size, abi_align, pref_align)
      else
        @alignments.insert(index, Align.new(type, size, abi_align, pref_align))
      end
    end

    private def find_alignment_lower_bound(type, bit_size)
      found = false

      @alignments.each_with_index do |align, index|
        if align.type == type
          return {index, align} if align.bit_size >= bit_size
          found = true
        elsif found
          return {index, align}
        end
      end

      raise "unreachable"
    end

    private def in_bytes(s : String)
      s.to_i // 8
    end
  end
end
