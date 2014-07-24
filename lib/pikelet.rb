require "pikelet/version"
require "pikelet/file_definition"
require "pikelet/record_definition"
require "pikelet/field_definition"

module Pikelet
  def self.define(&block)
    Pikelet::FileDefinition.new(&block)
  end
end
