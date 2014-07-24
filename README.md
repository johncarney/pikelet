# Pikelet

[![Gem Version][gem-badge]][gem]
[![Build status][build-badge]][build]
[![Coverage Status][coverage-badge]][coverage]

A pikelet is a type of small pancake popular in Australia and New Zealand.
Also, a simple flat-file database parser capable of dealing with
files containing heterogeneous records.

## Installation

Add this line to your application's Gemfile:

    gem 'pikelet'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pikelet

## Usage

### Homogeneous records, fixed-width fields

    require "pikelet"

    data = <<-FLATFILE.gsub(/^\s*/, "")
      Nicolaus  Copernicus
      Tycho     Brahe
    FLATFILE

    definition = Pikelet.define do
      first_name  0...10
      last_name  10...20
    end

    definition.parse(data.split(/[\r\n]+/)).to_a

    # => [#<struct first_name="Nicolaus", last_name="Copernicus">,
    #  #<struct first_name="Tycho", last_name="Brahe">]

### Heterogeneous records, fixed-width fields

    require "pikelet"

    data = <<-FLATFILE.gsub(/^\s*/, "")
      NAMENicolaus  Copernicus
      ADDR123 South Street    Nowhereville        45678Y    Someplace           Someland
    FLATFILE

    definition = Pikelet.define do
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
        country        74...94
      end
    end

    definition.parse(data.split(/[\r\n]+/)).to_a

    # => [#<struct
    #   type_signature="NAME",
    #   first_name="Nicolaus",
    #   last_name="Copernicus">,
    #  #<struct
    #   type_signature="ADDR",
    #   street_address="123 South Street",
    #   city="Nowhereville",
    #   postal_code="45678Y",
    #   state="Someplace",
    #   country="Someland">]

### CSV files

    require "pikelet"
    require "csv"

    data = <<-CSV.gsub(/^\s*/, "")
      NAME,Nicolaus,Copernicus
      ADDR,123 South Street,Nowhereville,45678Y,Someplace,Someland
    CSV

    definition = Pikelet.define do
      type_signature 0

      record "NAME" do
        first_name 1
        last_name  2
      end

      record "ADDR" do
        street_address 1
        city           2
        postal_code    3
        state          4
        country        5
      end
    end

    definition.parse(CSV.parse(data)).to_a

    # => [#<struct
    #   type_signature="NAME",
    #   first_name="Nicolaus",
    #   last_name="Copernicus">,
    #  #<struct
    #   type_signature="ADDR",
    #   street_address="123 South Street",
    #   city="Nowhereville",
    #   postal_code="45678Y",
    #   state="Someplace",
    #   country="Someland">]

### Inheritance

    require "pikelet"

    data = <<-FLATFILE.gsub(/^\s*/, "")
      SIMPLENicolaus  Copernicus
      FANCY Tycho     Brahe     Tykester
    FLATFILE

    definition = Pikelet.define do
      type_signature 0...6

      record "SIMPLE" do
        first_name  6...16
        last_name  16...26

        record "FANCY" do
          nickname 26...36
        end
      end
    end

    definition.parse(data.split(/[\r\n]+/)).to_a

    # => [#<struct
    #   type_signature="SIMPLE",
    #   first_name="Nicolaus",
    #   last_name="Copernicus">,
    #  #<struct
    #   type_signature="FANCY",
    #   first_name="Tycho",
    #   last_name="Brahe",
    #   nickname="Tykester">]


## Contributing

1. Fork it ( http://github.com/johncarney/pikelet/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

[gem-badge]:      https://badge.fury.io/rb/pikelet.svg
[gem]:            http://badge.fury.io/rb/pikelet
[build-badge]:    https://travis-ci.org/johncarney/pikelet.svg?branch=master
[build]:          https://travis-ci.org/johncarney/pikelet
[coverage-badge]: https://img.shields.io/coveralls/johncarney/pikelet.svg
[coverage]:       https://coveralls.io/r/johncarney/pikelet?branch=master
