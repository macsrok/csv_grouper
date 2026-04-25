# frozen_string_literal: true

require "csv"

require "csv_grouping/cli_options"
require "csv_grouping/column_resolver"
require "csv_grouping/csv_output"
require "csv_grouping/errors"
require "csv_grouping/record_grouper"

module CsvGrouping
  # Coordinates one CLI run from parsed options through grouped CSV output.
  class Application
    def self.call(argv:, stdout:, stderr:)
      new(argv, stdout, stderr).call
    end

    def initialize(argv, stdout, stderr)
      @argv = argv
      @stdout = stdout
      @stderr = stderr
    end

    def call
      options = CliOptions.parse(@argv)
      table = CSV.read(options.input_path, headers: true)
      output = build_output(options, table)

      @stdout.write(output.preview)
      0
    rescue ValidationError,
           UnknownColumnError,
           Errno::ENOENT,
           CSV::MalformedCSVError => error
      @stderr.puts("Error: #{error.message}")
      1
    end

    private

    def build_output(options, table)
      headers = table.headers
      columns = resolve_columns(options, headers)

      CsvOutput.write(
        input_path: options.input_path,
        matcher: options.matcher,
        headers: ["PersonId"] + headers,
        rows: grouped_rows(options, table, columns),
        output_dir: options.output_dir
      )
    end

    def grouped_rows(options, table, columns)
      RecordGrouper.group(
        rows: table.map(&:to_h),
        matcher: options.matcher,
        email_columns: columns.email_columns,
        phone_columns: columns.phone_columns
      )
    end

    def resolve_columns(options, headers)
      ColumnResolver.resolve(
        headers: headers,
        email_column: options.email_column,
        phone_column: options.phone_column,
        infer_column_names: options.infer_column_names
      )
    end
  end
end
