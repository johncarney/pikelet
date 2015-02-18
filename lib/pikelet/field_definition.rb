module Pikelet
  class FieldDefinition
    attr_reader :index, :parser, :width

    def initialize(index, parse: nil, &block)
      @index = index
      @width = index.respond_to?(:size) ? index.size : nil
      @parser = parse || block || :strip
      @parser = @parser.to_proc unless @parser.respond_to? :call
    end

    def parse(record)
      if value = record[index]
        parser.call(value)
      end
    end

    def format(value)
      if width
        pad(truncate(value))
      else
        value
      end
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
