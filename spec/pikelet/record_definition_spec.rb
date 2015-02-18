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

  describe "#parse_hash" do
    let(:record)      { definition.parse(data) }
    let(:record_hash) { Hash[record.to_h.to_a.reverse] }

    subject { definition.parse_hash(record_hash) }

    it { is_expected.to eq record }
  end

  describe "#format" do
    let(:record) { OpenStruct.new(hello: "Hello", world: "world") }

    subject { definition.format(record) }

    it { is_expected.to eq "Hello world" }
  end
end
