-- =====================================================================
-- test_10_1_file4_payment_compliance.sql
--
-- Automated regression tests for 10.1_file4_payment_compliance.sql.
-- See test_10_2_message_datatypes.sql for the ASSERT/CI rationale.
-- =====================================================================

\echo 'Running 10.1 File 4 (Payment Instructions & Compliance) tests...'

-- CreditTransferMandateData1: cross-file reuse of File 1's MandateTypeInformation2 / Frequency36Choice
DO $$
DECLARE
    svc_lvl public."ServiceLevel8Choice";
    mti public."MandateTypeInformation2";
    freq public."Frequency36Choice";
    mandate public."CreditTransferMandateData1";
BEGIN
    svc_lvl := ROW('SEPA', NULL);
    mti := ROW(svc_lvl, NULL, NULL, NULL);
    freq := ROW('MNTH', NULL, NULL);
    mandate := ROW('MNDT-001', mti, '2026-01-15', NULL, NULL, NULL, NULL, freq, NULL);

    ASSERT mandate."MandateIdentification" = 'MNDT-001', 'mandate id should round-trip correctly';
    ASSERT ((mandate."Type")."ServiceLevel")."Code" = 'SEPA',
        'nested ServiceLevel code (3 levels deep, reusing File 1''s type) should be accessible';
    ASSERT (mandate."Frequency")."Type" = 'MNTH', 'nested Frequency type (reusing File 1''s type) should be accessible';
    RAISE NOTICE 'PASS: CreditTransferMandateData1 (cross-file reuse)';
END $$;

-- RegulatoryReporting3: repeatable Details array, each element a composite with a nested Amount
DO $$
DECLARE
    amt public."ActiveOrHistoricCurrencyAndAmount";
    d1 public."StructuredRegulatoryReporting3";
    d2 public."StructuredRegulatoryReporting3";
    rr public."RegulatoryReporting3";
    auth public."RegulatoryAuthority2";
BEGIN
    amt := ROW(1000.00, 'EUR');
    d1 := ROW('CRED', '2026-01-01', 'FR', 'X123', amt, ARRAY['note1','note2']::public."Max35Text"[]);
    d2 := ROW('DEBT', NULL, 'DE', NULL, NULL, NULL);
    auth := ROW('Banque de France', 'FR');
    rr := ROW('BOTH', auth, ARRAY[d1, d2]);

    ASSERT array_length(rr."Details", 1) = 2, 'Details array should hold 2 entries';
    ASSERT ((rr."Details")[1])."Amount"."Ccy" = 'EUR', 'nested composite-in-array field should be accessible';
    ASSERT ((rr."Details")[1])."Information" = ARRAY['note1','note2']::public."Max35Text"[],
        'nested array-within-array-element field should round-trip correctly';
    ASSERT (rr."Authority")."Name" = 'Banque de France', 'nested Authority field should be accessible';
    RAISE NOTICE 'PASS: RegulatoryReporting3 (repeatable array of composites)';
END $$;

\echo 'All 10.1 File 4 tests passed.'
