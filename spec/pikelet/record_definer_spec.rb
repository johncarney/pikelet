require "spec_helper"
require "pikelet"

RSpec::Matchers.define :have_field_definition do |name|
  match do |record_definition|
    definition = record_definition.field_definitions[name]
    definition && (!@index || definition.index == @index) && (!@alignment || definition.alignment == @alignment)
  end

  chain :with_index do |index|
    @index = index
  end

  chain :with_alignment do |alignment|
    @alignment = alignment
  end

  description do
    message = "have field definition #{name.inspect}"
    message += " with index #{@index.inspect}" if @index
    message += " with #{@alignment.inspect} alignment" if @alignment
    message
  end
end

describe Pikelet::RecordDefiner do
  let(:file_definition)   { Pikelet::FileDefinition.new }
  let(:definer)           { described_class.new(file_definition, record_class: nil, base: nil) }
  let(:record_definition) { definer.definition }

  describe "#field" do
    let(:parser) { ->(v) { v.to_i } }

    subject(:field) { definer.field(:thing, 0...4, pad: "0", &parser) }

    its(:index)   { is_expected.to eq 0...4 }
    its(:padding) { is_expected.to eq "0" }
    its(:parser)  { is_expected.to eq parser }

    it "adds the field to the record definition" do
      field
      expect(record_definition.field_definitions[:thing]).to be field
    end
  end

  describe "#record" do
    let(:definition_block) { proc { field(:thing, 1..4) } }

    subject(:record) { definer.record("NAME", record_class: OpenStruct, &definition_block) }

    its(:record_class) { is_expected.to be OpenStruct }

    it "adds the record to the file definition" do
      record
      expect(file_definition.record_definitions["NAME"]).to be record
    end

    it "evaluates the definition block" do
      expect(record.field_definitions[:thing]).to_not be_nil
    end
  end

  describe "shorthand field definition" do
    let(:parser) { ->(v) { v.upcase } }

    subject(:field) { definer.thing(10...20, pad: "-", &parser) }

    its(:index)   { is_expected.to eq 10...20 }
    its(:padding) { is_expected.to eq "-" }
    its(:parser)  { is_expected.to eq parser }

    it "adds the field to the record definition" do
      field
      expect(record_definition.field_definitions[:thing]).to be field
    end
  end

  describe ".define" do
    subject(:definition) do
      described_class.define(file_definition, record_class: OpenStruct, base: nil) do
        field :thing, 20...30, align: :right
      end
    end

    its(:record_class) { is_expected.to be OpenStruct }

    it { is_expected.to have_field_definition(:thing).with_index(20...30).with_alignment(:right) }
  end
end
