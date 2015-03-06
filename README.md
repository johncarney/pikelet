# Pikelet

[![Gem Version][gem-badge]][gem]
[![Build status][build-badge]][build]
[![Coverage Status][coverage-badge]][coverage]

## Introduction

A [pikelet][pikelet-recipe] is a small, delicious pancake popular in Australia
and New Zealand. Also, the stage name of Australian musician
[Evelyn Morris][pikelet-musician]. Also, a simple flat-file database parser
capable of dealing with files containing heterogeneous records. Somehow you've
wound up at the github page for the last one.

The reason I built Pikelet was to handle "HOT" files as described in the
[IATA BSP Data Interchange Specifications handbook][dish]. These are
essentially flat-file databases comprised of a number of different fixed-width
record types. Each record type has a different structure, though some types
share common fields, and all types have a type signature.

However, Pikelet will also handle more typical flat-file databases comprised
of homogeneous records. It can also be used produce data in flat-file format.

## Installation

Add this line to your application's Gemfile:

    gem 'pikelet'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pikelet

## Usage

### The simple case: homogeneous records

Let's say our file is a simple list of first and last names with each field
being 10 characters in width, padded with spaces (vertical pipes used to
indicate field boundaries).

    |Grace     |Hopper    |
    |Ada       |Lovelace  |

We can describe this format using Pikelet as follows:

    definition = Pikelet.define do
      first_name   0...10
      last_name   10...20
    end

Each field is described with a field name and a range describing the field
boundaries. You can use either the end-inclusive (`..`) or end-exclusive
(`...`) form of range literals. I prefer the exclusive form for this.

Parsing the data is simple as this:

    definition.parse(data)

`data` is assumed to be an enumerable object yielding successive lines from
your file. For instance, you could do something like this:

    records = definition.parse(IO.readlines(filepath))

or this:

    records = File(filepath, 'r').do |f|
      definition.parse(f)
    end

`parse` returns an enumerator, which you can either iterate over, or convert
to an array, or whatever else you people do with enumerators. In any case,
what you'll end up with is a series of `Structs` like this:

    #<struct first_name="Grace", last_name="Hopper">,
    #<struct first_name="Ada", last_name="Lovelace">

You can output these records in flat-file format like so:

    definition.format(records)

Which will return an array of strings:

    [
      "Grace     Hopper    ",
      "Ada       Lovelace  "
    ]

### A more complex case: heterogeneous records

Now let's say we're given a file consisting of names and addresses, each
record contains a 4-character type signature - 'NAME' for names, 'ADDR' for
addresses:

    |NAME|Frida     |Kahlo     |
    |ADDR|123 South Street     |Sometown            |45678Y    |Someplace           |

We can describe it as follows:

    definition = Pikelet.define signature_field: :type do
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

The `signature_field` option tells Pikelet which field to use to determine
which record type to apply.

Each record type is described using `record` statements, which take the
record's type signature as a parameter and a block describing its fields.

When we parse the data, we end up with this:

    #<struct
      type="NAME",
      first_name="Frida",
      last_name="Kahlo">,
    #<struct
      type="ADDR",
      street_address="123 South Street",
      city="Sometown",
      postal_code="45678Y",
      state="Someplace">

As with the simple case of homogenous records, calling the `format` method on
your definition with the records will output an array of strings:

    [
      "NAMEFrida     Kahlo                                                        ",
      "ADDR123 South Street     Sometown            45678Y    Someplace           "
    ]

Note that each record is padded out to the full width of the widest record
type.

### Inheritance

Now we go back to our original example, starting with a simple list of names,
but this time some of the records include a middle name:

    |NAME |Rosa      |Parks     |
    |NAME+|Rosalind  |Franklin  |Elsie     |

The first and last name fields have the same boundaries in each case, but the
"NAME+" records have an additional field. We can describe this by nesting the
definition for NAME+ records inside the definition for the NAME records:

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

