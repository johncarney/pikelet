module Pikelet
  class FieldDefinition
    attr_reader :index, :parser, :formatter, :padding, :alignment, :width

    def initialize(index, parse: nil, format: nil, pad: nil, align: nil, &block)
      raise ArgumentError, "index must be a range" unless index.is_a? Range
      @index = index
      @width = index.size
      @parser = parse || block || :strip
      @formatter = format || :to_s
      @padding = pad && pad.to_s || " "
      @alignment = align || :left
    end

    def parse(record)
      if value = record[index]
        parser.to_proc.call(value)
      end
    end

    def format(value)
      pad(truncate(formatter.to_proc.call(value)))
    end

    def insert(value, record)
      record[index] = format(value)
      record
    end

    private

    def blank
      @blank ||= padding * width
    end

    def truncate(value)
      value[0...width]
    end

    def pad(value)
      if alignment == :left
        value + blank[value.size...width]
      else
        blank[-width..-(1+value.size)] + value
      end
    end
  end
end
