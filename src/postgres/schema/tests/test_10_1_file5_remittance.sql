-- =====================================================================
-- test_10_1_file5_remittance.sql
--
-- Automated regression tests for 10.1_file5_remittance.sql.
-- See test_10_2_message_datatypes.sql for the ASSERT/CI rationale.
--
-- Includes a regression test for a second empty-array edge case found
-- during this file's development: Postgres array_length() returns NULL
-- (not 0) for a non-NULL empty array, which silently broke both the
-- [1..*] minimum-length check (DocumentLineInformation2.Identification)
-- and, retroactively, the [0..7] maximum-length check in File 2
-- (PostalAddress27.AddressLine). Both were fixed with
-- COALESCE(array_length(...), 0).
-- =====================================================================

\echo 'Running 10.1 File 5 (Remittance) tests...'

-- *** Regression test: empty (non-NULL) array edge case ***
DO $$
DECLARE
    di1 public."DocumentLineIdentification1";
    dli public."DocumentLineInformation2";
BEGIN
    di1 := ROW(NULL, 'INV-001', NULL);
    dli := ROW(ARRAY[di1], NULL, NULL);
    ASSERT public.validate_document_line_information2(dli), 'should accept one Identification element ([1..*] satisfied)';

    dli := ROW(ARRAY[]::public."DocumentLineIdentification1"[], NULL, NULL);
    ASSERT NOT public.validate_document_line_information2(dli),
        'REGRESSION: a non-NULL EMPTY array must fail the [1..*] minimum-length check. '
        'Postgres array_length() returns NULL (not 0) for an empty array -- if this assertion '
        'fails with NULL rather than a clean pass/fail, the COALESCE(array_length(...), 0) fix '
        'has likely been reverted to a bare array_length() comparison. See README.md.';

    dli := ROW(NULL, NULL, NULL);
    ASSERT NOT public.validate_document_line_information2(dli), 'should reject a NULL Identification array';
    RAISE NOTICE 'PASS: DocumentLineInformation2 [1..*] minimum-length (empty-array regression test)';
END $$;

-- ReferredDocumentInformation8 / DocumentType1 chain
DO $$
DECLARE
    doctype public."DocumentType2Choice";
    doctype1 public."DocumentType1";
    refdoc public."ReferredDocumentInformation8";
BEGIN
    doctype := ROW('CINV', NULL);
    doctype1 := ROW(doctype, NULL);
    ASSERT public.validate_document_type1(doctype1), 'DocumentType1 should be valid with CodeOrProprietary set';
    refdoc := ROW(doctype1, 'INV-2026-001', NULL, NULL);
    ASSERT refdoc."Number" = 'INV-2026-001', 'ReferredDocumentInformation8 should round-trip correctly';
    RAISE NOTICE 'PASS: ReferredDocumentInformation8 / DocumentType1 chain';
END $$;

-- Tax chain: TaxPeriod3 / TaxRecordDetails3 / TaxAmount3 / TaxRecord3 / TaxData1,
-- reusing TaxParty1/TaxParty2 from File 1
DO $$
DECLARE
    taxper public."TaxPeriod3";
    trd public."TaxRecordDetails3";
    taxamt public."TaxAmount3";
    tr public."TaxRecord3";
    crd public."TaxParty1";
    dbtr public."TaxParty2";
    td public."TaxData1";
    amt1 public."ActiveOrHistoricCurrencyAndAmount";
BEGIN
    amt1 := ROW(100.00, 'EUR');
    taxper := ROW(2026, 'MM01', NULL);
    trd := ROW(taxper, amt1);
    ASSERT public.validate_tax_record_details3(trd), 'TaxRecordDetails3 should be valid with mandatory Amount set';
    taxamt := ROW(7.5, ROW(500.00,'EUR')::public."ActiveOrHistoricCurrencyAndAmount", amt1, ARRAY[trd]);
    tr := ROW('VAT', 'STD', NULL, NULL, NULL, NULL, taxper, taxamt, NULL);
    crd := ROW('CRED123', NULL, NULL);
    dbtr := ROW('DBT456', NULL, NULL, NULL);
    td := ROW(crd, dbtr, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, ARRAY[tr]);

    ASSERT ((td."Record")[1])."Type" = 'VAT', 'nested tax record type (3 levels deep) should be accessible';
    ASSERT array_length(((td."Record")[1])."TaxAmount"."Details", 1) = 1, 'nested tax amount details array should round-trip';
    ASSERT (td."Creditor")."TaxIdentification" = 'CRED123', 'Creditor (reused TaxParty1 from File 1) should be accessible';
    RAISE NOTICE 'PASS: Tax chain (TaxData1 and full nesting)';
