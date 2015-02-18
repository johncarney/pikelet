module Pikelet
  class FileDefinition
    attr_reader :base_record_definition

    def initialize(&block)
      @base_record_definition = RecordDefiner.new(self).define(&block)
    end

    def record(type_signature, base_definition: nil, &block)
      base_definition ||= base_record_definition
      record_definitions[type_signature] = RecordDefiner.new(self, base_definition: base_definition).define(&block)
    end

    def record_definitions
      @record_definitions ||= {}
    end

    def parse(data, &block)
      parse_records(data, method: :parse, &block)
    end

    def parse_hashes(hashes, &block)
      parse_records(hashes, method: :parse_hash, &block)
    end

    def format(records)
      records.map { |record| format_record(record, width: width) }
    end

    def width
      record_definitions.values.map(&:width).max
    end

    private

    def format_record(record, width:)
      record_definition = record.respond_to?(:type_signature) && record_definitions[record.type_signature]
      record_definition ||= base_record_definition
      record_definition.format(record, width: width)
    end

    def parse_records(data, method:, &block)
      records = Enumerator.new do |y|
        data.each do |data|
          y.yield(parse_record(data, method: method))
        end
      end
      if block_given?
        records.each(&block)
      else
        records
      end
    end

    def parse_record(data, method:)
      record = base_record_definition.send(method, data)
      if record.respond_to?(:type_signature)
        if definition = record_definitions[record.type_signature]
          record = definition.send(method, data)
        end
      end
      record
    end
  end
end
