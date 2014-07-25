module Pikelet
  class RecordDefinition
    attr_reader :file_definition, :field_definitions

    def initialize(file_definition, base_definition: nil, &block)
      @file_definition = file_definition
      @field_definitions = base_definition && base_definition.field_definitions.dup || {}
      if block_given?
        instance_eval(&block)
      end
    end

    def field(name, index, &block)
      @record_class = nil
      field_definitions[name] = Pikelet::FieldDefinition.new(index, &block)
    end

    def record(type_signature, &block)
      file_definition.record(type_signature, base_definition: self, &block)
    end

    def parse(data)
      record_class.new(*field_definitions.values.map { |field| field.parse(data) })
    end

    def method_missing(method, *args, &block)
      field(method, *args, &block)
    end

    def record_class
      @record_class ||= Struct.new(*field_definitions.keys.map(&:to_sym))
    end
  end
end
