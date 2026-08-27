# Generators

Python scripts that produced the SQL in [../schema/](../schema/) from source
registries and the ISO 20022 MDR specification text. Re-run them to
regenerate the schema against refreshed source data (currency/country codes,
external code sets) or an updated MDR version.

## Files

| File | Purpose |
| ---- | ------- |
| `generate_sql.py` | Generates `10.2_message_datatypes.sql` from ISO 4217, ISO 3166, and the ISO 20022 external code set registry. |
| `generate_10_1_file1.py` | Generates `10.1_file1_foundational.sql`. |
| `generate_10_1_file2.py` | Generates `10.1_file2_identity_contact.sql` (uses `type_registry.py` for cross-file type lookups). |
| `generate_10_1_file3.py` | Generates `10.1_file3_accounts_fi.sql`. |
| `generate_10_1_file4.py` | Generates `10.1_file4_payment_compliance.sql`. |
| `type_registry.py` | Shared registry of composite type field lists, persisted to [../config/type_fields_registry.json](../config/type_fields_registry.json), so later generators can resolve Choice-type branches defined by earlier ones. |
| `pdf_to_markdown.py` | Extracts ISO spec text from the source MDR PDF into diff-able Markdown, for future spec-version comparisons. |

## Known gap: hardcoded working paths

These scripts were authored in an exploratory AI-assisted session and still
read/write intermediate files (downloaded registry CSVs/XLSX, generated SQL
output) using absolute paths from that original environment (for example,
`/home/claude/...`). Only `type_registry.py`'s registry path has been fixed
to resolve relative to this repository (`../config/type_fields_registry.json`).

Before re-running any `generate_*.py` script in a new environment, update its
hardcoded input/output paths to suit your working directory. This is tracked
as a follow-up rather than fixed here, to avoid changing untested codegen
logic without validating the regenerated SQL against the existing schema and
test suite.
