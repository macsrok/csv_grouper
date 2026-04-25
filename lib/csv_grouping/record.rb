# frozen_string_literal: true

module CsvGrouping
  # Wraps one CSV row and exposes pre-normalized matcher keys.
  class Record
    MATCHER_KEY_READERS = {
      "same_email" => :email_keys,
      "same_phone" => :phone_keys,
      "same_email_or_phone" => :all_keys
    }.freeze

    attr_reader :row, :email_keys, :phone_keys

    def initialize(row, email_columns:, phone_columns:)
      @row = row
      @email_keys = email_columns.filter_map { |column| email_key(row[column]) }
      @phone_keys = phone_columns.filter_map { |column| phone_key(row[column]) }
    end

    def keys_for(matcher)
      reader = MATCHER_KEY_READERS.fetch(matcher, :empty_keys)
      public_send(reader)
    end

    def all_keys
      email_keys + phone_keys
    end

    def empty_keys
      []
    end

    private

    def email_key(value)
      normalized = value.to_s.strip.downcase
      "email:#{normalized}" unless normalized.empty?
    end

    def phone_key(value)
      normalized = value.to_s.gsub(/\D/, "")
      "phone:#{normalized}" unless normalized.empty?
    end
  end
end
