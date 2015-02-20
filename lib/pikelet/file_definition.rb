module Pikelet
  class FileDefinition
    attr_reader :base, :signature_field

    def initialize(signature_field: nil, record_class: nil, &block)
      @signature_field = signature_field
      if block_given?
        @base = define_record(nil, record_class: record_class, base: nil, &block)
      end
    end

    def define_record(signature, record_class:, base:, &block)
      record_definitions[signature] = RecordDefiner.define(self, record_class: record_class, base: base, &block)
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

    def record_signature(record)
      field = signature_field || (record_definitions.values.detect(&:signature_field) && :type_signature)
      record.send(field) if field && record.respond_to?(field)
    end

    def format_record(record, width:)
      definition = record_definitions[record_signature(record)]
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
      record_definitions.values.map(&:signature_field).compact.uniq
    end

    def parse_record(data)
      signatures = signature_fields.lazy.map { |field| field.parse(data) }.reject(&:nil?)
      definition = signatures.map { |sig| record_definitions[sig] }.reject(&:nil?).first || base
      definition.parse(data)
    end
  end
end
