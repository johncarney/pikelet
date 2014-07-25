require "spec_helper"
require "pikelet"
require "csv"

describe Pikelet::FieldDefinition do
  let(:data)        { "The quick brown fox" }
  let(:type)        { nil }
  let(:definition)  { Pikelet::FieldDefinition.new(indices, type: type) }

  subject(:value) { definition.parse(data) }

  describe "for a fixed-width field" do
    let(:indices) { [ 4...9 ] }

    it "extracts the field content from the data" do
      expect(value).to eq "quick"
    end
  end

  describe "given whitespace" do
    let(:indices) { [ 3...16 ] }

    it "strips leading and trailing whitespace" do
      expect(value).to eq "quick brown"
    end
  end

  describe "with multiple indices" do
    let(:indices) { [ 0...4, 16...19 ] }

    it "joins the sections together" do
      expect(value).to eq "The fox"
    end
  end

  describe "given a CSV row" do
    let(:data)    { CSV.parse("The,quick,brown,fox").first }
    let(:indices) { [ 2 ] }

    it "extracts the field" do
      expect(value).to eq "brown"
    end
  end

  describe "for integer fields" do
    let(:data)    { "xx326xx" }
    let(:indices) { [ 2...5] }
    let(:type)    { :integer }

    it "converts the value to an integer" do
      expect(value).to eq 326
    end
  end

  describe "for overpunch fields" do
    let(:data)    { "xx67Kxx" }
    let(:indices) { [ 2...5] }
    let(:type)    { :overpunch }

    it "converts the value to an integer" do
      expect(value).to eq -672
    end
  end

  describe "given a parser block" do
    let(:indices) { [ 4...9] }
    let(:definition) do
      Pikelet::FieldDefinition.new(indices) { |value| value.reverse }
    end

    it "yields the value to the parser" do
      expect(value).to eq "kciuq"
    end
  end

  describe "given a symbol for the parser block" do
    let(:indices) { [ 4...9] }
    let(:definition) do
      Pikelet::FieldDefinition.new(indices, &:upcase)
    end

    it "invokes the named method on the value" do
      expect(value).to eq "QUICK"
    end
  end
end
