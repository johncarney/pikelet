require "pikelet/version"
require "pikelet/file_definition"
require "pikelet/record_definition"
require "pikelet/field_definition"

module Pikelet
  def self.define(type_signature: nil, record_class: nil, &block)
    Pikelet::FileDefinition.new(type_signature: type_signature, record_class: record_class, &block)
  end
end