END $$;

-- Garnishment chain, reusing PartyIdentification272 from File 2
DO $$
DECLARE
    garn_type_choice public."GarnishmentType1Choice";
    garn_type public."GarnishmentType1";
    garnishee public."PartyIdentification272";
    garnishment public."Garnishment4";
    amt1 public."ActiveOrHistoricCurrencyAndAmount";
BEGIN
    garn_type_choice := ROW('GTPP', NULL);
    garn_type := ROW(garn_type_choice, NULL);
    garnishee."Name" := 'Jane Doe';
    amt1 := ROW(250.00, 'USD');
    garnishment := ROW(garn_type, garnishee, NULL, NULL, NULL, amt1, 'Y', 'N');
    ASSERT public.validate_garnishment4(garnishment), 'Garnishment4 should be valid with mandatory Type set';
    ASSERT (garnishment."Garnishee")."Name" = 'Jane Doe', 'nested Garnishee (reused PartyIdentification272) should be accessible';

    garnishment := ROW(NULL, garnishee, NULL, NULL, NULL, amt1, 'Y', 'N');
    ASSERT NOT public.validate_garnishment4(garnishment), 'should reject missing mandatory Type';
    RAISE NOTICE 'PASS: Garnishment4 (reusing File 2''s PartyIdentification272)';
END $$;

-- Full top-level assembly: StructuredRemittanceInformation18 + RemittanceInformation22,
-- including the [0..3] AdditionalRemittanceInformation bound
DO $$
DECLARE
    invoicer public."PartyIdentification272";
    crd_ref public."CreditorReferenceInformation3";
    sri public."StructuredRemittanceInformation18";
    ri public."RemittanceInformation22";
BEGIN
    invoicer."Name" := 'Acme Invoicing Ltd';
    crd_ref."Reference" := 'CDTR-REF-999';
    sri := ROW(NULL, NULL, crd_ref, invoicer, NULL, NULL, NULL,
               ARRAY['note A','note B']::public."Max140Text"[]);
    ASSERT public.validate_structured_remittance_information18(sri), 'should accept 2 AdditionalRemittanceInformation entries (bound is [0..3])';
    ASSERT (sri."Invoicer")."Name" = 'Acme Invoicing Ltd', 'nested Invoicer (reused File 2 type) should be accessible';

    sri."AdditionalRemittanceInformation" := ARRAY['a','b','c','d']::public."Max140Text"[];
    ASSERT NOT public.validate_structured_remittance_information18(sri), 'should reject 4 entries (exceeds [0..3] bound)';

    sri."AdditionalRemittanceInformation" := ARRAY['a','b','c']::public."Max140Text"[];
    ri := ROW(ARRAY['Unstructured note']::public."Max140Text"[], ARRAY[sri]);
    ASSERT array_length(ri."Structured", 1) = 1, 'RemittanceInformation22.Structured array should round-trip';
    ASSERT (((ri."Structured")[1])."Invoicer")."Name" = 'Acme Invoicing Ltd',
        'deep nested access through RemittanceInformation22 -> Structured -> Invoicer should work';
    RAISE NOTICE 'PASS: StructuredRemittanceInformation18 / RemittanceInformation22 (top-level assembly)';
END $$;

-- DocumentType2Choice: exactly-one-of-2 exclusive choice
DO $$
DECLARE d public."DocumentType2Choice";
BEGIN
    d := ROW('AROI', NULL);
    ASSERT public.validate_document_type2_choice(d), 'should accept the Code branch alone';
    d := ROW(NULL, 'Custom document type');
    ASSERT public.validate_document_type2_choice(d), 'should accept the Proprietary branch alone';
    d := ROW('AROI', 'Custom document type');
    ASSERT NOT public.validate_document_type2_choice(d), 'should reject both branches set';
    RAISE NOTICE 'PASS: DocumentType2Choice';
