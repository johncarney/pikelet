require "spec_helper"
require "pikelet"
require "csv"

describe Pikelet::FieldDefinition do
  let(:data)        { "The quick brown fox" }
  let(:definition)  { Pikelet::FieldDefinition.new(index) }

  subject(:value) { definition.parse(data) }

  describe "for a fixed-width field" do
    let(:index) { 4...9 }

    it "extracts the field content from the data" do
      expect(value).to eq "quick"
    end
  end

  describe "given whitespace" do
    let(:index) { 3...16 }

    it "strips leading and trailing whitespace" do
      expect(value).to eq "quick brown"
    end
  end

  describe "given a CSV row" do
    let(:data)  { CSV.parse("The,quick,brown,fox").first }
    let(:index) { 2 }

    it "extracts the field" do
      expect(value).to eq "brown"
    end
  end

  describe "given a parser block" do
    let(:index) { 4...9 }
    let(:definition) do
      Pikelet::FieldDefinition.new(index) { |value| value.reverse }
    end

    it "yields the value to the parser" do
      expect(value).to eq "kciuq"
    end
  end

  describe "given a symbol for the parser block" do
    let(:index) { 4...9 }
    let(:definition) do
      Pikelet::FieldDefinition.new(index, &:upcase)
    end

    it "invokes the named method on the value" do
      expect(value).to eq "QUICK"
    end
  end
end
