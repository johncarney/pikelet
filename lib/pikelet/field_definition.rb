module Pikelet
  class FieldDefinition
    attr_reader :index, :parser

    def initialize(index, &parser)
      @index = index
      @parser = parser || :strip.to_proc
    end

    def parse(text)
      if value = text[index]
        parser.call(value)
      end
    end
  end
end
