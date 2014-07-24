# Pikelet

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



    definition = Pikelet.define do
      first_name  0...10
      last_name  10...20
    end

### Heterogeneous records, fixed-width fields

    definition = Pikelet.define do
      type_signature 0...4

      record 'NAME' do
        first_name  4...14
        last_name  14...24
      end

      record 'ADDR' do
        street_address  4...24
        city           24...44
        postal_code    44...54
        state          44...64
        country        64...84
      end
    end

### CSV files

    definition = Pikelet.define do
      type_signature 0

      record 'NAME' do
        first_name 1
        last_name  2
      end

      record 'ADDR' do
        street_address 1
        city           2
        postal_code    3
        state          4
        country        5
      end
    end

### Inheritance

## Contributing

1. Fork it ( http://github.com/<my-github-username>/pikelet/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
