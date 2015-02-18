module Pikelet
  class FieldDefinition
    attr_reader :index, :parser

    def initialize(index, parse: nil, &parser)
      @index = index
      @parser = parser || parse || :strip
      @parser = @parser.to_proc unless @parser.respond_to? :call
    end

    def parse(text)
      if value = text[index]
        parser.call(value)
      end
    end
  end
end
