require "spec_helper"
require "pikelet"
require "csv"

describe Pikelet::FieldDefinition do
  let(:parser)     { { } }
  let(:formatter)  { { } }
  let(:padding)    { { } }
  let(:alignment)  { { } }
  let(:block)      { nil }
  let(:definition) { Pikelet::FieldDefinition.new(index, **parser, **formatter, **padding, **alignment, &block) }

  describe "defaults" do
    let(:index) { 0...1 }

    subject { definition }

    its(:parser)    { is_expected.to eq :strip }
    its(:formatter) { is_expected.to eq :to_s }
    its(:padding)   { is_expected.to eq " " }
    its(:alignment) { is_expected.to eq :left }
  end

  describe "#parse" do
    let(:data)       { "The quick brown fox" }

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
      let(:block_parser) { ->(value) { value } }

      before do
        allow(block_parser).to receive(:call).and_call_original
        parsed
      end

      context "as a block" do
        let(:index) { 4...9 }
        let(:block) { block_parser }

        it "yields the value to the parser" do
          expect(block_parser).to have_received(:call).with("quick")
        end
      end

      context "as a parse option" do
        let(:index)  { 10...15 }
        let(:parser) { { parse: block_parser } }

        it "yields the value to the parser" do
          expect(block_parser).to have_received(:call).with("brown")
        end
      end
    end

    context "given a shorthand parser" do
      let(:symbol_parser) { :upcase }

      context "as a block" do
        let(:index) { 10...15 }
        let(:block) { symbol_parser }

        it "invokes the named method on the value" do
          expect(parsed).to eq "BROWN"
        end
      end

      context "as a parse option" do
        let(:index)  { 4...9 }
        let(:parser) { { parse: symbol_parser } }

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
    subject(:formatted) { definition.format(value) }

    describe "truncation" do
      let(:index) { 4...9 }

      context "given a value that fits the field exactly" do
        let(:value) { "quick" }

        it "does not truncate the value" do
          expect(formatted).to eq value
        end
      end

      context "given a value that overflows the field" do
        let(:value) { "12345678" }

        it "truncates the value" do
          expect(formatted).to eq value[0...5]
        end
      end
    end

    describe "given a custom formatter" do
      let(:index)           { 4...5 }
      let(:block_formatter) { ->(value) { value } }
      let(:formatter)       { { format: block_formatter} }
      let(:value)           { "brown" }

      before do
        allow(block_formatter).to receive(:call).and_call_original
        formatted
      end

      it "yields the raw value to the formatter" do
        expect(block_formatter).to have_received(:call).with("brown")
      end
    end

    describe "using a shorthand formatter" do
      let(:index)     { 4...9 }
      let(:formatter) { { format: :upcase } }
      let(:value)     { "brown" }

      it "invokes the named method on the raw value" do
        expect(formatted).to eq "BROWN"
      end
    end

    describe "padding & alignment" do
      let(:index) { 3...7 }

      context "given a value that fits the field exactly" do
        let(:value)         { "1234" }

        it "does not pad the field" do
          expect(formatted).to eq value
        end
      end

      context "given a value that underflows the field" do
        let(:value) { "12" }

        context "with left alignment" do
          let(:alignment) { { align: :left } }

          context "with single-character padding" do
            let(:padding) { { pad: '-' } }

            it "pads the field on the right" do
              expect(formatted).to eq "12--"
            end
          end

          context "with multi-character padding" do
            let(:padding) { { pad: '<->' } }

            it "pads the field on the right" do
              expect(formatted).to eq "12><"
            end
          end
        end

        context "with right alignment" do
          let(:alignment) { { align: :right } }

          context "with single-character padding" do
            let(:padding) { { pad: '-' } }

            it "pads the field on the left" do
              expect(formatted).to eq "--12"
            end
          end

          context "with multi-character padding" do
            let(:padding) { { pad: '<->' } }

            it "pads the field on the left" do
              expect(formatted).to eq "><12"
            end
          end
        end
      end
    end
  end
end
