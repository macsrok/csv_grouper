# frozen_string_literal: true

require "optparse"

require "csv_grouping/record_grouper"

module CsvGrouping
  class CliOptions
    Options = Struct.new(
      :input_path,
      :matcher,
      :output_dir,
      :email_column,
      :phone_column,
      :infer_column_names,
      keyword_init: true
    )

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
    rescue OptionParser::ParseError => e
      raise ValidationError, e.message
    end

    private

    def parser
      OptionParser.new do |opts|
        opts.on("--input PATH") { |value| @values[:input_path] = value }
        opts.on("--matcher MATCHER") { |value| @values[:matcher] = value }
        opts.on("--output-dir DIR", "--output_dir DIR") { |value| @values[:output_dir] = value }
        opts.on("--email-column COLUMN", "--email_column COLUMN") { |value| @values[:email_column] = value }
        opts.on("--phone-column COLUMN", "--phone_column COLUMN") { |value| @values[:phone_column] = value }
        opts.on("--infer-column-names VALUE", "--infer_column_names VALUE") do |value|
          @values[:infer_column_names] = parse_boolean(value)
        end
      end
    end

    def validate
      raise ValidationError, "input is required" if blank?(@values[:input_path])
      raise ValidationError, "matcher is required" if blank?(@values[:matcher])

      return if RecordGrouper::MATCHERS.include?(@values[:matcher])

      raise ValidationError, "matcher must be one of #{RecordGrouper::MATCHERS.join(', ')}"
    end

    def parse_boolean(value)
      case value&.downcase
      when "true"
        true
      when "false"
        false
      else
        raise ValidationError, "infer-column-names must be true or false"
      end
    end

    def blank?(value)
      value.nil? || value.empty?
    end
  end
end
