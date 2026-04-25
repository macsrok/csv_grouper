# frozen_string_literal: true

module CsvGrouping
  # Tracks connected record indexes for transitive person matching.
  class UnionFind
    def initialize(size)
      @parents = Array.new(size) { |index| index }
    end

    def find(index)
      parent = @parents[index]
      return parent if parent == index

      @parents[index] = find(parent)
    end

    def union(left, right)
      left_root = find(left)
      right_root = find(right)
      return if left_root == right_root

      @parents[right_root] = left_root
    end
  end
end
