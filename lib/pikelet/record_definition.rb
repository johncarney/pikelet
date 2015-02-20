require "pikelet/record_definer"

module Pikelet
  class RecordDefinition
    attr_reader :file_definition, :field_definitions
    attr_writer :type_signature

    def initialize(file_definition, type_signature: nil, record_class: nil, base:)
      @file_definition = file_definition
      @field_definitions = base && base.field_definitions.dup || {}
      @record_class = record_class
      @type_signature = type_signature
    end

    def field(name, index, **options, &block)
      field_definitions[name] = Pikelet::FieldDefinition.new(index, **options, &block)
    end

    def type_signature
      @type_signature ||= field_definitions.key?(:type_signature) ? :type_signature : nil
    end

    def signature_field
      type_signature && field_definitions[type_signature]
    end

    def parse(data)
      record_class.new(parse_fields(data))
    end

    def format(record, width: nil)
      width ||= self.width
      field_definitions.each_with_object(" " * width) do |(field_name, field_definition), result|
        field_definition.insert(record.send(field_name.to_sym), result)
      end
    end

    def record_class
      @record_class ||= default_record_class
    end

    def default_record_class
      Struct.new(*field_names) do
        def initialize(**attributes)
          super(*attributes.values_at(*self.class.members))
        end
      end
    end

    def width
      field_definitions.values.map { |d| d.index.max }.max + 1
    end

    private

    def field_names
      field_definitions.keys.map(&:to_sym)
    end

    def parse_fields(data)
      field_definitions.each_with_object({}) do |(field, definition), result|
        result[field.to_sym] = definition.parse(data)
      end
    end
  end
end
