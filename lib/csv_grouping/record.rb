# frozen_string_literal: true

module CsvGrouping
  class Record
    attr_reader :row, :email_keys, :phone_keys

    def initialize(row, email_columns:, phone_columns:)
      @row = row
      @email_keys = normalized_keys(row, email_columns, "email")
      @phone_keys = normalized_keys(row, phone_columns, "phone")
    end

    def keys_for(matcher)
      case matcher
      when "same_email"
        email_keys
      when "same_phone"
        phone_keys
      when "same_email_or_phone"
        email_keys + phone_keys
      else
        []
      end
    end

    private

    def normalized_keys(row, columns, type)
      columns.filter_map do |column|
        value = normalize(row[column], type)
        "#{type}:#{value}" unless value.nil? || value.empty?
      end
    end

    def normalize(value, type)
      return nil if value.nil?

      type == "email" ? value.strip.downcase : value.gsub(/\D/, "")
    end
  end
end
