-- =====================================================================
-- test_10_1_file2_identity_contact.sql
--
-- Automated regression tests for 10.1_file2_identity_contact.sql.
-- See test_10_2_message_datatypes.sql for the ASSERT/CI rationale.
--
-- IMPORTANT: this file includes the regression test for the composite
-- NULL-semantics bug found during this project (see README.md). Do not
-- remove the "Party52Choice: realistic single-branch case" test below --
-- it is the exact scenario that silently failed before the fix
-- (num_nonnulls() vs plain IS NOT NULL on composite-typed choice
-- branches). If any future change reintroduces a plain IS NOT NULL check
-- on a composite-typed field, this test should catch it.
-- =====================================================================

\echo 'Running 10.1 File 2 (Identity & Contact) tests...'

-- PostalAddress27: AddressLine [0..7] bound (Postgres arrays have no inherent max length)
DO $$
DECLARE pa public."PostalAddress27";
BEGIN
    pa."AddressLine" := ARRAY['L1','L2','L3','L4','L5','L6','L7']::public."Max70Text"[];
    ASSERT public.validate_postal_address27(pa), 'should accept exactly 7 address lines';
    pa."AddressLine" := ARRAY['L1','L2','L3','L4','L5','L6','L7','L8']::public."Max70Text"[];
    ASSERT NOT public.validate_postal_address27(pa), 'should reject 8 address lines (bound is [0..7])';
    RAISE NOTICE 'PASS: PostalAddress27 AddressLine bound';
END $$;

-- *** Regression test for the composite NULL-semantics bug ***
-- Party52Choice: OrganisationIdentification39 and PersonIdentification18 both have
-- ALL-OPTIONAL sub-fields. A realistic populated value sets only SOME of them,
-- which is exactly the case plain "IS NOT NULL" gets wrong on a composite type.
DO $$
DECLARE org_id public."OrganisationIdentification39"; party_choice public."Party52Choice";
BEGIN
    -- Only AnyBIC set; LEI and Other left null. This is normal, valid, everyday
    -- data -- not an edge case -- and is exactly what broke before the fix.
    org_id := ROW('DEUTDEFF500', NULL, NULL);
    party_choice := ROW(org_id, NULL);
    ASSERT public.validate_party52_choice(party_choice),
        'REGRESSION: Party52Choice must accept an OrganisationIdentification39 with only '
        'ONE of its optional sub-fields set (AnyBIC alone). If this fails, the '
        'num_nonnulls()-based branch_populated_expr() fix has likely been reverted '
        'to a plain IS NOT NULL check -- see README.md.';
    RAISE NOTICE 'PASS: Party52Choice realistic single-branch case (composite NULL-semantics regression test)';
END $$;

DO $$
DECLARE
    dpob public."DateAndPlaceOfBirth1";
    person_id public."PersonIdentification18";
    party_choice public."Party52Choice";
BEGIN
    dpob := ROW('1985-06-15', 'Ontario', 'Toronto', 'CA');
    ASSERT public.validate_date_and_place_of_birth1(dpob), 'DateAndPlaceOfBirth1 should be valid with all mandatory fields set';
    person_id := ROW(dpob, NULL);
    party_choice := ROW(NULL, person_id);
    ASSERT public.validate_party52_choice(party_choice), 'should accept the PrivateIdentification branch alone';
    party_choice := ROW(NULL, NULL);
    ASSERT NOT public.validate_party52_choice(party_choice), 'should reject neither branch set';

    dpob := ROW(NULL, 'Ontario', 'Toronto', 'CA');
    ASSERT NOT public.validate_date_and_place_of_birth1(dpob), 'DateAndPlaceOfBirth1 should reject missing mandatory BirthDate';
    RAISE NOTICE 'PASS: PersonIdentification18 / DateAndPlaceOfBirth1 / Party52Choice';
END $$;

-- PartyIdentification272: full nested build, 5 levels deep, using File 1's Contact13 too
DO $$
DECLARE
    org_scheme public."OrganisationIdentificationSchemeName1Choice";
    other_org public."GenericOrganisationIdentification3";
    org_id public."OrganisationIdentification39";
    party_choice public."Party52Choice";
    addr public."PostalAddress27";
    contact public."Contact13";
    party public."PartyIdentification272";
