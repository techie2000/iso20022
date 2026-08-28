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

-- AccountSchemeName1Choice: exactly-one-of-2 exclusive choice
DO $$
DECLARE s public."AccountSchemeName1Choice";
BEGIN
    s := ROW('BBAN', NULL);
    ASSERT public.validate_account_scheme_name1_choice(s), 'should accept the Code branch alone';
    s := ROW(NULL, 'Custom scheme');
    ASSERT public.validate_account_scheme_name1_choice(s), 'should accept the Proprietary branch alone';
    s := ROW('BBAN', 'Custom scheme');
    ASSERT NOT public.validate_account_scheme_name1_choice(s), 'should reject both branches set';
    RAISE NOTICE 'PASS: AccountSchemeName1Choice';
END $$;

-- GenericAccountIdentification1 required-field check
DO $$
DECLARE g public."GenericAccountIdentification1";
BEGIN
    g := ROW('ACCT123', NULL, NULL);
    ASSERT public.validate_generic_account_identification1(g), 'should accept when Identification is set';
    g := ROW(NULL, NULL, 'IssuerX');
    ASSERT NOT public.validate_generic_account_identification1(g), 'should reject when Identification is missing';
    RAISE NOTICE 'PASS: GenericAccountIdentification1';
END $$;

-- CashAccountType2Choice: exactly-one-of-2 exclusive choice
DO $$
DECLARE c public."CashAccountType2Choice";
BEGIN
    c := ROW('CACC', NULL);
    ASSERT public.validate_cash_account_type2_choice(c), 'should accept the Code branch alone';
    c := ROW(NULL, 'Custom type');
    ASSERT public.validate_cash_account_type2_choice(c), 'should accept the Proprietary branch alone';
    c := ROW('CACC', 'Custom type');
    ASSERT NOT public.validate_cash_account_type2_choice(c), 'should reject both branches set';
    RAISE NOTICE 'PASS: CashAccountType2Choice';
END $$;

-- ProxyAccountType1Choice: exactly-one-of-2 exclusive choice
DO $$
DECLARE p public."ProxyAccountType1Choice";
BEGIN
    p := ROW('EMAL', NULL);
    ASSERT public.validate_proxy_account_type1_choice(p), 'should accept the Code branch alone';
    p := ROW(NULL, 'Custom proxy type');
    ASSERT public.validate_proxy_account_type1_choice(p), 'should accept the Proprietary branch alone';
    p := ROW('EMAL', 'Custom proxy type');
    ASSERT NOT public.validate_proxy_account_type1_choice(p), 'should reject both branches set';
    RAISE NOTICE 'PASS: ProxyAccountType1Choice';
END $$;

-- ProxyAccountIdentification1 required-field check
DO $$
DECLARE p public."ProxyAccountIdentification1";
BEGIN
    p := ROW(NULL, 'someone@example.com');
    ASSERT public.validate_proxy_account_identification1(p), 'should accept when Identification is set';
    p := ROW(NULL, NULL);
    ASSERT NOT public.validate_proxy_account_identification1(p), 'should reject when Identification is missing';
    RAISE NOTICE 'PASS: ProxyAccountIdentification1';
END $$;

-- ClearingSystemMemberIdentification2 required-field check
DO $$
DECLARE c public."ClearingSystemMemberIdentification2";
BEGIN
    c := ROW(NULL, 'MEMBER01');
    ASSERT public.validate_clearing_system_member_identification2(c), 'should accept when MemberIdentification is set';
    c := ROW(NULL, NULL);
    ASSERT NOT public.validate_clearing_system_member_identification2(c), 'should reject when MemberIdentification is missing';
    RAISE NOTICE 'PASS: ClearingSystemMemberIdentification2';
END $$;

-- FinancialIdentificationSchemeName1Choice: exactly-one-of-2 exclusive choice
DO $$
DECLARE s public."FinancialIdentificationSchemeName1Choice";
BEGIN
    s := ROW('BANK', NULL);
    ASSERT public.validate_financial_identification_scheme_name1_choice(s), 'should accept the Code branch alone';
    s := ROW(NULL, 'Custom scheme');
    ASSERT public.validate_financial_identification_scheme_name1_choice(s), 'should accept the Proprietary branch alone';
    s := ROW('BANK', 'Custom scheme');
    ASSERT NOT public.validate_financial_identification_scheme_name1_choice(s), 'should reject both branches set';
    RAISE NOTICE 'PASS: FinancialIdentificationSchemeName1Choice';
END $$;

-- GenericFinancialIdentification1 required-field check
DO $$
DECLARE g public."GenericFinancialIdentification1";
BEGIN
    g := ROW('FI123', NULL, NULL);
    ASSERT public.validate_generic_financial_identification1(g), 'should accept when Identification is set';
    g := ROW(NULL, NULL, 'IssuerX');
    ASSERT NOT public.validate_generic_financial_identification1(g), 'should reject when Identification is missing';
    RAISE NOTICE 'PASS: GenericFinancialIdentification1';
END $$;

\echo 'All 10.1 File 3 tests passed.'
