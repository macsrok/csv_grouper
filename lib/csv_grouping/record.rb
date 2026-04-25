# frozen_string_literal: true

module CsvGrouping
  # Wraps one CSV row and exposes pre-normalized matcher keys.
  class Record
    MATCHER_KEY_READERS = {
      "same_email" => :email_keys,
      "same_phone" => :phone_keys,
      "same_email_or_phone" => :all_keys
    }.freeze
    EMAIL_KEY = lambda do |value|
      normalized = value.to_s.strip.downcase
      "email:#{normalized}" unless normalized.empty?
    end
    PHONE_KEY = lambda do |value|
      normalized = value.to_s.gsub(/\D/, "")
      "phone:#{normalized}" unless normalized.empty?
    end

    attr_reader :row, :email_keys, :phone_keys

    def initialize(row, email_columns:, phone_columns:)
      @row = row
      @email_keys = normalized_keys(email_columns, EMAIL_KEY)
      @phone_keys = normalized_keys(phone_columns, PHONE_KEY)
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

    def normalized_keys(columns, normalizer)
      columns.filter_map { |column| normalizer.call(row[column]) }
    end
  end
end
