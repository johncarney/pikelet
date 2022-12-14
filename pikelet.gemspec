# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pikelet/version'

Gem::Specification.new do |spec|
  spec.name          = "pikelet"
  spec.version       = Pikelet::VERSION
  spec.authors       = ["John Carney"]
  spec.email         = ["john@carney.id.au"]
  spec.summary       = %q{A simple flat-file database parser.}
  spec.description   = %q{Pikelet is a type of small pancake popular in Australia and New Zealand. Also, a flat-file database parser capable of dealing with heterogeneous records.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 3.0.5'

  spec.add_development_dependency "bundler", "~> 2.1.4"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec-its"
  spec.add_development_dependency "rspec-collection_matchers"
  spec.add_development_dependency "coveralls"
  spec.add_development_dependency "pry"
end
