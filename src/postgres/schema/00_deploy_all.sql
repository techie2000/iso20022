-- =====================================================================
-- 00_deploy_all.sql
--
-- Deploys the entire ISO 20022 -> PostgreSQL schema in one command, in
-- the correct dependency order. Uses \ir (include relative) rather than
-- \i, so paths resolve relative to THIS script's own location -- run it
-- from any working directory and it will still find the other files,
-- as long as they stay in the same folder as this one.
--
-- Usage:
--   psql -d your_database -v ON_ERROR_STOP=1 -f 00_deploy_all.sql
--
-- ON_ERROR_STOP=1 is important: without it, psql prints an ERROR and
-- keeps going, which is exactly the failure mode that caused the
-- External*Code tables to silently stay empty earlier in this project's
-- history (see README.md, "Every file is idempotent" section). With it,
-- deployment stops immediately at the first real problem.
--
-- Safe to re-run against a database that already has this schema: every
-- object is created via DROP ... IF EXISTS ... CASCADE first (see
-- README.md for the CASCADE tradeoff once other schemas depend on this).
-- =====================================================================

\echo '=== 10.2 Message Datatypes ==='
\ir 10.2_message_datatypes.sql

\echo '=== 10.1 File 1: Foundational & standalone ==='
\ir 10.1_file1_foundational.sql

\echo '=== 10.1 File 2: Identity & Contact ==='
\ir 10.1_file2_identity_contact.sql

\echo '=== 10.1 File 3: Accounts & Financial Institutions ==='
\ir 10.1_file3_accounts_fi.sql

\echo '=== 10.1 File 4: Payment Instructions & Compliance ==='
\ir 10.1_file4_payment_compliance.sql

\echo '=== 10.1 File 5: Remittance ==='
\ir 10.1_file5_remittance.sql

\echo ''
\echo '=== Deployment complete. Object counts: ==='
SELECT 'domains' AS kind, count(*) AS count FROM pg_type t JOIN pg_namespace n ON t.typnamespace=n.oid WHERE n.nspname='public' AND t.typtype='d'
UNION ALL
SELECT 'enums', count(*) FROM pg_type t JOIN pg_namespace n ON t.typnamespace=n.oid WHERE n.nspname='public' AND t.typtype='e'
UNION ALL
SELECT 'composite types', count(*) FROM pg_type t JOIN pg_namespace n ON t.typnamespace=n.oid WHERE n.nspname='public' AND t.typtype='c'
UNION ALL
SELECT 'tables', count(*) FROM pg_tables WHERE schemaname='public'
UNION ALL
SELECT 'functions', count(*) FROM pg_proc p JOIN pg_namespace n ON p.pronamespace=n.oid WHERE n.nspname='public';
\echo ''
\echo 'Expected: 66 domains, 19 enums, 119 composite types, 29 tables, 62 functions.'
\echo 'If your counts differ, something above failed silently -- scroll up for ERROR lines,'
\echo 'or re-run with -v ON_ERROR_STOP=1 if you did not already.'
\echo ''
\echo 'Section 10.1 Message Components is now fully complete.'
\echo 'Next: run tests/run_all_tests.sql to verify the deployed schema actually behaves correctly.'
