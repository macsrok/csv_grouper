# frozen_string_literal: true

module CsvGrouping
  # Resolves the CSV columns used as email and phone match sources.
  class ColumnResolver
    # Column lists selected for email and phone matching.
    Result = Struct.new(:email_columns, :phone_columns, keyword_init: true)

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
      return inferred if !explicit_column && @infer_column_names != false
      return [] unless explicit_column

      validate_explicit_column(type, explicit_column)
      selected = [explicit_column]
      selected.concat(inferred) if @infer_column_names == true
      selected.uniq
    end

    def validate_explicit_column(type, column)
      return if @headers.include?(column)

      raise_unknown_column(type, column)
    end

    def raise_unknown_column(type, column)
      raise UnknownColumnError,
            "#{type} column \"#{column}\" was not found. Available columns: #{@headers.join(', ')}"
    end
  end
end
