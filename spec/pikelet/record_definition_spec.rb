require "spec_helper"
require "pikelet"

describe Pikelet::RecordDefinition do
  let(:definer) { Pikelet::RecordDefiner.new(nil, base: nil) }

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
