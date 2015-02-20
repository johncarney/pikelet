module Pikelet
  class RecordDefiner
    attr_reader :file_definition, :definition

    def initialize(file_definition, record_class: nil, base: nil)
      @file_definition = file_definition
      @definition = RecordDefinition.new(file_definition,
        record_class: record_class,
        base:         base
      )
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

    def record(signature, record_class: nil, &block)
      file_definition.record(signature, record_class: record_class, base: definition, &block)
    end

    def method_missing(method, *args, **options, &block)
      field(method, *args, **options, &block)
    end
  end
end
