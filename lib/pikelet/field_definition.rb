require "overpunch"

module Pikelet
  class FieldDefinition
    attr_reader :indices, :parser

    def initialize(indices, type: nil, &parser)
      @indices = indices
      if block_given?
        @parser = parser
      else
        @parser = parser_from_type(type)
      end
    end

    def parse(text)
      @parser.call(indices.map { |index| text[index] }.join)
    end

    private

    def parser_from_type(type)
      case type
      when :integer
        :to_i.to_proc
      when :overpunch
        Proc.new { |value| Overpunch.parse(value) }
      else
        :strip.to_proc
      end
    end
  end
end
