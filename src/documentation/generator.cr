module Runic
  class Documentation
    abstract struct Generator
      def initialize(@output : String)
      end

      abstract def generate(program : Program)
    end
  end
end
