module Pikelet
  class RecordDefiner
    attr_reader :file_definition, :definition

    def initialize(file_definition, base_definition: nil)
      @file_definition = file_definition
      @definition = RecordDefinition.new(file_definition, base_definition: base_definition)
    end

    def define(&block)
      if block_given?
        instance_eval(&block)
      end
      definition
    end

    def field(name, index, **options, &block)
      definition.field(name, index, **options, &block)
    end

    def type_signature(field_or_index, **options, &block)
      if field_or_index.is_a? Range
        field(:type_signature, field_or_index, **options, &block)
        definition.type_signature = :type_signature
      else
        definition.type_signature = field_or_index
      end
    end

    def record(type_signature, &block)
      file_definition.record(type_signature, base_definition: definition, &block)
    end

    def method_missing(method, *args, **options, &block)
      field(method, *args, **options, &block)
    end
  end
end
