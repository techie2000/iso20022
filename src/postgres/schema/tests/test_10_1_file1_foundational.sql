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

-- GenericIdentification3 required-field check
DO $$
DECLARE g public."GenericIdentification3";
BEGIN
    g := ROW('ABC123', 'ISO');
    ASSERT public.validate_generic_identification3(g), 'should accept when Identification is set';
    g := ROW(NULL, 'ISO');
    ASSERT NOT public.validate_generic_identification3(g), 'should reject when Identification is missing';
    RAISE NOTICE 'PASS: GenericIdentification3';
END $$;

-- OriginalGroupInformation27 required-field check
DO $$
DECLARE g public."OriginalGroupInformation27";
BEGIN
    g := ROW('MSG001', 'pacs.008.001.08', NULL, NULL, NULL);
    ASSERT public.validate_original_group_information27(g), 'should accept when both mandatory fields are set';
    g := ROW(NULL, 'pacs.008.001.08', NULL, NULL, NULL);
    ASSERT NOT public.validate_original_group_information27(g), 'should reject when OriginalMessageIdentification is missing';
    g := ROW('MSG001', NULL, NULL, NULL, NULL);
    ASSERT NOT public.validate_original_group_information27(g), 'should reject when OriginalMessageNameIdentification is missing';
    RAISE NOTICE 'PASS: OriginalGroupInformation27';
END $$;

-- OriginalGroupInformation29 required-field check
DO $$
DECLARE g public."OriginalGroupInformation29";
BEGIN
    g := ROW('MSG001', 'pacs.003.001.01', NULL);
    ASSERT public.validate_original_group_information29(g), 'should accept when both mandatory fields are set';
    g := ROW('MSG001', NULL, NULL);
    ASSERT NOT public.validate_original_group_information29(g), 'should reject when OriginalMessageNameIdentification is missing';
    RAISE NOTICE 'PASS: OriginalGroupInformation29';
END $$;

-- OriginalBusinessQuery1 required-field check
DO $$
DECLARE q public."OriginalBusinessQuery1";
BEGIN
    q := ROW('QRY001', NULL, NULL);
    ASSERT public.validate_original_business_query1(q), 'should accept when MessageIdentification is set';
    q := ROW(NULL, 'camt.060.001.05', NULL);
    ASSERT NOT public.validate_original_business_query1(q), 'should reject when MessageIdentification is missing';
    RAISE NOTICE 'PASS: OriginalBusinessQuery1';
END $$;

-- Authorisation1Choice: exactly-one-of-2 exclusive choice
DO $$
DECLARE a public."Authorisation1Choice";
BEGIN
    a := ROW('AUTH', NULL);
    ASSERT public.validate_authorisation1_choice(a), 'should accept the Code branch alone';
    a := ROW(NULL, 'Custom approval');
    ASSERT public.validate_authorisation1_choice(a), 'should accept the Proprietary branch alone';
    a := ROW('AUTH', 'Custom approval');
    ASSERT NOT public.validate_authorisation1_choice(a), 'should reject both branches set';
    a := ROW(NULL, NULL);
    ASSERT NOT public.validate_authorisation1_choice(a), 'should reject zero branches set';
    RAISE NOTICE 'PASS: Authorisation1Choice';
END $$;

-- SupplementaryData1 required-field check
DO $$
DECLARE s public."SupplementaryData1";
BEGIN
    s := ROW(NULL, '<Xtn>...</Xtn>');
    ASSERT public.validate_supplementary_data1(s), 'should accept when Envelope is set';
    s := ROW('/Doc/Xtn', NULL);
    ASSERT NOT public.validate_supplementary_data1(s), 'should reject when Envelope is missing';
    RAISE NOTICE 'PASS: SupplementaryData1';
END $$;

-- Purpose2Choice: exactly-one-of-2 exclusive choice
DO $$
DECLARE p public."Purpose2Choice";
BEGIN
    p := ROW('CASH', NULL);
    ASSERT public.validate_purpose2_choice(p), 'should accept the Code branch alone';
    p := ROW(NULL, 'Ad-hoc reason');
    ASSERT public.validate_purpose2_choice(p), 'should accept the Proprietary branch alone';
    p := ROW('CASH', 'Ad-hoc reason');
    ASSERT NOT public.validate_purpose2_choice(p), 'should reject both branches set';
    RAISE NOTICE 'PASS: Purpose2Choice';
END $$;

-- NumberOfTransactionsPerStatus5 required-field check
DO $$
DECLARE n public."NumberOfTransactionsPerStatus5";
BEGIN
    n := ROW('15', 'ACSC', NULL);
    ASSERT public.validate_number_of_transactions_per_status5(n), 'should accept when both mandatory fields are set';
    n := ROW(NULL, 'ACSC', NULL);
    ASSERT NOT public.validate_number_of_transactions_per_status5(n), 'should reject when DetailedNumberOfTransactions is missing';
    n := ROW('15', NULL, NULL);
    ASSERT NOT public.validate_number_of_transactions_per_status5(n), 'should reject when DetailedStatus is missing';
    RAISE NOTICE 'PASS: NumberOfTransactionsPerStatus5';
