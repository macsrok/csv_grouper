# frozen_string_literal: true

require "csv_grouping/group_id_assigner"
require "csv_grouping/record"
require "csv_grouping/union_find"

module CsvGrouping
  # Builds transitive person groups from each record's matcher keys.
  class RecordGrouper
    # Values needed to build person groups from CSV rows.
    Request = Struct.new(:rows, :matcher, :email_columns, :phone_columns, keyword_init: true)

    def self.group(request)
      new(request).group
    end

    def initialize(request)
      rows = request.rows
      @records = rows.map do |row|
        Record.new(row, email_columns: request.email_columns, phone_columns: request.phone_columns)
      end
      @matcher = request.matcher
      @union_find = UnionFind.new(rows.length)
    end

    def group
      union_matching_records
      assign_group_ids
    end

    private

    def union_matching_records
      indexes_by_key.each_value { |indexes| union_indexes(indexes) }
    end

    def union_indexes(indexes)
      first = indexes.first
      indexes.drop(1).each { |index| @union_find.union(first, index) }
    end

    def assign_group_ids
      assigner = GroupIdAssigner.new

      @records.each_with_index.map do |record, index|
        root = @union_find.find(index)
        { "PersonId" => assigner.id_for(root) }.merge(record.row)
      end
    end

    def indexes_by_key
      keys = Hash.new { |hash, key| hash[key] = [] }

      @records.each_with_index do |record, index|
        store_record_keys(keys, record, index)
      end

      keys
    end

    def store_record_keys(keys, record, index)
      record.keys_for(@matcher).each { |key| keys[key] << index }
    end

  end
end
