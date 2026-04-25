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
      @next_id.to_s.tap { @next_id += 1 }
    end
  end
end
