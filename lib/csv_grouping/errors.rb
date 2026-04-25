# frozen_string_literal: true

module CsvGrouping
  # Raised when command-line arguments are syntactically valid but unsupported.
  class ValidationError < StandardError; end

  # Raised when a requested explicit CSV column is absent from the header.
  class UnknownColumnError < StandardError; end
end
