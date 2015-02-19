require "spec_helper"
require "pikelet"

describe Pikelet::RecordDefinition do
  let(:data)  { "Hello world" }
  let(:definition) do
    Pikelet::RecordDefiner.new(nil, base_definition: nil).define do
      hello 0... 5
      world 6...11
    end
  end

  describe "#format" do
    let(:record) { OpenStruct.new(hello: "Hello", world: "world") }

    subject { definition.format(record) }

    it { is_expected.to eq "Hello world" }
  end

  describe "#type_signature" do
    let(:definition) { described_class.new(nil, base_definition: nil) }

    subject { definition }

    context "with no fields and no signature defined" do
      its(:type_signature) { is_expected.to be_nil }
    end

    context "with signature defined" do
      before do
        definition.type_signature = :type
      end

      its(:type_signature) { is_expected.to eq :type }
    end

    context "with a field named :type_signature" do
      before do
        definition.field(:type_signature, 0...3)
      end

      its(:type_signature) { is_expected.to eq :type_signature }
    end
  end
end
