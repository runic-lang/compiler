module Runic
  class Scope(T)
    class Values(T)
      getter parent : Values(T)?

      def initialize(@name : Symbol, @parent)
      end

      def []=(name : String, value : T)
        map[name] = value
      end

      def []?(name : String)
        map[name]?
      end

      private def map
        @map ||= {} of String => T
      end
    end

    def initialize
      @current = Values(T).new(:global, nil)
    end

    def push(name : Symbol)
      @current = Values(T).new(name, @current)
      begin
        yield
      ensure
        @current = @current.parent.not_nil!
      end
    end

    def fetch(name : String) : T
      @current[name] ||= yield
    end

    def get(name : String) : T?
      values = @current

      while values
        if value = values[name]?
          return value
        end
        values = values.parent
      end
    end

    def set(name : String, value : T) : T
      @current[name] = value
    end
  end
end
