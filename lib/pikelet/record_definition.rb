require "pikelet/record_definer"

module Pikelet
  class RecordDefinition
    attr_reader :file_definition, :field_definitions

    def initialize(file_definition, base_definition:)
      @file_definition = file_definition
      @field_definitions = base_definition && base_definition.field_definitions.dup || {}
    end

    def field(name, index, &block)
      @record_class = nil
      field_definitions[name] = Pikelet::FieldDefinition.new(index, &block)
    end

    def parse(data)
      record_class.new(*field_definitions.values.map { |field| field.parse(data) })
    end

    def parse_hash(hash)
      record_class.new(*hash.values_at(*field_definitions.keys))
    end

    def record_class
      @record_class ||= Struct.new(*field_definitions.keys.map(&:to_sym))
    end
  end
end
