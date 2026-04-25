# CSV Grouping Challenge Design

## Goal

Build a Ruby CSV grouping application that identifies rows that may represent the same person. The application supports matching by email, phone, or either value, prepends a deterministic person identifier to each row, writes the complete result to disk, and prints the last 100 output rows to stdout.

## User Interface

The user-facing entrypoint is a light bash wrapper in the repository root.

Example:

```bash
./group_records --input /path/to/file.csv --matcher same_email --output-dir /path/to/output --email-column workEmail --phone-column mobilePhone --infer-column-names true
```

The wrapper is intentionally small. It only:

- Requires `--input` and `--matcher`; if either is missing, it prints an error and exits nonzero.
- Prints the detailed help screen for `-h` or `--help` and exits zero before checking Ruby or Bundler.
- Checks that `ruby` exists and has major version `4`; if not, it prints an error and exits nonzero.
- Runs `bundle check`; if dependencies are missing, it runs `bundle install` automatically.
- Delegates all remaining validation and execution to the Ruby application.

The Ruby CLI owns execution option parsing and validation after the wrapper delegates.

## Matching

The Ruby application supports three matcher names:

- `same_email`: group rows that share a normalized email value.
- `same_phone`: group rows that share a normalized phone value.
- `same_email_or_phone`: group rows that share either a normalized email or normalized phone value.

Email normalization trims whitespace and compares case-insensitively. Phone normalization strips all non-digits and ignores blank results.

Grouping is transitive. If row A shares an email with row B, and row B shares a phone with row C, all three rows receive the same `PersonId` when using `same_email_or_phone`.

## Column Selection

Email and phone columns are inferred by default.

Email inference treats any column whose name contains `email`, case-insensitively, as an email column. Examples include `workEmail`, `email1`, `email2`, and `email`.

Phone inference treats any column whose name contains `phone`, case-insensitively, as a phone column.

If `--email-column` is provided, only that column is used for email matching instead of inferred columns. If `--infer-column-names true` is also provided, the explicit email column and all inferred email columns are used.

If `--phone-column` is provided, only that column is used for phone matching instead of inferred columns. If `--infer-column-names true` is also provided, the explicit phone column and all inferred phone columns are used.

Unknown explicit columns are validation errors reported by the Ruby application.

## Output

The application preserves the original CSV header and row order, prepending a `PersonId` column.

`PersonId` values are deterministic integers assigned by first group appearance in the input. The first connected group encountered receives `1`, the next receives `2`, and so on.

The complete grouped CSV is written to `outputs/` by default. If `--output-dir` is supplied, that directory is used instead. The output filename is based on the input filename and matcher, for example `input1_same_email.csv`.

The CLI prints the last 100 data rows of the grouped output to stdout, including the prepended header. If the output contains fewer than 100 data rows, it prints all data rows.

## Architecture

The implementation uses small Ruby objects:

- CLI option parser: parses arguments, validates matcher names and columns, and coordinates execution.
- Column resolver: computes the email and phone columns from headers and explicit options.
- Record: wraps one CSV row, normalizes email and phone values at creation time, and exposes matcher keys.
- Record grouper: builds connected groups from record matcher keys with a union-find structure and assigns deterministic person IDs.
- CSV writer: writes full output to disk and formats the stdout preview.

The bash wrapper remains a thin launcher and does not duplicate Ruby validation logic beyond help text, `--input`, `--matcher`, Ruby 4, and dependencies.

## Testing

Implementation uses TDD with RSpec. Each behavioral slice starts with a failing spec, then the smallest implementation to pass it, then cleanup while specs stay green.

Tests cover:

- Email matching with case-insensitive normalization.
- Phone matching across punctuation and country-code-like formatting.
- Transitive grouping for `same_email_or_phone`.
- Deterministic `PersonId` assignment by first group appearance.
- Default email and phone column inference.
- Explicit column override behavior.
- Explicit plus inferred column behavior when `--infer-column-names true` is passed.
- Output file creation in the default and custom output directories.
- Stdout preview containing the header and last 100 data rows.
- Detailed wrapper help text.
- Bash wrapper checks for required wrapper arguments, Ruby 4, and Bundler dependency installation.

## Documentation

The root README documents setup, usage examples, matcher semantics, output behavior, and AI-assistance process notes, including the user instructions that shaped the implementation.
