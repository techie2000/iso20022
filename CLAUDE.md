# CLAUDE.md

Context for Claude Code sessions working in this repo. Read this before making changes — it exists
specifically to prevent re-introducing two bugs that were already found, fixed, and regression-tested once.

## What this repo is

PostgreSQL DDL generated from the ISO 20022 Message Definition Report (MDR) Part 2 — Payments Clearing and
Settlement, Maintenance 2024-2025. Two layers, both complete:

- **Section 10.2 Message Datatypes** — leaf-level domains/enums/composite types (`Max35Text`,
  `IBAN2007Identifier`, `ActiveCurrencyAndAmount`, etc.), plus seed data for currency/country/external-code
  lookup tables.
- **Section 10.1 Message Components** — composite structures built from those datatypes (`CashAccount40`,
  `PartyIdentification272`, the full Remittance chain, etc.), split across 5 files by dependency order.

**Not started yet:** actual message-level tables (`pain.001`, `camt.053`, etc.) that would use these types as
columns. That's the next phase.

Full detail lives in `README.md` — this file is the condensed, mistake-prevention version.

## The most important rule: don't hand-edit the `.sql` files

Every `10.1_*.sql` and `10.2_*.sql` file is **generated output** from a matching `generate_*.py` script. If
you need to add, fix, or change a type:

1. Edit the Python generator, not the SQL file directly.
2. Re-run generators **in dependency order** (see below) — later files' generators load a shared registry
   (`type_fields_registry.json`) written by earlier ones.
3. Redeploy and rerun the full test suite before considering it done.

Hand-editing the `.sql` output will be silently overwritten and lost the next time anyone regenerates, and
risks drifting out of sync with the Python source of truth.

## Two bugs already found — do not reintroduce these patterns

### 1. Composite `IS NOT NULL` is wrong for partially-populated composites

Postgres row-wise NULL semantics: a composite value is `IS NOT NULL` only if **every** field is non-null,
and `IS NULL` only if **every** field is null. A composite with a *mix* of set/unset fields is neither —
both predicates return `false`.

This breaks any check written as `val."SomeCompositeField" IS NOT NULL` whenever that field's type has
optional sub-fields (the normal case, not an edge case — e.g. `OrganisationIdentification39` has three
independently-optional fields, and a real value typically sets only one).

**Fix in place:** `branch_populated_expr()` in every generator uses `num_nonnulls()` over the referenced
composite's own fields instead, via a lookup into `TYPE_FIELDS` (loaded from `type_fields_registry.json`).
If you add a new composite type, it must get registered into `TYPE_FIELDS` (the
`simple_type()`/`choice_type()` helpers do this automatically — only hand-written `CREATE TYPE` blocks that
bypass those helpers need manual registration, search each generator for `TYPE_FIELDS[...]  =` for
examples).

**Regression tests:** `test_10_1_file2_identity_contact.sql` (`Party52Choice`) and
`test_10_1_file3_accounts_fi.sql` (`BranchAndFinancialInstitutionIdentification8`).

### 2. `array_length()` returns NULL, not 0, for a non-NULL empty array

Any bound check written as `array_length(val."SomeArray", 1) <= N` or `>= N` silently evaluates to `NULL`
(not `true`/`false`) when the array is non-NULL but empty (`ARRAY[]::sometype[]`), because
`anything AND/OR NULL` is `NULL` in three-valued SQL logic.

**Fix in place:** always wrap as `COALESCE(array_length(val."SomeArray", 1), 0)` before comparing. See
`PostalAddress27.AddressLine` ([0..7] bound, File 2) and `DocumentLineInformation2.Identification`
([1..*] minimum, File 5) for the pattern.

**Regression test:** `test_10_1_file5_remittance.sql`, the `[1..*]` minimum-length test.

## Deploying and testing

```bash
psql -d your_database -v ON_ERROR_STOP=1 -f 00_deploy_all.sql
psql -d your_database -v ON_ERROR_STOP=1 -f run_all_tests.sql
```

