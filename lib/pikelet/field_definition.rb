require "overpunch"

module Pikelet
  class FieldDefinition
    attr_reader :indices, :type

    def initialize(indices, type: nil)
      @indices = indices
      @type = type
    end

    def parse(text)
      value = indices.map { |index| text[index] }.join
      case type
      when :integer
        value.to_i
      when :overpunch
        Overpunch.parse(value)
      else
        value.strip
      end
    end
  end
end
