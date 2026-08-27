# Schema

Deployable PostgreSQL DDL for ISO 20022 MDR Part 2 (Payments Clearing and
Settlement): Section 10.2 "Message Datatypes" (leaf-level types) and the
entirety of Section 10.1 "Message Components" (composite structures built on
10.2, including 10.1.18 Remittance).

## Deploying and testing

```bash
psql -d your_database -v ON_ERROR_STOP=1 -f 00_deploy_all.sql
psql -d your_database -v ON_ERROR_STOP=1 -f tests/run_all_tests.sql
```

`00_deploy_all.sql` deploys the six schema files below in dependency order
using `\ir` (include-relative), so it works regardless of the caller's
working directory as long as the files stay together in this folder.
`tests/run_all_tests.sql` runs the matching `test_*.sql` files in
[tests/](tests/) against an already-deployed database, using PL/pgSQL
`ASSERT` so a failure stops the script and exits non-zero (CI-safe).

`ON_ERROR_STOP=1` is required for both commands: without it, `psql` prints an
error and keeps going instead of failing the deployment/test run.

## Files

| File | Contents |
| ---- | -------- |
| `00_deploy_all.sql` | Run first. Deploys all six schema files in dependency order. |
| `10.2_message_datatypes.sql` | Domains, types, tables, and functions for Section 10.2, plus seed data for 29 reference tables. |
| `10.1_file1_foundational.sql` | Section 10.1 composite types with no dependency on the other 10.1 files. |
| `10.1_file2_identity_contact.sql` | Section 10.1 identity and contact composite types (depends on File 1). |
| `10.1_file3_accounts_fi.sql` | Section 10.1 account and financial institution composite types (depends on File 1). |
| `10.1_file4_payment_compliance.sql` | Section 10.1 payment instruction and compliance composite types (depends on File 1). |
| `10.1_file5_remittance.sql` | Section 10.1.18 remittance composite types (depends on File 1). |
| [tests/](tests/) | Automated test suite; run via `tests/run_all_tests.sql`. |

## Idempotency and the CASCADE tradeoff

Every `CREATE DOMAIN`/`CREATE TYPE`/`CREATE TABLE` is preceded by
`DROP ... IF EXISTS ... CASCADE`, so any file can be re-run without
"already exists" errors. Because 10.1 builds on 10.2, and Files 2-5 build on
File 1, re-running an earlier file cascades drops through everything built on
top of it. **Always re-run the full chain in order:**
`10.2 -> File 1 -> File 2 -> File 3 -> File 4 -> File 5`. Once other schemas
depend on these objects, this drop-and-rebuild approach should be replaced
with non-destructive migrations.

## Known gaps

- Section 10.1 message components are now fully covered; message-level
  pain/pacs/camt tables have not been started.
- The test suite covers scenarios exercised during initial development,
  including two named regressions; it is a starting pattern, not exhaustive
  coverage of every type and constraint.
- Two of the 26 `External*Code` lookup tables intentionally seed zero rows
  (no published values in the source registry as of the retrieval date
  recorded in `10.2_message_datatypes.sql`).

See generated `COMMENT ON` text in the SQL files themselves for per-type
Definition/Format/Constraints notes carried over from the MDR.
