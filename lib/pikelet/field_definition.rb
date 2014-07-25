module Pikelet
  class FieldDefinition
    attr_reader :indices, :parser

    def initialize(indices, &parser)
      @indices = indices
      @parser = parser || :strip.to_proc
    end

    def parse(text)
      @parser.call(indices.map { |index| text[index] }.join)
    end
  end
end
