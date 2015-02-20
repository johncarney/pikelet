module Pikelet
  class FileDefinition
    attr_reader :base, :signature_field

    def initialize(signature_field: nil, record_class: nil, &block)
      @signature_field = signature_field
      definer = RecordDefiner.new(self, record_class: record_class)
      @base = definer.define(&block)
    end

    def record(signature, record_class: nil, base: nil, &block)
      definer = RecordDefiner.new(self, record_class: record_class, base: base || self.base)
      record_definitions[signature] = definer.define(&block)
    end

    def record_definitions
      @record_definitions ||= {}
    end

    def parse(data, &block)
      parse_records(data, &block)
    end

    def format(records)
      records.map { |record| format_record(record, width: width) }
    end

    def width
      record_definitions.values.map(&:width).max
    end

    private

    def all_record_definitions
      [ base, *record_definitions.values ]
    end

    def records_with_type_signatures
      all_record_definitions.select(&:type_signature)
    end

    def type_signatures
      records_with_type_signatures.map(&:type_signature).uniq
    end

    def best_definition(signatures)
      signatures.map { |sig| record_definitions[sig] }.detect { |d| d } || base
    end

    def record_signature(record)
      field = signature_field || (all_record_definitions.detect(&:signature_field) && :type_signature)
      record.send(field) if record.respond_to?(field)
    end

    def format_record(record, width:)
      definition = record_definitions[record_signature(record)] || base
      definition.format(record, width: width)
    end

    def parse_records(data, &block)
      data.map(&method(:parse_record)).tap do |records|
        if block_given?
          records.each(&block)
        end
      end
    end

    def signature_fields
      all_record_definitions.map(&:signature_field).compact.uniq
    end

    def parse_record(data)
      signatures = signature_fields.lazy.map { |field| field.parse(data) }
      definition = signatures.map { |sig| record_definitions[sig] }.detect { |defn| defn } || base
      definition.parse(data)
    end
  end
end
