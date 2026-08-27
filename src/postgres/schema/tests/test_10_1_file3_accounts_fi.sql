-- =====================================================================
-- test_10_1_file3_accounts_fi.sql
--
-- Automated regression tests for 10.1_file3_accounts_fi.sql.
-- See test_10_2_message_datatypes.sql for the ASSERT/CI rationale.
--
-- IMPORTANT: includes the second regression test for the composite
-- NULL-semantics bug (see README.md and test_10_1_file2_identity_contact.sql).
-- This time it's a [1..1] REQUIRED field whose type is a composite with
-- all-optional sub-fields (FinancialInstitutionIdentification), not a
-- {Or}/{Or} choice branch -- a different code path (simple_type's
-- required-field check) that had the identical underlying bug.
-- =====================================================================

\echo 'Running 10.1 File 3 (Accounts & Financial Institutions) tests...'

-- CashAccount40: inclusive-or business rule (Identification OR Proxy)
DO $$
DECLARE acct_id public."AccountIdentification4Choice"; acct public."CashAccount40"; proxy public."ProxyAccountIdentification1";
BEGIN
    acct_id := ROW('GB29NWBK60161331926819', NULL);
    acct := ROW(acct_id, NULL, 'GBP', 'Main Account', NULL);
    ASSERT public.validate_cash_account40(acct), 'should accept Identification alone';

    acct := ROW(NULL, NULL, 'GBP', 'Main Account', NULL);
    ASSERT NOT public.validate_cash_account40(acct), 'should reject neither Identification nor Proxy';

    proxy := ROW(NULL, 'someone@example.com');
    acct := ROW(NULL, NULL, 'GBP', NULL, proxy);
    ASSERT public.validate_cash_account40(acct), 'should accept Proxy alone';
    RAISE NOTICE 'PASS: CashAccount40 (inclusive-or rule)';
END $$;

-- AccountIdentification4Choice: exclusivity with the real IBAN domain
DO $$
DECLARE aic public."AccountIdentification4Choice";
BEGIN
    aic := ROW('DE89370400440532013000', NULL);
    ASSERT public.validate_account_identification4_choice(aic), 'should accept the IBAN branch alone';
    RAISE NOTICE 'PASS: AccountIdentification4Choice';
END $$;

-- *** Regression test #2 for the composite NULL-semantics bug ***
-- FinancialInstitutionIdentification23 has ALL-OPTIONAL sub-fields
-- (BICFI/ClearingSystemMemberIdentification/LEI/Name/PostalAddress/Other).
-- A realistic populated value (BICFI + Name + PostalAddress set, the rest
-- null) is exactly the mixed-null case that breaks plain IS NOT NULL.
DO $$
DECLARE
    addr public."PostalAddress27";
    fi public."FinancialInstitutionIdentification23";
    branch public."BranchData5";
    bic_fi public."BranchAndFinancialInstitutionIdentification8";
BEGIN
    addr."TownName" := 'Frankfurt';
    addr."Country" := 'DE';
    fi := ROW('DEUTDEFFXXX', NULL, NULL, 'Deutsche Bank', addr, NULL);
    branch := ROW('BR001', NULL, 'Frankfurt Branch', NULL);
    bic_fi := ROW(fi, branch);

    ASSERT public.validate_branch_and_financial_institution_identification8(bic_fi),
        'REGRESSION: BranchAndFinancialInstitutionIdentification8 must accept a fully-valid '
        'FinancialInstitutionIdentification23 whose OWN sub-fields are only partially set '
        '(BICFI+Name+PostalAddress, not ClearingSystemMemberIdentification/LEI/Other). '
        'If this fails, simple_type()''s required-field check has likely regressed to a '
        'plain IS NOT NULL -- see README.md.';

    ASSERT (bic_fi."FinancialInstitutionIdentification")."BICFI" = 'DEUTDEFFXXX', 'nested BICFI should be accessible';
    ASSERT ((bic_fi."FinancialInstitutionIdentification")."PostalAddress")."TownName" = 'Frankfurt',
        'nested PostalAddress field (4 levels deep, reusing File 2''s type) should be accessible';

    bic_fi := ROW(NULL, branch);
    ASSERT NOT public.validate_branch_and_financial_institution_identification8(bic_fi),
        'should reject when the mandatory FinancialInstitutionIdentification is entirely absent';
    RAISE NOTICE 'PASS: BranchAndFinancialInstitutionIdentification8 (composite NULL-semantics regression test)';
END $$;

\echo 'All 10.1 File 3 tests passed.'