END $$;

-- DateType2Choice: exactly-one-of-2 exclusive choice
DO $$
DECLARE d public."DateType2Choice";
BEGIN
    d := ROW('INDA', NULL);
    ASSERT public.validate_date_type2_choice(d), 'should accept the Code branch alone';
    d := ROW(NULL, 'Custom date type');
    ASSERT public.validate_date_type2_choice(d), 'should accept the Proprietary branch alone';
    d := ROW('INDA', 'Custom date type');
    ASSERT NOT public.validate_date_type2_choice(d), 'should reject both branches set';
    RAISE NOTICE 'PASS: DateType2Choice';
END $$;

-- DateAndType1 required-field check (Type is itself a composite {Or}/{Or} choice)
DO $$
DECLARE t public."DateType2Choice"; d public."DateAndType1";
BEGIN
    t := ROW('INDA', NULL);
    d := ROW(t, '2026-01-15');
    ASSERT public.validate_date_and_type1(d), 'should accept when both mandatory fields are set';
    d := ROW(t, NULL);
    ASSERT NOT public.validate_date_and_type1(d), 'should reject when Date is missing';
    d := ROW(ROW(NULL, NULL)::public."DateType2Choice", '2026-01-15');
    ASSERT NOT public.validate_date_and_type1(d), 'should reject when Type has neither branch set';
    RAISE NOTICE 'PASS: DateAndType1';
END $$;

-- DocumentLineType1Choice: exactly-one-of-2 exclusive choice
DO $$
DECLARE d public."DocumentLineType1Choice";
BEGIN
    d := ROW('ADPI', NULL);
    ASSERT public.validate_document_line_type1_choice(d), 'should accept the Code branch alone';
    d := ROW(NULL, 'Custom line type');
    ASSERT public.validate_document_line_type1_choice(d), 'should accept the Proprietary branch alone';
    d := ROW('ADPI', 'Custom line type');
    ASSERT NOT public.validate_document_line_type1_choice(d), 'should reject both branches set';
    RAISE NOTICE 'PASS: DocumentLineType1Choice';
END $$;

-- DocumentLineType1 required-field check (CodeOrProprietary is a composite {Or}/{Or} choice)
DO $$
DECLARE c public."DocumentLineType1Choice"; d public."DocumentLineType1";
BEGIN
    c := ROW('ADPI', NULL);
    d := ROW(c, NULL);
    ASSERT public.validate_document_line_type1(d), 'should accept when CodeOrProprietary has a branch set';
    d := ROW(ROW(NULL, NULL)::public."DocumentLineType1Choice", 'IssuerX');
    ASSERT NOT public.validate_document_line_type1(d), 'should reject when CodeOrProprietary has neither branch set';
    RAISE NOTICE 'PASS: DocumentLineType1';
END $$;

-- DocumentAmountType1Choice: exactly-one-of-2 exclusive choice
DO $$
DECLARE d public."DocumentAmountType1Choice";
BEGIN
    d := ROW('CHAR', NULL);
    ASSERT public.validate_document_amount_type1_choice(d), 'should accept the Code branch alone';
    d := ROW(NULL, 'Custom amount type');
    ASSERT public.validate_document_amount_type1_choice(d), 'should accept the Proprietary branch alone';
    d := ROW('CHAR', 'Custom amount type');
    ASSERT NOT public.validate_document_amount_type1_choice(d), 'should reject both branches set';
    RAISE NOTICE 'PASS: DocumentAmountType1Choice';
END $$;

