require "spec_helper"
require "pikelet"

describe Pikelet::RecordDefinition do
  let(:definer) { Pikelet::RecordDefiner.new(nil, base_definition: nil) }

  let(:data)    { "Hello world" }

  let(:definition) do
    definer.define do
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

  describe "#width" do
    subject(:width) { definition.width }

    context "with contiguous fields" do
      let(:definition) do
        definer.define do
          hello 0... 5
          world 6...11
        end
      end

      it "returns the width of the record" do
        expect(width).to eq 11
      end
    end

    context "with overlapping fields" do
      let(:definition) do
        definer.define do
          hello 0..6
          world 4..9
        end
      end

      it "returns the width of the record" do
        expect(width).to eq 10
      end
    end

    context "with discontinuous fields" do
      let(:definition) do
        definer.define do
          hello 4... 7
          world 9...16
        end
      end

      it "returns the width of the record" do
        expect(width).to eq 16
      end
    end
  end
end
