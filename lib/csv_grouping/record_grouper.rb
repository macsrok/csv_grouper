# frozen_string_literal: true

require "csv_grouping/record"

module CsvGrouping
  # Builds transitive person groups from each record's matcher keys.
  class RecordGrouper
    MATCHERS = %w[same_email same_phone same_email_or_phone].freeze

    def self.group(rows:, matcher:, email_columns:, phone_columns:)
      new(rows, matcher, email_columns, phone_columns).group
    end

    def initialize(rows, matcher, email_columns, phone_columns)
      @records = rows.map do |row|
        Record.new(row, email_columns: email_columns, phone_columns: phone_columns)
      end
      @matcher = matcher
      @parents = Array.new(rows.length) { |index| index }
    end

    def group
      union_matching_records
      assign_group_ids
    end

    private

    def union_matching_records
      indexes_by_key.each_value do |indexes|
        first = indexes.first
        indexes.drop(1).each { |index| union(first, index) }
      end
    end

    def assign_group_ids
      group_ids = {}
      next_id = 1

      @records.each_with_index.map do |record, index|
        root = find(index)
        next_id = store_group_id(group_ids, root, next_id)
        { "PersonId" => group_ids.fetch(root) }.merge(record.row)
      end
    end

    def store_group_id(group_ids, root, next_id)
      return next_id if group_ids.key?(root)

      group_ids[root] = next_id.to_s
      next_id + 1
    end

    def indexes_by_key
      @records.each_with_index.each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |(record, index), keys|
        record.keys_for(@matcher).each do |key|
          keys[key] << index
        end
      end
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