Both exit non-zero on failure (tests use PL/pgSQL `ASSERT`, which raises a real exception — confirmed to
produce exit code 3 on a deliberately-reintroduced bug during development). Expected object counts after a
clean deploy: **66 domains, 19 enums, 119 composite types, 29 tables, 62 functions.**

## File dependency order (must be respected)

```text
10.2_message_datatypes.sql
  -> 10.1_file1_foundational.sql       (Amount, Date, Frequency, Mandate, Payment(Type), Tax, System ID, Misc.)
    -> 10.1_file2_identity_contact.sql   (Person, Postal Address, Party — uses File 1's GenericIdentification30)
      -> 10.1_file3_accounts_fi.sql        (Account, Financial Institution — uses File 1+2)
        -> 10.1_file4_payment_compliance.sql (Direct Debit, Regulatory Reporting — uses File 1-3)
          -> 10.1_file5_remittance.sql         (Remittance — uses File 1's DatePeriod2/TaxParty1/2,
                                                 File 2's PartyIdentification272 x4)
```

`00_deploy_all.sql` runs all of these via `\ir` (path-relative, works from any invocation directory). Don't
reorder — the grouping is by real cross-references found in the spec text, not the MDR's own subsection
numbering (e.g. `ClearingSystemMemberIdentification2` at 10.1.7 depends on something defined later, at
10.1.19).

**Every `CREATE DOMAIN`/`TYPE`/`TABLE` is preceded by an active `DROP ... IF EXISTS ... CASCADE`.** This
makes the whole chain idempotent, but also means re-running an *earlier* file alone will cascade-drop
everything built on top of it in later files — always redeploy the full chain after any change, not just
the file you edited.

## Conventions

- Schema `public`; every domain/type/enum/table named with the MDR's exact PascalCase name, double-quoted
  (`public."Max35Text"`).
- **10.2 uses XML-tag field names** for the two Amount+Currency composites (`Amt`, `Ccy`) — a decision made
  before the 10.1 convention below was settled.
- **10.1 uses full element names**, not XML-tag abbreviations (`FromDate` not `FrDt`) — matches the user's
  own pre-existing `DatePeriod2` code, which predates this whole build.
- `{Or}/{Or}` exclusive choices → composite `TYPE` (all branches nullable) + a `validate_<name>` function
  checking exactly one branch populated.
- Non-exclusive "at least one of" business rules (`PaymentIdentification13`, `CashAccount40`) get their own
  presence-based `validate_` function, not the exactly-one pattern.
- `[1..1]` mandatory fields: Postgres composite types can't enforce `NOT NULL` per field, so every type with
  a mandatory field gets a `validate_` function checking presence.
- Repeatable elements (`[0..n]`, `[0..*]`) → Postgres arrays, not child tables — child tables need a table
  parent with a primary key, which doesn't exist at this pure-type-library layer. Reconsider once
  message-level tables exist.
- Inline sub-types without their own MDR heading (e.g. `EquivalentAmount2`, `TaxAuthorisation1`) are still
  given the name the MDR's own prose assigns them, not an invented one.
- Every object gets a `COMMENT ON` carrying the MDR's Definition/Format/Constraints prose, so documentation
  survives independent of the source PDF.

## Keeping this in sync with future ISO spec revisions

`pdf_to_markdown.py` converts MDR PDF pages into diffable Markdown (already run for pages 743–869, checked
in as `10.1_message_components_spec.md` / `10.2_message_datatypes_spec.md`). When ISO publishes a new MDR
version: run it again against the new PDF with the same page range, `diff` against the checked-in Markdown,
and the diff shows exactly what needs auditing in the generators. See the "Spec extraction" section of
`README.md` for the full rationale and known limitations of the table-detection heuristic.

## Known gaps (see README.md for full detail)

- Message-level tables (pain/pacs/camt) — not started.
- A few MDR-inherent oddities reproduced as-is rather than "corrected" (documented in the relevant type's
  `COMMENT`): `References74Choice`'s inconsistent multiplicity on one branch, `SupplementaryData1.Envelope`'s
  unenforceable governance constraint, `RemittanceAmount4`'s data-dependent (not just cardinality) business
  rule.
- Test suites cover what came up during development, including both regressions above — not exhaustive
  coverage of every type.
