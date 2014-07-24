# Pikelet

[![Gem Version][gem-badge]][gem]
[![Build status][build-badge]][build]
[![Coverage Status][coverage-badge]][coverage]

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
of homogeneous records. Additionally, it will work equally as well with CSV
files as it will with fixed-width records.

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
being 10 characters in width, padded with spaces.

    Nicolaus  Copernicus
    Tycho     Brahe

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

The parse returns an enumerator, which you can either iterate over, or convert
to an array, or whatever else you people do with enumerators. In any case,
what you'll end up with is a series of `Structs` like this:

    #<struct first_name="Nicolaus", last_name="Copernicus">,
    #<struct first_name="Tycho", last_name="Brahe">

### A more complex case: heterogeneous records

Now let's say we're given a file consisting of names and addresses, each
record contains a 4-character type signature - 'NAME' for names, 'ADDR' for
addresses:

    NAMENicolaus  Copernicus
    ADDR123 South Street    Nowhereville        45678Y    Someplace

We can describe it as follows:

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
      end
    end

Note that the type signature is described as a field like any other, but it
must have the name `type_signature`.

Each record type is described in `record` statements which take the record's
type signature as a parameter and a block describing its fields.

When we parse the data, we end up with this:

    #<struct
      type_signature="NAME",
      first_name="Nicolaus",
      last_name="Copernicus">,
    #<struct
      type_signature="ADDR",
      street_address="123 South Street",
      city="Nowhereville",
      postal_code="45678Y",
      state="Someplace">

### Handling CSV files

What happens if we were given the data in the previous example in CSV form?

    NAME,Nicolaus,Copernicus
    ADDR,123 South Street,Nowhereville,45678Y,Someplace,Someland

In this case instead of describing fields with a boundary range, we just
give it a simple (zero-based) index, like so:

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

This yields the same results as above. Note that this ability to handle CSV
was not planned - it just sprang fully-formed from the implementation. One of
those pleasant little surprises that happens sometimes. If only I had a use
for it.

### Inheritance

Now we go back to our original example starting with a simple list of names,
but this time some of the records include a nickname:

    PLAINNicolaus  Copernicus
    FANCYTycho     Brahe     Tykester

The first and last name fields have the same boundaries in each case, but the
"FANCY" records have an additional field. We can describe this by nesting the
definition for FANCY records inside the definition for the PLAIN records:

    definition = Pikelet.define do
      type_signature 0...5

      record "PLAIN" do
        first_name  5...15
        last_name  15...25

        record "FANCY" do
          nickname 25...35
        end
      end
    end

Note that the outer definition is really just a record definition in disguise,
you might have already figured this out if you were paying attention.

Anyway, this is what we get when we parse it.

    #<struct
      type_signature="SIMPLE",
      first_name="Nicolaus",
      last_name="Copernicus">,
    #<struct
      type_signature="FANCY",
      first_name="Tycho",
      last_name="Brahe",
      nickname="Tykester">

### Numeric fields

Pikelet can convert numeric fields to integers. To arrange for this, simply
tell it what the field type is:

    Pikelet.define do
      a_number 0...4, type: :integer
    end

If you're into really, really old tech, it can also handle numbers in signed
overpunch format:

    Pikelet.define do
      a_number 0...4, type: :overpunch
    end

You can learn more about signed overpunch here:
[https://github.com/johncarney/overpunch][overpunch]. It's kinda interesting,
if you're some kind of tech hipster.

Currently only integers and signed overpunch numbers are supported.

### A stupid trick

The `field` statement will actually accepts multiple ranges/indices and will
simply glue the sections described together. Consider the following data:

    BFH0000000101LONZZZ  203TEST1101022359GB000001
    BCH00000002020111101007F110107
    BOH000000030391200001101031                       GBP2
    BKT0000000406      000001                    011X ZZZ

In this format the first three characters are a 'message identifier', the next
8 characters are a sequence number and the next 2 are a 'numeric qualifier'.
The message identifier and numeric qualifier together form the type signature.

We can describe this as follows (let's not bother describing all the
different record types):

    Pikelet.define do
      type_signature  0... 3, 11...13
      sequence        3...11, type: :integer
      payload        11.. -1
    end

Which will yield:

    #<struct
      type_signature="BFH01",
      sequence=1,
      payload="LONZZZ  203TEST1101022359GB000001">,
    #<struct
      type_signature="BCH02",
      sequence=2,
      payload="0111101007F110107">,
    #<struct
      type_signature="BOH03",
      sequence=3,
      payload="91200001101031                       GBP2">,
    #<struct
      type_signature="BKT06",
      sequence=4,
      payload="000001                    011X ZZZ">

In case you were wondering, no I didn't make that format up. That is what a
[BSP HOT file][dish] actually looks like, except there's a hell of a lot more
of it and many, many more record types.

## Thoughts/plans

* With a very small amount of work, Pikelet could produce flat file records
  as easily as it consumes them.
* The way integer fields are described is very primitive and I'd like to
  add the ability to accept 'pluggable' field parsers.
* I'd also like to ditch the signed overpunch, but it's the easiest way to
  deal with a particular itch I need scratched right now.
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
