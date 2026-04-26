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
      @email_keys = email_columns.filter_map { |col| email_key(row[col]) }
      @phone_keys = phone_columns.filter_map { |col| phone_key(row[col]) }
    end

    def keys_for(matcher)
      reader = MATCHER_KEY_READERS.fetch(matcher, :empty_keys)
      send(reader)
    end

    private

    def all_keys
      email_keys + phone_keys
    end

    def empty_keys
      []
    end

    def email_key(value)
      normalized = value.to_s.strip.downcase
      "email:#{normalized}" unless normalized.empty?
    end

    def phone_key(value)
      # Strips the North American country code (1) from 11-digit numbers so
      # "14441234567" and "4441234567" match. Anchored to exactly 11 digits
      # so a 10-digit number that happens to start with 1 (e.g. "1234567890")
      # is left alone. Only handles NANP (+1); for multi-region support, swap
      # in phonelib/libphonenumber to parse and normalise numbers by locale.
      normalized = value.to_s.gsub(/\D/, "").sub(/\A1(\d{10})\z/, '\1')
      "phone:#{normalized}" unless normalized.empty?
    end
  end
end
