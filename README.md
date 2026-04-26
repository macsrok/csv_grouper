# CSV Grouping

Ruby 4 command-line application for grouping CSV rows that may represent the same person. The public entrypoint is the root bash wrapper:

```bash
./group_records --input data/input1.csv --matcher same_email
```

## Requirements

- Ruby 4.x
- Bundler

The wrapper checks for Ruby 4 before execution. It runs `bundle check` and automatically runs `bundle install` when gems are missing.

## Usage

```bash
./group_records --input PATH --matcher MATCHER [options]
```

Required options:

- `--input PATH`: CSV file to process.
- `--matcher MATCHER`: one of `same_email`, `same_phone`, or `same_email_or_phone`.

Optional options:

- `--output-dir DIR`, `--output_dir DIR`: directory for the full output CSV. Defaults to `outputs/`.
- `--email-column COLUMN`, `--email_column COLUMN`: use this email column instead of inferred email columns.
- `--phone-column COLUMN`, `--phone_column COLUMN`: use this phone column instead of inferred phone columns.
- `--infer-column-names true|false`, `--infer_column_names true|false`: controls column inference. Defaults to `true`. When `true` and an explicit column is also provided, both the explicit and inferred columns are used. Pass `false` to use only the explicit column and skip inference entirely.
- `-h`, `--help`: print help.

Example:

```bash
./group_records \
  --input data/input2.csv \
  --matcher same_email_or_phone \
  --output-dir outputs \
  --email-column Email1 \
  --phone-column Phone1 \
  --infer-column-names true
```

## Matching

`same_email` groups rows that share any configured email value. Email matching trims whitespace and compares case-insensitively.

`same_phone` groups rows that share any configured phone value. Phone matching removes all non-digits before comparison.

`same_email_or_phone` groups rows that share either email or phone. Matching is transitive: if row A matches row B and row B matches row C, all three rows receive the same `PersonId`.

Blank normalized values are ignored.

## Column Selection

By default, email and phone columns are inferred from header names.

- Email columns: any header containing `email`, case-insensitively, such as `workEmail`, `email1`, `email2`, or `Email`.
- Phone columns: any header containing `phone`, case-insensitively, such as `Phone`, `Phone1`, or `mobilePhone`.

If `--email-column` is provided, that column and any inferred email columns are both used (inference is on by default). Pass `--infer-column-names false` to use only the explicit column.

If `--phone-column` is provided, that column and any inferred phone columns are both used (inference is on by default). Pass `--infer-column-names false` to use only the explicit column.

If no explicit column is provided for a match type, inferred columns are used.

If an explicit column does not exist in the CSV header, the Ruby application prints a clear validation error.

## Output

The output CSV preserves the original row order and prepends `PersonId`.

Person IDs are deterministic integers assigned by first group appearance in the input.

The full grouped CSV is written to `outputs/` by default, or to `--output-dir` when supplied. Filenames use the input basename and matcher, for example:

```text
outputs/input1_same_email.csv
```

The command also prints a preview to stdout: the header plus the last 100 data rows.

## Tests

Run the full test suite:

```bash
bundle exec rspec spec/
```

Run a specific spec:

```bash
bundle exec rspec spec/csv_grouping/record_grouper_spec.rb
```

## AI Process Notes

I used ChatGPT/Codex as a pair-programming assistant. The main instructions were to use Superpowers, follow TDD, and commit at each major code addition. I directed it to build a Ruby 4 solution with a root bash wrapper, RSpec tests, deterministic IDs, column inference, explicit-column overrides, output files, and sample-data smoke tests.

The full prompt and response transcript is available at `docs/session_exports/2026-04-25-csv-grouping-session.md`.

Important course corrections:

- Switched the test framework from Minitest to RSpec.
- Moved user-facing help text from Ruby into the bash wrapper because the wrapper is the public entrypoint.
- Added a `Record` object so each row encapsulates normalization and matcher key extraction at creation time.
- Standardized specs around `let`, `subject`, and `context` blocks instead of inline setup variables.

Prompts and instructions included:

```text
Use Superpowers to help me accomplish this task. TDD should be used.
Commits should be made at each major code addition.
```

```text
The entry point into the application should be a bash script.
The script should present an error if Ruby 4 is not installed.
It should check gems with bundle check and run bundle install automatically.
It should take --input and --matcher, write full output to /outputs by default,
print the last 100 rows to stdout, support --output-dir, explicit email/phone
columns, and --infer-column-names true.
```

```text
I want rspec not minitest.
```

```text
There should be a record object that encapsulates the row.
All normalization and key extraction should happen there.
```

```text
Do not use var = val; use let and context blocks.
```

### Second pass — Claude as code reviewer

After the initial build, I did a second pass with Claude playing the role of a hiring-manager-style reviewer. It identified 12 Ruby best-practice issues across the codebase: lambda constants used to hold behaviour rather than values, public methods that should have been private, a cross-layer coupling between `CliOptions` and `RecordGrouper`, a `tap`-based mutation in `GroupIdAssigner`, an over-engineered `OutputPath` class wrapping three string operations, a `CsvOutput::Request` struct with proxy methods that just delegated to `options`, and a recursive `UnionFind#find` that could overflow the stack on large inputs. I worked through the fixes task by task using subagent-driven development with spec-compliance and code-quality review after each change.

The same pass surfaced a real correctness bug: the phone normaliser stripped non-digits but did nothing about country codes, which silently caused row 5 (`14441234567`) to fail to match row 2 (`444.123.4567`) in `input1.csv`. I added a regex that strips a leading `1` from exactly 11-digit numbers, scoped the fix to NANP in a code comment, and added a regression test.

Other additions in the second pass: unit specs for `UnionFind` and `GroupIdAssigner` (which previously had only indirect coverage), SimpleCov with a 90% minimum coverage gate, README and `-h` help-text updates to reflect the `infer_column_names` default change, and verification that all three sample files produce correct groupings under all three matchers.
