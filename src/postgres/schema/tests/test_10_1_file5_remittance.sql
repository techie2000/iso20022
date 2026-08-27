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

\echo 'All 10.1 File 5 tests passed.'