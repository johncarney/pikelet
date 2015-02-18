require "spec_helper"
require "pikelet"
require "csv"

describe Pikelet::FieldDefinition do
  let(:data)       { "The quick brown fox" }
  let(:definition) { Pikelet::FieldDefinition.new(index) }

  subject(:result) { definition.parse(data) }

  context "for a fixed-width field" do
    let(:index) { 4...9 }

    it "extracts the field content from the data" do
      expect(result).to eq "quick"
    end
  end

  context "given whitespace" do
    let(:index) { 3...16 }

    it "strips leading and trailing whitespace" do
      expect(result).to eq "quick brown"
    end
  end

  context "given a CSV row" do
    let(:data)  { CSV.parse("The,quick,brown,fox").first }
    let(:index) { 2 }

    it "extracts the field" do
      expect(result).to eq "brown"
    end
  end

  context "given a custom parser" do
    let(:parser) { ->(value) { value } }

    before do
      allow(parser).to receive(:call)
      result
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
        expect(result).to eq "BROWN"
      end
    end

    context "as a parse option" do
      let(:index)      { 4...9 }
      let(:definition) { Pikelet::FieldDefinition.new(index, parse: parser) }

      it "invokes the named method on the value" do
        expect(result).to eq "QUICK"
      end
    end
  end

  context "given an index not covered in the data" do
    let(:index) { 999..999 }

    it "parses as nil" do
      expect(result).to be_nil
    end
  end
end