BEGIN
    org_scheme := ROW('BANK', NULL);
    other_org := ROW('123456', org_scheme, 'IssuerX');
    ASSERT public.validate_generic_organisation_identification3(other_org), 'GenericOrganisationIdentification3 should be valid';
    org_id := ROW(NULL, '5493001KJTIIGC8Y1R12', ARRAY[other_org]);
    party_choice := ROW(org_id, NULL);
    addr."TownName" := 'London';
    addr."Country" := 'GB';
    contact."EmailAddress" := 'ops@example.com';
    party := ROW('Acme Corp', addr, party_choice, 'GB', contact);

    ASSERT party."Name" = 'Acme Corp', 'party name should round-trip correctly';
    ASSERT (party."Identification")."OrganisationIdentification"."LEI" = '5493001KJTIIGC8Y1R12',
        'nested LEI (4 levels deep) should be accessible';
    ASSERT ((party."Identification")."OrganisationIdentification"."Other")[1]."SchemeName"."Code" = 'BANK',
        'nested array element field (5 levels deep) should be accessible';
    ASSERT public.validate_party52_choice(party."Identification"), 'nested Party52Choice should validate correctly';
    RAISE NOTICE 'PASS: PartyIdentification272 full nested build';
END $$;

-- OtherContact1 required-field check
DO $$
DECLARE o public."OtherContact1";
BEGIN
    o := ROW('EMAL', 'ops@example.com');
    ASSERT public.validate_other_contact1(o), 'should accept when ChannelType is set';
    o := ROW(NULL, 'ops@example.com');
    ASSERT NOT public.validate_other_contact1(o), 'should reject when ChannelType is missing';
    RAISE NOTICE 'PASS: OtherContact1';
END $$;

-- *** Regression test for the composite NULL-semantics bug ***
-- AddressType3Choice: Proprietary is a GenericIdentification30, which has an
-- optional SchemeName sub-field. A realistic populated value sets only
-- Identification/Issuer (the [1..1] fields), leaving SchemeName null -- the
-- same partially-populated-composite shape that broke plain IS NOT NULL.
DO $$
DECLARE prop public."GenericIdentification30"; a public."AddressType3Choice";
BEGIN
    prop := ROW('SEPA', 'ISO', NULL);
    a := ROW(NULL, prop);
    ASSERT public.validate_address_type3_choice(a),
        'REGRESSION: AddressType3Choice must accept a Proprietary GenericIdentification30 '
        'with SchemeName left null -- if this fails, the num_nonnulls()-based '
        'branch_populated_expr() fix has likely been reverted to a plain IS NOT NULL check.';
    a := ROW('ADDR', NULL);
    ASSERT public.validate_address_type3_choice(a), 'should accept the Code branch alone';
    a := ROW('ADDR', prop);
    ASSERT NOT public.validate_address_type3_choice(a), 'should reject both branches set';
    RAISE NOTICE 'PASS: AddressType3Choice (composite NULL-semantics regression test)';
END $$;

-- OrganisationIdentificationSchemeName1Choice: exactly-one-of-2 exclusive choice
DO $$
DECLARE s public."OrganisationIdentificationSchemeName1Choice";
BEGIN
    s := ROW('BANK', NULL);
    ASSERT public.validate_organisation_identification_scheme_name1_choice(s), 'should accept the Code branch alone';
    s := ROW(NULL, 'Custom scheme');
    ASSERT public.validate_organisation_identification_scheme_name1_choice(s), 'should accept the Proprietary branch alone';
    s := ROW('BANK', 'Custom scheme');
    ASSERT NOT public.validate_organisation_identification_scheme_name1_choice(s), 'should reject both branches set';
    RAISE NOTICE 'PASS: OrganisationIdentificationSchemeName1Choice';
END $$;

-- GenericPersonIdentification2 required-field check
DO $$
DECLARE g public."GenericPersonIdentification2";
BEGIN
    g := ROW('P123456', NULL, NULL);
    ASSERT public.validate_generic_person_identification2(g), 'should accept when Identification is set';
    g := ROW(NULL, NULL, 'IssuerX');
    ASSERT NOT public.validate_generic_person_identification2(g), 'should reject when Identification is missing';
    RAISE NOTICE 'PASS: GenericPersonIdentification2';
END $$;

-- PersonIdentificationSchemeName1Choice: exactly-one-of-2 exclusive choice
DO $$
DECLARE s public."PersonIdentificationSchemeName1Choice";
BEGIN
    s := ROW('CCPT', NULL);
    ASSERT public.validate_person_identification_scheme_name1_choice(s), 'should accept the Code branch alone';
    s := ROW(NULL, 'Custom scheme');
    ASSERT public.validate_person_identification_scheme_name1_choice(s), 'should accept the Proprietary branch alone';
    s := ROW('CCPT', 'Custom scheme');
    ASSERT NOT public.validate_person_identification_scheme_name1_choice(s), 'should reject both branches set';
    RAISE NOTICE 'PASS: PersonIdentificationSchemeName1Choice';
END $$;

\echo 'All 10.1 File 2 tests passed.'
