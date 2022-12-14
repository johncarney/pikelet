require "spec_helper"
require "pikelet"

describe "README Examples:" do
  def strip_data(text)
    text.gsub(/^#{text.scan(/^[ \t]*(?=\S)/).min || ''}/, '').gsub('|', '').split("\n")
  end

  RSpec::Matchers.define :match do |expected|
    def record_matches_hash?(record, hash)
      hash.all? { |attr, value| record.send(attr) == value }
    end

    match do |actual|
      actual.zip(expected).all? do |actual, expected|
        record_matches_hash?(actual, expected)
      end
    end
  end

  shared_examples_for "parse the data" do
    subject { definition.parse(strip_data(data)) }

    it { is_expected.to match expected_records }
  end

  shared_examples_for "format the records" do
    subject { definition.format(records) }

    it { is_expected.to eq strip_data(expected_data) }
  end

  describe "Homogeneous records" do
    let(:definition) do
      Pikelet.define do
        first_name  0...10
        last_name  10...20
      end
    end

    let(:data) do
      <<-DATA
        |Grace     |Hopper    |
        |Ada       |Lovelace  |
      DATA
    end

    let(:expected_records) do
      [
        { first_name: "Grace", last_name: "Hopper"   },
        { first_name: "Ada",   last_name: "Lovelace" }
      ]
    end

    it_will "parse the data"
  end

  describe "Heterogeneous records" do
    let(:definition) do
      Pikelet.define signature_field: :type do
        type 0...4

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

    let(:data) do
      <<-DATA
        |NAME|Frida     |Kahlo     |
        |ADDR|123 South Street     |Sometown            |45678Y    |Someplace           |
      DATA
    end

    let(:expected_records) do
      [
        { type: "NAME", first_name: "Frida", last_name: "Kahlo" },
        { type: "ADDR", street_address: "123 South Street", city: "Sometown", postal_code: "45678Y", state: "Someplace" }
      ]
    end

    it_will "parse the data"
  end

  describe "Inheritance" do
    let(:definition) do
      Pikelet.define signature_field: :record_type do
        record_type 0...5

        record "NAME" do
          first_name  5...15
          last_name  15...25

          record "NAME+" do
            middle_name 25...35
          end
        end
      end
    end

    let(:data) do
      <<-DATA
        |NAME |Rosa      |Parks     |
        |NAME+|Rosalind  |Franklin  |Elsie     |
      DATA
    end

    let(:expected_records) do
      [
        { record_type: "NAME",  first_name: "Rosa",     last_name: "Parks" },
        { record_type: "NAME+", first_name: "Rosalind", last_name: "Franklin", middle_name: "Elsie" }
      ]
    end

    it_will "parse the data"
  end

  describe "Custom field parsing" do
    let(:definition) do
      Pikelet.define do
        a_number(0... 4) { |value| value.to_i }

        another_number      4... 8, &:to_i
        yet_another_number  8...12, parse: ->(value) { value.to_i }
        some_text          12...20, parse: :upcase
      end
    end

    let(:data) do
      <<-DATA
        |  67|   3| 999|blah    |
      DATA
    end

    let(:expected_records) do
      [
        { a_number: 67, another_number: 3, yet_another_number: 999, some_text: "BLAH" }
      ]
    end

    it_will "parse the data"
  end

  describe "Custom field formatting" do
    let(:definition) do
      Pikelet.define do
        username  0...10, format: :downcase
        password 10...50, format: ->(v) { Digest::SHA1.hexdigest(v) }
      end
    end

    let(:records) do
      [
        OpenStruct.new(username: "Coleman",    password: "password"),
        OpenStruct.new(username: "Savitskaya", password: "sekrit"  )
      ]
    end

    let(:expected_data) do
      <<-DATA
        |coleman   |5baa61e4c9b93f3f0682250b6cf8331b7ee68fd8|
        |savitskaya|8d42e738c7adee551324955458b5e2c0b49ee655|
      DATA
    end

    it_will "format the records"
  end

  describe "Formatting options" do
    let(:definition) do
      Pikelet.define do
        number          0... 3, align: :right, pad: "0"
        text            3...10, align: :left,  pad: "-"
        another_number 10...13, type: :numeric
        more_text      13...20, type: :alpha
      end
    end

    let(:records) do
      [
        OpenStruct.new(number: 9, text: "blah", another_number: 12, more_text: "meh")
      ]
    end

    let(:expected_data) do
      <<-DATA
        |009|blah---|012|meh    |
      DATA
    end

    it_will "format the records"
  end

  describe "Custom record classes" do
    class Base
      attr_reader :type

      def initialize(attrs)
        @type = attrs[:type]
      end
    end

    class Name < Base
      attr_reader :name

      def initialize(attrs)
        super( { type: "NAME" } )
        @name = attrs[:name]
      end
    end

    class Address < Base
      attr_reader :street, :city

      def initialize(attrs)
        super( { type: "ADDR" } )
        @street = attrs[:street]
        @city = attrs[:city]
      end
    end

    let(:definition) do
      Pikelet.define signature_field: :type, record_class: Base do
        type 0...4

        record "NAME", record_class: Name do
          name 4...20
        end

        record "ADDR", record_class: Address do
          street  4...20
          city   20...30
        end
      end
    end

    let(:data) do
      <<-DATA
        |NAME|Frida Kahlo     |
        |ADDR|123 South Street|Sometown            |
      DATA
    end

    let(:expected_records) do
      [
        { class: Name,    type: "NAME", name: "Frida Kahlo" },
        { class: Address, type: "ADDR", street: "123 South Street", city: "Sometown" }
      ]
    end

    it_will "parse the data"
  end

  describe "Legacy type signature syntax" do
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
        end
      end
    end

    let(:data) do
      <<-DATA
        |NAME|Frida     |Kahlo     |
        |ADDR|123 South Street     |Sometown            |
      DATA
    end

    let(:expected_records) do
      [
        { type_signature: "NAME", first_name: "Frida", last_name: "Kahlo" },
        { type_signature: "ADDR", street_address: "123 South Street", city: "Sometown" }
      ]
    end

    it_will "parse the data"
  end
end
