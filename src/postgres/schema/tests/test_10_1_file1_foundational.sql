-- =====================================================================
-- test_10_1_file1_foundational.sql
--
-- Automated regression tests for 10.1_file1_foundational.sql.
-- See test_10_2_message_datatypes.sql for the ASSERT/CI rationale.
-- =====================================================================

\echo 'Running 10.1 File 1 (Foundational) tests...'

-- DatePeriod2 (reproduced from the user's own pre-existing pattern)
DO $$
DECLARE p public."DatePeriod2";
BEGIN
    p := ROW('2026-01-01', '2026-01-31');
    ASSERT public.validate_date_period(p), 'validate_date_period should accept FromDate <= ToDate';
    p := ROW('2026-01-31', '2026-01-01');
    ASSERT NOT public.validate_date_period(p), 'validate_date_period should reject FromDate > ToDate';
    RAISE NOTICE 'PASS: DatePeriod2';
END $$;

-- GenericIdentification30 required-field check
DO $$
DECLARE g public."GenericIdentification30";
BEGIN
    g := ROW('SEPA', 'ISO', 'Local scheme');
    ASSERT public.validate_generic_identification30(g), 'should accept when both mandatory fields are set';
    g := ROW(NULL, 'ISO', NULL);
    ASSERT NOT public.validate_generic_identification30(g), 'should reject when Identification is missing';
    RAISE NOTICE 'PASS: GenericIdentification30';
END $$;

-- References74Choice: exactly-one-of-10 exclusive choice
DO $$
DECLARE r public."References74Choice";
BEGIN
    r := ROW('SST123', NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
    ASSERT public.validate_references74_choice(r), 'should accept exactly one branch set';
    r := ROW('SST123', 'IPM456', NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
    ASSERT NOT public.validate_references74_choice(r), 'should reject two branches set';
    r := ROW(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
    ASSERT NOT public.validate_references74_choice(r), 'should reject zero branches set';
    RAISE NOTICE 'PASS: References74Choice';
END $$;

-- PaymentIdentification13: inclusive-or business rule (TransactionIdentification OR UETR)
DO $$
DECLARE p public."PaymentIdentification13";
BEGIN
    p := ROW(NULL, 'E2E123', 'TX456', NULL, NULL);
    ASSERT public.validate_payment_identification13(p), 'should accept TransactionIdentification alone';
    p := ROW(NULL, 'E2E123', NULL, 'f47ac10b-58cc-4372-a567-0e02b2c3d479', NULL);
    ASSERT public.validate_payment_identification13(p), 'should accept UETR alone';
    p := ROW(NULL, 'E2E123', 'TX456', 'f47ac10b-58cc-4372-a567-0e02b2c3d479', NULL);
    ASSERT public.validate_payment_identification13(p), 'should accept both TransactionIdentification and UETR (inclusive-or)';
    p := ROW(NULL, 'E2E123', NULL, NULL, NULL);
    ASSERT NOT public.validate_payment_identification13(p), 'should reject neither TransactionIdentification nor UETR';
    p := ROW(NULL, NULL, 'TX456', NULL, NULL);
    ASSERT NOT public.validate_payment_identification13(p), 'should reject missing mandatory EndToEndIdentification';
    RAISE NOTICE 'PASS: PaymentIdentification13 (inclusive-or rule)';
END $$;

-- Frequency36Choice: 3-way choice with composite-typed branches (Period, PointInTime)
DO $$
DECLARE f public."Frequency36Choice"; per public."FrequencyPeriod1";
BEGIN
    per := ROW('MNTH', 3);
    f := ROW(NULL, per, NULL);
    ASSERT public.validate_frequency36_choice(f), 'should accept the Period branch alone';
    f := ROW('WEEK', NULL, NULL);
    ASSERT public.validate_frequency36_choice(f), 'should accept the Type branch alone';
    f := ROW('WEEK', per, NULL);
    ASSERT NOT public.validate_frequency36_choice(f), 'should reject two branches set';
    RAISE NOTICE 'PASS: Frequency36Choice';
END $$;

-- PaymentTypeInformation28: array of ServiceLevel8Choice
DO $$
DECLARE pti public."PaymentTypeInformation28"; sl1 public."ServiceLevel8Choice"; sl2 public."ServiceLevel8Choice";
BEGIN
    sl1 := ROW('SEPA', NULL);
    sl2 := ROW('URGP', NULL);
    pti := ROW('HIGH', 'RTGS', ARRAY[sl1, sl2], NULL, NULL);
    ASSERT array_length(pti."ServiceLevel", 1) = 2, 'ServiceLevel array should hold 2 entries';
    ASSERT (pti."ServiceLevel")[1]."Code" = 'SEPA', 'first ServiceLevel entry should be accessible and correct';
    RAISE NOTICE 'PASS: PaymentTypeInformation28 (array of composite)';
END $$;

-- AmountType4Choice: nested EquivalentAmount2 branch, both required fields
DO $$
DECLARE amt public."AmountType4Choice"; eq public."EquivalentAmount2"; ccy_amt public."ActiveOrHistoricCurrencyAndAmount";
BEGIN
    ccy_amt := ROW(500.00, 'USD');
    eq := ROW(ccy_amt, 'EUR');
    ASSERT public.validate_equivalent_amount2(eq), 'EquivalentAmount2 should be valid when both fields set';
    amt := ROW(NULL, eq);
    ASSERT public.validate_amount_type4_choice(amt), 'should accept the EquivalentAmount branch alone';
    amt := ROW(ccy_amt, eq);
    ASSERT NOT public.validate_amount_type4_choice(amt), 'should reject both branches set';
    RAISE NOTICE 'PASS: AmountType4Choice';
END $$;

\echo 'All 10.1 File 1 tests passed.'
