module Pikelet
  class FieldDefinition
    attr_reader :index, :parser

    def initialize(index, &parser)
      @index = index
      @parser = parser || :strip.to_proc
    end

    def parse(text)
      parser.call(text[index])
    end
  end
end
