module Pikelet
  class FileDefinition
    attr_reader :base

    def initialize(type_signature: nil, record_class: nil, &block)
      definer = RecordDefiner.new(self, type_signature: type_signature, record_class: record_class)
      @base = definer.define(&block)
    end

    def record(type_signature, record_class: nil, base: nil, &block)
      definer = RecordDefiner.new(self, record_class: record_class, base: base || self.base)
      record_definitions[type_signature] = definer.define(&block)
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

    def records_with_type_signatures
      [ base, *record_definitions.values ].select(&:type_signature)
    end

    def type_signatures
      records_with_type_signatures.map(&:type_signature).uniq
    end

    def best_definition(signatures)
      signatures.map { |sig| record_definitions[sig] }.detect { |d| d } || base
    end

    def format_record(record, width:)
      signatures = type_signatures.lazy.select(&record.method(:respond_to?)).map(&record.method(:send))
      best_definition(signatures).format(record, width: width)
    end

    def parse_records(data, &block)
      data.map(&method(:parse_record)).tap do |records|
        if block_given?
          records.each(&block)
        end
      end
    end

    def signature_fields
      records_with_type_signatures.map(&:signature_field).uniq
    end

    def parse_record(data)
      signatures = signature_fields.lazy.map { |field| field.parse(data) }
      best_definition(signatures).parse(data)
    end
  end
end
