# frozen_string_literal: true

require "spec_helper"
require "csv_grouping/version"

RSpec.describe CsvGrouping::VERSION do
  it "is defined" do
    expect(CsvGrouping::VERSION).not_to be_nil
  end
end
