# frozen_string_literal: true

module CsvGrouping
  # Assigns stable sequential PersonId values to connected record roots.
  class GroupIdAssigner
    def initialize
      @group_ids = {}
      @next_id = 1
    end

    def id_for(root)
      @group_ids[root] ||= next_group_id
    end

    private

    def next_group_id
      id = @next_id
      @next_id += 1
      id.to_s
    end
  end
end
