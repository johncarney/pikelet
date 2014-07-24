module Pikelet
  class FileDefinition
    attr_reader :base_record_definition

    def initialize(&block)
      @base_record_definition = RecordDefinition.new(self, &block)
    end

    def record(type_signature, base_definition: nil, &block)
      base_definition ||= base_record_definition
      record_definitions[type_signature] = RecordDefinition.new(self, base_definition, &block)
    end

    def record_definitions
      @record_definitions ||= {}
    end

    def parse(data, &block)
      records = Enumerator.new do |y|
        data.each do |line|
          record = base_record_definition.parse(line)
          if record.respond_to?(:type_signature)
            if definition = record_definitions[record.type_signature]
              record = definition.parse(line)
            end
          end
          y.yield(record)
        end
      end
      if block_given?
        records.each(&block)
      else
        records
      end
    end
  end
end
