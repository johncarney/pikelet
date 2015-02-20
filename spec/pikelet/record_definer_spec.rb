require "spec_helper"
require "pikelet"

describe Pikelet::RecordDefiner do
  let(:definer)    { described_class.new(nil) }
  let(:definition) { definer.definition }
end

