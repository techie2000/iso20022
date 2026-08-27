-- =====================================================================
-- run_all_tests.sql
--
-- Runs every automated test file against an already-deployed schema, in
-- order. Uses \ir so it works regardless of the caller's working
-- directory, as long as all test files stay alongside this one (this
-- file lives in schema/tests/, one directory below the schema files
-- deployed by ../00_deploy_all.sql).
--
-- Usage (after running ../00_deploy_all.sql against the same database):
--   psql -d your_database -v ON_ERROR_STOP=1 -f run_all_tests.sql
--
-- ON_ERROR_STOP=1 is essential here: each test file uses PL/pgSQL ASSERT,
-- which raises a real exception on failure. Without ON_ERROR_STOP, psql
-- would print the error and barrel on into the next test file regardless.
-- With it, this script stops at the first failing assertion and exits
-- non-zero -- safe to wire into CI as a single pass/fail gate.
-- =====================================================================

\echo '======================================================'
\echo 'ISO 20022 -> PostgreSQL: full regression test suite'
\echo '======================================================'

\ir test_10_2_message_datatypes.sql
\ir test_10_1_file1_foundational.sql
\ir test_10_1_file2_identity_contact.sql
\ir test_10_1_file3_accounts_fi.sql
\ir test_10_1_file4_payment_compliance.sql
\ir test_10_1_file5_remittance.sql

\echo ''
\echo '======================================================'
\echo 'ALL TEST FILES PASSED.'
\echo '======================================================'
