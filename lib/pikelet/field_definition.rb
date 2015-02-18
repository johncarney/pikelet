module Pikelet
  class FieldDefinition
    attr_reader :index, :parser, :width

    def initialize(index, parse: nil, &block)
      raise ArgumentError, "index must be a range" unless index.is_a? Range
      @index = index
      @width = index.size
      @parser = parse || block || :strip
      @parser = @parser.to_proc unless @parser.respond_to? :call
    end

    def parse(record)
      if value = record[index]
        parser.call(value)
      end
    end

    def format(value)
      pad(truncate(value))
    end

    def insert(value, record)
      record[index] = format(value)
      record
    end

    private

    def truncate(value)
      value.to_s[0...width]
    end

    def pad(value)
      (" " * (width - value.size)) + value
    end
  end
end
