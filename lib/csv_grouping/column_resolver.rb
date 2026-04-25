# frozen_string_literal: true

module CsvGrouping
  class ColumnResolver
    Result = Struct.new(:email_columns, :phone_columns, keyword_init: true)

    class UnknownColumnError < StandardError; end

    def self.resolve(headers:, email_column:, phone_column:, infer_column_names:)
      new(headers, email_column, phone_column, infer_column_names).resolve
    end

    def initialize(headers, email_column, phone_column, infer_column_names)
      @headers = headers
      @email_column = email_column
      @phone_column = phone_column
      @infer_column_names = infer_column_names
    end

    def resolve
      Result.new(
        email_columns: resolve_type("email", @email_column),
        phone_columns: resolve_type("phone", @phone_column)
      )
    end

    private

    def resolve_type(type, explicit_column)
      inferred = @headers.select { |header| header.downcase.include?(type) }
      columns = []

      if explicit_column
        raise_unknown_column(type, explicit_column) unless @headers.include?(explicit_column)

        columns << explicit_column
      end

      columns.concat(inferred) if explicit_column && @infer_column_names == true
      columns = inferred if explicit_column.nil? && @infer_column_names != false
      columns.uniq
    end

    def raise_unknown_column(type, column)
      raise UnknownColumnError,
            "#{type} column \"#{column}\" was not found. Available columns: #{@headers.join(', ')}"
    end
  end
end
