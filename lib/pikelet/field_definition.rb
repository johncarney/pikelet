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
      if alignment == :right
        @align_method = :rjust
      else
        @align_method = :ljust
      end
    end

    def parse(record)
      if value = record[index]
        parser.to_proc.call(value)
      end
    end

    def format(value)
      align(formatter.to_proc.call(value))[0...width]
    end

    def insert(value, record)
      record[index] = format(value)
      record
    end

    private

    attr_reader :align_method

    def align(value)
      value.send(align_method, width, padding)
    end
  end
end