Note that the outer definition is really just a record definition in disguise,
you might have already figured this out if you were paying attention.

Anyway, this is what we get when we parse it.

    #<struct
      record_type="NAME",
      first_name="Rosa",
      last_name="Parks">,
    #<struct
      record_type="NAME+",
      first_name="Rosalind",
      last_name="Franklin",
      middle_name="Elsie">

### Custom field parsing

Field definitions can accept a block. If provided, the field value is yielded
to the block. This is useful for parsing numeric fields (say).

    Pikelet.define do
      a_number(0...4) { |value| value.to_i }
    end

You can also use shorthand syntax:

    Pikelet.define do
      a_number 0...4, &:to_i
    end

A parsers can also be supplied as an option.

    Pikelet.define do
      a_number  0... 4, parse: ->(value) { value.to_i }
      some_text 4...10, parse: :upcase
    end

### Custom field formatters

You can supply a custom formatter for a field.

    definition = Pikelet.define do
      username  0...10, format: :downcase
      password 10...50, format: ->(v) { Digest::SHA1.hexdigest(v) }
    end

    definition.format([
      OpenStruct.new(username: "Coleman",    password: "password"),
      OpenStruct.new(username: "Savitskaya", password: "sekrit"  )
    ])

This will produce the following array of strings:

    [
      "coleman   5baa61e4c9b93f3f0682250b6cf8331b7ee68fd8",
      "savitskaya8d42e738c7adee551324955458b5e2c0b49ee655"
    ]

### Formatting options

In addition to custom formatters, you can provide alignment and padding
options.

    definition = Pikelet.define do
      number 0... 3, align: :right, pad: "0"
      text   3...10, align: :left,  pad: " "
    end

There is also a `type` option, which is a shorthand for default alpha and
numeric formatting.

    definition = Pikelet.define do
      number 0... 3, type: :numeric # right-align, pad with zeroes
      text   3...10, type: :alpha   # left-align, pad with spaces
    end

### Custom record classes

By default Pikelet will return records as `Struct` objects, but you can supply
a custom class to use instead.

    class Base
      attr_reader :type

      def initialize(**attrs)
        @type = attrs[:type]
      end
    end

    class Name < Base
      attr_reader :name

      def initialize(**attrs)
        super(type: "NAME")
        @name = attrs[:name]
      end
    end

    class Address < Base
      attr_reader :street, :city

      def initialize(**attrs)
        super(type: "ADDR")
        @street = attrs[:street]
        @city = attrs[:city]
      end
    end

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

The only requirement on the class is that its constructor (ie. `initialize`
method) should accept attributes as a hash with symbol keys.

### Legacy type signature syntax

In Pikelet v1.x there wasn't a `signature_field` option. Instead, you were
required to name your signature field `type_signature`.

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

## Thoughts/plans

* I had a crack at supporting lazy enumeration, and it kinda works. Sometimes.
  If the moon is in the right quarter. I'd like to get it working properly.

## Contributing

1. Fork it ([http://github.com/johncarney/pikelet/fork][fork])
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

[pikelet-recipe]:   http://www.taste.com.au/recipes/5757/pikelets
[pikelet-musician]: http://en.wikipedia.org/wiki/Evelyn_Morris
[dish]:             http://www.iata.org/publications/Pages/bspdish.aspx
[overpunch]:        https://github.com/johncarney/overpunch
[gem-badge]:        https://badge.fury.io/rb/pikelet.svg
[gem]:              http://badge.fury.io/rb/pikelet
[build-badge]:      https://travis-ci.org/johncarney/pikelet.svg?branch=master
[build]:            https://travis-ci.org/johncarney/pikelet
[coverage-badge]:   https://img.shields.io/coveralls/johncarney/pikelet.svg
[coverage]:         https://coveralls.io/r/johncarney/pikelet?branch=master
[fork]:             http://github.com/johncarney/pikelet/fork
