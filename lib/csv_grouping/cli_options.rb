# frozen_string_literal: true

require "optparse"

require "csv_grouping/record_grouper"

module CsvGrouping
  # Parses and validates command-line options after the shell wrapper delegates.
  class CliOptions
    BOOLEAN_VALUES = {
      "true" => true,
      "false" => false
    }.freeze

    # Immutable option values consumed by the application runner.
    Options = Struct.new(
      :input_path,
      :matcher,
      :output_dir,
      :email_column,
      :phone_column,
      :infer_column_names,
      keyword_init: true
    )

    # Raised when CLI arguments are syntactically valid but unsupported.
    class ValidationError < StandardError; end

    def self.parse(argv)
      new(argv).parse
    end

    def initialize(argv)
      @argv = argv
      @values = {}
    end

    def parse
      parser.parse!(@argv)
      validate
      Options.new(**@values)
    rescue OptionParser::ParseError => error
      raise ValidationError, error.message
    end

    private

    def parser
      OptionParser.new do |opts|
        add_value_option(opts, :input_path, "--input PATH")
        add_value_option(opts, :matcher, "--matcher MATCHER")
        add_value_option(opts, :output_dir, "--output-dir DIR", "--output_dir DIR")
        add_value_option(opts, :email_column, "--email-column COLUMN", "--email_column COLUMN")
        add_value_option(opts, :phone_column, "--phone-column COLUMN", "--phone_column COLUMN")
        add_boolean_option(opts, :infer_column_names, "--infer-column-names VALUE", "--infer_column_names VALUE")
      end
    end

    def add_value_option(opts, key, *names)
      opts.on(*names) { |value| @values[key] = value }
    end

    def add_boolean_option(opts, key, *names)
      opts.on(*names) { |value| @values[key] = parse_boolean(value) }
    end

    def validate
      matcher = @values[:matcher]

      raise ValidationError, "input is required" if blank?(@values[:input_path])
      raise ValidationError, "matcher is required" if blank?(matcher)

      return if RecordGrouper::MATCHERS.include?(matcher)

      raise ValidationError, "matcher must be one of #{RecordGrouper::MATCHERS.join(', ')}"
    end

    def parse_boolean(value)
      BOOLEAN_VALUES.fetch(value.to_s.downcase) do
        raise ValidationError, "infer-column-names must be true or false"
      end
    end

    def blank?(value)
      value.to_s.empty?
    end
  end
end
