require "pikelet/record_definer"

module Pikelet
  class RecordDefinition
    attr_reader :file_definition, :field_definitions
    attr_writer :type_signature

    def initialize(file_definition, base_definition:)
      @file_definition = file_definition
      @field_definitions = base_definition && base_definition.field_definitions.dup || {}
    end

    def field(name, index, **options, &block)
      @record_class = nil
      field_definitions[name] = Pikelet::FieldDefinition.new(index, **options, &block)
    end

    def type_signature
      unless defined? @type_signature
        @type_signature = :type_signature if field_definitions.key? :type_signature
      end
      @type_signature
    end

    def signature_field
      type_signature && field_definitions[type_signature]
    end

    def parse(data)
      record_class.new(*field_definitions.values.map { |field| field.parse(data) })
    end

    def format(record, width: nil)
      width ||= self.width
      field_definitions.each_with_object(" " * width) do |(field_name, field_definition), result|
        field_definition.insert(record.send(field_name.to_sym), result)
      end
    end

    def record_class
      @record_class ||= Struct.new(*field_definitions.keys.map(&:to_sym))
    end

    def width
      field_definitions.values.map(&:width).inject(&:+)
    end
  end
end
