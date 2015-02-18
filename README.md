# Pikelet

[![Gem Version][gem-badge]][gem]
[![Build status][build-badge]][build]
[![Coverage Status][coverage-badge]][coverage]

## Beta notes

The next release of Pikelet will be capable of formatting flat-file databases
for output. As part of this I will be dropping CSV support as it is
constraining my options and, as far as I know, nobody is using it. For the
time being I want to let it evolve as a pure flat-file database parser. In a
future release I may restore CSV support, but I make no promises.

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
of homogeneous records.

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

    |Nicolaus  |Copernicus|
    |Tycho     |Brahe     |

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

    #<struct first_name="Nicolaus", last_name="Copernicus">,
    #<struct first_name="Tycho", last_name="Brahe">

### A more complex case: heterogeneous records

Now let's say we're given a file consisting of names and addresses, each
record contains a 4-character type signature - 'NAME' for names, 'ADDR' for
addresses:

    |NAME|Nicolaus  |Copernicus|
    |ADDR|123 South Street     |Nowhereville        |45678Y    |Someplace           |

We can describe it as follows:

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

Note that the type signature is described as a field like any other, but it
must have the name `type_signature`.

Each record type is described using `record` statements, which take the
record's type signature as a parameter and a block describing its fields.

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

### Inheritance

Now we go back to our original example, starting with a simple list of names,
but this time some of the records include a nickname:

    |PLAIN|Nicolaus  |Copernicus|
    |FANCY|Tycho     |Brahe     |Tykester  |

The first and last name fields have the same boundaries in each case, but the
"FANCY" records have an additional field. We can describe this by nesting the
definition for FANCY records inside the definition for the PLAIN records:

    Pikelet.define do
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

## Thoughts/plans

* With some work, Pikelet could produce flat file records as easily as it
  consumes them.
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
