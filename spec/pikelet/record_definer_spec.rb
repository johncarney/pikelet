require "spec_helper"
require "pikelet"

describe Pikelet::RecordDefiner do
  let(:definer)    { described_class.new(nil) }
  let(:definition) { definer.definition }

  describe "#type_signature" do
    context "given a field name" do
      before do
        allow(definition).to receive(:type_signature=).and_call_original
        definer.type_signature :type
      end

      it "sets the type signature field on the record definition" do
        expect(definition).to have_received(:type_signature=).with(:type)
      end
    end

    context "legacy usage" do
      before do
        allow(definition).to receive(:type_signature=).and_call_original
        allow(definer).to receive(:field).and_call_original
        definer.type_signature 0...4, align: :right, pad: "0", &:to_i
      end

      it "creates the field" do
        expect(definer).to have_received(:field).with(:type_signature, 0...4, align: :right, pad: "0", &:to_i)
      end

      it "sets the type signature field on the record definition" do
        expect(definition).to have_received(:type_signature=).with(:type_signature)
      end
    end
  end
end

