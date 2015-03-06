module Pikelet
  class FieldDefinition
    attr_reader :index, :parser, :formatter, :padding, :alignment, :width

    def initialize(index, parse: nil, type: :alpha, format: nil, pad: nil, align: nil, &block)
      raise ArgumentError, "index must be a range" unless index.is_a? Range
      raise ArgumentError, "type must be :alpha or :numeric" unless %i{ alpha numeric }.include? type
      if align
        raise ArgumentError, "align must be :left, :right, or :center" unless %i{ left right centre center }.include?(align)
      end

      @index = index
      @width = index.size
      @parser = parse || block
      @formatter = format || :to_s

      if type == :numeric
        @padding = pad && pad.to_s || "0"
        @alignment = align || :right
      else
        @padding = pad && pad.to_s || " "
        @alignment = align || :left
      end

      case alignment
      when :right
        @align_method = :rjust
      when :left
        @align_method = :ljust
      when :centre, :center
        @align_method = :center
      end
    end

    def parse(record)
      # TODO: Test that fields are always stripped.
      if value = record[index]
        value.strip!
        if parser
          parser.to_proc.call(value)
        else
          value
        end
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