END $$;

-- ClearingSystemIdentification2Choice: exactly-one-of-2 exclusive choice
DO $$
DECLARE c public."ClearingSystemIdentification2Choice";
BEGIN
    c := ROW('SWIF', NULL);
    ASSERT public.validate_clearing_system_identification2_choice(c), 'should accept the Code branch alone';
    c := ROW(NULL, 'PROP1');
    ASSERT public.validate_clearing_system_identification2_choice(c), 'should accept the Proprietary branch alone';
    c := ROW('SWIF', 'PROP1');
    ASSERT NOT public.validate_clearing_system_identification2_choice(c), 'should reject both branches set';
    RAISE NOTICE 'PASS: ClearingSystemIdentification2Choice';
END $$;

-- MandateClassification1Choice: exactly-one-of-2 exclusive choice
DO $$
DECLARE m public."MandateClassification1Choice";
BEGIN
    m := ROW('FIXE', NULL);
    ASSERT public.validate_mandate_classification1_choice(m), 'should accept the Code branch alone';
    m := ROW(NULL, 'Custom classification');
    ASSERT public.validate_mandate_classification1_choice(m), 'should accept the Proprietary branch alone';
    m := ROW('FIXE', 'Custom classification');
    ASSERT NOT public.validate_mandate_classification1_choice(m), 'should reject both branches set';
    m := ROW(NULL, NULL);
    ASSERT NOT public.validate_mandate_classification1_choice(m), 'should reject zero branches set';
    RAISE NOTICE 'PASS: MandateClassification1Choice';
END $$;

-- ServiceLevel8Choice: exactly-one-of-2 exclusive choice
DO $$
DECLARE s public."ServiceLevel8Choice";
BEGIN
    s := ROW('SEPA', NULL);
    ASSERT public.validate_service_level8_choice(s), 'should accept the Code branch alone';
    s := ROW(NULL, 'Custom level');
    ASSERT public.validate_service_level8_choice(s), 'should accept the Proprietary branch alone';
    s := ROW('SEPA', 'Custom level');
    ASSERT NOT public.validate_service_level8_choice(s), 'should reject both branches set';
    RAISE NOTICE 'PASS: ServiceLevel8Choice';
END $$;

-- LocalInstrument2Choice: exactly-one-of-2 exclusive choice
DO $$
DECLARE l public."LocalInstrument2Choice";
BEGIN
    l := ROW('CORE', NULL);
    ASSERT public.validate_local_instrument2_choice(l), 'should accept the Code branch alone';
    l := ROW(NULL, 'Custom instrument');
    ASSERT public.validate_local_instrument2_choice(l), 'should accept the Proprietary branch alone';
    l := ROW('CORE', 'Custom instrument');
    ASSERT NOT public.validate_local_instrument2_choice(l), 'should reject both branches set';
    RAISE NOTICE 'PASS: LocalInstrument2Choice';
END $$;

-- CategoryPurpose1Choice: exactly-one-of-2 exclusive choice
DO $$
DECLARE c public."CategoryPurpose1Choice";
BEGIN
    c := ROW('CASH', NULL);
    ASSERT public.validate_category_purpose1_choice(c), 'should accept the Code branch alone';
    c := ROW(NULL, 'Custom category');
    ASSERT public.validate_category_purpose1_choice(c), 'should accept the Proprietary branch alone';
    c := ROW('CASH', 'Custom category');
    ASSERT NOT public.validate_category_purpose1_choice(c), 'should reject both branches set';
    RAISE NOTICE 'PASS: CategoryPurpose1Choice';
END $$;

-- FrequencyPeriod1 required-field check
DO $$
DECLARE f public."FrequencyPeriod1";
BEGIN
    f := ROW('MNTH', 3);
    ASSERT public.validate_frequency_period1(f), 'should accept when both mandatory fields are set';
    f := ROW(NULL, 3);
    ASSERT NOT public.validate_frequency_period1(f), 'should reject when Type is missing';
    f := ROW('MNTH', NULL);
    ASSERT NOT public.validate_frequency_period1(f), 'should reject when CountPerPeriod is missing';
    RAISE NOTICE 'PASS: FrequencyPeriod1';
END $$;

-- FrequencyAndMoment1 required-field check
DO $$
DECLARE f public."FrequencyAndMoment1";
BEGIN
    f := ROW('MNTH', '15');
    ASSERT public.validate_frequency_and_moment1(f), 'should accept when both mandatory fields are set';
    f := ROW(NULL, '15');
    ASSERT NOT public.validate_frequency_and_moment1(f), 'should reject when Type is missing';
    f := ROW('MNTH', NULL);
    ASSERT NOT public.validate_frequency_and_moment1(f), 'should reject when PointInTime is missing';
    RAISE NOTICE 'PASS: FrequencyAndMoment1';
END $$;

\echo 'All 10.1 File 1 tests passed.'