-- DocumentAmount1 required-field check (both fields are optional-subfield composites)
DO $$
DECLARE t public."DocumentAmountType1Choice"; amt public."ActiveOrHistoricCurrencyAndAmount"; d public."DocumentAmount1";
BEGIN
    t := ROW('CHAR', NULL);
    amt := ROW(100.00, 'USD');
    d := ROW(t, amt);
    ASSERT public.validate_document_amount1(d), 'should accept when both mandatory fields are set';
    d := ROW(ROW(NULL, NULL)::public."DocumentAmountType1Choice", amt);
    ASSERT NOT public.validate_document_amount1(d), 'should reject when Type has neither branch set';
    d := ROW(t, ROW(NULL, NULL)::public."ActiveOrHistoricCurrencyAndAmount");
    ASSERT NOT public.validate_document_amount1(d), 'should reject when Amount is entirely unset';
    RAISE NOTICE 'PASS: DocumentAmount1';
END $$;

-- DocumentAdjustment1 required-field check
DO $$
DECLARE amt public."ActiveOrHistoricCurrencyAndAmount"; d public."DocumentAdjustment1";
BEGIN
    amt := ROW(50.00, 'GBP');
    d := ROW(amt, 'CRDT', NULL, NULL);
    ASSERT public.validate_document_adjustment1(d), 'should accept when Amount is set';
    d := ROW(ROW(NULL, NULL)::public."ActiveOrHistoricCurrencyAndAmount", 'CRDT', NULL, NULL);
    ASSERT NOT public.validate_document_adjustment1(d), 'should reject when Amount is entirely unset';
    RAISE NOTICE 'PASS: DocumentAdjustment1';
END $$;

-- CreditorReferenceType2Choice: exactly-one-of-2 exclusive choice
DO $$
DECLARE c public."CreditorReferenceType2Choice";
BEGIN
    c := ROW('DISP', NULL);
    ASSERT public.validate_creditor_reference_type2_choice(c), 'should accept the Code branch alone';
    c := ROW(NULL, 'Custom reference type');
    ASSERT public.validate_creditor_reference_type2_choice(c), 'should accept the Proprietary branch alone';
    c := ROW('DISP', 'Custom reference type');
    ASSERT NOT public.validate_creditor_reference_type2_choice(c), 'should reject both branches set';
    RAISE NOTICE 'PASS: CreditorReferenceType2Choice';
END $$;

-- CreditorReferenceType3 required-field check (CodeOrProprietary is a composite {Or}/{Or} choice)
DO $$
DECLARE c public."CreditorReferenceType2Choice"; t public."CreditorReferenceType3";
BEGIN
    c := ROW('DISP', NULL);
    t := ROW(c, NULL);
    ASSERT public.validate_creditor_reference_type3(t), 'should accept when CodeOrProprietary has a branch set';
    t := ROW(ROW(NULL, NULL)::public."CreditorReferenceType2Choice", 'IssuerX');
    ASSERT NOT public.validate_creditor_reference_type3(t), 'should reject when CodeOrProprietary has neither branch set';
    RAISE NOTICE 'PASS: CreditorReferenceType3';
END $$;

-- GarnishmentType1Choice: exactly-one-of-2 exclusive choice
DO $$
DECLARE g public."GarnishmentType1Choice";
BEGIN
    g := ROW('GNCS', NULL);
    ASSERT public.validate_garnishment_type1_choice(g), 'should accept the Code branch alone';
    g := ROW(NULL, 'Custom garnishment type');
    ASSERT public.validate_garnishment_type1_choice(g), 'should accept the Proprietary branch alone';
    g := ROW('GNCS', 'Custom garnishment type');
    ASSERT NOT public.validate_garnishment_type1_choice(g), 'should reject both branches set';
    RAISE NOTICE 'PASS: GarnishmentType1Choice';
END $$;

-- GarnishmentType1 required-field check (CodeOrProprietary is a composite {Or}/{Or} choice)
DO $$
DECLARE c public."GarnishmentType1Choice"; g public."GarnishmentType1";
BEGIN
    c := ROW('GNCS', NULL);
    g := ROW(c, NULL);
    ASSERT public.validate_garnishment_type1(g), 'should accept when CodeOrProprietary has a branch set';
    g := ROW(ROW(NULL, NULL)::public."GarnishmentType1Choice", 'IssuerX');
    ASSERT NOT public.validate_garnishment_type1(g), 'should reject when CodeOrProprietary has neither branch set';
    RAISE NOTICE 'PASS: GarnishmentType1';
END $$;

\echo 'All 10.1 File 5 tests passed.'