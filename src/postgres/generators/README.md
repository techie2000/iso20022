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

## Spec extraction — publishing the source as Markdown

Two Markdown files are published alongside the SQL, generated directly
from the same source PDF pages that drove this build, and checked in
under [docs/internal/](../../../docs/internal/):

| File | Source PDF pages | Mirrors |
| --- | --- | --- |
| [10.2_message_datatypes_spec.md](../../../docs/internal/10.2_message_datatypes_spec.md) | 845–869 | [../schema/10.2_message_datatypes.sql](../schema/10.2_message_datatypes.sql) |
| [10.1_message_components_spec.md](../../../docs/internal/10.1_message_components_spec.md) | 743–844 | `../schema/10.1_file1..5*.sql` (all of Section 10.1, including 10.1.18 Remittance) |

Both were generated from the source PDF at
[docs/vendor/ISO20022_MDRPart2_PaymentsClearingAndSettlement_2024_2025_v1.pdf](../../../docs/vendor/ISO20022_MDRPart2_PaymentsClearingAndSettlement_2024_2025_v1.pdf).

**Why**: these Markdown files are the actual compliance-checking artifact
going forward. When ISO publishes a new MDR version, run `pdf_to_markdown.py`
against the new PDF with the same page range and section title, then `diff`
the new Markdown against the version checked in here:

```bash
python3 pdf_to_markdown.py new_spec.pdf 845 869 10.2_new.md "..."
diff ../../../docs/internal/10.2_message_datatypes_spec.md 10.2_new.md
```

The diff tells you exactly what changed — a new external code type, an
added constraint, a changed field name, a modified multiplicity — which
is what actually needs auditing in the SQL generators. This turns
"did anything change in a 900-page spec" into a reviewable diff, rather
than re-reading the whole document from scratch each time ISO revises it.
(Page numbers do sometimes shift a little between MDR editions even for
unchanged sections — if a page range comes up mostly-empty or clearly
wrong on a new PDF, check the new edition's own table of contents for the
current page numbers of Section 10.1/10.2 first.)

See `pdf_to_markdown.py`'s own docstring for the design choices behind the
extraction (boilerplate stripping, header levels, verbatim table blocks).

### Known limitations

- **The output is sensitive to the installed `pdftotext` build/version.**
  Regenerating with a different `pdftotext` than originally used can shift
  column spacing enough to break the boilerplate-stripping regex (leftover
  page headers/footers leak into the output) and can render bullet
  characters differently (`•` vs `·`). Always `diff` a fresh regeneration
  against the checked-in file before trusting or committing it — if the
  diff shows noise unrelated to the actual spec content, it's a tooling
  artifact, not a real spec change.
- The extraction is text-only — any diagrams or images in the source PDF
  (none in Section 10, as it happens) aren't captured.
- The table-vs-prose heuristic is pattern-based, not a real table parser.
  It was validated by spot-checking the output against sections manually
  transcribed while building the SQL (including `PartyIdentification272`,
  the deepest nested structure in the whole library) and against a full
  scan for leftover boilerplate across both complete files — but an
  unusual new layout quirk in a future spec edition could conceivably
  confuse it. Spot-check a new PDF's Markdown output against a few known
  sections before trusting a diff completely.
- Occasional mid-word line wraps survive from the original PDF's fixed
  page width (e.g. a definition sentence breaking across two lines).
  These are cosmetic, not content loss — the full text is present.

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
