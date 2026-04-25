# frozen_string_literal: true

module CsvGrouping
  # Tracks connected record indexes for transitive person matching.
  class UnionFind
    def initialize(size)
      @parents = Array.new(size) { |index| index }
    end

    def find(index)
      root = index
      root = @parents[root] until @parents[root] == root

      current = index
      while current != root
        next_node = @parents[current]
        @parents[current] = root
        current = next_node
      end

      root
    end

    def union(left, right)
      left_root = find(left)
      right_root = find(right)
      return if left_root == right_root

      @parents[right_root] = left_root
    end
  end
end
