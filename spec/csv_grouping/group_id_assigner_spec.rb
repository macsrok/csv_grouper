# frozen_string_literal: true

require "spec_helper"
require "csv_grouping/group_id_assigner"

RSpec.describe CsvGrouping::GroupIdAssigner do
  subject(:assigner) { described_class.new }

  describe "#id_for" do
    it "assigns 1 to the first root seen" do
      expect(assigner.id_for(0)).to eq("1")
    end

    it "assigns incrementing ids to new roots" do
      expect(assigner.id_for(0)).to eq("1")
      expect(assigner.id_for(3)).to eq("2")
      expect(assigner.id_for(7)).to eq("3")
    end

    it "returns the same id for the same root on repeated calls" do
      assigner.id_for(0)
      assigner.id_for(1)
      expect(assigner.id_for(0)).to eq("1")
    end

    it "returns string ids" do
      expect(assigner.id_for(0)).to be_a(String)
    end
  end
end
