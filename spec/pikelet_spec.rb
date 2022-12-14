require "spec_helper"
require "pikelet"
require "csv"

describe Pikelet do
  RSpec::Matchers.define :match_hash do |expected|
    match do |actual|
      actual.to_h == expected
    end
  end

  describe "custom record classes" do
    let(:custom_class) do
      Class.new do
        attr_reader :first_name, :last_name

        def initialize(attrs)
          @first_name = attrs[:first_name]
          @last_name = attrs[:last_name]
        end
      end
    end

    let(:definition) do
      Pikelet.define record_class: custom_class do
        first_name  0...10
        last_name  10...20
      end
    end

    let(:data)       { [ "Nicolaus  Copernicus" ] }
    subject(:record) { definition.parse(data).to_a.first }

    it "uses the supplied record class" do
      expect(record).to be_a custom_class
    end

    its(:first_name) { is_expected.to eq "Nicolaus" }
    its(:last_name)  { is_expected.to eq "Copernicus" }
  end

  describe "#format" do
    let(:definition) do
      Pikelet.define do
        type_signature 0...4

        record "NAME" do
          first_name  4...14
          last_name  14...24
        end

        record "ADDR" do
          street_address  4...24
          city           24...44
          postal_code    44...54
          state          54...74
        end
      end
    end

    let(:records) do
      [
        { type_signature: 'NAME', first_name: "Nicolaus", last_name: 'Copernicus' },
        { type_signature: 'ADDR', street_address: "123 South Street", city: "Nowhereville", postal_code: "45678Y", state: "Someplace" }
      ].map(&OpenStruct.method(:new))
    end

    subject(:formatted) { definition.format(records) }

    it { is_expected.to have(2).lines }

    its(:first) { is_expected.to eq "NAMENicolaus  Copernicus                                                  " }
    its(:last)  { is_expected.to eq "ADDR123 South Street    Nowhereville        45678Y    Someplace           " }
  end

  describe "#parse" do
    let(:records) { definition.parse(data).to_a }

    subject { records }

    describe "for a simple flat file" do
      let(:definition) do
        Pikelet.define do
          name   0... 4
          number 4...13
        end
      end

      let(:data) do
        <<-FILE.split(/[\r\n]+/).map(&:lstrip)
          John012345678
          Sue 087654321
        FILE
      end

      it { is_expected.to have(2).records }

      its(:first) { is_expected.to match_hash(name: "John", number: "012345678") }
      its(:last)  { is_expected.to match_hash(name: "Sue",  number: "087654321") }
    end

    describe "for a file with heterogeneous records" do
      let(:definition) do
        Pikelet.define do
          type_signature 0...1

          record 'A' do
            name   1... 5
            number 5...14
          end

          record 'B' do
            number  1...10
            name   10...14
          end
        end
      end

      let(:data) do
        <<-FILE.split(/[\r\n]+/).map(&:lstrip)
          AJohn012345678
          B087654321Sue
        FILE
      end


      it { is_expected.to have(2).records }

      its(:first) { is_expected.to match_hash(name: "John", number: "012345678", type_signature: "A") }
      its(:last)  { is_expected.to match_hash(name: "Sue",  number: "087654321", type_signature: "B") }
    end

    describe "inheritance" do
      let(:definition) do
        Pikelet.define do
          type_signature 0...6

          record 'SIMPLE' do
            name 6...10

            record 'FANCY' do
              number 10...19
            end
          end
        end
      end

      let(:data) do
        <<-FILE.split(/[\r\n]+/).map(&:lstrip)
          SIMPLEJohn012345678
          FANCY Sue 087654321
        FILE
      end

      it { is_expected.to have(2).records }

      its(:first) { is_expected.to match_hash(name: "John", type_signature: "SIMPLE") }
      its(:last)  { is_expected.to match_hash(name: "Sue",  number: "087654321", type_signature: "FANCY") }
    end

    describe "given a block for field parsing" do
      let(:definition) do
        Pikelet.define do
          value(0...4) { |value| value.to_i }
        end
      end

      let(:data) do
        <<-FILE.split(/[\r\n]+/).map(&:lstrip)
          5637
        FILE
      end

      subject { records.first }

      its(:value) { is_expected.to eq 5637 }
    end

    describe "given a parse option" do
      let(:definition) do
        Pikelet.define do
          value 0...4, parse: ->(value) { value.to_i }
        end
      end

      let(:data) do
        <<-FILE.split(/[\r\n]+/).map(&:lstrip)
          5637
        FILE
      end

      subject { records.first }

      its(:value) { is_expected.to eq 5637 }
    end

    describe "given a shorthand parse option" do
      let(:definition) do
        Pikelet.define do
          value 0...4, parse: :to_i
        end
      end

      let(:data) do
        <<-FILE.split(/[\r\n]+/).map(&:lstrip)
          5637
        FILE
      end

      subject { records.first }

      its(:value) { is_expected.to eq 5637 }
    end

    describe "given a block when parsing" do
      let(:collected_records) { [] }

      let(:definition) do
        Pikelet.define do
          name   0... 4
          number 4...13
        end
      end

      let(:data) do
        <<-FILE.split(/[\r\n]+/).map(&:lstrip)
          John012345678
          Sue 087654321
        FILE
      end

      before do
        definition.parse(data) do |record|
          collected_records << record.to_h
        end
      end

      it 'yields each record to the block' do
        expect(collected_records).to contain_exactly(*records.map(&:to_h))
      end
    end
  end
end
