# frozen_string_literal: true

require "spec_helper"
require "csv_grouping/union_find"

RSpec.describe CsvGrouping::UnionFind do
  subject(:uf) { described_class.new(5) }

  describe "#find" do
    it "returns each index as its own root initially" do
      expect((0..4).map { |i| uf.find(i) }).to eq([0, 1, 2, 3, 4])
    end

    it "applies path compression on repeated find" do
      uf.union(0, 1)
      uf.union(1, 2)
      uf.find(2)
      expect(uf.find(2)).to eq(uf.find(0))
    end
  end

  describe "#union" do
    it "connects two separate indexes" do
      uf.union(0, 1)
      expect(uf.find(0)).to eq(uf.find(1))
    end

    it "is idempotent when indexes are already connected" do
      uf.union(0, 1)
      uf.union(0, 1)
      expect(uf.find(0)).to eq(uf.find(1))
    end

    it "does not connect unrelated indexes" do
      uf.union(0, 1)
      expect(uf.find(2)).not_to eq(uf.find(0))
    end

    it "supports transitive connections" do
      uf.union(0, 1)
      uf.union(1, 2)
      expect(uf.find(0)).to eq(uf.find(2))
    end
  end
end
