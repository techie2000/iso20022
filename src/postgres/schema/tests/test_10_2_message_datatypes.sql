-- =====================================================================
-- test_10_2_message_datatypes.sql
--
-- Automated regression tests for 10.2_message_datatypes.sql. Uses
-- PL/pgSQL ASSERT, which raises a real exception (assert_failure) on
-- failure -- unlike RAISE NOTICE, this actually stops the script and
-- gives psql (run with -v ON_ERROR_STOP=1) a non-zero exit code, so it's
-- safe to wire into CI rather than needing a human to read NOTICE output.
--
-- Run standalone: psql -d your_database -v ON_ERROR_STOP=1 -f test_10_2_message_datatypes.sql
-- Or via run_all_tests.sql, which runs every test file in order.
-- =====================================================================

\echo 'Running 10.2 Message Datatypes tests...'

-- Domain format checks
DO $$
BEGIN
    ASSERT 'USD'::public."ActiveCurrencyCode" = 'USD', 'ActiveCurrencyCode should accept a valid 3-letter code';
    BEGIN
        PERFORM 'usd'::public."ActiveCurrencyCode";
        ASSERT false, 'ActiveCurrencyCode should reject lowercase';
    EXCEPTION WHEN check_violation THEN NULL; -- expected
    END;

    ASSERT 'GB29NWBK60161331926819'::public."IBAN2007Identifier" IS NOT NULL, 'IBAN2007Identifier should accept a valid-format IBAN';
    BEGIN
        PERFORM 'GB29'::public."IBAN2007Identifier";
        ASSERT false, 'IBAN2007Identifier should reject a too-short value';
    EXCEPTION WHEN check_violation THEN NULL; -- expected
    END;

    ASSERT 'f47ac10b-58cc-4372-a567-0e02b2c3d479'::public."UUIDv4Identifier" IS NOT NULL, 'UUIDv4Identifier should accept a valid v4 UUID';
    BEGIN
        PERFORM 'f47ac10b-58cc-1372-a567-0e02b2c3d479'::public."UUIDv4Identifier";
        ASSERT false, 'UUIDv4Identifier should reject a non-v4 UUID (wrong version nibble)';
    EXCEPTION WHEN check_violation THEN NULL; -- expected
    END;

    RAISE NOTICE 'PASS: domain format checks';
END $$;

-- ENUM
DO $$
BEGIN
    ASSERT 'ADDR'::public."AddressType2Code" = 'ADDR', 'AddressType2Code should accept ADDR';
    BEGIN
        PERFORM 'ADRR'::public."AddressType2Code";
        ASSERT false, 'AddressType2Code should reject a bogus value';
    EXCEPTION WHEN invalid_text_representation THEN NULL; -- expected
    END;
    RAISE NOTICE 'PASS: enum checks';
END $$;

-- varchar(n) length enforcement on real insert (not explicit cast, which truncates silently -- see README)
DO $$
BEGIN
    CREATE TEMP TABLE _t_max35 ("Val" public."Max35Text");
    BEGIN
        INSERT INTO _t_max35 VALUES (repeat('x', 36));
        ASSERT false, 'Max35Text should reject a 36-character value on insert';
    EXCEPTION WHEN string_data_right_truncation THEN NULL; -- expected
    END;
    INSERT INTO _t_max35 VALUES (repeat('x', 35));
    ASSERT (SELECT count(*) FROM _t_max35) = 1, 'Max35Text should accept exactly 35 characters';
    DROP TABLE _t_max35;
    RAISE NOTICE 'PASS: varchar(n) length enforcement on insert';
END $$;

-- Composite Amount+Currency type and its validate_ function
DO $$
DECLARE v public."ActiveCurrencyAndAmount";
BEGIN
    v := ROW(150.25, 'USD');
    ASSERT public.validate_active_currency_and_amount(v), 'validate_active_currency_and_amount should accept a positive amount with valid currency';
    v := ROW(-5.00, 'USD');
    ASSERT NOT public.validate_active_currency_and_amount(v), 'validate_active_currency_and_amount should reject a negative amount';
    RAISE NOTICE 'PASS: ActiveCurrencyAndAmount composite + validate function';
END $$;

-- External*Code lookup table + paired domain
DO $$
DECLARE pre_existing boolean;
BEGIN
    SELECT EXISTS(SELECT 1 FROM public."ExternalPurpose1CodeValues" WHERE "Code" = 'ZZZT') INTO pre_existing;
    IF NOT pre_existing THEN
        INSERT INTO public."ExternalPurpose1CodeValues" ("Code", "Name", "Definition")
            VALUES ('ZZZT', 'Test purpose', 'Inserted by automated test');
    END IF;
    ASSERT EXISTS (SELECT 1 FROM public."ExternalPurpose1CodeValues" WHERE "Code" = 'ZZZT'), 'ExternalPurpose1CodeValues should accept a valid 4-char code';
    IF NOT pre_existing THEN
        DELETE FROM public."ExternalPurpose1CodeValues" WHERE "Code" = 'ZZZT';
    END IF;
    BEGIN
        INSERT INTO public."ExternalPurpose1CodeValues" ("Code", "Name") VALUES ('TOOLONG5', 'x');
        ASSERT false, 'ExternalPurpose1CodeValues should reject an over-length code (maxLength 4)';
    EXCEPTION WHEN string_data_right_truncation THEN NULL; -- expected
    END;
    RAISE NOTICE 'PASS: External*Code lookup table + domain';
END $$;

-- Seed data landed (currency/country + external codes)
DO $$
DECLARE cnt int;
BEGIN
    SELECT count(*) INTO cnt FROM public."ActiveCurrencyCodeValues";
    ASSERT cnt = 178, format('ActiveCurrencyCodeValues should have 178 rows, has %s', cnt);

    SELECT count(*) INTO cnt FROM public."CountryCodeValues";
    ASSERT cnt = 249, format('CountryCodeValues should have 249 rows, has %s', cnt);

    SELECT count(*) INTO cnt FROM public."ExternalPurpose1CodeValues";
    ASSERT cnt > 0, 'ExternalPurpose1CodeValues should be seeded (non-zero rows)';

    -- The two code sets confirmed to have zero published values this quarter should indeed be empty
    SELECT count(*) INTO cnt FROM public."ExternalFinancialInstitutionIdentification1CodeValues";
    ASSERT cnt = 0, 'ExternalFinancialInstitutionIdentification1CodeValues is expected to be empty this quarter';

    RAISE NOTICE 'PASS: seed data row counts';
END $$;

\echo 'All 10.2 Message Datatypes tests passed.'
