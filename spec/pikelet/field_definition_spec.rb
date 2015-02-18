require "spec_helper"
require "pikelet"
require "csv"

describe Pikelet::FieldDefinition do
  describe "#parse" do
    let(:data)       { "The quick brown fox" }
    let(:definition) { Pikelet::FieldDefinition.new(index) }

    subject(:parsed) { definition.parse(data) }

    context "for a fixed-width field" do
      let(:index) { 4...9 }

      it "extracts the field content from the data" do
        expect(parsed).to eq "quick"
      end
    end

    context "given whitespace" do
      let(:index) { 3...16 }

      it "strips leading and trailing whitespace" do
        expect(parsed).to eq "quick brown"
      end
    end

    context "given a custom parser" do
      let(:parser) { ->(value) { value } }

      before do
        allow(parser).to receive(:call)
        parsed
      end

      context "as a block" do
        let(:index)      { 4...9 }
        let(:definition) { Pikelet::FieldDefinition.new(index, &parser) }

        it "yields the value to the parser" do
          expect(parser).to have_received(:call).with("quick")
        end
      end

      context "as a parse option" do
        let(:index)      { 10...15 }
        let(:definition) { Pikelet::FieldDefinition.new(index, parse: parser) }

        it "yields the value to the parser" do
          expect(parser).to have_received(:call).with("brown")
        end
      end
    end

    context "given a shorthand parser" do
      let(:parser) { :upcase }

      context "as a block" do
        let(:index)      { 10...15 }
        let(:definition) { Pikelet::FieldDefinition.new(index, &parser) }

        it "invokes the named method on the value" do
          expect(parsed).to eq "BROWN"
        end
      end

      context "as a parse option" do
        let(:index)      { 4...9 }
        let(:definition) { Pikelet::FieldDefinition.new(index, parse: parser) }

        it "invokes the named method on the value" do
          expect(parsed).to eq "QUICK"
        end
      end
    end

    context "given an index not covered in the data" do
      let(:index) { 999..999 }

      it "parses as nil" do
        expect(parsed).to be_nil
      end
    end
  end

  describe "#insert" do
    let(:index)      { 4...9 }
    let(:record)     { "The _____ brown fox" }
    let(:value)      { "quick" }
    let(:definition) { Pikelet::FieldDefinition.new(index) }

    subject(:result) { definition.insert(value, record) }

    before do
      allow(definition).to receive(:format).with(value) { value }
    end

    it "formats the value" do
      result
      expect(definition).to have_received(:format).with(value)
    end

    it "inserts the formatted value into record" do
      expect(result).to eq "The quick brown fox"
    end
  end

  describe "#format" do
    let(:index) { 4...9 }

    subject(:formatted) { definition.format(value) }

    context "with the default formatter" do
      let(:definition) { Pikelet::FieldDefinition.new(index) }

      context "given a value that fits the field exactly" do
        let(:value) { "quick" }

        it "returns the value" do
          expect(formatted).to eq "quick"
        end
      end

      context "given a value larger than the field" do
        let(:value) { "quickk" }

        it "truncates the value" do
          expect(formatted).to eq "quick"
        end
      end

      context "givem a value smaller than the field" do
        let(:value) { "quik" }

        it "pads the the value with spaces at the left" do
          expect(formatted).to eq " quik"
        end
      end
    end
  end
end
