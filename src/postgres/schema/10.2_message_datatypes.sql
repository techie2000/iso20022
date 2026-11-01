-- =====================================================================
-- ISO 20022 Message Definition Report - Part 2
-- Payments Clearing and Settlement - Maintenance 2024-2025 (Feb 2025)
-- Section 10.2 "Message Datatypes" (source PDF pages 845-869)
--
-- Foundation layer: leaf datatypes referenced throughout 10.1 Message
-- Components and every pain/pacs/camt message. Build this before the
-- component library.
--
-- Conventions:
--   * schema: public
--   * identifiers: exact MDR PascalCase name, double-quoted
--   * every domain/type/function documented via COMMENT ON, carrying
--     the MDR's Definition / Format / Constraints text
--   * CodeSets with values embedded in the MDR -> native ENUM
--   * CodeSets whose values are external (ISO-maintained) -> domain
--     (format-only check) + an empty paired lookup table scaffold
--   * Amount-with-currency datatypes -> composite TYPE + validate_
--     function (mirrors the DatePeriod2 / validate_date_period pattern)
-- =====================================================================
-- ---------------------------------------------------------------------
-- PART 1 -- 10.2.3 CodeSet: pattern-only codes backed by external registries
-- (ISO 4217 currency list, UN/ISO 3166 country list). Format-only checks.
-- ---------------------------------------------------------------------
-- Domain: ActiveCurrencyCode
DROP DOMAIN IF EXISTS public."ActiveCurrencyCode" CASCADE;
CREATE DOMAIN public."ActiveCurrencyCode" AS varchar(3)
    CHECK (VALUE ~ '^[A-Z]{3}$');
ALTER DOMAIN public."ActiveCurrencyCode" OWNER TO postgres;
COMMENT ON DOMAIN public."ActiveCurrencyCode" IS
'Definition: A code allocated to a currency by a Maintenance Agency under an international identification scheme as described in the latest edition of ISO 4217 "Codes for the representation of currencies and funds".

Format: pattern [A-Z]{3,3} (3 contiguous uppercase letters).

Constraint - ActiveCurrency: The currency code must be a valid ACTIVE currency code, not yet withdrawn on the day the message containing the currency is exchanged. Valid active currency codes are registered with the ISO 4217 Maintenance Agency, consist of three (3) contiguous letters, and are not yet withdrawn on the day the message is exchanged.

Note: this domain enforces FORMAT ONLY (3 letters). Whether a code is currently active per ISO 4217 is not enforced at the database layer -- see the paired public."ActiveCurrencyCodeValues" lookup table below.';
-- Table: ActiveCurrencyCodeValues
DROP TABLE IF EXISTS public."ActiveCurrencyCodeValues" CASCADE;
CREATE TABLE public."ActiveCurrencyCodeValues" (
    "Code" public."ActiveCurrencyCode" PRIMARY KEY,
    "Name" text NOT NULL,
    "Definition" text,
    "IsActive" boolean NOT NULL DEFAULT true
);
ALTER TABLE public."ActiveCurrencyCodeValues" OWNER TO postgres;
COMMENT ON TABLE public."ActiveCurrencyCodeValues" IS
'Lookup scaffold for ActiveCurrencyCode (ISO 4217 currently-active currencies). Empty by design -- populate from the current ISO 4217 Maintenance Agency list before relying on it for FK-enforced validation. Ask if you would like this pre-populated with the current published list.';
-- Domain: ActiveOrHistoricCurrencyCode
DROP DOMAIN IF EXISTS public."ActiveOrHistoricCurrencyCode" CASCADE;
CREATE DOMAIN public."ActiveOrHistoricCurrencyCode" AS varchar(3)
    CHECK (VALUE ~ '^[A-Z]{3}$');
ALTER DOMAIN public."ActiveOrHistoricCurrencyCode" OWNER TO postgres;
COMMENT ON DOMAIN public."ActiveOrHistoricCurrencyCode" IS
'Definition: A code allocated to a currency by a Maintenance Agency under an international identification scheme, as described in ISO 4217 "Codes for the representation of currencies and funds".

Format: pattern [A-Z]{3,3} (3 contiguous uppercase letters).

Constraint - ActiveOrHistoricCurrency: The currency code must be registered, or have already been registered (i.e. active OR historic / withdrawn). Valid codes are registered with the ISO 4217 Maintenance Agency.

Note: this domain enforces FORMAT ONLY (3 letters), not registration status -- see the paired public."ActiveOrHistoricCurrencyCodeValues" lookup table below.';
-- Table: ActiveOrHistoricCurrencyCodeValues
DROP TABLE IF EXISTS public."ActiveOrHistoricCurrencyCodeValues" CASCADE;
CREATE TABLE public."ActiveOrHistoricCurrencyCodeValues" (
    "Code" public."ActiveOrHistoricCurrencyCode" PRIMARY KEY,
    "Name" text NOT NULL,
    "Definition" text,
    "IsActive" boolean NOT NULL DEFAULT true
);
ALTER TABLE public."ActiveOrHistoricCurrencyCodeValues" OWNER TO postgres;
COMMENT ON TABLE public."ActiveOrHistoricCurrencyCodeValues" IS
'Lookup scaffold for ActiveOrHistoricCurrencyCode (ISO 4217 active AND historic/withdrawn currencies). Empty by design -- populate from the ISO 4217 Maintenance Agency list (including withdrawn codes) before relying on it for FK-enforced validation. "IsActive" distinguishes currently-active codes from historic/withdrawn ones once populated. Ask if you would like this pre-populated.';
-- Domain: CountryCode
DROP DOMAIN IF EXISTS public."CountryCode" CASCADE;
CREATE DOMAIN public."CountryCode" AS varchar(2)
    CHECK (VALUE ~ '^[A-Z]{2}$');
ALTER DOMAIN public."CountryCode" OWNER TO postgres;
COMMENT ON DOMAIN public."CountryCode" IS
'Definition: Code to identify a country, a dependency, or another area of particular geopolitical interest, on the basis of country names obtained from the United Nations (ISO 3166, Alpha-2 code).

Format: pattern [A-Z]{2,2} (2 contiguous uppercase letters).

Constraint - Country: The code is checked against the list of country names obtained from the United Nations (ISO 3166, Alpha-2 code).

Note: this domain enforces FORMAT ONLY (2 letters), not current UN/ISO 3166 list membership -- see the paired public."CountryCodeValues" lookup table below.';
-- Table: CountryCodeValues
DROP TABLE IF EXISTS public."CountryCodeValues" CASCADE;
CREATE TABLE public."CountryCodeValues" (
    "Code" public."CountryCode" PRIMARY KEY,
    "Name" text NOT NULL,
    "Definition" text,
    "IsActive" boolean NOT NULL DEFAULT true
);
ALTER TABLE public."CountryCodeValues" OWNER TO postgres;
COMMENT ON TABLE public."CountryCodeValues" IS
'Lookup scaffold for CountryCode (UN/ISO 3166-1 Alpha-2 country codes). Empty by design -- populate from the current ISO 3166 list before relying on it for FK-enforced validation. Ask if you would like this pre-populated with the current published list.';
-- ---------------------------------------------------------------------
-- PART 1b -- Seed data: ISO 4217 currencies and ISO 3166-1 countries
-- Source: ISO 4217 -- https://datahub.io/core/currency-codes
--         (SIX Interbank Clearing Ltd on behalf of ISO; ODC-PDDL-1.0;
--          consolidated Tables A.1 + A.3; retrieved 2026-08-26)
--         ISO 3166-1 alpha-2 -- https://datahub.io/core/country-list
--         (source: ISO Online Browsing Platform; ODC-PDDL-1.0;
--          249 entries as of 2026-05-12; retrieved 2026-08-26)
-- Re-run against a refreshed CSV to update; these lists do drift
-- (new currencies, redenominations, occasional country code changes).
-- ---------------------------------------------------------------------
-- ---------------------------------------------------------------------
-- PART 1b -- Seed data: ISO 4217 currencies and ISO 3166-1 countries
-- Source: ISO 4217 -- https://datahub.io/core/currency-codes
--         (SIX Interbank Clearing Ltd on behalf of ISO; ODC-PDDL-1.0;
--          consolidated Tables A.1 + A.3; retrieved 2026-08-26)
--         ISO 3166-1 alpha-2 -- https://datahub.io/core/country-list
--         (source: ISO Online Browsing Platform; ODC-PDDL-1.0;
--          249 entries as of 2026-05-12; retrieved 2026-08-26)
-- Re-run against a refreshed CSV to update; these lists do drift
-- (new currencies, redenominations, occasional country code changes).
--
-- NOTE: 6 country names contain accented characters (Curacao, Cote
-- d'Ivoire, Reunion, Saint Barthelemy, Turkiye, Aland Islands). The
-- client_encoding line below guards against a non-UTF8 session silently
-- failing the whole batch on those rows.
-- ---------------------------------------------------------------------
SET client_encoding = 'UTF8';
-- Seed: ActiveCurrencyCodeValues (currently active ISO 4217 codes)
INSERT INTO public."ActiveCurrencyCodeValues" ("Code", "Name") VALUES
    ('AED', 'UAE Dirham'),
    ('AFN', 'Afghani'),
    ('ALL', 'Lek'),
    ('AMD', 'Armenian Dram'),
    ('AOA', 'Kwanza'),
    ('ARS', 'Argentine Peso'),
    ('AUD', 'Australian Dollar'),
    ('AWG', 'Aruban Florin'),
    ('AZN', 'Azerbaijan Manat'),
    ('BAM', 'Convertible Mark'),
    ('BBD', 'Barbados Dollar'),
    ('BDT', 'Taka'),
    ('BHD', 'Bahraini Dinar'),
    ('BIF', 'Burundi Franc'),
    ('BMD', 'Bermudian Dollar'),
    ('BND', 'Brunei Dollar'),
    ('BOB', 'Boliviano'),
    ('BOV', 'Mvdol'),
    ('BRL', 'Brazilian Real'),
    ('BSD', 'Bahamian Dollar'),
    ('BTN', 'Ngultrum'),
    ('BWP', 'Pula'),
    ('BYN', 'Belarusian Ruble'),
    ('BZD', 'Belize Dollar'),
    ('CAD', 'Canadian Dollar'),
    ('CDF', 'Congolese Franc'),
    ('CHE', 'WIR Euro'),
    ('CHF', 'Swiss Franc'),
    ('CHW', 'WIR Franc'),
    ('CLF', 'Unidad de Fomento'),
    ('CLP', 'Chilean Peso'),
    ('CNY', 'Yuan Renminbi'),
    ('COP', 'Colombian Peso'),
    ('COU', 'Unidad de Valor Real'),
    ('CRC', 'Costa Rican Colon'),
    ('CUP', 'Cuban Peso'),
    ('CVE', 'Cabo Verde Escudo'),
    ('CZK', 'Czech Koruna'),
    ('DJF', 'Djibouti Franc'),
    ('DKK', 'Danish Krone')
ON CONFLICT ("Code") DO NOTHING;
INSERT INTO public."ActiveCurrencyCodeValues" ("Code", "Name") VALUES
    ('DOP', 'Dominican Peso'),
    ('DZD', 'Algerian Dinar'),
    ('EGP', 'Egyptian Pound'),
    ('ERN', 'Nakfa'),
    ('ETB', 'Ethiopian Birr'),
    ('EUR', 'Euro'),
    ('FJD', 'Fiji Dollar'),
    ('FKP', 'Falkland Islands Pound'),
    ('GBP', 'Pound Sterling'),
    ('GEL', 'Lari'),
    ('GHS', 'Ghana Cedi'),
    ('GIP', 'Gibraltar Pound'),
    ('GMD', 'Dalasi'),
    ('GNF', 'Guinean Franc'),
    ('GTQ', 'Quetzal'),
    ('GYD', 'Guyana Dollar'),
    ('HKD', 'Hong Kong Dollar'),
    ('HNL', 'Lempira'),
    ('HTG', 'Gourde'),
    ('HUF', 'Forint'),
    ('IDR', 'Rupiah'),
    ('ILS', 'New Israeli Sheqel'),
    ('INR', 'Indian Rupee'),
    ('IQD', 'Iraqi Dinar'),
    ('IRR', 'Iranian Rial'),
    ('ISK', 'Iceland Krona'),
    ('JMD', 'Jamaican Dollar'),
    ('JOD', 'Jordanian Dinar'),
    ('JPY', 'Yen'),
    ('KES', 'Kenyan Shilling'),
    ('KGS', 'Som'),
    ('KHR', 'Riel'),
    ('KMF', 'Comorian Franc'),
    ('KPW', 'North Korean Won'),
    ('KRW', 'Won'),
    ('KWD', 'Kuwaiti Dinar'),
    ('KYD', 'Cayman Islands Dollar'),
    ('KZT', 'Tenge'),
    ('LAK', 'Lao Kip'),
    ('LBP', 'Lebanese Pound')
ON CONFLICT ("Code") DO NOTHING;
INSERT INTO public."ActiveCurrencyCodeValues" ("Code", "Name") VALUES
    ('LKR', 'Sri Lanka Rupee'),
    ('LRD', 'Liberian Dollar'),
    ('LSL', 'Loti'),
    ('LYD', 'Libyan Dinar'),
    ('MAD', 'Moroccan Dirham'),
    ('MDL', 'Moldovan Leu'),
    ('MGA', 'Malagasy Ariary'),
    ('MKD', 'Denar'),
    ('MMK', 'Kyat'),
    ('MNT', 'Tugrik'),
    ('MOP', 'Pataca'),
    ('MRU', 'Ouguiya'),
    ('MUR', 'Mauritius Rupee'),
    ('MVR', 'Rufiyaa'),
    ('MWK', 'Malawi Kwacha'),
    ('MXN', 'Mexican Peso'),
    ('MXV', 'Mexican Unidad de Inversion (UDI)'),
    ('MYR', 'Malaysian Ringgit'),
    ('MZN', 'Mozambique Metical'),
    ('NAD', 'Namibia Dollar'),
    ('NGN', 'Naira'),
    ('NIO', 'Cordoba Oro'),
    ('NOK', 'Norwegian Krone'),
    ('NPR', 'Nepalese Rupee'),
    ('NZD', 'New Zealand Dollar'),
    ('OMR', 'Rial Omani'),
    ('PAB', 'Balboa'),
    ('PEN', 'Sol'),
    ('PGK', 'Kina'),
    ('PHP', 'Philippine Peso'),
    ('PKR', 'Pakistan Rupee'),
    ('PLN', 'Zloty'),
    ('PYG', 'Guarani'),
    ('QAR', 'Qatari Rial'),
    ('RON', 'Romanian Leu'),
    ('RSD', 'Serbian Dinar'),
    ('RUB', 'Russian Ruble'),
    ('RWF', 'Rwanda Franc'),
    ('SAR', 'Saudi Riyal'),
    ('SBD', 'Solomon Islands Dollar')
ON CONFLICT ("Code") DO NOTHING;
INSERT INTO public."ActiveCurrencyCodeValues" ("Code", "Name") VALUES
    ('SCR', 'Seychelles Rupee'),
    ('SDG', 'Sudanese Pound'),
    ('SEK', 'Swedish Krona'),
    ('SGD', 'Singapore Dollar'),
    ('SHP', 'Saint Helena Pound'),
    ('SLE', 'Leone'),
    ('SOS', 'Somali Shilling'),
    ('SRD', 'Surinam Dollar'),
    ('SSP', 'South Sudanese Pound'),
    ('STN', 'Dobra'),
    ('SVC', 'El Salvador Colon'),
    ('SYP', 'Syrian Pound'),
    ('SZL', 'Lilangeni'),
    ('THB', 'Baht'),
    ('TJS', 'Somoni'),
    ('TMT', 'Turkmenistan New Manat'),
    ('TND', 'Tunisian Dinar'),
    ('TOP', 'Pa''anga'),
    ('TRY', 'Turkish Lira'),
    ('TTD', 'Trinidad and Tobago Dollar'),
    ('TWD', 'New Taiwan Dollar'),
    ('TZS', 'Tanzanian Shilling'),
    ('UAH', 'Hryvnia'),
    ('UGX', 'Uganda Shilling'),
    ('USD', 'US Dollar'),
    ('USN', 'US Dollar (Next day)'),
    ('UYI', 'Uruguay Peso en Unidades Indexadas (UI)'),
    ('UYU', 'Peso Uruguayo'),
    ('UYW', 'Unidad Previsional'),
    ('UZS', 'Uzbekistan Sum'),
    ('VED', 'Bolívar Soberano'),
    ('VES', 'Bolívar Soberano'),
    ('VND', 'Dong'),
    ('VUV', 'Vatu'),
    ('WST', 'Tala'),
    ('XAD', 'Arab Accounting Dinar'),
    ('XAF', 'CFA Franc BEAC'),
    ('XAG', 'Silver'),
    ('XAU', 'Gold'),
    ('XBA', 'Bond Markets Unit European Composite Unit (EURCO)')
ON CONFLICT ("Code") DO NOTHING;
INSERT INTO public."ActiveCurrencyCodeValues" ("Code", "Name") VALUES
    ('XBB', 'Bond Markets Unit European Monetary Unit (E.M.U.-6)'),
    ('XBC', 'Bond Markets Unit European Unit of Account 9 (E.U.A.-9)'),
    ('XBD', 'Bond Markets Unit European Unit of Account 17 (E.U.A.-17)'),
    ('XCD', 'East Caribbean Dollar'),
    ('XCG', 'Caribbean Guilder'),
    ('XDR', 'SDR (Special Drawing Right)'),
    ('XOF', 'CFA Franc BCEAO'),
    ('XPD', 'Palladium'),
    ('XPF', 'CFP Franc'),
    ('XPT', 'Platinum'),
    ('XSU', 'Sucre'),
    ('XTS', 'Codes specifically reserved for testing purposes'),
    ('XUA', 'ADB Unit of Account'),
    ('XXX', 'The codes assigned for transactions where no currency is involved'),
    ('YER', 'Yemeni Rial'),
    ('ZAR', 'Rand'),
    ('ZMW', 'Zambian Kwacha'),
    ('ZWG', 'Zimbabwe Gold')
ON CONFLICT ("Code") DO NOTHING;
-- Seed: ActiveOrHistoricCurrencyCodeValues (active + historic/withdrawn)
INSERT INTO public."ActiveOrHistoricCurrencyCodeValues" ("Code", "Name", "IsActive") VALUES
    ('ADP', 'Andorran Peseta', false),
    ('AED', 'UAE Dirham', true),
    ('AFA', 'Afghani', false),
    ('AFN', 'Afghani', true),
    ('ALK', 'Old Lek', false),
    ('ALL', 'Lek', true),
    ('AMD', 'Armenian Dram', true),
    ('ANG', 'Netherlands Antillean Guilder', false),
    ('AOA', 'Kwanza', true),
    ('AOK', 'Kwanza', false),
    ('AON', 'New Kwanza', false),
    ('AOR', 'Kwanza Reajustado', false),
    ('ARA', 'Austral', false),
    ('ARP', 'Peso Argentino', false),
    ('ARS', 'Argentine Peso', true),
    ('ARY', 'Peso', false),
    ('ATS', 'Schilling', false),
    ('AUD', 'Australian Dollar', true),
    ('AWG', 'Aruban Florin', true),
    ('AYM', 'Azerbaijan Manat', false),
    ('AZM', 'Azerbaijanian Manat', false),
    ('AZN', 'Azerbaijan Manat', true),
    ('BAD', 'Dinar', false),
    ('BAM', 'Convertible Mark', true),
    ('BBD', 'Barbados Dollar', true),
    ('BDT', 'Taka', true),
    ('BEC', 'Convertible Franc', false),
    ('BEF', 'Belgian Franc', false),
    ('BEL', 'Financial Franc', false),
    ('BGJ', 'Lev A/52', false),
    ('BGK', 'Lev A/62', false),
    ('BGL', 'Lev', false),
    ('BGN', 'Bulgarian Lev', false),
    ('BHD', 'Bahraini Dinar', true),
    ('BIF', 'Burundi Franc', true),
    ('BMD', 'Bermudian Dollar', true),
    ('BND', 'Brunei Dollar', true),
    ('BOB', 'Boliviano', true),
    ('BOP', 'Peso boliviano', false),
    ('BOV', 'Mvdol', true)
ON CONFLICT ("Code") DO NOTHING;
INSERT INTO public."ActiveOrHistoricCurrencyCodeValues" ("Code", "Name", "IsActive") VALUES
    ('BRB', 'Cruzeiro', false),
    ('BRC', 'Cruzado', false),
    ('BRE', 'Cruzeiro', false),
    ('BRL', 'Brazilian Real', true),
    ('BRN', 'New Cruzado', false),
    ('BRR', 'Cruzeiro Real', false),
    ('BSD', 'Bahamian Dollar', true),
    ('BTN', 'Ngultrum', true),
    ('BUK', 'Kyat', false),
    ('BWP', 'Pula', true),
    ('BYB', 'Belarusian Ruble', false),
    ('BYN', 'Belarusian Ruble', true),
    ('BYR', 'Belarusian Ruble', false),
    ('BZD', 'Belize Dollar', true),
    ('CAD', 'Canadian Dollar', true),
    ('CDF', 'Congolese Franc', true),
    ('CHC', 'WIR Franc (for electronic)', false),
    ('CHE', 'WIR Euro', true),
    ('CHF', 'Swiss Franc', true),
    ('CHW', 'WIR Franc', true),
    ('CLF', 'Unidad de Fomento', true),
    ('CLP', 'Chilean Peso', true),
    ('CNY', 'Yuan Renminbi', true),
    ('COP', 'Colombian Peso', true),
    ('COU', 'Unidad de Valor Real', true),
    ('CRC', 'Costa Rican Colon', true),
    ('CSD', 'Serbian Dinar', false),
    ('CSJ', 'Krona A/53', false),
    ('CSK', 'Koruna', false),
    ('CUC', 'Peso Convertible', false),
    ('CUP', 'Cuban Peso', true),
    ('CVE', 'Cabo Verde Escudo', true),
    ('CYP', 'Cyprus Pound', false),
    ('CZK', 'Czech Koruna', true),
    ('DDM', 'Mark der DDR', false),
    ('DEM', 'Deutsche Mark', false),
    ('DJF', 'Djibouti Franc', true),
    ('DKK', 'Danish Krone', true),
    ('DOP', 'Dominican Peso', true),
    ('DZD', 'Algerian Dinar', true)
ON CONFLICT ("Code") DO NOTHING;
INSERT INTO public."ActiveOrHistoricCurrencyCodeValues" ("Code", "Name", "IsActive") VALUES
    ('ECS', 'Sucre', false),
    ('ECV', 'Unidad de Valor Constante (UVC)', false),
    ('EEK', 'Kroon', false),
    ('EGP', 'Egyptian Pound', true),
    ('ERN', 'Nakfa', true),
    ('ESA', 'Spanish Peseta', false),
    ('ESB', '"A" Account (convertible Peseta Account)', false),
    ('ESP', 'Spanish Peseta', false),
    ('ETB', 'Ethiopian Birr', true),
    ('EUR', 'Euro', true),
    ('FIM', 'Markka', false),
    ('FJD', 'Fiji Dollar', true),
    ('FKP', 'Falkland Islands Pound', true),
    ('FRF', 'French Franc', false),
    ('GBP', 'Pound Sterling', true),
    ('GEK', 'Georgian Coupon', false),
    ('GEL', 'Lari', true),
    ('GHC', 'Cedi', false),
    ('GHP', 'Ghana Cedi', false),
    ('GHS', 'Ghana Cedi', true),
    ('GIP', 'Gibraltar Pound', true),
    ('GMD', 'Dalasi', true),
    ('GNE', 'Syli', false),
    ('GNF', 'Guinean Franc', true),
    ('GNS', 'Syli', false),
    ('GQE', 'Ekwele', false),
    ('GRD', 'Drachma', false),
    ('GTQ', 'Quetzal', true),
    ('GWE', 'Guinea Escudo', false),
    ('GWP', 'Guinea-Bissau Peso', false),
    ('GYD', 'Guyana Dollar', true),
    ('HKD', 'Hong Kong Dollar', true),
    ('HNL', 'Lempira', true),
    ('HRD', 'Croatian Dinar', false),
    ('HRK', 'Croatian Kuna', false),
    ('HTG', 'Gourde', true),
    ('HUF', 'Forint', true),
    ('IDR', 'Rupiah', true),
    ('IEP', 'Irish Pound', false),
    ('ILP', 'Pound', false)
ON CONFLICT ("Code") DO NOTHING;
INSERT INTO public."ActiveOrHistoricCurrencyCodeValues" ("Code", "Name", "IsActive") VALUES
    ('ILR', 'Old Shekel', false),
    ('ILS', 'New Israeli Sheqel', true),
    ('INR', 'Indian Rupee', true),
    ('IQD', 'Iraqi Dinar', true),
    ('IRR', 'Iranian Rial', true),
    ('ISJ', 'Old Krona', false),
    ('ISK', 'Iceland Krona', true),
    ('ITL', 'Italian Lira', false),
    ('JMD', 'Jamaican Dollar', true),
    ('JOD', 'Jordanian Dinar', true),
    ('JPY', 'Yen', true),
    ('KES', 'Kenyan Shilling', true),
    ('KGS', 'Som', true),
    ('KHR', 'Riel', true),
    ('KMF', 'Comorian Franc', true),
    ('KPW', 'North Korean Won', true),
    ('KRW', 'Won', true),
    ('KWD', 'Kuwaiti Dinar', true),
    ('KYD', 'Cayman Islands Dollar', true),
    ('KZT', 'Tenge', true),
    ('LAJ', 'Pathet Lao Kip', false),
    ('LAK', 'Lao Kip', true),
    ('LBP', 'Lebanese Pound', true),
    ('LKR', 'Sri Lanka Rupee', true),
    ('LRD', 'Liberian Dollar', true),
    ('LSL', 'Loti', true),
    ('LSM', 'Loti', false),
    ('LTL', 'Lithuanian Litas', false),
    ('LTT', 'Talonas', false),
    ('LUC', 'Luxembourg Convertible Franc', false),
    ('LUF', 'Luxembourg Franc', false),
    ('LUL', 'Luxembourg Financial Franc', false),
    ('LVL', 'Latvian Lats', false),
    ('LVR', 'Latvian Ruble', false),
    ('LYD', 'Libyan Dinar', true),
    ('MAD', 'Moroccan Dirham', true),
    ('MDL', 'Moldovan Leu', true),
    ('MGA', 'Malagasy Ariary', true),
    ('MGF', 'Malagasy Franc', false),
    ('MKD', 'Denar', true)
ON CONFLICT ("Code") DO NOTHING;
INSERT INTO public."ActiveOrHistoricCurrencyCodeValues" ("Code", "Name", "IsActive") VALUES
    ('MLF', 'Mali Franc', false),
    ('MMK', 'Kyat', true),
    ('MNT', 'Tugrik', true),
    ('MOP', 'Pataca', true),
    ('MRO', 'Ouguiya', false),
    ('MRU', 'Ouguiya', true),
    ('MTL', 'Maltese Lira', false),
    ('MTP', 'Maltese Pound', false),
    ('MUR', 'Mauritius Rupee', true),
    ('MVQ', 'Maldive Rupee', false),
    ('MVR', 'Rufiyaa', true),
    ('MWK', 'Malawi Kwacha', true),
    ('MXN', 'Mexican Peso', true),
    ('MXP', 'Mexican Peso', false),
    ('MXV', 'Mexican Unidad de Inversion (UDI)', true),
    ('MYR', 'Malaysian Ringgit', true),
    ('MZE', 'Mozambique Escudo', false),
    ('MZM', 'Mozambique Metical', false),
    ('MZN', 'Mozambique Metical', true),
    ('NAD', 'Namibia Dollar', true),
    ('NGN', 'Naira', true),
    ('NIC', 'Cordoba', false),
    ('NIO', 'Cordoba Oro', true),
    ('NLG', 'Netherlands Guilder', false),
    ('NOK', 'Norwegian Krone', true),
    ('NPR', 'Nepalese Rupee', true),
    ('NZD', 'New Zealand Dollar', true),
    ('OMR', 'Rial Omani', true),
    ('PAB', 'Balboa', true),
    ('PEH', 'Sol', false),
    ('PEI', 'Inti', false),
    ('PEN', 'Sol', true),
    ('PES', 'Sol', false),
    ('PGK', 'Kina', true),
    ('PHP', 'Philippine Peso', true),
    ('PKR', 'Pakistan Rupee', true),
    ('PLN', 'Zloty', true),
    ('PLZ', 'Zloty', false),
    ('PTE', 'Portuguese Escudo', false),
    ('PYG', 'Guarani', true)
ON CONFLICT ("Code") DO NOTHING;
INSERT INTO public."ActiveOrHistoricCurrencyCodeValues" ("Code", "Name", "IsActive") VALUES
    ('QAR', 'Qatari Rial', true),
    ('RHD', 'Rhodesian Dollar', false),
    ('ROK', 'Leu A/52', false),
    ('ROL', 'Old Leu', false),
    ('RON', 'Romanian Leu', true),
    ('RSD', 'Serbian Dinar', true),
    ('RUB', 'Russian Ruble', true),
    ('RUR', 'Russian Ruble', false),
    ('RWF', 'Rwanda Franc', true),
    ('SAR', 'Saudi Riyal', true),
    ('SBD', 'Solomon Islands Dollar', true),
    ('SCR', 'Seychelles Rupee', true),
    ('SDD', 'Sudanese Dinar', false),
    ('SDG', 'Sudanese Pound', true),
    ('SDP', 'Sudanese Pound', false),
    ('SEK', 'Swedish Krona', true),
    ('SGD', 'Singapore Dollar', true),
    ('SHP', 'Saint Helena Pound', true),
    ('SIT', 'Tolar', false),
    ('SKK', 'Slovak Koruna', false),
    ('SLE', 'Leone', true),
    ('SLL', 'Leone', false),
    ('SOS', 'Somali Shilling', true),
    ('SRD', 'Surinam Dollar', true),
    ('SRG', 'Surinam Guilder', false),
    ('SSP', 'South Sudanese Pound', true),
    ('STD', 'Dobra', false),
    ('STN', 'Dobra', true),
    ('SUR', 'Rouble', false),
    ('SVC', 'El Salvador Colon', true),
    ('SYP', 'Syrian Pound', true),
    ('SZL', 'Lilangeni', true),
    ('THB', 'Baht', true),
    ('TJR', 'Tajik Ruble', false),
    ('TJS', 'Somoni', true),
    ('TMM', 'Turkmenistan Manat', false),
    ('TMT', 'Turkmenistan New Manat', true),
    ('TND', 'Tunisian Dinar', true),
    ('TOP', 'Pa''anga', true),
    ('TPE', 'Timor Escudo', false)
ON CONFLICT ("Code") DO NOTHING;
INSERT INTO public."ActiveOrHistoricCurrencyCodeValues" ("Code", "Name", "IsActive") VALUES
    ('TRL', 'Old Turkish Lira', false),
    ('TRY', 'Turkish Lira', true),
    ('TTD', 'Trinidad and Tobago Dollar', true),
    ('TWD', 'New Taiwan Dollar', true),
    ('TZS', 'Tanzanian Shilling', true),
    ('UAH', 'Hryvnia', true),
    ('UAK', 'Karbovanet', false),
    ('UGS', 'Uganda Shilling', false),
    ('UGW', 'Old Shilling', false),
    ('UGX', 'Uganda Shilling', true),
    ('USD', 'US Dollar', true),
    ('USN', 'US Dollar (Next day)', true),
    ('USS', 'US Dollar (Same day)', false),
    ('UYI', 'Uruguay Peso en Unidades Indexadas (UI)', true),
    ('UYN', 'Old Uruguay Peso', false),
    ('UYP', 'Uruguayan Peso', false),
    ('UYU', 'Peso Uruguayo', true),
    ('UYW', 'Unidad Previsional', true),
    ('UZS', 'Uzbekistan Sum', true),
    ('VEB', 'Bolivar', false),
    ('VED', 'Bolívar Soberano', true),
    ('VEF', 'Bolivar Fuerte', false),
    ('VES', 'Bolívar Soberano', true),
    ('VNC', 'Old Dong', false),
    ('VND', 'Dong', true),
    ('VUV', 'Vatu', true),
    ('WST', 'Tala', true),
    ('XAD', 'Arab Accounting Dinar', true),
    ('XAF', 'CFA Franc BEAC', true),
    ('XAG', 'Silver', true),
    ('XAU', 'Gold', true),
    ('XBA', 'Bond Markets Unit European Composite Unit (EURCO)', true),
    ('XBB', 'Bond Markets Unit European Monetary Unit (E.M.U.-6)', true),
    ('XBC', 'Bond Markets Unit European Unit of Account 9 (E.U.A.-9)', true),
    ('XBD', 'Bond Markets Unit European Unit of Account 17 (E.U.A.-17)', true),
    ('XCD', 'East Caribbean Dollar', true),
    ('XCG', 'Caribbean Guilder', true),
    ('XDR', 'SDR (Special Drawing Right)', true),
    ('XEU', 'European Currency Unit (E.C.U)', false),
    ('XFO', 'Gold-Franc', false)
ON CONFLICT ("Code") DO NOTHING;
INSERT INTO public."ActiveOrHistoricCurrencyCodeValues" ("Code", "Name", "IsActive") VALUES
    ('XFU', 'UIC-Franc', false),
    ('XOF', 'CFA Franc BCEAO', true),
    ('XPD', 'Palladium', true),
    ('XPF', 'CFP Franc', true),
    ('XPT', 'Platinum', true),
    ('XRE', 'RINET Funds Code', false),
    ('XSU', 'Sucre', true),
    ('XTS', 'Codes specifically reserved for testing purposes', true),
    ('XUA', 'ADB Unit of Account', true),
    ('XXX', 'The codes assigned for transactions where no currency is involved', true),
    ('YDD', 'Yemeni Dinar', false),
    ('YER', 'Yemeni Rial', true),
    ('YUD', 'New Yugoslavian Dinar', false),
    ('YUM', 'New Dinar', false),
    ('YUN', 'Yugoslavian Dinar', false),
    ('ZAL', 'Financial Rand', false),
    ('ZAR', 'Rand', true),
    ('ZMK', 'Zambian Kwacha', false),
    ('ZMW', 'Zambian Kwacha', true),
    ('ZRN', 'New Zaire', false),
    ('ZRZ', 'Zaire', false),
    ('ZWC', 'Rhodesian Dollar', false),
    ('ZWD', 'Zimbabwe Dollar (old)', false),
    ('ZWG', 'Zimbabwe Gold', true),
    ('ZWL', 'Zimbabwe Dollar', false),
    ('ZWN', 'Zimbabwe Dollar (new)', false),
    ('ZWR', 'Zimbabwe Dollar', false)
ON CONFLICT ("Code") DO NOTHING;
-- Seed: CountryCodeValues (ISO 3166-1 alpha-2, official short names)
INSERT INTO public."CountryCodeValues" ("Code", "Name", "Definition") VALUES
    ('AD', 'Andorra', NULL),
    ('AE', 'United Arab Emirates', NULL),
    ('AF', 'Afghanistan', NULL),
    ('AG', 'Antigua and Barbuda', NULL),
    ('AI', 'Anguilla', NULL),
    ('AL', 'Albania', NULL),
    ('AM', 'Armenia', NULL),
    ('AO', 'Angola', NULL),
    ('AQ', 'Antarctica', NULL),
    ('AR', 'Argentina', NULL),
    ('AS', 'American Samoa', NULL),
    ('AT', 'Austria', NULL),
    ('AU', 'Australia', NULL),
    ('AW', 'Aruba', NULL),
    ('AX', 'Åland Islands', NULL),
    ('AZ', 'Azerbaijan', NULL),
    ('BA', 'Bosnia and Herzegovina', NULL),
    ('BB', 'Barbados', NULL),
    ('BD', 'Bangladesh', NULL),
    ('BE', 'Belgium', NULL),
    ('BF', 'Burkina Faso', NULL),
    ('BG', 'Bulgaria', NULL),
    ('BH', 'Bahrain', NULL),
    ('BI', 'Burundi', NULL),
    ('BJ', 'Benin', NULL),
    ('BL', 'Saint Barthélemy', NULL),
    ('BM', 'Bermuda', NULL),
    ('BN', 'Brunei Darussalam', NULL),
    ('BO', 'Bolivia, Plurinational State of', NULL),
    ('BQ', 'Bonaire, Sint Eustatius and Saba', NULL),
    ('BR', 'Brazil', NULL),
    ('BS', 'Bahamas', NULL),
    ('BT', 'Bhutan', NULL),
    ('BV', 'Bouvet Island', NULL),
    ('BW', 'Botswana', NULL),
    ('BY', 'Belarus', NULL),
    ('BZ', 'Belize', NULL),
    ('CA', 'Canada', NULL),
    ('CC', 'Cocos (Keeling) Islands', NULL),
    ('CD', 'Congo, The Democratic Republic of the', NULL)
ON CONFLICT ("Code") DO NOTHING;
INSERT INTO public."CountryCodeValues" ("Code", "Name", "Definition") VALUES
    ('CF', 'Central African Republic', NULL),
    ('CG', 'Congo', NULL),
    ('CH', 'Switzerland', NULL),
    ('CI', 'Côte d''Ivoire', NULL),
    ('CK', 'Cook Islands', NULL),
    ('CL', 'Chile', NULL),
    ('CM', 'Cameroon', NULL),
    ('CN', 'China', NULL),
    ('CO', 'Colombia', NULL),
    ('CR', 'Costa Rica', NULL),
    ('CU', 'Cuba', NULL),
    ('CV', 'Cabo Verde', NULL),
    ('CW', 'Curaçao', NULL),
    ('CX', 'Christmas Island', NULL),
    ('CY', 'Cyprus', NULL),
    ('CZ', 'Czechia', NULL),
    ('DE', 'Germany', NULL),
    ('DJ', 'Djibouti', NULL),
    ('DK', 'Denmark', NULL),
    ('DM', 'Dominica', NULL),
    ('DO', 'Dominican Republic', NULL),
    ('DZ', 'Algeria', NULL),
    ('EC', 'Ecuador', NULL),
    ('EE', 'Estonia', NULL),
    ('EG', 'Egypt', NULL),
    ('EH', 'Western Sahara', NULL),
    ('ER', 'Eritrea', NULL),
    ('ES', 'Spain', NULL),
    ('ET', 'Ethiopia', NULL),
    ('FI', 'Finland', NULL),
    ('FJ', 'Fiji', NULL),
    ('FK', 'Falkland Islands (Malvinas)', NULL),
    ('FM', 'Micronesia, Federated States of', NULL),
    ('FO', 'Faroe Islands', NULL),
    ('FR', 'France', NULL),
    ('GA', 'Gabon', NULL),
    ('GB', 'United Kingdom', NULL),
    ('GD', 'Grenada', NULL),
    ('GE', 'Georgia', NULL),
    ('GF', 'French Guiana', NULL)
ON CONFLICT ("Code") DO NOTHING;
INSERT INTO public."CountryCodeValues" ("Code", "Name", "Definition") VALUES
    ('GG', 'Guernsey', NULL),
    ('GH', 'Ghana', NULL),
    ('GI', 'Gibraltar', NULL),
    ('GL', 'Greenland', NULL),
    ('GM', 'Gambia', NULL),
    ('GN', 'Guinea', NULL),
    ('GP', 'Guadeloupe', NULL),
    ('GQ', 'Equatorial Guinea', NULL),
    ('GR', 'Greece', NULL),
    ('GS', 'South Georgia and the South Sandwich Islands', NULL),
    ('GT', 'Guatemala', NULL),
    ('GU', 'Guam', NULL),
    ('GW', 'Guinea-Bissau', NULL),
    ('GY', 'Guyana', NULL),
    ('HK', 'Hong Kong', NULL),
    ('HM', 'Heard Island and McDonald Islands', NULL),
    ('HN', 'Honduras', NULL),
    ('HR', 'Croatia', NULL),
    ('HT', 'Haiti', NULL),
    ('HU', 'Hungary', NULL),
    ('ID', 'Indonesia', NULL),
    ('IE', 'Ireland', NULL),
    ('IL', 'Israel', NULL),
    ('IM', 'Isle of Man', NULL),
    ('IN', 'India', NULL),
    ('IO', 'British Indian Ocean Territory', NULL),
    ('IQ', 'Iraq', NULL),
    ('IR', 'Iran, Islamic Republic of', NULL),
    ('IS', 'Iceland', NULL),
    ('IT', 'Italy', NULL),
    ('JE', 'Jersey', NULL),
    ('JM', 'Jamaica', NULL),
    ('JO', 'Jordan', NULL),
    ('JP', 'Japan', NULL),
    ('KE', 'Kenya', NULL),
    ('KG', 'Kyrgyzstan', NULL),
    ('KH', 'Cambodia', NULL),
    ('KI', 'Kiribati', NULL),
    ('KM', 'Comoros', NULL),
    ('KN', 'Saint Kitts and Nevis', NULL)
ON CONFLICT ("Code") DO NOTHING;
INSERT INTO public."CountryCodeValues" ("Code", "Name", "Definition") VALUES
    ('KP', 'Korea, Democratic People''s Republic of', NULL),
    ('KR', 'Korea, Republic of', NULL),
    ('KW', 'Kuwait', NULL),
    ('KY', 'Cayman Islands', NULL),
    ('KZ', 'Kazakhstan', NULL),
    ('LA', 'Lao People''s Democratic Republic', NULL),
    ('LB', 'Lebanon', NULL),
    ('LC', 'Saint Lucia', NULL),
    ('LI', 'Liechtenstein', NULL),
    ('LK', 'Sri Lanka', NULL),
    ('LR', 'Liberia', NULL),
    ('LS', 'Lesotho', NULL),
    ('LT', 'Lithuania', NULL),
    ('LU', 'Luxembourg', NULL),
    ('LV', 'Latvia', NULL),
    ('LY', 'Libya', NULL),
    ('MA', 'Morocco', NULL),
    ('MC', 'Monaco', NULL),
    ('MD', 'Moldova, Republic of', NULL),
    ('ME', 'Montenegro', NULL),
    ('MF', 'Saint Martin (French part)', NULL),
    ('MG', 'Madagascar', NULL),
    ('MH', 'Marshall Islands', NULL),
    ('MK', 'North Macedonia', NULL),
    ('ML', 'Mali', NULL),
    ('MM', 'Myanmar', NULL),
    ('MN', 'Mongolia', NULL),
    ('MO', 'Macao', NULL),
    ('MP', 'Northern Mariana Islands', NULL),
    ('MQ', 'Martinique', NULL),
    ('MR', 'Mauritania', NULL),
    ('MS', 'Montserrat', NULL),
    ('MT', 'Malta', NULL),
    ('MU', 'Mauritius', NULL),
    ('MV', 'Maldives', NULL),
    ('MW', 'Malawi', NULL),
    ('MX', 'Mexico', NULL),
    ('MY', 'Malaysia', NULL),
    ('MZ', 'Mozambique', NULL),
    ('NA', 'Namibia', NULL)
ON CONFLICT ("Code") DO NOTHING;
INSERT INTO public."CountryCodeValues" ("Code", "Name", "Definition") VALUES
    ('NC', 'New Caledonia', NULL),
    ('NE', 'Niger', NULL),
    ('NF', 'Norfolk Island', NULL),
    ('NG', 'Nigeria', NULL),
    ('NI', 'Nicaragua', NULL),
    ('NL', 'Netherlands', NULL),
    ('NO', 'Norway', NULL),
    ('NP', 'Nepal', NULL),
    ('NR', 'Nauru', NULL),
    ('NU', 'Niue', NULL),
    ('NZ', 'New Zealand', NULL),
    ('OM', 'Oman', NULL),
    ('PA', 'Panama', NULL),
    ('PE', 'Peru', NULL),
    ('PF', 'French Polynesia', NULL),
    ('PG', 'Papua New Guinea', NULL),
    ('PH', 'Philippines', NULL),
    ('PK', 'Pakistan', NULL),
    ('PL', 'Poland', NULL),
    ('PM', 'Saint Pierre and Miquelon', NULL),
    ('PN', 'Pitcairn', NULL),
    ('PR', 'Puerto Rico', NULL),
    ('PS', 'Palestine, State of', NULL),
    ('PT', 'Portugal', NULL),
    ('PW', 'Palau', NULL),
    ('PY', 'Paraguay', NULL),
    ('QA', 'Qatar', NULL),
    ('RE', 'Réunion', NULL),
    ('RO', 'Romania', NULL),
    ('RS', 'Serbia', NULL),
    ('RU', 'Russian Federation', NULL),
    ('RW', 'Rwanda', NULL),
    ('SA', 'Saudi Arabia', NULL),
    ('SB', 'Solomon Islands', NULL),
    ('SC', 'Seychelles', NULL),
    ('SD', 'Sudan', NULL),
    ('SE', 'Sweden', NULL),
    ('SG', 'Singapore', NULL),
    ('SH', 'Saint Helena, Ascension and Tristan da Cunha', NULL),
    ('SI', 'Slovenia', NULL)
ON CONFLICT ("Code") DO NOTHING;
INSERT INTO public."CountryCodeValues" ("Code", "Name", "Definition") VALUES
    ('SJ', 'Svalbard and Jan Mayen', NULL),
    ('SK', 'Slovakia', NULL),
    ('SL', 'Sierra Leone', NULL),
    ('SM', 'San Marino', NULL),
    ('SN', 'Senegal', NULL),
    ('SO', 'Somalia', NULL),
    ('SR', 'Suriname', NULL),
    ('SS', 'South Sudan', NULL),
    ('ST', 'Sao Tome and Principe', NULL),
    ('SV', 'El Salvador', NULL),
    ('SX', 'Sint Maarten (Dutch part)', NULL),
    ('SY', 'Syrian Arab Republic', NULL),
    ('SZ', 'Eswatini', NULL),
    ('TC', 'Turks and Caicos Islands', NULL),
    ('TD', 'Chad', NULL),
    ('TF', 'French Southern Territories', NULL),
    ('TG', 'Togo', NULL),
    ('TH', 'Thailand', NULL),
    ('TJ', 'Tajikistan', NULL),
    ('TK', 'Tokelau', NULL),
    ('TL', 'Timor-Leste', NULL),
    ('TM', 'Turkmenistan', NULL),
    ('TN', 'Tunisia', NULL),
    ('TO', 'Tonga', NULL),
    ('TR', 'Türkiye', NULL),
    ('TT', 'Trinidad and Tobago', NULL),
    ('TV', 'Tuvalu', NULL),
    ('TW', 'Taiwan, Province of China', NULL),
    ('TZ', 'Tanzania, United Republic of', NULL),
    ('UA', 'Ukraine', NULL),
    ('UG', 'Uganda', NULL),
    ('UM', 'United States Minor Outlying Islands', NULL),
    ('US', 'United States', NULL),
    ('UY', 'Uruguay', NULL),
    ('UZ', 'Uzbekistan', NULL),
    ('VA', 'Holy See (Vatican City State)', NULL),
    ('VC', 'Saint Vincent and the Grenadines', NULL),
    ('VE', 'Venezuela, Bolivarian Republic of', NULL),
    ('VG', 'Virgin Islands, British', NULL),
    ('VI', 'Virgin Islands, U.S.', NULL)
ON CONFLICT ("Code") DO NOTHING;
INSERT INTO public."CountryCodeValues" ("Code", "Name", "Definition") VALUES
    ('VN', 'Viet Nam', NULL),
    ('VU', 'Vanuatu', NULL),
    ('WF', 'Wallis and Futuna', NULL),
    ('WS', 'Samoa', NULL),
    ('YE', 'Yemen', NULL),
    ('YT', 'Mayotte', NULL),
    ('ZA', 'South Africa', NULL),
    ('ZM', 'Zambia', NULL),
    ('ZW', 'Zimbabwe', NULL)
ON CONFLICT ("Code") DO NOTHING;
-- Verification -- confirms seed data actually landed. If any of these
-- read 0, look upward in your client output for an ERROR line from one
-- of the INSERT batches above (a common cause: non-UTF8 client_encoding
-- choking on the accented country names noted above).
SELECT 'ActiveCurrencyCodeValues' AS "Table", count(*) AS "RowCount" FROM public."ActiveCurrencyCodeValues"
UNION ALL SELECT 'ActiveOrHistoricCurrencyCodeValues', count(*) FROM public."ActiveOrHistoricCurrencyCodeValues"
UNION ALL SELECT 'CountryCodeValues', count(*) FROM public."CountryCodeValues";
-- ---------------------------------------------------------------------
-- PART 2 -- 10.2.3 CodeSet: embedded value lists -> native ENUM
-- ---------------------------------------------------------------------
-- Type: AddressType2Code
DROP TYPE IF EXISTS public."AddressType2Code" CASCADE;
CREATE TYPE public."AddressType2Code" AS ENUM
    ('ADDR', 'PBOX', 'HOME', 'BIZZ', 'MLTO', 'DLVY');
ALTER TYPE public."AddressType2Code" OWNER TO postgres;
COMMENT ON TYPE public."AddressType2Code" IS
'Specifies the type of address.
CodeSet:
ADDR (Postal): Address is the complete postal address.
PBOX (POBox): Address is a postal office (PO) box.
HOME (Residential): Address is the home address.
BIZZ (Business): Address is the business address.
MLTO (MailTo): Address is the address to which mail is sent.
DLVY (DeliveryTo): Address is the address to which delivery is to take place.';
-- Type: Authorisation1Code
DROP TYPE IF EXISTS public."Authorisation1Code" CASCADE;
CREATE TYPE public."Authorisation1Code" AS ENUM
    ('AUTH', 'FDET', 'FSUM', 'ILEV');
ALTER TYPE public."Authorisation1Code" OWNER TO postgres;
COMMENT ON TYPE public."Authorisation1Code" IS
'Specifies the level of approval depending on a number of factors, including payment type, threshold amount or local country or operations practice.
CodeSet:
AUTH (PreAuthorisedFile): Indicates a file has been pre authorised or approved within the originating customer environment and no further approval is required.
FDET (FileLevelAuthorisationDetails): Indicates that a file requires additional file level approval, with the ability to view both the payment information block and supporting customer credit transaction detail.
FSUM (FileLevelAuthorisationSummary): Indicates that a file requires additional file level approval, with the ability to view only the payment information block level information.
ILEV (InstructionLevelAuthorisation): Indicates that a file requires all customer transactions to be authorised or approved.';
-- Type: ChargeBearerType1Code
DROP TYPE IF EXISTS public."ChargeBearerType1Code" CASCADE;
CREATE TYPE public."ChargeBearerType1Code" AS ENUM
    ('DEBT', 'CRED', 'SHAR', 'SLEV');
ALTER TYPE public."ChargeBearerType1Code" OWNER TO postgres;
COMMENT ON TYPE public."ChargeBearerType1Code" IS
'Specifies which party(ies) will pay charges due for processing of the instruction.
CodeSet:
DEBT (BorneByDebtor): All transaction charges are to be borne by the debtor.
CRED (BorneByCreditor): All transaction charges are to be borne by the creditor.
SHAR (Shared): In a credit transfer context, means that transaction charges on the sender side are to be borne by the debtor, transaction charges on the receiver side are to be borne by the creditor. In a direct debit context, means that transaction charges on the sender side are to be borne by the creditor, transaction charges on the receiver side are to be borne by the debtor.
SLEV (FollowingServiceLevel): Charges are to be applied following the rules agreed in the service level and/or scheme.';
-- Type: ClearingChannel2Code
DROP TYPE IF EXISTS public."ClearingChannel2Code" CASCADE;
CREATE TYPE public."ClearingChannel2Code" AS ENUM
    ('RTGS', 'RTNS', 'MPNS', 'BOOK');
ALTER TYPE public."ClearingChannel2Code" OWNER TO postgres;
COMMENT ON TYPE public."ClearingChannel2Code" IS
'Specifies the clearing channel for the routing of the transaction, as part of the payment type identification.
CodeSet:
RTGS (RealTimeGrossSettlementSystem): Clearing channel is a real-time gross settlement system.
RTNS (RealTimeNetSettlementSystem): Clearing channel is a real-time net settlement system.
MPNS (MassPaymentNetSystem): Clearing channel is a mass payment net settlement system.
BOOK (BookTransfer): Payment through internal book transfer.';
-- Type: CreditDebitCode
DROP TYPE IF EXISTS public."CreditDebitCode" CASCADE;
CREATE TYPE public."CreditDebitCode" AS ENUM
    ('CRDT', 'DBIT');
ALTER TYPE public."CreditDebitCode" OWNER TO postgres;
COMMENT ON TYPE public."CreditDebitCode" IS
'Specifies if an operation is an increase or a decrease.
CodeSet:
CRDT (Credit): Operation is an increase.
DBIT (Debit): Operation is a decrease.';
-- Type: Frequency6Code
DROP TYPE IF EXISTS public."Frequency6Code" CASCADE;
CREATE TYPE public."Frequency6Code" AS ENUM
    ('YEAR', 'MNTH', 'QURT', 'MIAN', 'WEEK', 'DAIL', 'ADHO', 'INDA', 'FRTN');
ALTER TYPE public."Frequency6Code" OWNER TO postgres;
COMMENT ON TYPE public."Frequency6Code" IS
'Specifies the regularity of an event.
CodeSet:
YEAR (Annual): Event takes place every year or once a year.
MNTH (Monthly): Event takes place every month or once a month.
QURT (Quarterly): Event takes place every three months or four times a year.
MIAN (SemiAnnual): Event takes place every six months or two times a year.
WEEK (Weekly): Event takes place once a week.
DAIL (Daily): Event takes place every day.
ADHO (Adhoc): Event takes place on request or as necessary.
INDA (IntraDay): Event takes place several times a day.
FRTN (Fortnightly): Event takes place every two weeks.';
-- Type: Instruction4Code
DROP TYPE IF EXISTS public."Instruction4Code" CASCADE;
CREATE TYPE public."Instruction4Code" AS ENUM
    ('PHOA', 'TELA');
ALTER TYPE public."Instruction4Code" OWNER TO postgres;
COMMENT ON TYPE public."Instruction4Code" IS
'Specifies further instructions concerning the processing of a payment instruction, provided by the sending clearing agent to the next agent(s).
CodeSet:
PHOA (PhoneNextAgent): Please advise/contact next agent by phone.
TELA (TelecomNextAgent): Please advise/contact next agent by the most efficient means of telecommunication.';
-- Type: MandateClassification1Code
DROP TYPE IF EXISTS public."MandateClassification1Code" CASCADE;
CREATE TYPE public."MandateClassification1Code" AS ENUM
    ('FIXE', 'USGB', 'VARI');
ALTER TYPE public."MandateClassification1Code" OWNER TO postgres;
COMMENT ON TYPE public."MandateClassification1Code" IS
'Specifies the type of direct debit amount, such as fixed or variable.
CodeSet:
FIXE (Fixed): Direct debit amount is fixed.
USGB (UsageBased): Direct debit amount is based on usage.
VARI (Variable): Direct debit amount is variable.';
-- Type: NamePrefix2Code
DROP TYPE IF EXISTS public."NamePrefix2Code" CASCADE;
CREATE TYPE public."NamePrefix2Code" AS ENUM
    ('DOCT', 'MADM', 'MISS', 'MIST', 'MIKS');
ALTER TYPE public."NamePrefix2Code" OWNER TO postgres;
COMMENT ON TYPE public."NamePrefix2Code" IS
'Specifies the terms used to formally address a person.
CodeSet:
DOCT (Doctor): Title of the person is Doctor or Dr.
MADM (Madam): Title of the person is Madam.
MISS (Miss): Title of the person is Miss.
MIST (Mister): Title of the person is Mister or Mr.
MIKS (GenderNeutral): Title of the person is gender neutral (Mx).';
-- Type: PaymentMethod4Code
DROP TYPE IF EXISTS public."PaymentMethod4Code" CASCADE;
CREATE TYPE public."PaymentMethod4Code" AS ENUM
    ('CHK', 'TRF', 'DD', 'TRA');
ALTER TYPE public."PaymentMethod4Code" OWNER TO postgres;
COMMENT ON TYPE public."PaymentMethod4Code" IS
'Specifies the transfer method that will be used to transfer an amount of money.
CodeSet:
CHK (Cheque): Written order to a bank to pay a certain amount of money from one person to another person.
TRF (CreditTransfer): Transfer of an amount of money in the books of the account servicer.
DD (DirectDebit): Collection of an amount of money from the debtor''s bank account by the creditor. The amount of money and dates of collections may vary.
TRA (TransferAdvice): Transfer of an amount of money in the books of the account servicer. An advice should be sent back to the account owner.';
-- Type: PreferredContactMethod2Code
DROP TYPE IF EXISTS public."PreferredContactMethod2Code" CASCADE;
CREATE TYPE public."PreferredContactMethod2Code" AS ENUM
    ('MAIL', 'FAXX', 'LETT', 'CELL', 'ONLI', 'PHON');
ALTER TYPE public."PreferredContactMethod2Code" OWNER TO postgres;
COMMENT ON TYPE public."PreferredContactMethod2Code" IS
'Preferred method used to reach the individual contact within an organisation.
CodeSet:
MAIL (Email): Preferred method used to reach the contact is per email.
FAXX (Fax): Preferred method used to reach the contact is per fax.
LETT (Letter): Preferred method used to reach the contact is per letter.
CELL (MobileOrCellPhone): Preferred method used to reach the contact is per mobile or cell phone.
ONLI (Online): Preferred method used to reach the contact is online.
PHON (Phone): Preferred method used to reach the contact is per phone.';
-- Type: Priority2Code
DROP TYPE IF EXISTS public."Priority2Code" CASCADE;
CREATE TYPE public."Priority2Code" AS ENUM
    ('HIGH', 'NORM');
ALTER TYPE public."Priority2Code" OWNER TO postgres;
COMMENT ON TYPE public."Priority2Code" IS
'Specifies the priority level of an event.
CodeSet:
HIGH (High): Priority level is high.
NORM (Normal): Priority level is normal.';
-- Type: Priority3Code
DROP TYPE IF EXISTS public."Priority3Code" CASCADE;
CREATE TYPE public."Priority3Code" AS ENUM
    ('URGT', 'HIGH', 'NORM');
ALTER TYPE public."Priority3Code" OWNER TO postgres;
COMMENT ON TYPE public."Priority3Code" IS
'Specifies the priority level of an event.
CodeSet:
URGT (Urgent): Priority level is urgent (highest priority possible).
HIGH (High): Priority level is high.
NORM (Normal): Priority level is normal.';
-- Type: RegulatoryReportingType1Code
DROP TYPE IF EXISTS public."RegulatoryReportingType1Code" CASCADE;
CREATE TYPE public."RegulatoryReportingType1Code" AS ENUM
    ('CRED', 'DEBT', 'BOTH');
ALTER TYPE public."RegulatoryReportingType1Code" OWNER TO postgres;
COMMENT ON TYPE public."RegulatoryReportingType1Code" IS
'Identifies whether the regulatory reporting information applies to the debit side, to the credit side or to both debit and credit sides of the transaction.
CodeSet:
CRED (Credit): Regulatory information applies to the credit side.
DEBT (Debit): Regulatory information applies to the debit side.
BOTH (Both): Regulatory information applies to both credit and debit sides.';
-- Type: RemittanceLocationMethod2Code
DROP TYPE IF EXISTS public."RemittanceLocationMethod2Code" CASCADE;
CREATE TYPE public."RemittanceLocationMethod2Code" AS ENUM
    ('FAXI', 'EDIC', 'URID', 'EMAL', 'POST', 'SMSM');
ALTER TYPE public."RemittanceLocationMethod2Code" OWNER TO postgres;
COMMENT ON TYPE public."RemittanceLocationMethod2Code" IS
'Specifies the method used to deliver the remittance advice information.
CodeSet:
FAXI (Fax): Remittance advice information must be faxed.
EDIC (ElectronicDataInterchange): Remittance advice information must be sent through Electronic Data Interchange (EDI).
URID (UniformResourceIdentifier): Remittance advice information needs to be sent to a Uniform Resource Identifier (URI). URI is a compact string of characters that uniquely identify an abstract or physical resource. URI''s are the super-set of identifiers, such as URLs, email addresses, ftp sites, etc, and as such, provide the syntax for all of the identification schemes.
EMAL (EMail): Remittance advice information must be sent through e-mail.
POST (Post): Remittance advice information must be sent through postal services.
SMSM (SMS): Remittance advice information must be sent through by phone as a short message service (SMS).';
-- Type: SequenceType3Code
DROP TYPE IF EXISTS public."SequenceType3Code" CASCADE;
CREATE TYPE public."SequenceType3Code" AS ENUM
    ('FRST', 'RCUR', 'FNAL', 'OOFF', 'RPRE');
ALTER TYPE public."SequenceType3Code" OWNER TO postgres;
COMMENT ON TYPE public."SequenceType3Code" IS
'Specifies the type of the current transaction that belongs to a sequence of transactions.
CodeSet:
FRST (First): First collection of a series of direct debit instructions.
RCUR (Recurring): Direct debit instruction where the debtor''s authorisation is used for regular direct debit transactions initiated by the creditor.
FNAL (Final): Final collection of a series of direct debit instructions.
OOFF (OneOff): Direct debit instruction where the debtor''s authorisation is used to initiate one single direct debit transaction.
RPRE (Represented): Collection used to re-present previously reversed or returned direct debit transactions.';
-- Type: SettlementMethod1Code
DROP TYPE IF EXISTS public."SettlementMethod1Code" CASCADE;
CREATE TYPE public."SettlementMethod1Code" AS ENUM
    ('INDA', 'INGA', 'COVE', 'CLRG');
ALTER TYPE public."SettlementMethod1Code" OWNER TO postgres;
COMMENT ON TYPE public."SettlementMethod1Code" IS
'Specifies the method used to settle the credit transfer instruction.
CodeSet:
INDA (InstructedAgent): Settlement is done by the agent instructed to execute a payment instruction.
INGA (InstructingAgent): Settlement is done by the agent instructing and forwarding the payment to the next party in the payment chain.
COVE (CoverMethod): Settlement is done through a cover payment.
CLRG (ClearingSystem): Settlement is done through a payment clearing system.';
-- Type: SettlementMethod2Code
DROP TYPE IF EXISTS public."SettlementMethod2Code" CASCADE;
CREATE TYPE public."SettlementMethod2Code" AS ENUM
    ('INDA', 'INGA', 'CLRG');
ALTER TYPE public."SettlementMethod2Code" OWNER TO postgres;
COMMENT ON TYPE public."SettlementMethod2Code" IS
'Specifies the method used to settle the credit transfer instruction.
CodeSet:
INDA (InstructedAgent): Settlement is done by the agent instructed to execute a payment instruction.
INGA (InstructingAgent): Settlement is done by the agent instructing and forwarding the payment to the next party in the payment chain.
CLRG (ClearingSystem): Settlement is done through a payment clearing system.';
-- Type: TaxRecordPeriod1Code
DROP TYPE IF EXISTS public."TaxRecordPeriod1Code" CASCADE;
CREATE TYPE public."TaxRecordPeriod1Code" AS ENUM
    ('MM01', 'MM02', 'MM03', 'MM04', 'MM05', 'MM06', 'MM07', 'MM08', 'MM09', 'MM10', 'MM11', 'MM12', 'QTR1', 'QTR2', 'QTR3', 'QTR4', 'HLF1', 'HLF2');
ALTER TYPE public."TaxRecordPeriod1Code" OWNER TO postgres;
COMMENT ON TYPE public."TaxRecordPeriod1Code" IS
'Specifies the period related to the tax payment.
CodeSet:
MM01 (FirstMonth): Tax is related to the first month of the period.
MM02 (SecondMonth): Tax is related to the second month of the period.
MM03 (ThirdMonth): Tax is related to the third month of the period.
MM04 (FourthMonth): Tax is related to the fourth month of the period.
MM05 (FifthMonth): Tax is related to the fifth month of the period.
MM06 (SixthMonth): Tax is related to the sixth month of the period.
MM07 (SeventhMonth): Tax is related to the seventh month of the period.
MM08 (EighthMonth): Tax is related to the eighth month of the period.
MM09 (NinthMonth): Tax is related to the ninth month of the period.
MM10 (TenthMonth): Tax is related to the tenth month of the period.
MM11 (EleventhMonth): Tax is related to the eleventh month of the period.
MM12 (TwelfthMonth): Tax is related to the twelfth month of the period.
QTR1 (FirstQuarter): Tax is related to the first quarter of the period.
QTR2 (SecondQuarter): Tax is related to the second quarter of the period.
QTR3 (ThirdQuarter): Tax is related to the third quarter of the period.
QTR4 (FourthQuarter): Tax is related to the fourth quarter of the period.
HLF1 (FirstHalf): Tax is related to the first half of the period.
HLF2 (SecondHalf): Tax is related to the second half of the period.';
-- ---------------------------------------------------------------------
-- PART 3 -- 10.2.3 CodeSet: External*Code -> domain + lookup table scaffold
-- Values are maintained by ISO 20022, not embedded in the MDR. Populate
-- each "<Name>Values" table from https://www.iso20022.org external code
-- list downloads, then FK downstream columns to it for strict validation.
-- ---------------------------------------------------------------------
-- Domain: ExternalAccountIdentification1Code
DROP DOMAIN IF EXISTS public."ExternalAccountIdentification1Code" CASCADE;
CREATE DOMAIN public."ExternalAccountIdentification1Code" AS varchar(4)
    CHECK (char_length(VALUE) >= 1);
ALTER DOMAIN public."ExternalAccountIdentification1Code" OWNER TO postgres;
COMMENT ON DOMAIN public."ExternalAccountIdentification1Code" IS
'Specifies the external account identification scheme name code in the format of character string with a maximum length of 4 characters. The list of valid codes is an external code list published separately.

Format: minLength 1, maxLength 4.

Note: values are maintained externally by ISO 20022, not embedded in the MDR. This domain enforces LENGTH ONLY. Download the current list from https://www.iso20022.org and populate public."ExternalAccountIdentification1CodeValues" below; reference that table via FK from consuming columns for authoritative validation.';
-- Table: ExternalAccountIdentification1CodeValues
DROP TABLE IF EXISTS public."ExternalAccountIdentification1CodeValues" CASCADE;
CREATE TABLE public."ExternalAccountIdentification1CodeValues" (
    "Code" public."ExternalAccountIdentification1Code" PRIMARY KEY,
    "Name" text NOT NULL,
    "Definition" text,
    "Status" text,
    "LastUpdate" date,
    "CreationDate" date,
    "ReplacedBy" text,
    "AdditionalInformation" text
);
ALTER TABLE public."ExternalAccountIdentification1CodeValues" OWNER TO postgres;
COMMENT ON TABLE public."ExternalAccountIdentification1CodeValues" IS
'Lookup for the ExternalAccountIdentification1Code external code list, sourced from the official ISO 20022 External Code Sets registry (https://www.iso20022.org, quarterly XLSX publication). "Status" is the registry''s own field (''Registered'' or ''Obsolete''), not a derived flag. "ReplacedBy" is free text (the successor code), not FK-constrained, since a successor can be a code retired from an earlier quarter''s list.';
-- Domain: ExternalCashAccountType1Code
DROP DOMAIN IF EXISTS public."ExternalCashAccountType1Code" CASCADE;
CREATE DOMAIN public."ExternalCashAccountType1Code" AS varchar(4)
    CHECK (char_length(VALUE) >= 1);
ALTER DOMAIN public."ExternalCashAccountType1Code" OWNER TO postgres;
COMMENT ON DOMAIN public."ExternalCashAccountType1Code" IS
'Specifies the nature, or use, of the cash account in the format of character string with a maximum length of 4 characters. The list of valid codes is an external code list published separately.

Format: minLength 1, maxLength 4.

Note: values are maintained externally by ISO 20022, not embedded in the MDR. This domain enforces LENGTH ONLY. Download the current list from https://www.iso20022.org and populate public."ExternalCashAccountType1CodeValues" below; reference that table via FK from consuming columns for authoritative validation.';
-- Table: ExternalCashAccountType1CodeValues
DROP TABLE IF EXISTS public."ExternalCashAccountType1CodeValues" CASCADE;
CREATE TABLE public."ExternalCashAccountType1CodeValues" (
    "Code" public."ExternalCashAccountType1Code" PRIMARY KEY,
    "Name" text NOT NULL,
    "Definition" text,
    "Status" text,
    "LastUpdate" date,
    "CreationDate" date,
    "ReplacedBy" text,
    "AdditionalInformation" text
);
ALTER TABLE public."ExternalCashAccountType1CodeValues" OWNER TO postgres;
COMMENT ON TABLE public."ExternalCashAccountType1CodeValues" IS
'Lookup for the ExternalCashAccountType1Code external code list, sourced from the official ISO 20022 External Code Sets registry (https://www.iso20022.org, quarterly XLSX publication). "Status" is the registry''s own field (''Registered'' or ''Obsolete''), not a derived flag. "ReplacedBy" is free text (the successor code), not FK-constrained, since a successor can be a code retired from an earlier quarter''s list.';
-- Domain: ExternalCashClearingSystem1Code
DROP DOMAIN IF EXISTS public."ExternalCashClearingSystem1Code" CASCADE;
CREATE DOMAIN public."ExternalCashClearingSystem1Code" AS varchar(3)
    CHECK (char_length(VALUE) >= 1);
ALTER DOMAIN public."ExternalCashClearingSystem1Code" OWNER TO postgres;
COMMENT ON DOMAIN public."ExternalCashClearingSystem1Code" IS
'Specifies the cash clearing system, as published in an external cash clearing system code list.

Format: minLength 1, maxLength 3.

Note: values are maintained externally by ISO 20022, not embedded in the MDR. This domain enforces LENGTH ONLY. Download the current list from https://www.iso20022.org and populate public."ExternalCashClearingSystem1CodeValues" below; reference that table via FK from consuming columns for authoritative validation.';
-- Table: ExternalCashClearingSystem1CodeValues
DROP TABLE IF EXISTS public."ExternalCashClearingSystem1CodeValues" CASCADE;
CREATE TABLE public."ExternalCashClearingSystem1CodeValues" (
    "Code" public."ExternalCashClearingSystem1Code" PRIMARY KEY,
    "Name" text NOT NULL,
    "Definition" text,
    "Status" text,
    "LastUpdate" date,
    "CreationDate" date,
    "ReplacedBy" text,
    "AdditionalInformation" text
);
ALTER TABLE public."ExternalCashClearingSystem1CodeValues" OWNER TO postgres;
COMMENT ON TABLE public."ExternalCashClearingSystem1CodeValues" IS
'Lookup for the ExternalCashClearingSystem1Code external code list, sourced from the official ISO 20022 External Code Sets registry (https://www.iso20022.org, quarterly XLSX publication). "Status" is the registry''s own field (''Registered'' or ''Obsolete''), not a derived flag. "ReplacedBy" is free text (the successor code), not FK-constrained, since a successor can be a code retired from an earlier quarter''s list.';
-- Domain: ExternalCategoryPurpose1Code
DROP DOMAIN IF EXISTS public."ExternalCategoryPurpose1Code" CASCADE;
CREATE DOMAIN public."ExternalCategoryPurpose1Code" AS varchar(4)
    CHECK (char_length(VALUE) >= 1);
ALTER DOMAIN public."ExternalCategoryPurpose1Code" OWNER TO postgres;
COMMENT ON DOMAIN public."ExternalCategoryPurpose1Code" IS
'Specifies the category purpose, as published in an external category purpose code list.

Format: minLength 1, maxLength 4.

Note: values are maintained externally by ISO 20022, not embedded in the MDR. This domain enforces LENGTH ONLY. Download the current list from https://www.iso20022.org and populate public."ExternalCategoryPurpose1CodeValues" below; reference that table via FK from consuming columns for authoritative validation.';
-- Table: ExternalCategoryPurpose1CodeValues
DROP TABLE IF EXISTS public."ExternalCategoryPurpose1CodeValues" CASCADE;
CREATE TABLE public."ExternalCategoryPurpose1CodeValues" (
    "Code" public."ExternalCategoryPurpose1Code" PRIMARY KEY,
    "Name" text NOT NULL,
    "Definition" text,
    "Status" text,
    "LastUpdate" date,
    "CreationDate" date,
    "ReplacedBy" text,
    "AdditionalInformation" text
);
ALTER TABLE public."ExternalCategoryPurpose1CodeValues" OWNER TO postgres;
COMMENT ON TABLE public."ExternalCategoryPurpose1CodeValues" IS
'Lookup for the ExternalCategoryPurpose1Code external code list, sourced from the official ISO 20022 External Code Sets registry (https://www.iso20022.org, quarterly XLSX publication). "Status" is the registry''s own field (''Registered'' or ''Obsolete''), not a derived flag. "ReplacedBy" is free text (the successor code), not FK-constrained, since a successor can be a code retired from an earlier quarter''s list.';
-- Domain: ExternalChargeType1Code
DROP DOMAIN IF EXISTS public."ExternalChargeType1Code" CASCADE;
CREATE DOMAIN public."ExternalChargeType1Code" AS varchar(4)
    CHECK (char_length(VALUE) >= 1);
ALTER DOMAIN public."ExternalChargeType1Code" OWNER TO postgres;
COMMENT ON DOMAIN public."ExternalChargeType1Code" IS
'Specifies the nature, or use, of the charges in the format of character string with a maximum length of 4 characters. The list of valid codes is an external code list published separately.

Format: minLength 1, maxLength 4.

Note: values are maintained externally by ISO 20022, not embedded in the MDR. This domain enforces LENGTH ONLY. Download the current list from https://www.iso20022.org and populate public."ExternalChargeType1CodeValues" below; reference that table via FK from consuming columns for authoritative validation.';
-- Table: ExternalChargeType1CodeValues
DROP TABLE IF EXISTS public."ExternalChargeType1CodeValues" CASCADE;
CREATE TABLE public."ExternalChargeType1CodeValues" (
    "Code" public."ExternalChargeType1Code" PRIMARY KEY,
    "Name" text NOT NULL,
    "Definition" text,
    "Status" text,
    "LastUpdate" date,
    "CreationDate" date,
    "ReplacedBy" text,
    "AdditionalInformation" text
);
ALTER TABLE public."ExternalChargeType1CodeValues" OWNER TO postgres;
COMMENT ON TABLE public."ExternalChargeType1CodeValues" IS
'Lookup for the ExternalChargeType1Code external code list, sourced from the official ISO 20022 External Code Sets registry (https://www.iso20022.org, quarterly XLSX publication). "Status" is the registry''s own field (''Registered'' or ''Obsolete''), not a derived flag. "ReplacedBy" is free text (the successor code), not FK-constrained, since a successor can be a code retired from an earlier quarter''s list.';
-- Domain: ExternalClearingSystemIdentification1Code
DROP DOMAIN IF EXISTS public."ExternalClearingSystemIdentification1Code" CASCADE;
CREATE DOMAIN public."ExternalClearingSystemIdentification1Code" AS varchar(5)
    CHECK (char_length(VALUE) >= 1);
ALTER DOMAIN public."ExternalClearingSystemIdentification1Code" OWNER TO postgres;
COMMENT ON DOMAIN public."ExternalClearingSystemIdentification1Code" IS
'Specifies the clearing system identification code, as published in an external clearing system identification code list.

Format: minLength 1, maxLength 5.

Note: values are maintained externally by ISO 20022, not embedded in the MDR. This domain enforces LENGTH ONLY. Download the current list from https://www.iso20022.org and populate public."ExternalClearingSystemIdentification1CodeValues" below; reference that table via FK from consuming columns for authoritative validation.';
-- Table: ExternalClearingSystemIdentification1CodeValues
DROP TABLE IF EXISTS public."ExternalClearingSystemIdentification1CodeValues" CASCADE;
CREATE TABLE public."ExternalClearingSystemIdentification1CodeValues" (
    "Code" public."ExternalClearingSystemIdentification1Code" PRIMARY KEY,
    "Name" text NOT NULL,
    "Definition" text,
    "Status" text,
    "LastUpdate" date,
    "CreationDate" date,
    "ReplacedBy" text,
    "AdditionalInformation" text
);
ALTER TABLE public."ExternalClearingSystemIdentification1CodeValues" OWNER TO postgres;
COMMENT ON TABLE public."ExternalClearingSystemIdentification1CodeValues" IS
'Lookup for the ExternalClearingSystemIdentification1Code external code list, sourced from the official ISO 20022 External Code Sets registry (https://www.iso20022.org, quarterly XLSX publication). "Status" is the registry''s own field (''Registered'' or ''Obsolete''), not a derived flag. "ReplacedBy" is free text (the successor code), not FK-constrained, since a successor can be a code retired from an earlier quarter''s list.';
-- Domain: ExternalCreditorAgentInstruction1Code
DROP DOMAIN IF EXISTS public."ExternalCreditorAgentInstruction1Code" CASCADE;
CREATE DOMAIN public."ExternalCreditorAgentInstruction1Code" AS varchar(4)
    CHECK (char_length(VALUE) >= 1);
ALTER DOMAIN public."ExternalCreditorAgentInstruction1Code" OWNER TO postgres;
COMMENT ON DOMAIN public."ExternalCreditorAgentInstruction1Code" IS
'Specifies further instructions concerning the processing of a payment instruction, as provided to the creditor agent.

Format: minLength 1, maxLength 4.

Note: values are maintained externally by ISO 20022, not embedded in the MDR. This domain enforces LENGTH ONLY. Download the current list from https://www.iso20022.org and populate public."ExternalCreditorAgentInstruction1CodeValues" below; reference that table via FK from consuming columns for authoritative validation.';
-- Table: ExternalCreditorAgentInstruction1CodeValues
DROP TABLE IF EXISTS public."ExternalCreditorAgentInstruction1CodeValues" CASCADE;
CREATE TABLE public."ExternalCreditorAgentInstruction1CodeValues" (
    "Code" public."ExternalCreditorAgentInstruction1Code" PRIMARY KEY,
    "Name" text NOT NULL,
    "Definition" text,
    "Status" text,
    "LastUpdate" date,
    "CreationDate" date,
    "ReplacedBy" text,
    "AdditionalInformation" text
);
ALTER TABLE public."ExternalCreditorAgentInstruction1CodeValues" OWNER TO postgres;
COMMENT ON TABLE public."ExternalCreditorAgentInstruction1CodeValues" IS
'Lookup for the ExternalCreditorAgentInstruction1Code external code list, sourced from the official ISO 20022 External Code Sets registry (https://www.iso20022.org, quarterly XLSX publication). "Status" is the registry''s own field (''Registered'' or ''Obsolete''), not a derived flag. "ReplacedBy" is free text (the successor code), not FK-constrained, since a successor can be a code retired from an earlier quarter''s list.';
-- Domain: ExternalCreditorReferenceType1Code
DROP DOMAIN IF EXISTS public."ExternalCreditorReferenceType1Code" CASCADE;
CREATE DOMAIN public."ExternalCreditorReferenceType1Code" AS varchar(4)
    CHECK (char_length(VALUE) >= 1);
ALTER DOMAIN public."ExternalCreditorReferenceType1Code" OWNER TO postgres;
COMMENT ON DOMAIN public."ExternalCreditorReferenceType1Code" IS
'Specifies the type of creditor reference as published in an external creditor reference type code set.

Format: minLength 1, maxLength 4.

Note: values are maintained externally by ISO 20022, not embedded in the MDR. This domain enforces LENGTH ONLY. Download the current list from https://www.iso20022.org and populate public."ExternalCreditorReferenceType1CodeValues" below; reference that table via FK from consuming columns for authoritative validation.';
-- Table: ExternalCreditorReferenceType1CodeValues
DROP TABLE IF EXISTS public."ExternalCreditorReferenceType1CodeValues" CASCADE;
CREATE TABLE public."ExternalCreditorReferenceType1CodeValues" (
    "Code" public."ExternalCreditorReferenceType1Code" PRIMARY KEY,
    "Name" text NOT NULL,
    "Definition" text,
    "Status" text,
    "LastUpdate" date,
    "CreationDate" date,
    "ReplacedBy" text,
    "AdditionalInformation" text
);
ALTER TABLE public."ExternalCreditorReferenceType1CodeValues" OWNER TO postgres;
COMMENT ON TABLE public."ExternalCreditorReferenceType1CodeValues" IS
'Lookup for the ExternalCreditorReferenceType1Code external code list, sourced from the official ISO 20022 External Code Sets registry (https://www.iso20022.org, quarterly XLSX publication). "Status" is the registry''s own field (''Registered'' or ''Obsolete''), not a derived flag. "ReplacedBy" is free text (the successor code), not FK-constrained, since a successor can be a code retired from an earlier quarter''s list.';
-- Domain: ExternalDateType1Code
DROP DOMAIN IF EXISTS public."ExternalDateType1Code" CASCADE;
CREATE DOMAIN public."ExternalDateType1Code" AS varchar(4)
    CHECK (char_length(VALUE) >= 1);
ALTER DOMAIN public."ExternalDateType1Code" OWNER TO postgres;
COMMENT ON DOMAIN public."ExternalDateType1Code" IS
'Defines the type of date, as published in an external date type code list.

Format: minLength 1, maxLength 4.

Note: values are maintained externally by ISO 20022, not embedded in the MDR. This domain enforces LENGTH ONLY. Download the current list from https://www.iso20022.org and populate public."ExternalDateType1CodeValues" below; reference that table via FK from consuming columns for authoritative validation.';
-- Table: ExternalDateType1CodeValues
DROP TABLE IF EXISTS public."ExternalDateType1CodeValues" CASCADE;
CREATE TABLE public."ExternalDateType1CodeValues" (
    "Code" public."ExternalDateType1Code" PRIMARY KEY,
    "Name" text NOT NULL,
    "Definition" text,
    "Status" text,
    "LastUpdate" date,
    "CreationDate" date,
    "ReplacedBy" text,
    "AdditionalInformation" text
);
ALTER TABLE public."ExternalDateType1CodeValues" OWNER TO postgres;
COMMENT ON TABLE public."ExternalDateType1CodeValues" IS
'Lookup for the ExternalDateType1Code external code list, sourced from the official ISO 20022 External Code Sets registry (https://www.iso20022.org, quarterly XLSX publication). "Status" is the registry''s own field (''Registered'' or ''Obsolete''), not a derived flag. "ReplacedBy" is free text (the successor code), not FK-constrained, since a successor can be a code retired from an earlier quarter''s list.';
-- Domain: ExternalDocumentAmountType1Code
DROP DOMAIN IF EXISTS public."ExternalDocumentAmountType1Code" CASCADE;
CREATE DOMAIN public."ExternalDocumentAmountType1Code" AS varchar(4)
    CHECK (char_length(VALUE) >= 1);
ALTER DOMAIN public."ExternalDocumentAmountType1Code" OWNER TO postgres;
COMMENT ON DOMAIN public."ExternalDocumentAmountType1Code" IS
'Specifies the nature, or use, of the amount, as published in an external document amount type code set.

Format: minLength 1, maxLength 4.

Note: values are maintained externally by ISO 20022, not embedded in the MDR. This domain enforces LENGTH ONLY. Download the current list from https://www.iso20022.org and populate public."ExternalDocumentAmountType1CodeValues" below; reference that table via FK from consuming columns for authoritative validation.';
-- Table: ExternalDocumentAmountType1CodeValues
DROP TABLE IF EXISTS public."ExternalDocumentAmountType1CodeValues" CASCADE;
CREATE TABLE public."ExternalDocumentAmountType1CodeValues" (
    "Code" public."ExternalDocumentAmountType1Code" PRIMARY KEY,
    "Name" text NOT NULL,
    "Definition" text,
    "Status" text,
    "LastUpdate" date,
    "CreationDate" date,
    "ReplacedBy" text,
    "AdditionalInformation" text
);
ALTER TABLE public."ExternalDocumentAmountType1CodeValues" OWNER TO postgres;
COMMENT ON TABLE public."ExternalDocumentAmountType1CodeValues" IS
'Lookup for the ExternalDocumentAmountType1Code external code list, sourced from the official ISO 20022 External Code Sets registry (https://www.iso20022.org, quarterly XLSX publication). "Status" is the registry''s own field (''Registered'' or ''Obsolete''), not a derived flag. "ReplacedBy" is free text (the successor code), not FK-constrained, since a successor can be a code retired from an earlier quarter''s list.';
-- Domain: ExternalDocumentLineType1Code
DROP DOMAIN IF EXISTS public."ExternalDocumentLineType1Code" CASCADE;
CREATE DOMAIN public."ExternalDocumentLineType1Code" AS varchar(4)
    CHECK (char_length(VALUE) >= 1);
ALTER DOMAIN public."ExternalDocumentLineType1Code" OWNER TO postgres;
COMMENT ON DOMAIN public."ExternalDocumentLineType1Code" IS
'Specifies the document line type as published in an external document type code list.

Format: minLength 1, maxLength 4.

Note: values are maintained externally by ISO 20022, not embedded in the MDR. This domain enforces LENGTH ONLY. Download the current list from https://www.iso20022.org and populate public."ExternalDocumentLineType1CodeValues" below; reference that table via FK from consuming columns for authoritative validation.';
-- Table: ExternalDocumentLineType1CodeValues
DROP TABLE IF EXISTS public."ExternalDocumentLineType1CodeValues" CASCADE;
CREATE TABLE public."ExternalDocumentLineType1CodeValues" (
    "Code" public."ExternalDocumentLineType1Code" PRIMARY KEY,
    "Name" text NOT NULL,
    "Definition" text,
    "Status" text,
    "LastUpdate" date,
    "CreationDate" date,
    "ReplacedBy" text,
    "AdditionalInformation" text
);
ALTER TABLE public."ExternalDocumentLineType1CodeValues" OWNER TO postgres;
COMMENT ON TABLE public."ExternalDocumentLineType1CodeValues" IS
'Lookup for the ExternalDocumentLineType1Code external code list, sourced from the official ISO 20022 External Code Sets registry (https://www.iso20022.org, quarterly XLSX publication). "Status" is the registry''s own field (''Registered'' or ''Obsolete''), not a derived flag. "ReplacedBy" is free text (the successor code), not FK-constrained, since a successor can be a code retired from an earlier quarter''s list.';
-- Domain: ExternalDocumentType1Code
DROP DOMAIN IF EXISTS public."ExternalDocumentType1Code" CASCADE;
CREATE DOMAIN public."ExternalDocumentType1Code" AS varchar(4)
    CHECK (char_length(VALUE) >= 1);
ALTER DOMAIN public."ExternalDocumentType1Code" OWNER TO postgres;
COMMENT ON DOMAIN public."ExternalDocumentType1Code" IS
'Specifies the document type as published in an external document type code list.

Format: minLength 1, maxLength 4.

Note: values are maintained externally by ISO 20022, not embedded in the MDR. This domain enforces LENGTH ONLY. Download the current list from https://www.iso20022.org and populate public."ExternalDocumentType1CodeValues" below; reference that table via FK from consuming columns for authoritative validation.';
-- Table: ExternalDocumentType1CodeValues
DROP TABLE IF EXISTS public."ExternalDocumentType1CodeValues" CASCADE;
CREATE TABLE public."ExternalDocumentType1CodeValues" (
    "Code" public."ExternalDocumentType1Code" PRIMARY KEY,
    "Name" text NOT NULL,
    "Definition" text,
    "Status" text,
    "LastUpdate" date,
    "CreationDate" date,
    "ReplacedBy" text,
    "AdditionalInformation" text
);
ALTER TABLE public."ExternalDocumentType1CodeValues" OWNER TO postgres;
COMMENT ON TABLE public."ExternalDocumentType1CodeValues" IS
'Lookup for the ExternalDocumentType1Code external code list, sourced from the official ISO 20022 External Code Sets registry (https://www.iso20022.org, quarterly XLSX publication). "Status" is the registry''s own field (''Registered'' or ''Obsolete''), not a derived flag. "ReplacedBy" is free text (the successor code), not FK-constrained, since a successor can be a code retired from an earlier quarter''s list.';
-- Domain: ExternalFinancialInstitutionIdentification1Code
DROP DOMAIN IF EXISTS public."ExternalFinancialInstitutionIdentification1Code" CASCADE;
CREATE DOMAIN public."ExternalFinancialInstitutionIdentification1Code" AS varchar(4)
    CHECK (char_length(VALUE) >= 1);
ALTER DOMAIN public."ExternalFinancialInstitutionIdentification1Code" OWNER TO postgres;
COMMENT ON DOMAIN public."ExternalFinancialInstitutionIdentification1Code" IS
'Specifies the external financial institution identification scheme name code in the format of character string with a maximum length of 4 characters. The list of valid codes is an external code list published separately.

Format: minLength 1, maxLength 4.

Note: values are maintained externally by ISO 20022, not embedded in the MDR. This domain enforces LENGTH ONLY. Download the current list from https://www.iso20022.org and populate public."ExternalFinancialInstitutionIdentification1CodeValues" below; reference that table via FK from consuming columns for authoritative validation.';
-- Table: ExternalFinancialInstitutionIdentification1CodeValues
DROP TABLE IF EXISTS public."ExternalFinancialInstitutionIdentification1CodeValues" CASCADE;
CREATE TABLE public."ExternalFinancialInstitutionIdentification1CodeValues" (
    "Code" public."ExternalFinancialInstitutionIdentification1Code" PRIMARY KEY,
    "Name" text NOT NULL,
    "Definition" text,
    "Status" text,
    "LastUpdate" date,
    "CreationDate" date,
    "ReplacedBy" text,
    "AdditionalInformation" text
);
ALTER TABLE public."ExternalFinancialInstitutionIdentification1CodeValues" OWNER TO postgres;
COMMENT ON TABLE public."ExternalFinancialInstitutionIdentification1CodeValues" IS
'Lookup for the ExternalFinancialInstitutionIdentification1Code external code list, sourced from the official ISO 20022 External Code Sets registry (https://www.iso20022.org, quarterly XLSX publication). "Status" is the registry''s own field (''Registered'' or ''Obsolete''), not a derived flag. "ReplacedBy" is free text (the successor code), not FK-constrained, since a successor can be a code retired from an earlier quarter''s list.';
-- Domain: ExternalGarnishmentType1Code
DROP DOMAIN IF EXISTS public."ExternalGarnishmentType1Code" CASCADE;
CREATE DOMAIN public."ExternalGarnishmentType1Code" AS varchar(4)
    CHECK (char_length(VALUE) >= 1);
ALTER DOMAIN public."ExternalGarnishmentType1Code" OWNER TO postgres;
COMMENT ON DOMAIN public."ExternalGarnishmentType1Code" IS
'Specifies the garnishment type as published in an external document type code list.

Format: minLength 1, maxLength 4.

Note: values are maintained externally by ISO 20022, not embedded in the MDR. This domain enforces LENGTH ONLY. Download the current list from https://www.iso20022.org and populate public."ExternalGarnishmentType1CodeValues" below; reference that table via FK from consuming columns for authoritative validation.';
-- Table: ExternalGarnishmentType1CodeValues
DROP TABLE IF EXISTS public."ExternalGarnishmentType1CodeValues" CASCADE;
CREATE TABLE public."ExternalGarnishmentType1CodeValues" (
    "Code" public."ExternalGarnishmentType1Code" PRIMARY KEY,
    "Name" text NOT NULL,
    "Definition" text,
    "Status" text,
    "LastUpdate" date,
    "CreationDate" date,
    "ReplacedBy" text,
    "AdditionalInformation" text
);
ALTER TABLE public."ExternalGarnishmentType1CodeValues" OWNER TO postgres;
COMMENT ON TABLE public."ExternalGarnishmentType1CodeValues" IS
'Lookup for the ExternalGarnishmentType1Code external code list, sourced from the official ISO 20022 External Code Sets registry (https://www.iso20022.org, quarterly XLSX publication). "Status" is the registry''s own field (''Registered'' or ''Obsolete''), not a derived flag. "ReplacedBy" is free text (the successor code), not FK-constrained, since a successor can be a code retired from an earlier quarter''s list.';
-- Domain: ExternalLocalInstrument1Code
DROP DOMAIN IF EXISTS public."ExternalLocalInstrument1Code" CASCADE;
CREATE DOMAIN public."ExternalLocalInstrument1Code" AS varchar(35)
    CHECK (char_length(VALUE) >= 1);
ALTER DOMAIN public."ExternalLocalInstrument1Code" OWNER TO postgres;
COMMENT ON DOMAIN public."ExternalLocalInstrument1Code" IS
'Specifies the external local instrument code in the format of character string with a maximum length of 35 characters. The list of valid codes is an external code list published separately.

Format: minLength 1, maxLength 35.

Note: values are maintained externally by ISO 20022, not embedded in the MDR. This domain enforces LENGTH ONLY. Download the current list from https://www.iso20022.org and populate public."ExternalLocalInstrument1CodeValues" below; reference that table via FK from consuming columns for authoritative validation.';
-- Table: ExternalLocalInstrument1CodeValues
DROP TABLE IF EXISTS public."ExternalLocalInstrument1CodeValues" CASCADE;
CREATE TABLE public."ExternalLocalInstrument1CodeValues" (
    "Code" public."ExternalLocalInstrument1Code" PRIMARY KEY,
    "Name" text NOT NULL,
    "Definition" text,
    "Status" text,
    "LastUpdate" date,
    "CreationDate" date,
    "ReplacedBy" text,
    "AdditionalInformation" text
);
ALTER TABLE public."ExternalLocalInstrument1CodeValues" OWNER TO postgres;
COMMENT ON TABLE public."ExternalLocalInstrument1CodeValues" IS
'Lookup for the ExternalLocalInstrument1Code external code list, sourced from the official ISO 20022 External Code Sets registry (https://www.iso20022.org, quarterly XLSX publication). "Status" is the registry''s own field (''Registered'' or ''Obsolete''), not a derived flag. "ReplacedBy" is free text (the successor code), not FK-constrained, since a successor can be a code retired from an earlier quarter''s list.';
-- Domain: ExternalMandateSetupReason1Code
DROP DOMAIN IF EXISTS public."ExternalMandateSetupReason1Code" CASCADE;
CREATE DOMAIN public."ExternalMandateSetupReason1Code" AS varchar(4)
    CHECK (char_length(VALUE) >= 1);
ALTER DOMAIN public."ExternalMandateSetupReason1Code" OWNER TO postgres;
COMMENT ON DOMAIN public."ExternalMandateSetupReason1Code" IS
'Specifies the external mandate setup reason code in the format of character string with a maximum length of 4 characters.

Format: minLength 1, maxLength 4.

Note: values are maintained externally by ISO 20022, not embedded in the MDR. This domain enforces LENGTH ONLY. Download the current list from https://www.iso20022.org and populate public."ExternalMandateSetupReason1CodeValues" below; reference that table via FK from consuming columns for authoritative validation.';
-- Table: ExternalMandateSetupReason1CodeValues
DROP TABLE IF EXISTS public."ExternalMandateSetupReason1CodeValues" CASCADE;
CREATE TABLE public."ExternalMandateSetupReason1CodeValues" (
    "Code" public."ExternalMandateSetupReason1Code" PRIMARY KEY,
    "Name" text NOT NULL,
    "Definition" text,
    "Status" text,
    "LastUpdate" date,
    "CreationDate" date,
    "ReplacedBy" text,
    "AdditionalInformation" text
);
ALTER TABLE public."ExternalMandateSetupReason1CodeValues" OWNER TO postgres;
COMMENT ON TABLE public."ExternalMandateSetupReason1CodeValues" IS
'Lookup for the ExternalMandateSetupReason1Code external code list, sourced from the official ISO 20022 External Code Sets registry (https://www.iso20022.org, quarterly XLSX publication). "Status" is the registry''s own field (''Registered'' or ''Obsolete''), not a derived flag. "ReplacedBy" is free text (the successor code), not FK-constrained, since a successor can be a code retired from an earlier quarter''s list.';
-- Domain: ExternalOrganisationIdentification1Code
DROP DOMAIN IF EXISTS public."ExternalOrganisationIdentification1Code" CASCADE;
CREATE DOMAIN public."ExternalOrganisationIdentification1Code" AS varchar(4)
    CHECK (char_length(VALUE) >= 1);
ALTER DOMAIN public."ExternalOrganisationIdentification1Code" OWNER TO postgres;
COMMENT ON DOMAIN public."ExternalOrganisationIdentification1Code" IS
'Specifies the external organisation identification scheme name code in the format of character string with a maximum length of 4 characters. The list of valid codes is an external code list published separately.

Format: minLength 1, maxLength 4.

Note: values are maintained externally by ISO 20022, not embedded in the MDR. This domain enforces LENGTH ONLY. Download the current list from https://www.iso20022.org and populate public."ExternalOrganisationIdentification1CodeValues" below; reference that table via FK from consuming columns for authoritative validation.';
-- Table: ExternalOrganisationIdentification1CodeValues
DROP TABLE IF EXISTS public."ExternalOrganisationIdentification1CodeValues" CASCADE;
CREATE TABLE public."ExternalOrganisationIdentification1CodeValues" (
    "Code" public."ExternalOrganisationIdentification1Code" PRIMARY KEY,
    "Name" text NOT NULL,
    "Definition" text,
    "Status" text,
    "LastUpdate" date,
    "CreationDate" date,
    "ReplacedBy" text,
    "AdditionalInformation" text
);
ALTER TABLE public."ExternalOrganisationIdentification1CodeValues" OWNER TO postgres;
COMMENT ON TABLE public."ExternalOrganisationIdentification1CodeValues" IS
'Lookup for the ExternalOrganisationIdentification1Code external code list, sourced from the official ISO 20022 External Code Sets registry (https://www.iso20022.org, quarterly XLSX publication). "Status" is the registry''s own field (''Registered'' or ''Obsolete''), not a derived flag. "ReplacedBy" is free text (the successor code), not FK-constrained, since a successor can be a code retired from an earlier quarter''s list.';
-- Domain: ExternalPaymentGroupStatus1Code
DROP DOMAIN IF EXISTS public."ExternalPaymentGroupStatus1Code" CASCADE;
CREATE DOMAIN public."ExternalPaymentGroupStatus1Code" AS varchar(4)
    CHECK (char_length(VALUE) >= 1);
ALTER DOMAIN public."ExternalPaymentGroupStatus1Code" OWNER TO postgres;
COMMENT ON DOMAIN public."ExternalPaymentGroupStatus1Code" IS
'Specifies the status of a group of payment instructions, as published in an external payment group status code set.

Format: minLength 1, maxLength 4.

Note: values are maintained externally by ISO 20022, not embedded in the MDR. This domain enforces LENGTH ONLY. Download the current list from https://www.iso20022.org and populate public."ExternalPaymentGroupStatus1CodeValues" below; reference that table via FK from consuming columns for authoritative validation.';
-- Table: ExternalPaymentGroupStatus1CodeValues
DROP TABLE IF EXISTS public."ExternalPaymentGroupStatus1CodeValues" CASCADE;
CREATE TABLE public."ExternalPaymentGroupStatus1CodeValues" (
    "Code" public."ExternalPaymentGroupStatus1Code" PRIMARY KEY,
    "Name" text NOT NULL,
    "Definition" text,
    "Status" text,
    "LastUpdate" date,
    "CreationDate" date,
    "ReplacedBy" text,
    "AdditionalInformation" text
);
ALTER TABLE public."ExternalPaymentGroupStatus1CodeValues" OWNER TO postgres;
COMMENT ON TABLE public."ExternalPaymentGroupStatus1CodeValues" IS
'Lookup for the ExternalPaymentGroupStatus1Code external code list, sourced from the official ISO 20022 External Code Sets registry (https://www.iso20022.org, quarterly XLSX publication). "Status" is the registry''s own field (''Registered'' or ''Obsolete''), not a derived flag. "ReplacedBy" is free text (the successor code), not FK-constrained, since a successor can be a code retired from an earlier quarter''s list.';
-- Domain: ExternalPaymentTransactionStatus1Code
DROP DOMAIN IF EXISTS public."ExternalPaymentTransactionStatus1Code" CASCADE;
CREATE DOMAIN public."ExternalPaymentTransactionStatus1Code" AS varchar(4)
    CHECK (char_length(VALUE) >= 1);
ALTER DOMAIN public."ExternalPaymentTransactionStatus1Code" OWNER TO postgres;
COMMENT ON DOMAIN public."ExternalPaymentTransactionStatus1Code" IS
'Specifies the status of an individual payment instructions, as published in an external payment transaction status code set.

Format: minLength 1, maxLength 4.

Note: values are maintained externally by ISO 20022, not embedded in the MDR. This domain enforces LENGTH ONLY. Download the current list from https://www.iso20022.org and populate public."ExternalPaymentTransactionStatus1CodeValues" below; reference that table via FK from consuming columns for authoritative validation.';
-- Table: ExternalPaymentTransactionStatus1CodeValues
DROP TABLE IF EXISTS public."ExternalPaymentTransactionStatus1CodeValues" CASCADE;
CREATE TABLE public."ExternalPaymentTransactionStatus1CodeValues" (
    "Code" public."ExternalPaymentTransactionStatus1Code" PRIMARY KEY,
    "Name" text NOT NULL,
    "Definition" text,
    "Status" text,
    "LastUpdate" date,
    "CreationDate" date,
    "ReplacedBy" text,
    "AdditionalInformation" text
);
ALTER TABLE public."ExternalPaymentTransactionStatus1CodeValues" OWNER TO postgres;
COMMENT ON TABLE public."ExternalPaymentTransactionStatus1CodeValues" IS
'Lookup for the ExternalPaymentTransactionStatus1Code external code list, sourced from the official ISO 20022 External Code Sets registry (https://www.iso20022.org, quarterly XLSX publication). "Status" is the registry''s own field (''Registered'' or ''Obsolete''), not a derived flag. "ReplacedBy" is free text (the successor code), not FK-constrained, since a successor can be a code retired from an earlier quarter''s list.';
-- Domain: ExternalPersonIdentification1Code
DROP DOMAIN IF EXISTS public."ExternalPersonIdentification1Code" CASCADE;
CREATE DOMAIN public."ExternalPersonIdentification1Code" AS varchar(4)
    CHECK (char_length(VALUE) >= 1);
ALTER DOMAIN public."ExternalPersonIdentification1Code" OWNER TO postgres;
COMMENT ON DOMAIN public."ExternalPersonIdentification1Code" IS
'Specifies the external person identification scheme name code in the format of character string with a maximum length of 4 characters. The list of valid codes is an external code list published separately.

Format: minLength 1, maxLength 4.

Note: values are maintained externally by ISO 20022, not embedded in the MDR. This domain enforces LENGTH ONLY. Download the current list from https://www.iso20022.org and populate public."ExternalPersonIdentification1CodeValues" below; reference that table via FK from consuming columns for authoritative validation.';
-- Table: ExternalPersonIdentification1CodeValues
DROP TABLE IF EXISTS public."ExternalPersonIdentification1CodeValues" CASCADE;
CREATE TABLE public."ExternalPersonIdentification1CodeValues" (
    "Code" public."ExternalPersonIdentification1Code" PRIMARY KEY,
    "Name" text NOT NULL,
    "Definition" text,
    "Status" text,
    "LastUpdate" date,
    "CreationDate" date,
    "ReplacedBy" text,
    "AdditionalInformation" text
);
ALTER TABLE public."ExternalPersonIdentification1CodeValues" OWNER TO postgres;
COMMENT ON TABLE public."ExternalPersonIdentification1CodeValues" IS
'Lookup for the ExternalPersonIdentification1Code external code list, sourced from the official ISO 20022 External Code Sets registry (https://www.iso20022.org, quarterly XLSX publication). "Status" is the registry''s own field (''Registered'' or ''Obsolete''), not a derived flag. "ReplacedBy" is free text (the successor code), not FK-constrained, since a successor can be a code retired from an earlier quarter''s list.';
-- Domain: ExternalProxyAccountType1Code
DROP DOMAIN IF EXISTS public."ExternalProxyAccountType1Code" CASCADE;
CREATE DOMAIN public."ExternalProxyAccountType1Code" AS varchar(4)
    CHECK (char_length(VALUE) >= 1);
ALTER DOMAIN public."ExternalProxyAccountType1Code" OWNER TO postgres;
COMMENT ON DOMAIN public."ExternalProxyAccountType1Code" IS
'Specifies the external proxy account type code, as published in the proxy account type external code set.

Format: minLength 1, maxLength 4.

Note: values are maintained externally by ISO 20022, not embedded in the MDR. This domain enforces LENGTH ONLY. Download the current list from https://www.iso20022.org and populate public."ExternalProxyAccountType1CodeValues" below; reference that table via FK from consuming columns for authoritative validation.';
-- Table: ExternalProxyAccountType1CodeValues
DROP TABLE IF EXISTS public."ExternalProxyAccountType1CodeValues" CASCADE;
CREATE TABLE public."ExternalProxyAccountType1CodeValues" (
    "Code" public."ExternalProxyAccountType1Code" PRIMARY KEY,
    "Name" text NOT NULL,
    "Definition" text,
    "Status" text,
    "LastUpdate" date,
    "CreationDate" date,
    "ReplacedBy" text,
    "AdditionalInformation" text
);
ALTER TABLE public."ExternalProxyAccountType1CodeValues" OWNER TO postgres;
COMMENT ON TABLE public."ExternalProxyAccountType1CodeValues" IS
'Lookup for the ExternalProxyAccountType1Code external code list, sourced from the official ISO 20022 External Code Sets registry (https://www.iso20022.org, quarterly XLSX publication). "Status" is the registry''s own field (''Registered'' or ''Obsolete''), not a derived flag. "ReplacedBy" is free text (the successor code), not FK-constrained, since a successor can be a code retired from an earlier quarter''s list.';
-- Domain: ExternalPurpose1Code
DROP DOMAIN IF EXISTS public."ExternalPurpose1Code" CASCADE;
CREATE DOMAIN public."ExternalPurpose1Code" AS varchar(4)
    CHECK (char_length(VALUE) >= 1);
ALTER DOMAIN public."ExternalPurpose1Code" OWNER TO postgres;
COMMENT ON DOMAIN public."ExternalPurpose1Code" IS
'Specifies the external purpose code in the format of character string with a maximum length of 4 characters. The list of valid codes is an external code list published separately.

Format: minLength 1, maxLength 4.

Note: values are maintained externally by ISO 20022, not embedded in the MDR. This domain enforces LENGTH ONLY. Download the current list from https://www.iso20022.org and populate public."ExternalPurpose1CodeValues" below; reference that table via FK from consuming columns for authoritative validation.';
-- Table: ExternalPurpose1CodeValues
DROP TABLE IF EXISTS public."ExternalPurpose1CodeValues" CASCADE;
CREATE TABLE public."ExternalPurpose1CodeValues" (
    "Code" public."ExternalPurpose1Code" PRIMARY KEY,
    "Name" text NOT NULL,
    "Definition" text,
    "Status" text,
    "LastUpdate" date,
    "CreationDate" date,
    "ReplacedBy" text,
    "AdditionalInformation" text
);
ALTER TABLE public."ExternalPurpose1CodeValues" OWNER TO postgres;
COMMENT ON TABLE public."ExternalPurpose1CodeValues" IS
'Lookup for the ExternalPurpose1Code external code list, sourced from the official ISO 20022 External Code Sets registry (https://www.iso20022.org, quarterly XLSX publication). "Status" is the registry''s own field (''Registered'' or ''Obsolete''), not a derived flag. "ReplacedBy" is free text (the successor code), not FK-constrained, since a successor can be a code retired from an earlier quarter''s list.';
-- Domain: ExternalReturnReason1Code
DROP DOMAIN IF EXISTS public."ExternalReturnReason1Code" CASCADE;
CREATE DOMAIN public."ExternalReturnReason1Code" AS varchar(4)
    CHECK (char_length(VALUE) >= 1);
ALTER DOMAIN public."ExternalReturnReason1Code" OWNER TO postgres;
COMMENT ON DOMAIN public."ExternalReturnReason1Code" IS
'Specifies the return reason, as published in an external return reason code list.

Format: minLength 1, maxLength 4.

Note: values are maintained externally by ISO 20022, not embedded in the MDR. This domain enforces LENGTH ONLY. Download the current list from https://www.iso20022.org and populate public."ExternalReturnReason1CodeValues" below; reference that table via FK from consuming columns for authoritative validation.';
-- Table: ExternalReturnReason1CodeValues
DROP TABLE IF EXISTS public."ExternalReturnReason1CodeValues" CASCADE;
CREATE TABLE public."ExternalReturnReason1CodeValues" (
    "Code" public."ExternalReturnReason1Code" PRIMARY KEY,
    "Name" text NOT NULL,
    "Definition" text,
    "Status" text,
    "LastUpdate" date,
    "CreationDate" date,
    "ReplacedBy" text,
    "AdditionalInformation" text
);
ALTER TABLE public."ExternalReturnReason1CodeValues" OWNER TO postgres;
COMMENT ON TABLE public."ExternalReturnReason1CodeValues" IS
'Lookup for the ExternalReturnReason1Code external code list, sourced from the official ISO 20022 External Code Sets registry (https://www.iso20022.org, quarterly XLSX publication). "Status" is the registry''s own field (''Registered'' or ''Obsolete''), not a derived flag. "ReplacedBy" is free text (the successor code), not FK-constrained, since a successor can be a code retired from an earlier quarter''s list.';
-- Domain: ExternalReversalReason1Code
DROP DOMAIN IF EXISTS public."ExternalReversalReason1Code" CASCADE;
CREATE DOMAIN public."ExternalReversalReason1Code" AS varchar(4)
    CHECK (char_length(VALUE) >= 1);
ALTER DOMAIN public."ExternalReversalReason1Code" OWNER TO postgres;
COMMENT ON DOMAIN public."ExternalReversalReason1Code" IS
'Specifies the reversal reason, as published in an external reversal reason code list.

Format: minLength 1, maxLength 4.

Note: values are maintained externally by ISO 20022, not embedded in the MDR. This domain enforces LENGTH ONLY. Download the current list from https://www.iso20022.org and populate public."ExternalReversalReason1CodeValues" below; reference that table via FK from consuming columns for authoritative validation.';
-- Table: ExternalReversalReason1CodeValues
DROP TABLE IF EXISTS public."ExternalReversalReason1CodeValues" CASCADE;
CREATE TABLE public."ExternalReversalReason1CodeValues" (
    "Code" public."ExternalReversalReason1Code" PRIMARY KEY,
    "Name" text NOT NULL,
    "Definition" text,
    "Status" text,
    "LastUpdate" date,
    "CreationDate" date,
    "ReplacedBy" text,
    "AdditionalInformation" text
);
ALTER TABLE public."ExternalReversalReason1CodeValues" OWNER TO postgres;
COMMENT ON TABLE public."ExternalReversalReason1CodeValues" IS
'Lookup for the ExternalReversalReason1Code external code list, sourced from the official ISO 20022 External Code Sets registry (https://www.iso20022.org, quarterly XLSX publication). "Status" is the registry''s own field (''Registered'' or ''Obsolete''), not a derived flag. "ReplacedBy" is free text (the successor code), not FK-constrained, since a successor can be a code retired from an earlier quarter''s list.';
-- Domain: ExternalServiceLevel1Code
DROP DOMAIN IF EXISTS public."ExternalServiceLevel1Code" CASCADE;
CREATE DOMAIN public."ExternalServiceLevel1Code" AS varchar(4)
    CHECK (char_length(VALUE) >= 1);
ALTER DOMAIN public."ExternalServiceLevel1Code" OWNER TO postgres;
COMMENT ON DOMAIN public."ExternalServiceLevel1Code" IS
'Specifies the external service level code in the format of character string with a maximum length of 4 characters. The list of valid codes is an external code list published separately.

Format: minLength 1, maxLength 4.

Note: values are maintained externally by ISO 20022, not embedded in the MDR. This domain enforces LENGTH ONLY. Download the current list from https://www.iso20022.org and populate public."ExternalServiceLevel1CodeValues" below; reference that table via FK from consuming columns for authoritative validation.';
-- Table: ExternalServiceLevel1CodeValues
DROP TABLE IF EXISTS public."ExternalServiceLevel1CodeValues" CASCADE;
CREATE TABLE public."ExternalServiceLevel1CodeValues" (
    "Code" public."ExternalServiceLevel1Code" PRIMARY KEY,
    "Name" text NOT NULL,
    "Definition" text,
    "Status" text,
    "LastUpdate" date,
    "CreationDate" date,
    "ReplacedBy" text,
    "AdditionalInformation" text
);
ALTER TABLE public."ExternalServiceLevel1CodeValues" OWNER TO postgres;
COMMENT ON TABLE public."ExternalServiceLevel1CodeValues" IS
'Lookup for the ExternalServiceLevel1Code external code list, sourced from the official ISO 20022 External Code Sets registry (https://www.iso20022.org, quarterly XLSX publication). "Status" is the registry''s own field (''Registered'' or ''Obsolete''), not a derived flag. "ReplacedBy" is free text (the successor code), not FK-constrained, since a successor can be a code retired from an earlier quarter''s list.';
-- Domain: ExternalStatusReason1Code
DROP DOMAIN IF EXISTS public."ExternalStatusReason1Code" CASCADE;
CREATE DOMAIN public."ExternalStatusReason1Code" AS varchar(4)
    CHECK (char_length(VALUE) >= 1);
ALTER DOMAIN public."ExternalStatusReason1Code" OWNER TO postgres;
COMMENT ON DOMAIN public."ExternalStatusReason1Code" IS
'Specifies the status reason, as published in an external status reason code list.

Format: minLength 1, maxLength 4.

Note: values are maintained externally by ISO 20022, not embedded in the MDR. This domain enforces LENGTH ONLY. Download the current list from https://www.iso20022.org and populate public."ExternalStatusReason1CodeValues" below; reference that table via FK from consuming columns for authoritative validation.';
-- Table: ExternalStatusReason1CodeValues
DROP TABLE IF EXISTS public."ExternalStatusReason1CodeValues" CASCADE;
CREATE TABLE public."ExternalStatusReason1CodeValues" (
    "Code" public."ExternalStatusReason1Code" PRIMARY KEY,
    "Name" text NOT NULL,
    "Definition" text,
    "Status" text,
    "LastUpdate" date,
    "CreationDate" date,
    "ReplacedBy" text,
    "AdditionalInformation" text
);
ALTER TABLE public."ExternalStatusReason1CodeValues" OWNER TO postgres;
COMMENT ON TABLE public."ExternalStatusReason1CodeValues" IS
'Lookup for the ExternalStatusReason1Code external code list, sourced from the official ISO 20022 External Code Sets registry (https://www.iso20022.org, quarterly XLSX publication). "Status" is the registry''s own field (''Registered'' or ''Obsolete''), not a derived flag. "ReplacedBy" is free text (the successor code), not FK-constrained, since a successor can be a code retired from an earlier quarter''s list.';
-- ---------------------------------------------------------------------
-- PART 3b -- Seed data: the 26 External*Code lookup tables
-- Source: ISO 20022 External Code Sets registry, 1Q2026 (v1) publication
-- https://www.iso20022.org/catalogue-messages/additional-content-messages/external-code-sets
-- (XLSX format, sheet "AllCodeSets"; retrieved 2026-08-26)
-- Re-run against a refreshed download to update -- external code sets
-- follow a quarterly update cycle (end of Feb/May/Aug/Nov).
-- ---------------------------------------------------------------------
-- Seed: ExternalAccountIdentification1CodeValues (4 codes)
INSERT INTO public."ExternalAccountIdentification1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('AIIN', 'IssuerIdentificationNumber', 'Issuer Identification Number (IIN) - identifies a card issuing institution in an international interchange environment. Issued by ABA (American Bankers Association).', 'Registered', '2016-04-01'::date, '2016-03-01'::date, NULL, NULL),
    ('BBAN', 'BBANIdentifier', 'Basic Bank Account Number (BBAN) - identifier used nationally by financial institutions, ie, in individual countries, generally as part of a National Account Numbering Scheme(s), to uniquely identify the account of a customer.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('CUID', 'CHIPSUniversalIdentifier', '(United States) Clearing House Interbank Payments System (CHIPS) Universal Identification (UID) - identifies entities that own accounts at CHIPS participating financial institutions, through which CHIPS payments are effected. The CHIPS UID is assigned by the New York Clearing House.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('UPIC', 'UPICIdentifier', 'Universal Payment Identification Code (UPIC) - identifier used by the New York Clearing House to mask confidential data, such as bank accounts and bank routing numbers. UPIC numbers remain with business customers, regardless of banking relationship changes.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL)
ON CONFLICT ("Code") DO NOTHING;
-- Seed: ExternalCashAccountType1CodeValues (28 codes)
INSERT INTO public."ExternalCashAccountType1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('CACC', 'Current', 'Account used to post debits and credits when no specific account has been nominated.', 'Registered', '2012-05-31'::date, '2012-05-31'::date, NULL, NULL),
    ('CARD', 'CardAccount', 'Account used for credit card payments.', 'Registered', '2020-08-01'::date, '2020-08-01'::date, NULL, NULL),
    ('CASH', 'CashPayment', 'Account used for the payment of cash.', 'Registered', '2012-05-31'::date, '2012-05-31'::date, NULL, NULL),
    ('CHAR', 'Charges', 'Account used for charges if different from the account for
payment.', 'Registered', '2012-05-31'::date, '2012-05-31'::date, NULL, NULL),
    ('CISH', 'CashIncome', 'Account used for payment of income if different from the current cash account', 'Registered', '2012-05-31'::date, '2012-05-31'::date, NULL, NULL),
    ('COMM', 'Commission', 'Account used for commission if different from the account
for payment.', 'Registered', '2012-05-31'::date, '2012-05-31'::date, NULL, NULL),
    ('CPAC', 'ClearingParticipantSettlementAccount', 'Account used to post settlement debit and credit entries on behalf of a designated Clearing Participant.', 'Registered', '2017-02-08'::date, '2017-02-01'::date, NULL, NULL),
    ('LLSV', 'LimitedLiquiditySavingsAccount', 'Account used for savings with special interest and withdrawal terms.', 'Registered', '2012-05-31'::date, '2012-05-31'::date, NULL, NULL),
    ('LOAN', 'Loan', 'Account used for loans.', 'Registered', '2012-05-31'::date, '2012-05-31'::date, NULL, NULL),
    ('MGLD', 'MarginalLending', 'Account used for a marginal lending facility.', 'Registered', '2012-05-31'::date, '2012-05-31'::date, NULL, NULL),
    ('MOMA', 'MoneyMarket', 'Account used for money markets if different from the cash
account.', 'Registered', '2012-05-31'::date, '2012-05-31'::date, NULL, NULL),
    ('NFCA', 'NonResidentForeignCurrencyAccount', 'Non-Resident Individual / Entity Foreign Current held domestically.', 'Registered', '2022-11-30'::date, '2022-11-30'::date, NULL, NULL),
    ('NLCY', 'NonResidentLocalDomesticCurrencyAccount', 'Non-Resident domestic currency account.', 'Registered', '2025-11-30'::date, '2025-11-30'::date, NULL, NULL),
    ('NREX', 'NonResidentExternal', 'Account used for non-resident external.', 'Registered', '2012-05-31'::date, '2012-05-31'::date, NULL, NULL),
    ('ODEP', 'OrdinaryDeposit', 'Account used as ordinary deposit for everyday deposits and withdrawals.', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, 'Many banks were using FUTS as Proprietary Code, but  with new ISO code ODEP, banks can move away from usage of Proprietary codes.'),
    ('ODFT', 'Overdraft', 'Account is used for overdrafts.', 'Registered', '2012-05-31'::date, '2012-05-31'::date, NULL, NULL),
    ('ONDP', 'OverNightDeposit', 'Account used for overnight deposits.', 'Registered', '2012-05-31'::date, '2012-05-31'::date, NULL, NULL),
    ('OTHR', 'OtherAccount', 'Account not otherwise specified.', 'Registered', '2012-05-31'::date, '2012-05-31'::date, NULL, NULL),
    ('REFC', 'ResidentEntityForeignCurrency', 'Resident Entity Foreign Currency held domestically.', 'Registered', '2025-11-30'::date, '2025-11-30'::date, NULL, NULL),
    ('RFCA', 'ResidentIndividualForeignCurrencyAccount', 'Resident Individual Foreign Currency held domestically.', 'Registered', '2025-11-30'::date, '2025-11-30'::date, NULL, NULL),
    ('RLCY', 'ResidentLocalDomesticCurrency', 'Resident domestic currency account.', 'Registered', '2025-11-30'::date, '2025-11-30'::date, NULL, NULL),
    ('SACC', 'Settlement', 'Account used to post debit and credit entries, as a result of transactions cleared and settled through a specific clearing and settlement system.', 'Registered', '2012-05-31'::date, '2012-05-31'::date, NULL, NULL),
    ('SLRY', 'Salary', 'Accounts used for salary payments.', 'Registered', '2012-05-31'::date, '2012-05-31'::date, NULL, NULL),
    ('SVGS', 'Savings', 'Account used for savings.', 'Registered', '2012-05-31'::date, '2012-05-31'::date, NULL, NULL),
    ('TAXE', 'Tax', 'Account used for taxes if different from the account for
payment.', 'Registered', '2012-05-31'::date, '2012-05-31'::date, NULL, NULL),
    ('TRAN', 'TransactingAccount', 'A transacting account is the most basic type of bank account that you can get. The main difference between transaction and cheque accounts is that you usually do not get a cheque book with your transacting account and neither are you offered an overdraft facility.', 'Registered', '2016-11-18'::date, '2016-10-03'::date, NULL, NULL),
    ('TRAS', 'CashTrading', 'Account used for trading if different from the current cash account.', 'Registered', '2012-05-31'::date, '2012-05-31'::date, NULL, NULL),
    ('VACC', 'VirtualAccount', 'Account created virtually to facilitate collection and reconciliation.', 'Registered', '2022-02-15'::date, '2022-02-15'::date, NULL, NULL)
ON CONFLICT ("Code") DO NOTHING;
-- Seed: ExternalCashClearingSystem1CodeValues (145 codes)
INSERT INTO public."ExternalCashClearingSystem1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('ABE', 'EBAEuro1Step1', 'EBA Euro1/Step1.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('ACH', 'ACH', 'Automated Clearing House. Payment system that clears cash transfers and settles the proceeds in a lump sum, usually on a multilateral netting basis.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('ACS', 'CanadaACSS', 'Canadian Dollar (CAD)  - Automated Clearing Settlement System (ACSS).', 'Registered', '2020-05-01'::date, '2014-01-16'::date, NULL, NULL),
    ('AIP', 'Albania', 'AL (Albania) -  Albania Interbank Payment System.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('ART', 'Austrian', 'AT (Austria) - Austrian RTGS.', 'Registered', '2019-05-01'::date, '2009-04-01'::date, NULL, NULL),
    ('AVP', 'NewZealand', 'NZ (New Zealand) - New Zealand Assured Value Payments.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('AZM', 'Azerbaijan', 'AZ (Azerbaijan) - Azerbaijan Interbank Payment System (AZIPS).', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('B27', 'P27', 'P27 Clearing - Batch Payment Platform.', 'Registered', '2022-02-15'::date, '2022-02-15'::date, NULL, NULL),
    ('BAP', 'BosniaHerzegovina', 'BA (Bosnia and Herzegovina).', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('BCC', 'SwedenBGC', 'SE (Sweden) - Sweden BGC Clearing CUG.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('BCE', 'Ecuador', 'EC (Ecuador) - Ecuadorian Central Payment System (Sistema Central de Pagos Ecuatoriano)', 'Registered', '2014-06-13'::date, '2014-06-13'::date, NULL, NULL),
    ('BDS', 'Barbados', 'BB (Barbados) - Barbados RTGS (CBRTGS).', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('BEL', 'Belgium', 'BE (Belgium) - Belgium RTGS (ELLIPS).', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('BGN', 'Bulgaria', 'BG (Bulgaria) - Bulgaria RTGS.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('BHS', 'Bahamas', 'BS (Bahamas) - Bahamas RTGS.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('BIS', 'Botswana', 'BW (Botswana) - Botswana Interbank Settlement System.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('BOF', 'Finland', 'FI (Finland) - RTGS (BOF).', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('BOJ', 'BankOfJapanNet', 'the Bank of Japan clearing system.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('BOK', 'KoreaBOKWire', 'KR (South Korea) - Korean Won RTGS (BOK-Wire+).', 'Registered', '2023-05-31'::date, '2023-05-31'::date, NULL, NULL),
    ('BRL', 'Italy', 'IT (Italy) - Italy RTGS (BIREL).', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('BSP', 'Philippines', 'PH (Philippines) - Philippines Payment System.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('CAD', 'CanadaCAD', 'CA (Canada) - Canadian Large Value Transfer System (LVTS).', 'Registered', '2020-05-01'::date, '2009-04-01'::date, 'LVT', 'Do not use.'),
    ('CAM', 'SpainCAM', 'ES (Spain).', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('CBA', 'CentralBankOfArubaCSM', 'AW (Aruba) - Central Bank of Aruba CSM.', 'Registered', '2018-08-01'::date, '2018-08-01'::date, NULL, NULL),
    ('CBC', 'CentraleBankVanCuraçaoEnSintMaartenCSM', 'CW (Curaçao), SX (Sint Maarten) Central Bank of Curaçao and Sint    Maarten CSM', 'Registered', '2020-05-01'::date, '2020-05-01'::date, NULL, NULL),
    ('CBH', 'COMESAREPSS', 'COMESA Clearing House Regional Payment and Settlement System, a regional cross-border payment and settlement platform designed to facilitate efficient and secure intra-regional trade payments within COMESA (Common Market for Eastern and Southern Africa) member states.', 'Registered', '2025-11-30'::date, '2025-11-30'::date, NULL, NULL),
    ('CBJ', 'Ireland', 'IE (Ireland) - Irish RTGS (IRIS).', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('CBP', 'COMESASS', 'COMESA (Common Market for Eastern and Southern Africa) RTGS system.', 'Registered', '2025-11-30'::date, '2025-11-30'::date, NULL, NULL),
    ('CCE', 'Peru', 'Real-Time Payment System Peru', 'Registered', '2020-05-01'::date, '2020-05-01'::date, NULL, NULL),
    ('CHI', 'USTCHChips', 'US - The Clearing House CHIPS', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('CHP', 'UnitedKingdom', 'GB (UK) - British Euro RTGS (CHAPS).', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('CIP', 'China', 'Cross-border Interbank Payment System (CIPS).', 'Registered', '2019-08-01'::date, '2019-08-01'::date, NULL, NULL),
    ('CIS', 'CentralInteroperabilityService', 'Central Interoperability Service of the EACHA Clearing Cooperative, for exchanging SEPA payments between Automated Clearing Houses in the EEA.', 'Registered', '2015-02-27'::date, '2015-02-27'::date, NULL, NULL),
    ('CIT', 'CITAD', 'Inter-Bank Payment System (IBPS), settlement of multi-currency, real-time and batch interbank payments in Vietnam.', 'Registered', '2025-08-29'::date, '2025-05-31'::date, NULL, 'Infrastructure through which the payment instruction is processed, as published in an external clearing system identification code list. Provide tracking information to Swift users when payment is sent to CITAD.'),
    ('COE', 'ColumbiaCEDEC', 'CO (Columbia) - Colombian Electronic Cheque System named CEDEC (Compensación Electrónica De Cheques).', 'Registered', '2020-05-01'::date, '2009-04-01'::date, NULL, NULL),
    ('COI', 'ColumbiaCENIT', 'CO (Columbia) - Colombian Central Bank´s ACH named CENIT (Compensación Electrónica Nacional Interbancaria).', 'Registered', '2020-05-01'::date, '2009-04-01'::date, NULL, NULL),
    ('COU', 'ColumbiaCUD', 'CO (Columbia) - Colombian RTGS System named CUD (Cuentas de Depósito).', 'Registered', '2020-05-01'::date, '2009-04-01'::date, NULL, NULL),
    ('DDK', 'DenmarkDDK', 'DK (Denmark) - Danish Krone RTGS (KRONOS)', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('DKC', 'Denmark', 'DK (Denmark) - Danish Euro RTGS (KRONOS)', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('DZR', 'AlgeriaRTGS', 'Identification of the RTGS system of the Algeria.', 'Registered', '2025-11-30'::date, '2025-11-30'::date, NULL, NULL)
ON CONFLICT ("Code") DO NOTHING;
INSERT INTO public."ExternalCashClearingSystem1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('EBA', 'EBAEuro1', 'EBA Euro1.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('ELS', 'GermanyELS', 'DE (Germany).', 'Registered', '2014-07-31'::date, '2009-04-01'::date, NULL, NULL),
    ('EMZ', 'Germany', 'Elektronischer Massenzahlungsverkehr (EMZ).
DE (Germany) - retail payment system operated by the Deutsche Bundesbank.', 'Registered', '2014-06-13'::date, '2014-06-13'::date, NULL, 'Replaces SCL'),
    ('EPM', 'ECB', 'ECB (European Central Bank) - ECB Payment Mechanism.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('EPN', 'USTCHEPN', 'US - The Clearing House EPN', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('ERP', 'EBAStep1', 'EBA step 1 (members).', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('FDA', 'USFedACH', 'US (United States) - Federal Reserve Banks Automated Clearing House Service.', 'Registered', '2020-11-01'::date, '2009-04-01'::date, NULL, NULL),
    ('FDN', 'USFedNow', 'US (United States) - Federal Reserve Banks FedNow Service.', 'Registered', '2020-11-01'::date, '2009-04-01'::date, NULL, NULL),
    ('FDW', 'USFedwireFunds', 'US (United States) - Federal Reserve Banks Fedwire Funds  Service.', 'Registered', '2020-11-01'::date, '2009-04-01'::date, NULL, NULL),
    ('FEY', 'ForeignExchangeYenClearing', 'JP (Japan) the Foreign Exchange Yen Clearing system (FEYCS). It is the Japanese electronic interbank system for sending guaranteed and unconditional yen payments of FX deals for same day settlement from one settlement bank, on behalf of itself or its customers, to another settlement bank.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('FPS', 'FasterPaymentsServices', 'Faster Payments Service in UK.', 'Registered', '2020-11-01'::date, '2020-11-01'::date, NULL, NULL),
    ('GIS', 'Ghana', 'GH (Ghana) - Ghana Interbank Settlement System (GISS).', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('HKL', 'HongKongCHATS', 'Hong Kong Clearing House Automated Transfer System (CHATS).', 'Registered', '2020-11-01'::date, '2020-11-01'::date, NULL, NULL),
    ('HKS', 'HongKongFPS', 'Hong Kong Faster Payment System or FPS. A system owned and operated by the HKICL, to provide instant clearing and settlement payment services.', 'Registered', '2021-05-01'::date, '2021-05-01'::date, NULL, NULL),
    ('HRK', 'Croatia', 'HR (Croatia) - HSVP.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('HRM', 'Greece', 'GR (Greece) - Greek RTGS (HERMES).', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('HUF', 'Hungary', 'HU (Hungary) - VIBER.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('I27', 'P27RealTime', 'P27 Clearing - Instant Payment Platform.', 'Registered', '2022-02-15'::date, '2022-02-15'::date, NULL, NULL),
    ('IBG', 'MalaysiaInterbankGIRO', 'MY (Malaysia) - Interbank GIRO.', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, 'Provide tracking information to Swift users when payment is sent to IBG.'),
    ('IBP', 'SpainIberpayInstantPayments', 'ES - Spain - Iberpay Instant Payments', 'Registered', '2021-05-01'::date, '2021-05-01'::date, NULL, NULL),
    ('IMP', 'IndiaImmediatePaymentService', 'India Immediate Payment Service', 'Registered', '2020-11-01'::date, '2020-11-01'::date, NULL, NULL),
    ('INC', 'DEandNLEquens', 'DE and NL - Equens.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('ISG', 'Iceland', 'IS (Iceland) - Icelandic krona RTGS (MBK).', 'Registered', '2021-08-31'::date, '2021-08-23'::date, NULL, 'CR1042'),
    ('ISR', 'IsraelRTGS', 'IL- Bank of Israel RTGS System Code.', 'Registered', '2024-02-28'::date, '2024-02-28'::date, NULL, NULL),
    ('ISW', 'NGInterswitch', 'NG (Nigeria) - Interswitch.', 'Registered', '2021-11-30'::date, '2021-11-30'::date, NULL, 'CR1073'),
    ('JOD', 'Jordan', 'JO (Jordan) - Jordan RTGS.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('KPS', 'Kenya', 'KE (Kenya) - Kenyan Electronic Payment Settlement System.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('KRI', 'KoreaBOKWireInternational', 'KR (South Korea) - Korean Won International RTGS', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, NULL),
    ('KTS', 'PapuaNewGuineaKATS', 'PG (Papua New Guinea) - Kina Automated Transfer System RTGS (KATS RTGS).', 'Registered', '2023-07-06'::date, '2023-07-06'::date, NULL, NULL),
    ('LGS', 'Luxemburg', 'LU (Luxemburg) - Luxembourg RTGS (LIPS).', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('LKB', 'SriLanka', 'LK (Sri Lanka) - Sri Lanka (Lankasettle).', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('LSW', 'Lesotho', 'LS (Lesotho) - RTGS (Wire).', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('LVL', 'Latvia', 'LV (Latvia).', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('LVT', 'CanadaLVTS', 'CA (Canada) - Large Value Transfer System (LVTS).', 'Registered', '2020-05-01'::date, '2014-01-16'::date, NULL, 'Replaces CAD'),
    ('LYX', 'LynxCanada', 'CA (Canada) Lynx High Value Payment System.', 'Registered', '2019-11-01'::date, '2019-11-01'::date, NULL, NULL),
    ('MDP', 'MDP', 'MDP, a licensed intermediary payment service in Vietnam providing financial switching, payment gateways and clearing services.', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, 'Infrastructure through which the payment instruction is processed, as published in an external clearing system identification code list. Provide tracking information to Swift users when payment is sent to MDP.'),
    ('MEP', 'Singapore', 'SG (Singapore) - Singapore RTGS (MEPS+).', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('MGR', 'MadagascarRTGS', 'MG (Madagascar) Real Time Gross Settlement System', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, NULL),
    ('MOC', 'BancoDeMocambiqueRTGS', 'Banco de Mocambique RTGS system.', 'Registered', '2022-11-30'::date, '2022-11-30'::date, NULL, NULL),
    ('MOS', 'SouthAfrica', 'ZA (South Africa) - South-African Multiple Option Settlement.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL)
ON CONFLICT ("Code") DO NOTHING;
INSERT INTO public."ExternalCashClearingSystem1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('MQQ', 'MacaoRTGS', 'Macao Real Time Gross Settlement System', 'Registered', '2020-08-01'::date, '2020-08-01'::date, NULL, NULL),
    ('MRS', 'Malta', 'MT (Malta) - Malta Realtime Interbank Settlement System.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('MUP', 'Mauritius', 'MU (Mauritius).', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('NAM', 'Namibia', 'NA (Namibian) - Namibian Interbank Settlement System.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('NAP', 'NAPAS', 'Instant Payment System for payments in VN Dong denomination.', 'Registered', '2025-05-31'::date, '2025-05-31'::date, NULL, 'Infrastructure through which the payment instruction is processed.'),
    ('NBO', 'NorwayRTGS', 'NO - Norway NOK RTGS Norges Bank', 'Registered', '2021-08-31'::date, '2021-08-24'::date, NULL, 'CR1047'),
    ('NFT', 'IndiaNationalElectronicFundsTransferSystem', 'Provides information to the remitter when incoming cross border transactions are routed through NEFT in the Indian domestic leg.', 'Registered', '2024-08-30'::date, '2024-08-30'::date, NULL, NULL),
    ('NOC', 'Norway', 'NO (Norway).', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('NOR', 'NorwayNICSReal', 'NICS Real (Norway)', 'Registered', '2020-08-01'::date, '2020-08-01'::date, NULL, NULL),
    ('NPP', 'AustraliaNPP', 'AU (Australia) - New Payments Platform (NPP).', 'Registered', '2020-05-01'::date, '2016-04-01'::date, NULL, NULL),
    ('NSS', 'USNSS', 'US (United States) - Federal Reserve Banks National Settlement Service.', 'Registered', '2020-11-01'::date, '2020-11-01'::date, NULL, NULL),
    ('NZE', 'NewZealandRTGS', 'NZ (New Zealand) - New Zealand Dollar RTGS (ESAS)', 'Registered', '2021-02-01'::date, '2021-02-01'::date, NULL, NULL),
    ('PCH', 'Switzerland', 'CH (Switzerland).', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('PDS', 'AustraliaPDS', 'AU (Australia).', 'Registered', '2020-05-01'::date, '2009-04-01'::date, NULL, NULL),
    ('PEG', 'Egypt', 'EG (Egypt).', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('PNS', 'FrancePNS', 'FR (France).', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('PSA', 'AustrianCSM', 'AT (Austria) - Austrian CSM.', 'Registered', '2021-02-01'::date, '2021-02-01'::date, NULL, NULL),
    ('PTR', 'Angola', 'AO (Angola) - Angola RTGS.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('PVE', 'Venezuela', 'Ve (Venezuela).', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('RBM', 'ReserveBankOfMalawiRTGS', 'Malawi - Malawi Interbank Transfer and Settlement System.', 'Registered', '2023-11-30'::date, '2023-11-30'::date, NULL, NULL),
    ('REN', 'RENTAS', 'MY (Malaysia) - RENTAS, Real Time Electronic Transfer of Funds and Securities in Ringgit denomination.', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('RGS', 'IndiaRTGS', 'Provides information to the remitter when incoming cross border transactions are routed through RTGS in the Indian domestic leg.', 'Registered', '2024-08-30'::date, '2024-08-30'::date, NULL, NULL),
    ('RIX', 'RIXRTGSSverigesRiksbank', 'SE (Sweden) - SEK RTGS (RIX).', 'Registered', '2022-05-31'::date, '2022-05-31'::date, NULL, NULL),
    ('ROL', 'RomaniaEPO', 'RO (Romania) - Romanian Electronic Payment Operations RT.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('RON', 'RomaniaRTGS', 'RO- Romania RON RTGS National Bank of Romania.', 'Registered', '2023-08-31'::date, '2023-08-31'::date, NULL, NULL),
    ('ROS', 'RomaniaGSRS', 'RO (Romania) - Romanian GSRS.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('RSD', 'SerbiaRTGS', 'RS (Republic of Serbia) - Serbian RTGS in Serbian Dinars.', 'Registered', '2025-08-29'::date, '2025-08-29'::date, NULL, NULL),
    ('RSE', 'SerbiaInterbankAndInternationalClearingOfFXPayments', 'RS (Republic of Serbia) - Interbank and International Clearing of FX Payments in Euros.', 'Registered', '2025-08-29'::date, '2025-08-29'::date, NULL, NULL),
    ('RTG', 'RTGS', 'Real Time Gross Settlement System. Payment system that simultaneously clears individual transfers and settles them in central bank money.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('RTP', 'GermanyRTGSPlus', 'DE (Germany).', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('RTR', 'RTRCanada', 'CA (Canada) Real Time Rail Payment System.', 'Registered', '2019-11-01'::date, '2019-11-01'::date, NULL, NULL),
    ('SCL', 'RPSAndSEPAClearer', 'DE - SEPA-Clearer of the Retail Payment System operated by Deutsche Bundesbank', 'Registered', '2014-06-13'::date, '2010-08-01'::date, 'EMZ', 'Do not use.'),
    ('SCP', 'Chili', 'CL (Chile) - Chilean Interbank Payment System.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('SCR', 'SingaporeSCRIPS', 'SG (Singapore) - Singapore RTGS (SCRIPS).', 'Obsolete', '2024-12-04'::date, '2022-05-31'::date, NULL, 'SCRIPS project has been closed.'),
    ('SEC', 'SwedenSEC', 'SE (Sweden) - Swedish Euro RTGS (SEC).', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('SEU', 'euroSIC', 'CH (Switzerland) - Swiss EUR RTGS named euroSIC.', 'Registered', '2021-05-01'::date, '2021-05-01'::date, NULL, NULL),
    ('SGA', 'BankOfTheCentralAfricanStates', 'BEAC (Bank of the Central African States) RTGS (SYGMA)', 'Registered', '2025-02-28'::date, '2025-02-28'::date, NULL, 'Settlement system used by participants to transfer money between themselves or the central bank in Cameroon, Central Africa Republic, Chad, Equatorial Guinea, Gabon and Republic of the Congo. In this case, it is particular to the form of electronic payment of Real Time Gross Settlement.'),
    ('SIC', 'SIC', 'CH (Switzerland) - Swiss CHF RTGS named SIC.', 'Registered', '2021-05-01'::date, '2021-05-01'::date, NULL, NULL),
    ('SIP', 'SICIP', 'CH (Switzerland) - Swiss Instant Payment service in CHF operated by SIX Interbank Clearing.', 'Registered', '2021-05-01'::date, '2021-05-01'::date, NULL, NULL),
    ('SIT', 'Slovania', 'SI (Slovenia).', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL)
ON CONFLICT ("Code") DO NOTHING;
INSERT INTO public."ExternalCashClearingSystem1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('SLB', 'SpainES', 'ES (Spain) - Spanish RTGS (SLBE).', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('SPG', 'Portugal', 'PT (Portugal) - Portuguese RTGS (SPGT).', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('SRB', 'SORBNET3', 'Narodowy Bank Polski RTGS System.', 'Registered', '2023-08-31'::date, '2023-08-31'::date, NULL, NULL),
    ('SSK', 'SwedenSSK', 'SE (Sweden) - SEK RTGS (RIX).', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('ST2', 'EBAClearingSTEP2', 'EBA Clearing STEP 2.', 'Registered', '2020-05-01'::date, '2009-04-01'::date, NULL, NULL),
    ('STG', 'UnitedKingdomGBP', 'UK (United Kingdom) - CHAPS Sterling RTGS.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('TBF', 'FranceFR', 'FR (France) - French RTGS (TBF).', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('TCH', 'USTCHRealTime', 'US - The Clearing House Real-TimePayment System', 'Registered', '2016-08-31'::date, '2016-08-01'::date, NULL, NULL),
    ('TGT', 'Target', 'Target.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('THB', 'Thailand', 'TH (Thailand) - Thailand Payment System (BAHTNET).', 'Registered', '2016-05-11'::date, '2016-04-01'::date, NULL, NULL),
    ('THN', 'Thailand-NITMX', 'TH (Thailand) - National ITMX Payment System', 'Registered', '2016-05-11'::date, '2016-04-01'::date, NULL, NULL),
    ('TIS', 'Tanzania', 'TZ (Tanzania) - Tanzania Interbank Settlement System (TISS).', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('TOP', 'Netherlands', 'NL (Netherlands) - Dutch RTGS (TOP).', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('TTD', 'TrinidadAndTobago', 'TT (Trinidad and Tobago ) - Trinidad and Tobago SAFE-TT.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('TWP', 'TaiwanRTGS', 'Taiwan Real-Time Gross Settlement System.', 'Registered', '2023-08-31'::date, '2023-08-31'::date, NULL, NULL),
    ('UBE', 'CanadaUSBE', 'United States Dollar  (USD) - US Bulk Exchange Clearing System (USBE).', 'Registered', '2020-05-01'::date, '2014-01-16'::date, NULL, NULL),
    ('UGD', 'BankOfUgandaRTGS', 'UG (Uganda) - Uganda Domestic Automated Transfer System RTGS.', 'Registered', '2025-11-30'::date, '2025-11-30'::date, NULL, NULL),
    ('UIS', 'Uganda', 'UG (Uganda) - Uganda National Interbank Settlement System, for cross-border payments.', 'Registered', '2025-11-30'::date, '2009-04-01'::date, NULL, NULL),
    ('UKD', 'UnitedKingdomUKD', 'UK (United Kingdom) - Pay.UK Sterling Domestic.', 'Registered', '2022-02-15'::date, '2022-02-15'::date, NULL, NULL),
    ('UPI', 'IndiaUnifiedPaymentsInterface', 'India Unified Payments Interface.', 'Registered', '2020-11-01'::date, '2020-11-01'::date, NULL, NULL),
    ('VCS', 'VocaLink', 'VocaLink Clearing System', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('XCT', 'EBASTEP2XCT', 'EBA step 2.', 'Registered', '2020-05-01'::date, '2009-04-01'::date, NULL, NULL),
    ('ZEN', 'Zengin', 'JP (Japan) the Zengin system. The electronic payment system for domestic third party transfers managed by the Tokyo Bankers Association.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('ZET', 'Zimbabwe', 'ZW (Zimbabwe) - Zimbabwe Electronic Transfer & Settlement System.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('ZIS', 'Zambia', 'ZM (Zambia) - Zambian Interbank Payment &Settlement System.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL)
ON CONFLICT ("Code") DO NOTHING;
-- Seed: ExternalCategoryPurpose1CodeValues (49 codes)
INSERT INTO public."ExternalCategoryPurpose1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('BONU', 'BonusPayment', 'Transaction is the payment of a bonus.', 'Registered', '2012-02-09'::date, '2012-02-09'::date, NULL, NULL),
    ('CASH', 'CashManagementTransfer', 'Transaction is a general cash management instruction.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('CBLK', 'CardBulkClearing', 'A service that is settling money for a bulk of card transactions, while referring to a specific transaction file or other information like terminal ID, card acceptor ID or other transaction details.', 'Registered', '2012-10-08'::date, '2012-10-08'::date, NULL, NULL),
    ('CCRD', 'CreditCardPayment', 'Transaction is related to a payment of credit card.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('CDIS', 'AdditionalClaimDisposition', 'Additional disposition following a claim payment made through a claim payment system.', 'Registered', '2026-05-22'::date, '2026-05-22'::date, NULL, 'Used in a pacs.008 credit transfer message to route an additional disposition following receipt of a claim payment.'),
    ('CGWV', 'CarrierGuardedWholesaleValuables', 'Transaction is a payment towards a Party for the collection of cash by the Cash in Transit company.', 'Registered', '2023-04-06'::date, '2023-04-06'::date, NULL, NULL),
    ('CIPC', 'CashInPreCredit', 'Transaction is a direct debit for a cash order of notes and/or coins.', 'Registered', '2022-11-30'::date, '2022-11-30'::date, NULL, NULL),
    ('CONC', 'CashOutNotesCoins', 'Transaction is a direct debit for a cash order of notes and/or coins.', 'Registered', '2022-11-30'::date, '2022-11-30'::date, NULL, NULL),
    ('CORT', 'TradeSettlementPayment', 'Transaction is related to settlement of a trade, eg a foreign exchange deal or a securities transaction.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('CPAY', 'ClaimPayment', 'Transaction is related to the payment of a claim though a claim payment system.', 'Registered', '2026-05-22'::date, '2026-05-22'::date, NULL, 'Used in a pacs.008 credit transfer message to route a payment through a dedicated claim resolution system to fully or partially resolve a claim.'),
    ('CRYP', 'CryptoAssets', 'Transaction is related to the purchase or sale of crypto assets.', 'Registered', '2026-05-22'::date, '2026-05-22'::date, NULL, 'To be used within payment initiations, so the paying and/or paid agent is aware of the nature of the transaction.'),
    ('CTDF', 'DoddFrank1073Payment', 'Cross border transaction initiated by US natural person that is subject to compliance with Dodd Frank 1073.', 'Registered', '2024-08-30'::date, '2024-08-30'::date, NULL, 'Category Purpose code for US Consumer Cross Border "Dodd Frank" payments. Used in pacs.008 and pacs.009 messages.'),
    ('DCRD', 'DebitCardPayment', 'Transaction is related to a payment of debit card.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('DIVI', 'Dividend', 'Transaction is the payment of dividends.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('DVPM', 'DeliverAgainstPayment', 'Code used to pre-advise the account servicer of a forthcoming deliver against payment instruction.', 'Registered', '2015-08-31'::date, '2015-08-31'::date, NULL, NULL),
    ('EPAY', 'Epayment', 'Transaction is related to ePayment.', 'Registered', '2014-12-26'::date, '2011-05-23'::date, NULL, NULL),
    ('FCDT', 'ForeignCurrencyDomesticTransfer', 'Foreign Currency Transaction that is processed between two domestic financial institutions.', 'Registered', '2022-11-30'::date, '2022-11-30'::date, NULL, NULL),
    ('FCIN', 'FeeCollectionAndInterest', 'Transaction is related to the payment of a fee and interest.', 'Registered', '2020-11-01'::date, '2020-11-01'::date, NULL, NULL),
    ('FCOL', 'FeeCollection', 'A service that is settling card transaction related fees between two parties.', 'Registered', '2012-10-08'::date, '2012-10-08'::date, NULL, NULL),
    ('GOVT', 'GovernmentPayment', 'Transaction is a payment to or from a government department.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('GP2P', 'PersontoPersonPayment', 'General Person-to-Person Payment. Debtor and Creditor are natural persons.', 'Registered', '2021-05-01'::date, '2021-05-01'::date, NULL, NULL),
    ('HEDG', 'Hedging', 'Transaction is related to the payment of a hedging operation.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('ICCP', 'IrrevocableCreditCardPayment', 'Transaction is reimbursement of credit card payment.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('IDCP', 'IrrevocableDebitCardPayment', 'Transaction is reimbursement of debit card payment.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('INTC', 'IntraCompanyPayment', 'Transaction is an intra-company payment, ie, a payment between two companies belonging to the same group.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('INTE', 'Interest', 'Transaction is the payment of interest.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('LBOX', 'LockboxTransactions', 'Transaction is related to identify cash handling via Night Safe or Lockbox by bank or vendor on behalf of a physical store.', 'Registered', '2021-05-01'::date, '2021-05-01'::date, NULL, NULL),
    ('LOAN', 'Loan', 'Transaction is related to the transfer of a loan to a borrower.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('MP2B', 'Commercial', 'Mobile P2B Payment', 'Registered', '2017-05-01'::date, '2017-05-01'::date, NULL, 'A service which enables a user to use an app on its mobile to pay a merchant or other business payees by initiating a payment message. Within this context, the account information or an alias of the payee might be transported through different channels to the app, for example QR Code, NFC, Bluetooth, other Networks.'),
    ('MP2P', 'Consumer', 'Mobile P2P Payment', 'Registered', '2017-05-01'::date, '2017-05-01'::date, NULL, 'A service which enables a user to use an app on its mobile to initiate moving funds from his/her bank account to another person''s bank account while not using the account number  but an alias information like an MSISDN as account addressing information in his/her app.'),
    ('OTHR', 'OtherPayment', 'Other payment purpose.', 'Registered', '2012-02-09'::date, '2012-02-09'::date, NULL, NULL),
    ('PENS', 'PensionPayment', 'Transaction is the payment of pension.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('RPRE', 'Represented', 'Collection used to re-present previously reversed or returned direct debit transactions.', 'Registered', '2019-05-01'::date, '2019-05-01'::date, NULL, NULL),
    ('RRCT', 'ReimbursementReceivedCreditTransfer', 'Transaction is related to a reimbursement for commercial reasons of a correctly received credit transfer.', 'Registered', '2018-11-01'::date, '2018-11-01'::date, NULL, NULL),
    ('RVPM', 'ReceiveAgainstPayment', 'Code used to pre-advise the account servicer of a forthcoming receive against payment instruction.', 'Registered', '2015-08-31'::date, '2015-08-31'::date, NULL, NULL),
    ('SALA', 'SalaryPayment', 'Transaction is the payment of salaries.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('SAVG', 'Savings', 'Transfer to / from savings or to retirement account.', 'Registered', '2024-08-30'::date, '2024-08-30'::date, NULL, 'Used to identify transfers performed between savings accounts and current accounts held at different PSPs by the same holder, in order to check that the holder of both accounts is the same.'),
    ('SECU', 'Securities', 'Transaction is the payment of securities.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('SSBE', 'SocialSecurityBenefit', 'Transaction is a social security benefit, ie payment made by a government to support individuals.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('SUPP', 'SupplierPayment', 'Transaction is related to a payment to a supplier.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, 'Recommended default')
ON CONFLICT ("Code") DO NOTHING;
INSERT INTO public."ExternalCategoryPurpose1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('SWEP', 'CashManagementSweepAccount', 'Classification: Cash Management. Transaction relates to a cash management instruction, requesting a sweep of the account of the Debtor above an agreed floor amount, up to a target or zero balance.
The purpose is to move the funds from multiple accounts to a single bank account. Funds can move domestically or across border and more than one bank can be used.', 'Registered', '2021-11-30'::date, '2021-11-30'::date, NULL, 'CR1069'),
    ('TAXS', 'TaxPayment', 'Transaction is the payment of taxes.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('TOPG', 'CashManagementTopAccount', 'Classification: Cash Management. Transaction relates to a cash management instruction, requesting to top the account of the Creditor above a certain floor amount, up to a target or zero balance. 
The floor amount, if not pre-agreed by the parties involved, may be specified.', 'Registered', '2021-11-30'::date, '2021-11-30'::date, NULL, 'CR1069'),
    ('TRAD', 'Trade', 'Transaction is related to the payment of a trade finance transaction.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('TREA', 'TreasuryPayment', 'Transaction is related to treasury operations.  E.g. financial contract settlement.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('VATX', 'ValueAddedTaxPayment', 'Transaction is the payment of value added tax.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('VOST', 'CrossborderMIPayments', 'Transaction to be processed as a domestic payment instruction originated from a foreign bank.', 'Registered', '2022-08-31'::date, '2022-08-31'::date, NULL, NULL),
    ('WHLD', 'WithHolding', 'Transaction is the payment of withholding tax.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('ZABA', 'CashManagementZeroBalanceAccount', 'Transaction relates to a cash management instruction, requesting to zero balance the account of the Debtor.
Zero Balance Accounts empty or fill the balances in accounts at the same bank, in the same country into or out of a main account each day.', 'Registered', '2021-11-30'::date, '2021-11-30'::date, NULL, 'CR1069')
ON CONFLICT ("Code") DO NOTHING;
-- Seed: ExternalChargeType1CodeValues (14 codes)
INSERT INTO public."ExternalChargeType1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('ACCM', 'AccMaintenanceFee', 'Account maintenance fee.', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, 'Billing of Correspondent Services.'),
    ('AMND', 'Amendment', 'Payment order was changed based on request to do so from the (original) sending bank or as a result of receiving amended information from the (original) sending bank.', 'Registered', '2023-08-31'::date, '2023-08-31'::date, NULL, NULL),
    ('BRKF', 'BrokerageFee', 'Fee paid to a broker for services provided.', 'Registered', '2012-05-31'::date, '2012-05-31'::date, NULL, NULL),
    ('BTCH', 'Batch', 'Fee paid for processing a batch of transactions.', 'Registered', '2012-05-31'::date, '2012-05-31'::date, NULL, NULL),
    ('CFEE', 'CancellationFee', 'Used when fees are assessed for cancellation of a payment.', 'Registered', '2023-08-31'::date, '2023-08-31'::date, NULL, NULL),
    ('CLEF', 'ClearingFee', 'Used when fees are assessed for standard processing of financial institution type transfers.', 'Registered', '2023-08-31'::date, '2023-08-31'::date, NULL, NULL),
    ('COMM', 'Commission', 'Fee paid for services provided.', 'Registered', '2012-05-31'::date, '2012-05-31'::date, NULL, NULL),
    ('DEBT', 'BorneByDebtor', 'Claim is being submitted in response to receiving a customer credit transfer with DEBT in Charge Bearer code.', 'Registered', '2023-08-31'::date, '2023-08-31'::date, NULL, NULL),
    ('INTE', 'Interest', 'Interest related charges.', 'Registered', '2023-08-31'::date, '2023-08-31'::date, NULL, NULL),
    ('INVS', 'Investigation', 'Charges related to the processing of an investigation case/inquiry.', 'Registered', '2023-08-31'::date, '2023-08-31'::date, NULL, NULL),
    ('NSTP', 'NonSTPCharges', 'Charge for a payment that required an intervention during processing.', 'Registered', '2023-08-31'::date, '2023-08-31'::date, NULL, NULL),
    ('RECH', 'ReportingCharges', 'Charge for a reporting message (camt.05X).', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, 'Billing of Correspondent Services.'),
    ('SUMM', 'Summation', 'Summation of individual fees.', 'Registered', '2012-05-31'::date, '2012-05-31'::date, NULL, NULL),
    ('TELE', 'TelecommunicationCharges', 'Charges relating to the most appropriate and efficient means of telecommunications available, for example, SWIFT, telex, telephone, facsimile, as determined by the party executing the payment instruction.', 'Registered', '2023-08-31'::date, '2023-08-31'::date, NULL, NULL)
ON CONFLICT ("Code") DO NOTHING;
-- Seed: ExternalClearingSystemIdentification1CodeValues (172 codes)
INSERT INTO public."ExternalClearingSystemIdentification1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('AD', 'AndorraClearingSystemID', 'Clearing System ID used in Andorra', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('AE', 'UnitedArabEmiratesClearingSystemID', 'Clearing System ID used in United Arab Emirates', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('AF', 'AfghanistanClearingSystemID', 'Clearing System ID used in Afghanistan', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('AI', 'AntiguaandBermudaClearingSystemID', 'Clearing System ID used in Antigua and Bermuda', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('AL', 'AlbaniaClearingSystemID', 'Clearing System ID used in Albania', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('AM', 'ArmeniaClearingSystemID', 'Clearing System ID used in Armenia', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('AO', 'AngolaClearingSystemID', 'Clearing System ID used in Angola', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('AR', 'ArgentinaClearingSystemID', 'Clearing System ID used in Argentina', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('AS', 'AmericanSamoaClearingSystemID', 'Clearing System ID used in American Samoa', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('ATBLZ', 'AustrianBankleitzahl', 'Bank Branch code used in Austria.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Austria [0-9]{5,5}'),
    ('AUBSB', 'AustralianBankStateBranchCodeBSB', 'Bank Branch code used in Australia.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Australia [0-9]{6,6}'),
    ('AW', 'ArubaClearingSystemID', 'Clearing System ID used in Aruba.', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('AZ', 'AzerbaijanClearingSystemID', 'Clearing System ID used in Azerbaijan', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('BA', 'BosniaandHerzegovinaClearingSystemID', 'Clearing System ID used in Bosnia and Herzegovina', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('BD', 'BangladeshClearingSystemID', 'Clearing System ID used in Bangladesh', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('BG', 'BulgariaClearingSystemID', 'Clearing System ID used in Bulgaria', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('BH', 'BahrainClearingSystemID', 'Clearing System ID used in Bahrain', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('BI', 'BurundiClearingSystemID', 'Clearing System ID used in Burundi', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('BL', 'SaintBarthelemyClearingSystemID', 'Clearing System ID used in Saint Barthelemy', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('BM', 'BermudaClearingSystemID', 'Clearing System ID used in Bermuda', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('BN', 'BruneiDarussalamClearingSystemID', 'Clearing System ID used in Brunei Darussalam', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('BO', 'BoliviaClearingSystemID', 'Clearing System ID used in Bolivia', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('BRISP', 'BrazilianBankIdentificationCode', 'Bank Identification code used in Brazil (ISPB).', 'Registered', '2024-08-30'::date, '2024-08-30'::date, NULL, NULL),
    ('BS', 'BahamasClearingSystemID', 'Clearing System ID used in Bahamas', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('BT', 'BhutanClearingSystemID', 'Clearing System ID used in Bhutan', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('BW', 'BotswanaClearingSystemID', 'Clearing System ID used in Botswana', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('BY', 'BelarusClearingSystemID', 'Clearing System ID used in Belarus', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('BZ', 'BelizeClearingSystemID', 'Clearing System ID used in Belize', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('CACPA', 'CanadianPaymentsAssociationPaymentRoutingNumber', 'Bank Branch code used in Canada.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Canada [0-9]{9,9}'),
    ('CBHAC', 'COMESAREPSSAccountIdentificationCode', 'REPSS (regional cross-border payment and settlement platform designed to facilitate efficient and secure intra-regional trade payments within COMESA member states) settlement account.', 'Registered', '2025-11-30'::date, '2025-11-30'::date, NULL, 'Code used for Clearing System Identification under the Financial Institution Identification section of the messages to identify a settlement account.'),
    ('CBHPA', 'COMESAREPSSParticipantIdentificationCode', 'REPSS (Regional cross-border payment and settlement platform designed to facilitate efficient and secure intra-regional trade payments within COMESA member states) participant identification code.', 'Registered', '2025-11-30'::date, '2025-11-30'::date, NULL, 'Code used for Clearing System Identification under the Financial Institution Identification section of the messages to identify a participant. COMESA stands for Common Market for Eastern and Southern Africa. REPSS stands for Regional Electronic Payments and Settlement System.'),
    ('CBPAC', 'COMESASSAccountIdentificationCode', 'COMESA SS settlement account.', 'Registered', '2025-11-30'::date, '2025-11-30'::date, NULL, 'Code used for Clearing System Identification under the Financial Institution Identification section of the messages to identify a settlement account. COMESA stands for Common Market for Eastern and Southern Africa.'),
    ('CBPPA', 'COMESASSParticipantIdentificationCode', 'COMESA SS participant identification code.', 'Registered', '2025-11-30'::date, '2025-11-30'::date, NULL, 'Code used for Clearing System Identification under the Financial Institution Identification section of the messages to identify a participant. COMESA stands for Common Market for Eastern and Southern Africa.'),
    ('CD', 'DemocraticRepublicofTheCongoClearingSystemID', 'Clearing System ID used in Democratic Republic of The Congo.', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('CEAAC', 'BankOfCentralAfricanStateParticipantAccountIdentificationCode', 'Bank Of Central African States (BEAC) Participant Account Identification Code - Financial Institution Identification used in BEAC''s SYGMA system for settlement between participants accounts in Cameroon, Central Africa Republic, Chad, Equatorial Guinea, Gabon and Republic of the Congo. In this case, it is particular to the form of electronic payment of Real Time Gross Settlement.', 'Registered', '2025-08-29'::date, '2025-08-29'::date, NULL, NULL),
    ('CEAPA', 'BankOfCentralAfricanStateParticipantIdentificationCode', 'Bank Of Central African States (BEAC) Participant Identification Code - Financial Institution Identification used in BEAC''s SYGMA system for settlement between participants in Cameroon, Central Africa Republic, Chad, Equatorial Guinea, Gabon and Republic of the Congo. In this case, it is particular to the form of electronic payment of Real Time Gross Settlement.', 'Registered', '2025-08-29'::date, '2025-08-29'::date, NULL, NULL),
    ('CHBCC', 'SwissFinancialInstitutionIdentificationShort', 'Financial Institution Identification (IID) used in Switzerland, without check digit.', 'Registered', '2016-03-01'::date, '2007-09-01'::date, NULL, 'Switzerland [0-9]{3,5}'),
    ('CHSIC', 'SwissFinancialInstitutionIdentificationLong', 'Financial Institution Identification (IID) used in Switzerland, including check digit.', 'Registered', '2016-03-01'::date, '2007-09-01'::date, NULL, 'Switzerland [0-9]{6,6}'),
    ('CL', 'ChileClearingSystemID', 'Clearing System ID used in Chile', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('CNAPS', 'CNAPSIdentifier', 'Bank Branch code used in China.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'China [0-9]{12,12}')
ON CONFLICT ("Code") DO NOTHING;
INSERT INTO public."ExternalClearingSystemIdentification1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('CNCIP', 'CrossBorderInterbankPaymentSystem', 'Chinese Cross-border Interbank Payment System (CIPS) Identifier.', 'Registered', '2022-11-30'::date, '2022-11-30'::date, NULL, 'China [0-9,A-Z]{11,11}'),
    ('CO', 'ColombiaClearingSystemID', 'Clearing System ID used in Colombia', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('CR', 'CostaRicaClearingSystemID', 'Clearing System ID used in Costa Rica', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('CV', 'CaboVerdeClearingSystemID', 'Clearing System ID used in Cabo Verde', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('CW', 'CuracaoClearingSystemID', 'Clearing System ID used in Curacao', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('CY', 'CyprusClearingSystemID', 'Clearing System ID used in Cyprus', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('CZ', 'CzechRepublicClearingSystemID', 'Clearing System ID used in Czech Republic', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('DEBLZ', 'GermanBankleitzahl', 'Bank Branch code used in Germany.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Germany [0-9]{8,8}'),
    ('DO', 'DominicanRepublicClearingSystemID', 'Clearing System ID used in Dominican Republic', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('DZ', 'AlgeriaClearingSystemID', 'Clearing System ID used in Algeria', 'Obsolete', '2026-02-28'::date, '2024-12-03'::date, NULL, NULL),
    ('DZRAC', 'AlgeriaAcсountIdentificationCode', 'Account identification code used in the RTGS system of Algeria.', 'Registered', '2025-11-30'::date, '2025-11-30'::date, NULL, 'Code used for Clearing System Identification under the Financial Institution Identification section of the messages to identify a settlement account.'),
    ('DZRPA', 'AlgeriaAgentIdentificationCode', 'Agent identification code used in the RTGS system of Algeria.', 'Registered', '2025-11-30'::date, '2025-11-30'::date, NULL, 'Code used for Clearing System Identification under the Financial Institution Identification section of the messages to identify a settlement account.'),
    ('EC', 'EcuadorClearingSystemID', 'Clearing System ID used in Ecuador', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('EE', 'EstoniaClearingSystemID', 'Clearing System ID used in Estonia', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('EGNCC', 'EgyptianNationalClearingCode', 'RTGS Clearing system Identification code used in Egypt.', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('ESNCC', 'SpanishDomesticInterbankingCode', 'Bank Branch code used in Spain.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Spain [0-9]{8,9}'),
    ('GBDSC', 'UKDomesticSortCode', 'Bank Branch code used in the UK.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'UK [0-9]{6,6}'),
    ('GE', 'GeorgiaClearingSystemID', 'Clearing System ID used in Georgia', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('GH', 'GhanaClearingSystemID', 'Clearing System ID used in Ghana', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('GN', 'GuineaClearingSystemID', 'Clearing System ID used in Guinea', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('GRBIC', 'HelenicBankIdentificationCode', 'Bank Branch code used in Greece.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Greece [0-9]{7,7}'),
    ('GT', 'GuatemalaClearingSystemID', 'Clearing System ID used in Guatemala', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('GY', 'GuyanaClearingSystemID', 'Clearing System ID used in Guyana', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('HKNCC', 'HongKongBankCode', 'Bank Branch code used in Hong Kong.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Hong Kong [0-9]{3,3}'),
    ('HN', 'HondurasClearingSystemID', 'Clearing System ID used in Honduras', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('HR', 'CroatiaClearingSystemID', 'Clearing System ID used in Croatia', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('HT', 'HaitiClearingSystemID', 'Clearing System ID used in Haiti', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('HU', 'HungaryClearingSystemID', 'Clearing System ID used in Hungary', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('ID', 'IndonesiaClearingSystemID', 'Clearing System ID used in Indonesia', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('IENCC', 'IrishNationalClearingCode', 'Bank Branch code used in Ireland.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Ireland [0-9]{6,6}'),
    ('IL', 'IsraelClearingSystemID', 'Clearing System ID used in Israel', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('INFSC', 'IndianFinancialSystemCode', 'Bank Branch code used in India.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'India [a-zA-Z0-9]{11,11}'),
    ('IQ', 'IraqClearingSystemID', 'Clearing System ID used in Iraq', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('IS', 'IcelandClearingSystemID', 'Clearing System ID used in Iceland', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('ITNCC', 'ItalianDomesticIdentificationCode', 'Bank Branch code used in Italy.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Italy [0-9]{10,10}'),
    ('JM', 'JamaicaClearingSystemID', 'Clearing System ID used in Jamaica', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('JO', 'JordanClearingSystemID', 'Clearing System ID used in Jordan', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('JPZGN', 'JapanZenginClearingCode', 'Bank Branch code used in Japan.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Japan [0-9]{7,7}'),
    ('KE', 'KenyaClearingSystemID', 'Clearing System ID used in Kenya', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('KG', 'TheKyrgyzRepublicClearingSystemID', 'Clearing System ID used in The Kyrgyz Republic', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL)
ON CONFLICT ("Code") DO NOTHING;
INSERT INTO public."ExternalClearingSystemIdentification1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('KH', 'CambodiaClearingSystemID', 'Clearing System ID used in Cambodia', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('KM', 'ComorosClearingSystemID', 'Clearing System ID used in Comoros', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('KRBOK', 'SouthKoreaCentralBankIdentificationCode', 'Participant Institution code used by BOK-Wire+ in South Korea.', 'Registered', '2023-05-31'::date, '2023-05-31'::date, NULL, 'South Korea [0-9]{4,4}'),
    ('KW', 'KuwaitClearingSystemID', 'Clearing System ID used in Kuwait', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('KZ', 'KazakhstanClearingSystemID', 'Clearing System ID used in Kazakhstan', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('LB', 'LebanonClearingSystemID', 'Clearing System ID used in Lebanon', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('LK', 'SriLankaClearingSystemID', 'Clearing System ID used in Sri Lanka', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('LR', 'LiberiaClearingSystemID', 'Clearing System ID used in Liberia', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('LS', 'LesothoClearingSystemID', 'Clearing System ID used in Lesotho', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('LT', 'LithuaniaClearingSystemID', 'Clearing System ID used in Lithuania.', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('LV', 'LatviaClearingSystemID', 'Clearing System ID used in Latvia', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('LY', 'LibyaClearingSystemID', 'Clearing System ID used in Libya', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('MA', 'MoroccoClearingSystemID', 'Clearing System ID used in Morocco', 'Obsolete', '2025-02-28'::date, '2024-12-03'::date, NULL, 'Replaced by Morocco RTGS National Clearing Code [MARAC] and Morocco RTGS Participant Identification Code [MARPA]'),
    ('MARAC', 'MoroccoRTGSNationalClearingCode', 'RTGS clearing system identification used in the Kingdom of Morocco.', 'Registered', '2025-02-28'::date, '2025-02-28'::date, NULL, 'Used for Clearing System Identification under the Financial Institution Identification section of the messages to identify a settlement account.'),
    ('MARPA', 'MoroccoRTGSParticipantIdentificationCode', 'RTGS participant identification code used in the Kingdom of Morocco.', 'Registered', '2025-02-28'::date, '2025-02-28'::date, NULL, 'Used for Clearing System Identification under the Financial Institution Identification section of the messages to identify a participant.'),
    ('MD', 'MoldovaClearingSystemID', 'Clearing System ID used in Moldova', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('ME', 'MontenegroClearingSystemID', 'Clearing System ID used in Montenegro', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('MG', 'MadagascarClearingSystemID', 'Clearing System ID used in Madagascar', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('MGRAC', 'MadagascarRTGSAccountIdentificationCode', 'RTGS account identification code used in Madagascar', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, 'The code is used for Clearing System Identification under the Financial Institution Identification section of the messages to identify a participant account.'),
    ('MGRPA', 'MadagascarRTGSParticipantIdentificationCode', 'RTGS participant identification code used in Madagascar', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, 'The code is used for Clearing System Identification under the Financial Institution Identification section of the messages to identify a participant.'),
    ('MK', 'NorthMacedoniaClearingSystemID', 'Clearing System ID used in North Macedonia', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('MN', 'MongoliaClearingSystemID', 'Clearing System ID used in Mongolia', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('MO', 'MacaoClearingSystemID', 'Clearing System ID used in Macao', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('MR', 'MauritaniaClearingSystemID', 'Clearing System ID used in Mauritania', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('MT', 'MaltaClearingSystemID', 'Clearing System ID used in Malta', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('MU', 'MauritiusClearingSystemID', 'Clearing System ID used in Mauritius', 'Obsolete', '2026-02-28'::date, '2024-12-03'::date, NULL, NULL),
    ('MUPAC', 'MauritiusRTGSAccountIdentificationCode', 'MACSS settlement account used in Mauritius.', 'Registered', '2025-11-30'::date, '2025-11-30'::date, NULL, 'Code used for Clearing System Identification under the Financial Institution Identification section of the messages to identify a settlement account.'),
    ('MUPPA', 'MauritiusRTGSParticipantIdentificationCode', 'MACSS participant identification code used in Mauritus.', 'Registered', '2025-11-30'::date, '2025-11-30'::date, NULL, 'Code used for Clearing System Identification under the Financial Institution Identification section of the messages to identify a participant.'),
    ('MW', 'MalawiClearingSystemID', 'Clearing System ID used in Malawi.', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('MX', 'MexicoClearingSystemID', 'Clearing System ID used in Mexico', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('MY', 'MalaysiaClearingSystemID', 'Clearing System ID used in Malaysia', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('MZBMO', 'BancoDeMocambiqueRTGS', 'Banco de Mocambique RTGS system.', 'Registered', '2022-11-30'::date, '2022-11-30'::date, NULL, NULL),
    ('NACSC', 'NamibiaClearingSystemCode', 'Clearing system Identification code used in Namibia.', 'Registered', '2024-08-30'::date, '2024-08-30'::date, NULL, NULL),
    ('NG', 'NigeriaClearingSystemID', 'Clearing System ID used in Nigeria', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('NI', 'NicaraguaClearingSystemID', 'Clearing System ID used in Nicaragua', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('NP', 'NepalClearingSystemID', 'Clearing System ID used in Nepal', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('NZNCC', 'NewZealandNationalClearingCode', 'Bank Branch code used in New Zealand.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'New Zealand [0-9]{6,6}'),
    ('NZRSA', 'NewZealandRTGSClearingCode', 'RTGS settlement account used in New Zealand.', 'Registered', '2021-08-31'::date, '2021-08-24'::date, NULL, 'New Zealand [0-9,A-Z]{8,15}'),
    ('OM', 'OmanClearingSystemID', 'Clearing System ID used in Oman', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('PA', 'PanamaClearingSystemID', 'Clearing System ID used in Panama', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL)
ON CONFLICT ("Code") DO NOTHING;
INSERT INTO public."ExternalClearingSystemIdentification1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('PE', 'PeruClearingSystemID', 'Clearing System ID used in Peru', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('PG', 'PapuaNewGuineaClearingSystemID', 'Clearing System ID used in Papua New Guinea', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('PH', 'PhilippinesClearingSystemID', 'Clearing System ID used in Philippines.', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('PK', 'PakistanClearingSystemID', 'Clearing System ID used in Pakistan', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('PLKNR', 'PolishNationalClearingCode', 'Bank Branch code used in Poland.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Poland [0-9]{8,8}'),
    ('PS', 'PalestineClearingSystemID', 'Clearing System ID used in Palestine', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('PTNCC', 'PortugueseNationalClearingCode', 'Bank Branch code used in Portugal.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Portugal [0-9]{8,8}'),
    ('PY', 'ParaguayClearingSystemID', 'Clearing System ID used in Paraguay.', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('QA', 'QatarClearingSystemID', 'Clearing System ID used in Qatar', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('RO', 'RomaniaClearingSystemID', 'Clearing System ID used in Romania', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('RS', 'SerbiaClearingSystemID', 'Clearing System ID used in Serbia', 'Obsolete', '2026-02-28'::date, '2024-12-03'::date, NULL, NULL),
    ('RSDAC', 'SerbiaRTGSAccountIdentificationCode', 'RTGS account identification code used in the Republic of Serbia.', 'Registered', '2025-08-29'::date, '2025-08-29'::date, NULL, 'Code is used for Clearing System Identification under the Financial Institution Identification section of the messages to identify a settlement account.'),
    ('RSDPA', 'SerbiaRTGSParticipantIdentificationCode', 'RTGS participant identification code used in the Republic of Serbia.', 'Registered', '2025-08-29'::date, '2025-08-29'::date, NULL, 'Code used for Clearing System Identification under the Financial Institution Identification section of the messages to identify a participant.'),
    ('RSEAC', 'SerbiaNationalClearingAccountIdentificationCode', 'Interbank and International Clearing of FX Payments account identification code used in the Republic of Serbia.', 'Registered', '2025-08-29'::date, '2025-08-29'::date, NULL, 'Code is used for Clearing System Identification under the Financial Institution Identification section of the messages to identify a settlement account.'),
    ('RSEPA', 'SerbiaNationalClearingParticipantIdentificationCode', 'Interbank and International Clearing of FX Payments System participant identification code used in the Republic of Serbia.', 'Registered', '2025-08-29'::date, '2025-08-29'::date, NULL, 'Code is used for Clearing System Identification under the Financial Institution Identification section of the messages to identify a participant.'),
    ('RUCBC', 'RussianCentralBankIdentificationCode', 'Bank Branch code used in Russia.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Russia [0-9]{9,9}'),
    ('RW', 'RwandaClearingSystemID', 'Clearing System ID used in Rwanda', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('SA', 'SaudiArabiaClearingSystemID', 'Clearing System ID used in Saudi Arabia', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('SC', 'SeychellesClearingSystemID', 'Clearing System ID used in Seychelles', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('SD', 'SudanClearingSystemID', 'Clearing System ID used in Sudan', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('SESBA', 'SwedenBankgiroClearingCode', 'Bank Branch code used in Sweden.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, 'Sweden [0-9]{4,4}'),
    ('SGIBG', 'IBGSortCode', 'Bank Branch code used in Singapore.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Singapore [0-9]{7,7} or [0-9]{3,4}'),
    ('SI', 'SloveniaClearingSystemID', 'Clearing System ID used in Slovenia', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('SK', 'SlovakiaClearingSystemID', 'Clearing System ID used in Slovakia.', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('SL', 'SierraLeoneClearingSystemID', 'Clearing System ID used in Sierra Leone', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('ST', 'SaoTomeandPrincipeClearingSystemID', 'Clearing System ID used in Sao Tome and Principe', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('SV', 'ElSalvadorClearingSystemID', 'Clearing System ID used in El Salvador', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('SZ', 'EswatiniClearingSystemID', 'Clearing System ID used in Eswatini.', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('THCBC', 'ThaiCentralBankIdentificationCode', 'Bank Identification code used in Thailand.', 'Registered', '2014-01-16'::date, '2014-01-16'::date, NULL, 'Thailand [0-9]{3,3}'),
    ('TJ', 'TajikistanClearingSystemID', 'Clearing System ID used in Tajikistan', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('TL', 'Timor-LesteClearingSystemID', 'Clearing System ID used in Timor-Leste', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('TM', 'TurkmenistanClearingSystemID', 'Clearing System ID used in Turkmenistan', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('TN', 'TunisiaClearingSystemID', 'Clearing System ID used in Tunisia', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('TR', 'TurkeyClearingSystemID', 'Clearing System ID used in Turkey', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('TT', 'TrinidadandTobagoClearingSystemID', 'Clearing System ID used in Trinidad and Tobago', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('TWNCC', 'FinancialInstitutionCode', 'Bank Branch code used in Taiwan.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Taiwan [0-9]{7,7}'),
    ('TZ', 'TanzaniaClearingSystemID', 'Clearing System ID used in Tanzania', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('UA', 'UkraineClearingSystemID', 'Clearing System ID used in Ukraine', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('UG', 'UgandaClearingSystemID', 'Clearing System ID used in Uganda', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('UGDAC', 'UgandaRTGSAccountIdentificationCode', 'RTGS account identification code used in the Republic of Uganda.', 'Registered', '2026-02-28'::date, '2026-02-28'::date, NULL, 'Usage: Code used for Clearing System Identification under the Financial Institution Identification section of the messages to identify a settlement account.')
ON CONFLICT ("Code") DO NOTHING;
INSERT INTO public."ExternalClearingSystemIdentification1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('UGDPA', 'UgandaRTGSParticipantIdentificationCode', 'RTGS participant identification code used in the Republic of Uganda.', 'Registered', '2026-02-28'::date, '2026-02-28'::date, NULL, 'Usage: Code used for Clearing System Identification under the Financial Institution Identification section of the messages to identify a participant.'),
    ('USABA', 'UnitedStatesRoutingNumberFedwireNACHA', 'Routing Transit number assigned by the ABA for US financial institutions.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'US [0-9]{9,9}'),
    ('USPID', 'CHIPSParticipantIdentifier', 'Bank identifier used by CHIPs in the US.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'US [0-9]{4,4}'),
    ('UY', 'UruguayClearingSystemID', 'Clearing System ID used in Uruguay', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('UZ', 'UzbekistanClearingSystemID', 'Clearing System ID used in Uzbekistan', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('VA', 'VaticanCityClearingSystemID', 'Clearing System ID used in Vatican City', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('VE', 'VenezuelaClearingSystemID', 'Clearing System ID used in Venezuela', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('VN', 'VietnamClearingSystemID', 'Clearing System ID used in Vietnam', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('XK', 'KosovoClearingSystemID', 'Clearing System ID used in Kosovo', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('ZANCC', 'SouthAfricanNationalClearingCode', 'Bank Branch code used in South Africa.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'South Africa [0-9]{6,6}'),
    ('ZM', 'ZambiaClearingSystemID', 'Clearing System ID used in Zambia', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('ZWTSS', 'ZimbabweClearingSystemCode', 'System Identification Code used in the Zimbabwe settlement system.', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL)
ON CONFLICT ("Code") DO NOTHING;
-- Seed: ExternalCreditorAgentInstruction1CodeValues (14 codes)
INSERT INTO public."ExternalCreditorAgentInstruction1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('CHQB', 'PayCreditorByCheque', '(Ultimate) creditor must be paid by cheque.', 'Registered', '2021-02-01'::date, '2021-02-01'::date, NULL, NULL),
    ('HOLD', 'HoldCashForCreditor', 'Amount of money must be held for the (ultimate) creditor, who will call. Pay on identification.', 'Registered', '2021-02-01'::date, '2021-02-01'::date, NULL, NULL),
    ('PHOB', 'PhoneBeneficiary', 'Please advise/contact (ultimate) creditor/claimant by phone.', 'Registered', '2021-02-01'::date, '2021-02-01'::date, NULL, NULL),
    ('PRTK', 'PayerTokenRequested', 'Indicates that a payer token is requested/used.', 'Registered', '2021-02-01'::date, '2021-02-01'::date, NULL, NULL),
    ('RECI', 'ReceiverCustomerInformation', 'Further information regarding the intended recipient.', 'Registered', '2021-02-01'::date, '2021-02-01'::date, NULL, NULL),
    ('SEID', 'SecondaryIdentification', 'Use of Secondary Identification of Creditor Account (which may relate to Head Office Collection Account, Building Society Roll Number or Credit Card Primary Account Number).', 'Registered', '2023-08-31'::date, '2023-08-31'::date, NULL, NULL),
    ('TELB', 'Telecom', 'Please advise/contact (ultimate) creditor/claimant by the most efficient means of telecommunication.', 'Registered', '2021-02-01'::date, '2021-02-01'::date, NULL, NULL),
    ('TKCM', 'TokenCounterpartyMismatch', 'Token found with counterparty mismatch.', 'Registered', '2021-02-01'::date, '2021-02-01'::date, NULL, NULL),
    ('TKSG', 'TokenSingleUse', 'Single Use Token already used.', 'Registered', '2021-02-01'::date, '2021-02-01'::date, NULL, NULL),
    ('TKSP', 'TokenSuspended', 'Token found with suspended status.', 'Registered', '2021-02-01'::date, '2021-02-01'::date, NULL, NULL),
    ('TKVE', 'TokenValueLimitExceeded', 'Token found with value limit rule violation.', 'Registered', '2021-02-01'::date, '2021-02-01'::date, NULL, NULL),
    ('TKXP', 'TokenExpired', 'Token expired.', 'Registered', '2021-02-01'::date, '2021-02-01'::date, NULL, NULL),
    ('TOKN', 'Token', 'Token information.', 'Registered', '2021-02-01'::date, '2021-02-01'::date, NULL, NULL),
    ('VLTK', 'TokenValidation', 'Additional validation information to be used in conjunction with the token.', 'Registered', '2021-02-01'::date, '2021-02-01'::date, NULL, NULL)
ON CONFLICT ("Code") DO NOTHING;
-- Seed: ExternalCreditorReferenceType1CodeValues (7 codes)
INSERT INTO public."ExternalCreditorReferenceType1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('DISP', 'DispatchAdvice', 'Document is a dispatch advice.', 'Registered', '2024-02-28'::date, '2024-02-28'::date, NULL, NULL),
    ('FXDR', 'ForeignExchangeDealReference', 'Document is a pre-agreed or pre-arranged foreign exchange transaction to which the payment transaction refers.', 'Registered', '2024-02-28'::date, '2024-02-28'::date, NULL, NULL),
    ('PRNB', 'PaymentReferenceNumber', 'Document is a payment reference number used to identify, match, or reconcile the referred contribution payment or related remittance information.', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, '1. Payment type is associated with a contribution made towards the employee''s retirement funds known as Super Annuation Fund in Australia. 2. In accordance with Australian Taxation Office (ATO) guidelines, a unique Payment Reference Number (PRN) must be generated by the employer (payer) to associate superannuation payment transactions with the corresponding employee superannuation information. This unique PRN enables accurate tracking and reconciliation of contributions. 3. This mandatory PRN information is consumed by Super Annuation Funds to reconcile the payment against the associated reporting instructions standards dictated by ATO.'),
    ('PUOR', 'PurchaseOrder', 'Document is a purchase order.', 'Registered', '2024-02-28'::date, '2024-02-28'::date, NULL, NULL),
    ('RADM', 'RemittanceAdviceMessage', 'Document is a remittance advice sent separately from the current transaction.', 'Registered', '2024-02-28'::date, '2024-02-28'::date, NULL, NULL),
    ('RPIN', 'RelatedPaymentInstruction', 'Document is a linked payment instruction to which the current payment instruction is related, for example, in a cover scenario.', 'Registered', '2024-02-28'::date, '2024-02-28'::date, NULL, NULL),
    ('SCOR', 'StructuredCommunicationReference', 'Document is a structured communication reference provided by the creditor to identify the referred transaction.', 'Registered', '2024-02-28'::date, '2024-02-28'::date, NULL, NULL)
ON CONFLICT ("Code") DO NOTHING;
-- Seed: ExternalDateType1CodeValues (5 codes)
INSERT INTO public."ExternalDateType1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('INDA', 'InvoiceDate', 'Relates to the invoice date.', 'Registered', '2024-02-28'::date, '2024-02-28'::date, NULL, NULL),
    ('NTAV', 'NotAvailable', 'Date type is not available.', 'Registered', '2024-02-28'::date, '2024-02-28'::date, NULL, NULL),
    ('NXBD', 'NextBillingDate', 'Relates to the next billing date.', 'Registered', '2024-02-28'::date, '2024-02-28'::date, NULL, NULL),
    ('PADD', 'PaymentDueDate', 'Relates to the payment due date.', 'Registered', '2024-02-28'::date, '2024-02-28'::date, NULL, NULL),
    ('PYDT', 'PayrollDate', 'Relates to the payroll date.', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, NULL)
ON CONFLICT ("Code") DO NOTHING;
-- Seed: ExternalDocumentAmountType1CodeValues (27 codes)
INSERT INTO public."ExternalDocumentAmountType1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('APDS', 'AdditionalPromotionalDiscount', 'Addition discount based on third-party agreed business promotional activity, i.e., extra 10 percent discount for 15 days)', 'Registered', '2024-02-28'::date, '2024-02-28'::date, NULL, NULL),
    ('CHAR', 'NewCharges', 'Amount is new charges, for example new charges on a credit card.', 'Registered', '2024-02-28'::date, '2024-02-28'::date, NULL, NULL),
    ('CITY', 'CityTax', 'Tax accessed by city jurisdictions within a country.', 'Registered', '2024-02-28'::date, '2024-02-28'::date, NULL, NULL),
    ('CNTY', 'CountyTax', 'Tax accessed by county jurisdictions within a country.', 'Registered', '2024-02-28'::date, '2024-02-28'::date, NULL, NULL),
    ('CREN', 'CreditNote', 'Amount is a credit note.', 'Registered', '2024-02-28'::date, '2024-02-28'::date, NULL, NULL),
    ('CRTL', 'AvailableCredit', 'Amount is available credit.', 'Registered', '2024-02-28'::date, '2024-02-28'::date, NULL, NULL),
    ('DISC', 'DiscountApplied', 'Discount Applied. Generic usage if cannot be specified by any other discount code.', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, NULL),
    ('DUPA', 'DuePayable', 'Amount is due payable.', 'Registered', '2024-02-28'::date, '2024-02-28'::date, NULL, NULL),
    ('ESCO', 'Escrow', 'Amount is in escrow.', 'Registered', '2024-02-28'::date, '2024-02-28'::date, NULL, NULL),
    ('FEES', 'Fees', 'Amount is fees.', 'Registered', '2024-02-28'::date, '2024-02-28'::date, NULL, NULL),
    ('INSU', 'Insurance', 'Amount is insurance.', 'Registered', '2024-02-28'::date, '2024-02-28'::date, NULL, NULL),
    ('INTC', 'InterestCharges', 'Amount is interest charges, or example interest charges on a credit card.', 'Registered', '2024-02-28'::date, '2024-02-28'::date, NULL, NULL),
    ('INTE', 'InterestPayment', 'Amount is the interest.', 'Registered', '2024-02-28'::date, '2024-02-28'::date, NULL, NULL),
    ('LOCL', 'LocalTax', 'Tax accessed by local jurisdictions within a country.', 'Registered', '2024-02-28'::date, '2024-02-28'::date, NULL, NULL),
    ('MIDU', 'MinimumDue', 'Amount is the minimum due.', 'Registered', '2024-02-28'::date, '2024-02-28'::date, NULL, NULL),
    ('OBAL', 'OutstandingBalance', 'Amount is the outstanding balance.', 'Registered', '2024-02-28'::date, '2024-02-28'::date, NULL, NULL),
    ('PADU', 'PastDue', 'Amount is past due.', 'Registered', '2024-02-28'::date, '2024-02-28'::date, NULL, NULL),
    ('PBAL', 'PreviousBalance', 'Amount is the previous balance.', 'Registered', '2024-02-28'::date, '2024-02-28'::date, NULL, NULL),
    ('PRIN', 'OutstandingPrincipal', 'Amount is the outstanding principal.', 'Registered', '2024-02-28'::date, '2024-02-28'::date, NULL, NULL),
    ('PROV', 'ProvinceTax', 'Tax accessed by province jurisdictions within a country.', 'Registered', '2024-02-28'::date, '2024-02-28'::date, NULL, NULL),
    ('REMI', 'Remitted', 'Amount remitted.', 'Registered', '2024-02-28'::date, '2024-02-28'::date, NULL, NULL),
    ('SBAL', 'StatementBalance', 'Amount is the statement balance.', 'Registered', '2024-02-28'::date, '2024-02-28'::date, NULL, NULL),
    ('STAT', 'StateTax', 'Tax accessed by state jurisdictions within a country.', 'Registered', '2024-02-28'::date, '2024-02-28'::date, NULL, NULL),
    ('STDS', 'StandingDiscount', 'Discount based on volume purchased.', 'Registered', '2024-02-28'::date, '2024-02-28'::date, NULL, NULL),
    ('TAXS', 'Tax', 'Amount is tax.', 'Registered', '2024-02-28'::date, '2024-02-28'::date, NULL, NULL),
    ('TMDS', 'TermsDiscount', 'Discount based on terms negotiated for payment within a specified time period, i.e., 2/10 Net 30 (2 percent discount if paid in 10 days; otherwise, net amount is due in 30 days).', 'Registered', '2024-02-28'::date, '2024-02-28'::date, NULL, NULL),
    ('TOTA', 'TotalPayment', 'Amount is the total.', 'Registered', '2024-02-28'::date, '2024-02-28'::date, NULL, NULL)
ON CONFLICT ("Code") DO NOTHING;
-- Seed: ExternalDocumentLineType1CodeValues (19 codes)
INSERT INTO public."ExternalDocumentLineType1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('ADPI', 'AdditionalProductIdentificationAssignedByTheManufacturer', 'Line item reference is an additional product identification assigned by the manufacturer.', 'Registered', '2014-04-17'::date, '2014-04-17'::date, NULL, NULL),
    ('AISB', 'AlternateISBN', 'Line item reference is an alternate International Standard Book Number (ISBN).', 'Registered', '2014-04-17'::date, '2014-04-17'::date, NULL, NULL),
    ('ASNB', 'AssetNumber', 'Line item reference is an asset number.', 'Registered', '2014-04-17'::date, '2014-04-17'::date, NULL, NULL),
    ('CTNB', 'CatalogNumber', 'Line item reference is a catalog number.', 'Registered', '2014-04-17'::date, '2014-04-17'::date, NULL, NULL),
    ('DBSP', 'DunBradstreetStandardProductAndServiceCode', 'Line item reference is Dun & Bradstreet Standard Product and Service code.', 'Registered', '2014-04-17'::date, '2014-04-17'::date, NULL, NULL),
    ('EANN', 'EuropeanArticleNumberEAN2551', 'Line item reference is an European Article Number (EAN).', 'Registered', '2014-04-17'::date, '2014-04-17'::date, NULL, NULL),
    ('EINB', 'EquipmentIdentificationNumber', 'Line item reference is an equipment identification number.', 'Registered', '2014-04-17'::date, '2014-04-17'::date, NULL, NULL),
    ('GSNB', 'GeneralSpecificationNumber', 'Line item reference is a general specification number.', 'Registered', '2014-04-17'::date, '2014-04-17'::date, NULL, NULL),
    ('HIBC', 'HIBCHealthCareIndustryBarCode', 'Line item reference is a Health Care Industry Bar Code (HIBC)', 'Registered', '2014-04-17'::date, '2014-04-17'::date, NULL, NULL),
    ('ISBN', 'InternationalStandardBookNumberISBN', 'Line item reference is an International Standard Book Number (ISBN).', 'Registered', '2014-04-17'::date, '2014-04-17'::date, NULL, NULL),
    ('LTNB', 'LotNumber', 'Line item reference is a lot number.', 'Registered', '2014-04-17'::date, '2014-04-17'::date, NULL, NULL),
    ('MDNB', 'ModelNumber', 'Line item reference is a model number', 'Registered', '2014-04-17'::date, '2014-04-17'::date, NULL, NULL),
    ('PRNB', 'PartNumber', 'Line item reference is a part reference number.', 'Registered', '2014-04-17'::date, '2014-04-17'::date, NULL, NULL),
    ('PTCD', 'ProductTypeCode', 'Line item reference is a product type code.', 'Registered', '2014-04-17'::date, '2014-04-17'::date, NULL, NULL),
    ('SKNB', 'StockNumber', 'Line item reference is a stock number.', 'Registered', '2014-04-17'::date, '2014-04-17'::date, NULL, NULL),
    ('STNB', 'StyleNumber', 'Line item reference is a style number.', 'Registered', '2014-04-17'::date, '2014-04-17'::date, NULL, NULL),
    ('TONB', 'TechnicalOrderNumber', 'Line item reference is a technical order number.', 'Registered', '2014-04-17'::date, '2014-04-17'::date, NULL, NULL),
    ('UPCC', 'UPCConsumerPackageCode', 'Line item reference is an UPC consumer package code.', 'Registered', '2014-04-17'::date, '2014-04-17'::date, NULL, NULL),
    ('UPNB', 'UniversalProductNumber', 'Line item reference is an Universal Product Number.', 'Registered', '2014-04-17'::date, '2014-04-17'::date, NULL, NULL)
ON CONFLICT ("Code") DO NOTHING;
-- Seed: ExternalDocumentType1CodeValues (23 codes)
INSERT INTO public."ExternalDocumentType1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('AROI', 'AccountReceivableOpenItem', 'Document is a payment that applies to a specific source document.', 'Registered', '2024-02-28'::date, '2024-02-28'::date, NULL, NULL),
    ('BOLD', 'BillOfLading', 'Document is a shipping notice.', 'Registered', '2024-02-28'::date, '2024-02-28'::date, NULL, NULL),
    ('CINV', 'CommercialInvoice', 'Document is an invoice.', 'Registered', '2010-11-30'::date, '2010-11-30'::date, NULL, NULL),
    ('CMCN', 'CommercialContract', 'Document is an agreement between the parties, stipulating the terms and conditions of the delivery of goods or services.', 'Registered', '2024-02-28'::date, '2024-02-28'::date, NULL, NULL),
    ('CNFA', 'CreditNoteRelatedToFinancialAdjustment', 'Document is a credit note for the final amount settled for a commercial transaction.', 'Registered', '2010-11-30'::date, '2010-11-30'::date, NULL, NULL),
    ('CONT', 'Contract', 'Document is a contract evidencing an agreement between the seller and buyer for the supply of goods and/or services.', 'Registered', '2010-11-30'::date, '2010-11-30'::date, NULL, NULL),
    ('CREN', 'CreditNote', 'Document is a credit note.', 'Registered', '2010-11-30'::date, '2010-11-30'::date, NULL, NULL),
    ('DEBN', 'DebitNote', 'Document is a debit note.', 'Registered', '2010-11-30'::date, '2010-11-30'::date, NULL, NULL),
    ('DISP', 'DispatchAdvice', 'Document is an advice of dispatch of the goods.', 'Registered', '2010-11-30'::date, '2010-11-30'::date, NULL, NULL),
    ('DNFA', 'DebitNoteRelatedToFinancialAdjustment', 'Document is a debit note for the final amount settled for a commercial transaction.', 'Registered', '2010-11-30'::date, '2010-11-30'::date, NULL, NULL),
    ('HIRI', 'HireInvoice', 'Document is an invoice for the hiring of human resources or renting goods or equipment.', 'Registered', '2010-11-30'::date, '2010-11-30'::date, NULL, NULL),
    ('INVS', 'InvoiceSigned', 'Document is a signed invoice.', 'Registered', '2010-11-30'::date, '2010-11-30'::date, NULL, NULL),
    ('MSIN', 'MeteredServiceInvoice', 'Document is an invoice claiming payment for the supply of metered services, eg. Gas or electricity, supplied to a fixed meter.', 'Registered', '2010-11-30'::date, '2010-11-30'::date, NULL, NULL),
    ('PROF', 'ProformaInvoice', 'In trade transactions, a pro forma invoice is a document that states a commitment from the seller to sell goods to the buyer at specified prices and terms. It is used to declare the value of the trade. It is not a true invoice, because it is not used to record accounts receivable for the seller and accounts payable for the buyer.', 'Registered', '2010-11-30'::date, '2010-11-30'::date, NULL, NULL),
    ('PUOR', 'PurchaseOrder', 'Document is a purchase order.', 'Registered', '2010-11-30'::date, '2010-11-30'::date, NULL, NULL),
    ('QUOT', 'Quotation', 'Document is a quotation setting out the conditions under which the goods and/or services are offered.', 'Registered', '2010-11-30'::date, '2010-11-30'::date, NULL, NULL),
    ('SBIN', 'SelfBilledInvoice', 'Document is a statement of the transactions posted to the debtor''s account at the supplier.', 'Registered', '2010-11-30'::date, '2010-11-30'::date, NULL, NULL),
    ('SOAC', 'StatementOfAccount', 'Document is a statement of the transactions posted to the debtor''s account at the supplier.', 'Registered', '2024-02-28'::date, '2024-02-28'::date, NULL, NULL),
    ('SPRR', 'SellerPresentment', 'Document is a document presented by the seller in support of the procurement of goods and/or services.', 'Registered', '2010-11-30'::date, '2010-11-30'::date, NULL, NULL),
    ('TISH', 'TimeSheet', 'Document is a timesheet recording times for the provision of services and/or delivery of goods.', 'Registered', '2010-11-30'::date, '2010-11-30'::date, NULL, NULL),
    ('TSUT', 'TradeServicesUtilityTransaction', 'Document is a transaction identifier as assigned by the Trade Services Utility.', 'Registered', '2024-02-28'::date, '2024-02-28'::date, NULL, NULL),
    ('USAR', 'UsageReport', 'Document is a usage report indicating the consumption pattern for designated goods and/or services.', 'Registered', '2010-11-30'::date, '2010-11-30'::date, NULL, NULL),
    ('VCHR', 'Voucher', 'Document is an electronic payment document.', 'Registered', '2024-02-28'::date, '2024-02-28'::date, NULL, NULL)
ON CONFLICT ("Code") DO NOTHING;
-- Seed: ExternalFinancialInstitutionIdentification1CodeValues (0 codes)
-- No codes currently published for ExternalFinancialInstitutionIdentification1Code in the 1Q2026 registry --
-- it is a registered/defined code set with zero enumerated values
-- this quarter (confirmed via the registry's "CodeSetsDefinition" sheet,
-- Status: Registered). Table intentionally left empty.
-- Seed: ExternalGarnishmentType1CodeValues (3 codes)
INSERT INTO public."ExternalGarnishmentType1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('GNCS', 'GarnishmentForChildSupport', 'Garnishment from a third party payer for Child Support', 'Registered', '2014-04-17'::date, '2014-04-17'::date, NULL, NULL),
    ('GNDP', 'GarnishmentForChildSupportFromDirectPayer', 'Garnishment from a direct payer for Child Support', 'Registered', '2014-04-17'::date, '2014-04-17'::date, NULL, NULL),
    ('GTPP', 'GarnishmentToTaxingAgency', 'Garnishment from a third party payer to taxing agency', 'Registered', '2014-04-17'::date, '2014-04-17'::date, NULL, NULL)
ON CONFLICT ("Code") DO NOTHING;
-- Seed: ExternalLocalInstrument1CodeValues (115 codes)
INSERT INTO public."ExternalLocalInstrument1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('0000', 'BusinessPayment', 'Transaction is related to business payment', 'Obsolete', '2018-03-01'::date, '2007-09-01'::date, NULL, 'Retired code. Do not use'),
    ('0001', 'ConvertedBankPayment', 'Transaction is related to converted (bank) payment.
Conversion of physical instrument to electonric form for transmission to the paying bank and where the original paper document does not continue in the clearing process.The instrument rules change upon conversion.', 'Obsolete', '2018-03-01'::date, '2007-09-01'::date, NULL, 'Retired code. Do not use'),
    ('0002', 'StandingOrder', 'Transaction is related to standing order.', 'Obsolete', '2018-03-01'::date, '2007-09-01'::date, NULL, 'Retired code. Do not use'),
    ('0090', 'MassPaymentBeneficiary', 'Transaction is related to mass payment beneficiary.', 'Obsolete', '2018-03-01'::date, '2007-09-01'::date, NULL, 'Retired code. Do not use'),
    ('0091', 'MassPaymentOurs', 'Transaction is related to mass payment ours.', 'Obsolete', '2018-03-01'::date, '2007-09-01'::date, NULL, 'Retired code. Do not use'),
    ('0092', 'MassPaymentShared', 'Transaction is related to mass payment shared.', 'Obsolete', '2018-03-01'::date, '2007-09-01'::date, NULL, 'Retired code. Do not use'),
    ('0220', 'StandingAuthorisationGeneral', 'Transaction is related to standing authorisation general.', 'Obsolete', '2018-03-01'::date, '2007-09-01'::date, NULL, 'Retired code. Do not use'),
    ('0221', 'OneOffAuthorisation', 'Transaction is related to one-off authorisation.', 'Obsolete', '2018-03-01'::date, '2007-09-01'::date, NULL, 'Retired code. Do not use'),
    ('0222', 'StandingAuthorisationCompanies', 'Transaction is related to standing authorisation companies.', 'Obsolete', '2018-03-01'::date, '2007-09-01'::date, NULL, 'Retired code. Do not use'),
    ('0223', 'StandingAuthorisationLotteries', 'Transaction is related to standing authorisation lotteries.', 'Obsolete', '2018-03-01'::date, '2007-09-01'::date, NULL, 'Retired code. Do not use'),
    ('0224', 'OneOffAuthorisationCharities', 'Transaction is related to one-off authorisation charities.', 'Obsolete', '2018-03-01'::date, '2007-09-01'::date, NULL, 'Retired code. Do not use'),
    ('0225', 'OneOffAuthorisationTuitionFees', 'Transaction is related to one-off authorisation tuition fees.', 'Obsolete', '2018-03-01'::date, '2007-09-01'::date, NULL, 'Retired code. Do not use'),
    ('0226', 'OneOffAuthorisationConstructionIndustry', 'Transaction is related to one-off authorisation construction industry.', 'Obsolete', '2018-03-01'::date, '2007-09-01'::date, NULL, 'Retired code. Do not use'),
    ('0227', 'StandingAuthorisationCompaniesWithoutDebtorRevocationRight', 'Transaction is related to standing authorisation companies without debtor revocation right.', 'Obsolete', '2018-03-01'::date, '2007-09-01'::date, NULL, 'Retired code. Do not use'),
    ('04', 'PreauthorisedDirectDebitDE', 'Transaction is related to a direct debit that is pre authorised (Abbuchungsauftrag).', 'Registered', '2020-05-01'::date, '2012-02-09'::date, NULL, 'EMEA,DE,EUR,Domestic DE,DD,Both'),
    ('05', 'NonPreauthorisedDirectDebitDE', 'Transaction is related to a direct debit that is not pre authorised (Einzugsermächtigung).', 'Registered', '2020-05-01'::date, '2012-02-09'::date, NULL, 'EMEA,DE,EUR,Domestic DE,DD,Both'),
    ('08', 'PreauthorisedDirectDebitOrdinaireNormalClearing4Day', 'Transaction is related to a direct debit that is pre authorised (Avis de Prélèvement).', 'Registered', '2012-02-09'::date, '2012-02-09'::date, NULL, 'EMEA,FR,EUR,Domestic FR,DD,Both'),
    ('19', 'BusinessToCustomerDirectDebit', 'Transaction is related to a business-to-customer direct debit (CSB19).', 'Registered', '2012-02-09'::date, '2012-02-09'::date, NULL, 'EMEA,ES,EUR,Domestic ES,DD,Both'),
    ('58', 'BusinessToBusinessDirectDebit', 'Transaction is related to a business-to-business direct debit (CSB58).', 'Registered', '2012-02-09'::date, '2012-02-09'::date, NULL, 'EMEA,ES,EUR,Domestic ES,DD,Both'),
    ('60', 'RecoveredBillofExchangeorPromissoryNote', 'LCR - Lettre de Change Relevé (Recovered Bill of Exchange) and BOR - Billet à Orde Relevé (Promissory Note)', 'Registered', '2012-02-09'::date, '2012-02-09'::date, NULL, 'EMEA,FR,EUR,Domestic FR,Other,Both'),
    ('82', 'NonPreauthorisedDirectDebitAT', 'Transaction is related to a direct debit that is not pre authorised (Einzugsermächtigung).', 'Registered', '2020-05-01'::date, '2012-02-09'::date, NULL, 'EMEA,AT,EUR, Domestic AT,DD,Both'),
    ('83', 'PreauthorisedDirectDebitAT', 'Transaction is related to a direct debit that is pre authorised (Abbuchungsauftrag).', 'Registered', '2020-05-01'::date, '2012-02-09'::date, NULL, 'EMEA,AT,EUR, Domestic AT,DD,Both'),
    ('85', 'PreauthorisedDirectDebitAccéléréAcceleratedClearing2DayOrdinaireNormalClearing4Day', 'Transaction is related to an urgent direct debit that is pre authorised (Avis de Prélèvement accéléré).', 'Registered', '2012-02-09'::date, '2012-02-09'::date, NULL, 'EMEA,FR,EUR,Domestic FR,DD,Both'),
    ('89', 'PreauthorisedDirectDebitVérifiéVerifiedClearing', 'Transaction is related to an urgent direct debit that is pre authorised (Avis de Prélèvement vérifié).', 'Registered', '2012-02-09'::date, '2012-02-09'::date, NULL, 'EMEA,FR,EUR,Domestic FR,DD,Both'),
    ('ACCEPT', 'PaymentViaAcceptgiroOwnedByCurrence', 'Transaction is related to payments via Acceptgiro owned by Currence.', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, 'EMEA,NL,EUR,All,CT'),
    ('ADD', 'AuthenticatedDirectDebit', 'Transaction is authenticated direct debit for domestic use.', 'Registered', '2019-11-01'::date, '2016-11-18'::date, NULL, 'GLOBAL,GLOBAL,All,All,DD,Bot'),
    ('ARC', 'AccountsReceivableCheck', 'Transaction is related to accounts receivable check.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'WHEM,US,USD,NACHA,DD,Both'),
    ('ASTI', 'AncillarySystemTransferInitiation', 'Indicates that the payment is sent by an authorized third party on behalf of the participant.', 'Registered', '2018-05-01'::date, '2018-05-01'::date, NULL, 'EMEA,EU,All,EMIP,CT,B2B'),
    ('B2B', 'SEPABusinessToBusinessDirectDebit', 'Transaction is related to SEPA business to business direct debit.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, 'EMEA,SEPA,EUR,PEACH,DD'),
    ('B2BAMIPM', 'SEPAB2BDirectDebitAMI', 'SEPA B2B Direct Debit AMI based on a paper mandate', 'Registered', '2011-12-02'::date, '2011-12-02'::date, NULL, 'EMEA,SEPA,EUR,PEACH,DD'),
    ('BACP', 'BackupPayment', 'Indicates that the payment was initiated manually using a GUI (Graphical User Interface).', 'Registered', '2018-05-01'::date, '2018-05-01'::date, NULL, 'EMEA,EU,All,EMIP,CT,B2B'),
    ('BPA', 'BatchPaymentsAruba', 'Transaction is related to an Instant Credit Transfer under the rules of the Centrale Bank van Aruba, based on the EPC SCT Inst scheme, with a specific batch time-out delay.', 'Registered', '2018-11-01'::date, '2018-11-01'::date, NULL, 'Caribbean,AW,AWG,All,CT,Both'),
    ('BSE', 'PaperlessChequeCollection', 'Transaction is related to the German Paperless Cheque Collection procedure "Belegloser Scheckeinzug - BSE"', 'Registered', '2015-08-31'::date, '2015-08-31'::date, NULL, 'EMEA,DE,EUR,Domestic DE,Other,Bk2Bk'),
    ('BTR', 'BankTransfer', 'Transaction is related to a bank transfer.', 'Obsolete', '2018-11-01'::date, '2011-08-31'::date, NULL, 'Retired code. Do not use'),
    ('CARD', 'CardClearing', 'Transaction is related to card clearing.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, 'EMEA,DE,EUR,All,Both'),
    ('CCD', 'CashConcentrationOrDisbursementCorporateCounterparty', 'Transaction is related to cash concentration or disbursement corporate counterparty.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'WHEM,US,USD,NACHA,Both plus prenote.,Both'),
    ('CCI', 'CashConcentrationIntragroup', 'Transaction is related to an intra-group bank initiated cash management payment', 'Registered', '2011-12-02'::date, '2011-12-02'::date, NULL, 'GLOBAL,GLOBAL,All,All,DD, CT and CPAR'),
    ('CHN', 'TruncatedChecks', 'Transaction is related to truncated checks.
Conversion of physical instrument to electonric form for transmission to the paying bank and where the original paper document does not continue in the clearing process..The original instrument rules are retained throughout the life of the instrument.', 'Registered', '2011-12-02'::date, '2007-09-01'::date, NULL, 'EMEA,AT,EUR,correspondent banking,DD'),
    ('CIE', 'CustomerInitiatedEntry', 'A credit entry initiated by or on behalf of the holder of a consumer account', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, 'WHEM,US,USD,NACHA,CT,Both'),
    ('CKS', 'CheckSameDaySettlementWire', 'Transaction is related to check same day settlement wire.', 'Obsolete', '2018-11-01'::date, '2009-04-01'::date, NULL, 'Retired code. Do not use')
ON CONFLICT ("Code") DO NOTHING;
INSERT INTO public."ExternalLocalInstrument1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('CLSCCPERX', 'CLSClearedFXForEurex', 'Transaction is related to the CLSClearedFX service for Eurex.  
Usage: The code is mandatory for all pacs.009 payments to this service.', 'Registered', '2021-02-01'::date, '2021-02-01'::date, NULL, 'GLOBAL,GLOBAL,All,All,CT,B2B'),
    ('CLSCCPLCH', 'CLSClearedFXForLCH', 'Transaction is related to the CLSClearedFX service for London Exchange Clearing House. 
Usage: The code is mandatory for all pacs.009 payments to this service.', 'Registered', '2021-02-01'::date, '2021-02-01'::date, NULL, 'GLOBAL,GLOBAL,All,All,CT,B2B'),
    ('COR1', 'SEPADirectDebit1DaySettlement', 'Optional shorter time cycle (D-1) for SEPA Core Direct Debit', 'Registered', '2011-12-02'::date, '2011-12-02'::date, NULL, 'EMEA,SEPA,EUR,PEACH,DD'),
    ('CORAMIPM', 'SEPACoreDirectDebitAMI', 'SEPA Core Direct Debit AMI based on a paper mandate', 'Registered', '2011-12-02'::date, '2011-12-02'::date, NULL, 'EMEA,SEPA,EUR,PEACH,DD'),
    ('CORE', 'SEPADirectDebitCore', 'Transaction is related to SEPA direct debit -core.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, 'EMEA,SEPA,EUR,PEACH,DD,Both'),
    ('CPP', 'CashPerPost', 'Transaction is related to cash per post.
Transaction to ultimate recipient having no bank account. Primary beneficiary is a postal service provider. Funds are paid out by cash. Additional necessary information for address and delivery options need to be attached.', 'Registered', '2011-12-02'::date, '2007-09-01'::date, NULL, 'EMEA,AT,EUR,correspondent banking,CT'),
    ('CR1AMIPM', 'SEPACoreD1DirectDebitAMI', 'Optional shorter time cycle (D-1) for SEPA Core Direct Debit AMI based on a paper mandate', 'Registered', '2011-12-02'::date, '2011-12-02'::date, NULL, 'EMEA,SEPA,EUR,PEACH,DD'),
    ('CTP', 'CustomerTransferPlus', 'Transaction is related to a customer transfer, which may include information related to a cover payment or extended remittance information.', 'Obsolete', '2018-11-01'::date, '2009-04-01'::date, NULL, 'Retired code. Do not use'),
    ('CTR', 'CustomerTransfer', 'Transaction is related to customer transfer.', 'Obsolete', '2018-11-01'::date, '2009-04-01'::date, NULL, 'Retired code. Do not use'),
    ('CTX', 'CorporateTradeExchange', 'Transaction is related to corporate trade exchange.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'WHEM,US,USD,NACHA,Both plus prenote.,Both'),
    ('DDFA', 'DirectDebitFixedAmount', 'SEPA Fixed Amount Direct Debit', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, 'EMEA,SEPA,EUR,PEACH,DD,B2B'),
    ('DDMC', 'DirectDebitConfirmedElectronicMandate', 'Transaction is related to a direct debit instruction authorized under a confirmed electronic mandate.', 'Registered', '2017-02-08'::date, '2017-02-01'::date, NULL, 'APAC,HK,All,eDDA,DD,Both'),
    ('DDMP', 'DirectDebitPaperMandateWithPaperAuthorization', 'Transaction is related to a direct debit instruction authorized under a paper based mandate, supported by paper authorization signed by the debtor.', 'Registered', '2017-02-08'::date, '2017-02-01'::date, NULL, 'APAC,HK,All,eDDA,DD,Both'),
    ('DDMU', 'DirectDebitUnconfirmedElectronicMandate', 'Transaction is related to a direct debit instruction authorized under an unconfirmed electronic mandate requiring confirmation by the debtor.', 'Registered', '2017-02-08'::date, '2017-02-01'::date, NULL, 'APAC,HK,All,eDDA,DD,Both'),
    ('DDNR', 'CoreNoRefund', 'SEPA Core Direct Debit with ''no refund'' option', 'Registered', '2010-08-01'::date, '2010-01-01'::date, 'DDFA', 'EMEA,SEPA,EUR,PEACH,DD,B2B'),
    ('DDT', 'DirectDebits', 'Transaction is related to direct debits.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'EMEA,AT,EUR,correspondent banking,DD'),
    ('DEP', 'DepositToSendersAccount', 'Transaction is related to deposit to sender''s account.', 'Obsolete', '2018-11-01'::date, '2009-04-01'::date, NULL, 'Retired code. Do not use'),
    ('DRB', 'BankToBankDrawdownRequestOrResponseNonvalue', 'Transaction is related to bank-to-bank drawdown request or response (non-value)', 'Obsolete', '2018-11-01'::date, '2009-04-01'::date, NULL, 'Retired code. Do not use'),
    ('DRC', 'CustomerOrCorporateDrawdownRequestOrResponseNonvalue', 'Transaction is related to customer or corporate drawdown request or response (non-value).', 'Obsolete', '2018-11-01'::date, '2007-09-01'::date, NULL, 'Retired code. Do not use'),
    ('DRW', 'DrawdownResponseValueToHonorADrawdownRequest', 'Transaction is related to drawdown response (value) to honor a drawdown request.', 'Obsolete', '2018-11-01'::date, '2007-09-01'::date, NULL, 'Retired code. Do not use'),
    ('FADAMIPM', 'SEPAFADirectDebitAMI', 'SEPA Fixed Amount Direct Debit AMI based on a paper mandate', 'Registered', '2011-12-02'::date, '2011-12-02'::date, NULL, 'EMEA,SEPA,EUR,PEACH,DD'),
    ('FDP', 'ForwardDatedPayment', 'Type of Payment used within the New Payments Architecture (UK). Forward-dated payments are one-off payments sent and received on a pre-arranged date, set-up by the customer in advance, for example, to pay a bill.', 'Registered', '2023-08-31'::date, '2023-08-31'::date, NULL, NULL),
    ('FFR', 'FedFundsReturned', 'Transaction is related to Fed funds returned.', 'Obsolete', '2018-11-01'::date, '2009-04-01'::date, NULL, 'Retired code. Do not use'),
    ('FFS', 'FedFundsSold', 'Transaction is related to Fed funds sold.', 'Obsolete', '2018-11-01'::date, '2009-04-01'::date, NULL, 'Retired code. Do not use'),
    ('GST', 'TruncatedCreditTransfers', 'Transaction is related to truncated credit transfers.
Conversion of physical instrument to electonric form for transmission to the paying bank and where the original paper document does not continue in the clearing process..The original instrument rules are retained throughout the life of the instrument.
Transaction triggered by specific marked and populated paper slip.
Reconciliation reference is secured by check digits supporting secure optical recognition. All other remittance information is truncated prior transmission.', 'Registered', '2011-12-02'::date, '2007-09-01'::date, NULL, 'EMEA,AT,EUR,correspondent banking,CT'),
    ('IAT', 'InternationalACH', 'Transaction is related to international ACH.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, 'WHEM,US,USD,NACHA,Both,Both'),
    ('ICMC', 'IncidentManagementCorrection', 'Transaction is related to an Incident Management Correction procedure based on the DD infrastructure.', 'Registered', '2019-02-01'::date, '2019-02-01'::date, NULL, 'EMEA,NL,EUR,All,DD,B2B'),
    ('IDEAL', 'PaymentsViaInternetOwnedByCurrence', 'Transaction is related to payments via internet owned by Currence.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, 'EMEA,NL,EUR,All,Both'),
    ('IMD', 'ImmediatePayment', 'Type of Payment used within the New Payments Architecture (UK). Immediate Payments are used for payments initiated by customers using channels such as internet, mobile or telephone banking, where the customer wants the payment to be effected immediately.', 'Registered', '2023-08-31'::date, '2023-08-31'::date, NULL, NULL),
    ('IMPS', 'IMPSClearing', 'Instant payment via the Indian IMPS clearing system.', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, 'Applies to India only.'),
    ('IN', 'CrossBorderCustomerCreditTransfer', 'Transaction is related to cross border customer credit transfer.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'EMEA,SE,All,All,CT'),
    ('INST', 'InstantCreditTransfer', 'Transaction is related to an Instant Credit Transfer.
Use case example: SEPA Instant Credit Transfer (SCT Inst)', 'Registered', '2016-05-11'::date, '2016-04-01'::date, NULL, 'GLOBAL,GLOBAL,All,All,CT'),
    ('INSTIDEAL', 'PaymentsViaInternetOwnedByCurrenceUsingInstantCreditTransfer', 'Transaction is related to payments via internet owned by Currence which uses an Instant Credit Transfer.', 'Registered', '2017-11-01'::date, '2017-11-01'::date, NULL, 'EMEA,NL,EUR,All,CT,Both'),
    ('INSTNT01', 'InstantCreditTransferNotTimeCritical', 'The transaction is related to a regular  Credit Transfer and will be instantly processed under the Dutch AOS on top of the EPC SCT scheme.', 'Registered', '2017-09-01'::date, '2017-09-01'::date, NULL, 'EMEA,NL,EUR,All,CT,Both'),
    ('INSTNT01IDEAL', 'PaymentsViaInternetOwnedByCurrenceUsingInstantCreditTransferNotTimeCritical', 'Transaction is related to payments via internet owned by Currence which uses a regular  Credit Transfer and will be instantly processed under the Dutch AOS on top of the EPC SCT scheme.', 'Registered', '2017-11-01'::date, '2017-11-01'::date, NULL, 'EMEA,NL,EUR,All,CT,Both'),
    ('INSTTC01', 'InstantCreditTransferTimeCritical', 'The transaction is related to an Instant Credit Transfer under the rules of the Dutch AOS on top of the EPC SCT Inst scheme.', 'Registered', '2017-09-01'::date, '2017-09-01'::date, NULL, 'EMEA,NL,EUR,All,CT,Both'),
    ('INSTTC01IDEAL', 'PaymentsViaInternetOwnedByCurrenceUsingInstantCreditTransferTimeCritical', 'Transaction is related to payments via internet owned by Currence which uses an Instant Credit Transfer under the rules of the Dutch AOS on top of the EPC SCT Inst scheme.', 'Registered', '2017-11-01'::date, '2017-11-01'::date, NULL, 'EMEA,NL,EUR,All,CT,Both'),
    ('IPA', 'InstantPaymentsAruba', 'Transaction is related to an Instant Credit Transfer under the rules of the Centrale Bank van Aruba, based on the EPC SCT Inst scheme.', 'Registered', '2018-11-01'::date, '2018-11-01'::date, NULL, 'Caribbean,AW,AWG,All,CT,Both'),
    ('ISE', 'ImageBasedChequeCollection', 'Transaction is related to the German Image-based Cheque Collection Procedure "Imagegestützter Scheckeinzug - ISE"', 'Registered', '2015-08-31'::date, '2015-08-31'::date, NULL, 'EMEA,DE,EUR,Domestic DE,Other,Bk2Bk'),
    ('ITP', 'InstantCreditTransferPreferred', 'Payment via Instant Credit Transfer but Credit Transfer is also possible.', 'Registered', '2024-02-28'::date, '2021-11-30'::date, NULL, 'CR1351/SIC')
ON CONFLICT ("Code") DO NOTHING;
INSERT INTO public."ExternalLocalInstrument1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('IUPI', 'UPIClearing', 'Instant payment via the Indian UPI clearing system.', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, 'Applies to India only.'),
    ('MANP', 'MandatedPayment', 'Indicates that the payment is sent by responsible Central Bank on behalf of the participant in case of contingency.', 'Registered', '2018-05-01'::date, '2018-05-01'::date, NULL, 'EMEA,EU,All,EMIP,CT,B2B'),
    ('MDP', 'MultiDayPayment', 'Type of New Payments Architecture (NPA) payment. Payments are processed over a three-day cycle and available to customers early in the morning of Day 3.', 'Registered', '2022-05-31'::date, '2022-05-31'::date, NULL, 'Usage: EMEA-UK.'),
    ('NACH', 'NACHClearing', 'Payment via the Indian NACH clearing (net settlement).', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, 'Applies to India only.'),
    ('NEFT', 'NEFTClearing', 'Payment via the Indian NEFT clearing (net settlement).', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, 'Applies to India only.'),
    ('NLDO', 'DutchDomesticBulkPayment', 'Transaction is related to a Domestic payment initiated by PAIN.001', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, 'EMEA,NL,EUR,All,CT'),
    ('NLGOV', 'DirectDebitInitiatedByTheGovernmentWithSpecialConditions', 'Transaction is related to direct debit scheme owned by the NVB.', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, 'EMEA,NL,EUR,All,DD'),
    ('NLUP', 'DutchUrgentPayment', 'Transaction is related to a Domestic payment initiated by PAIN.001', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, 'EMEA,NL,EUR,All,CT'),
    ('ONCL', 'Overnight', 'Transaction is related to overnight clearing.', 'Registered', '2010-12-01'::date, '2010-12-01'::date, NULL, 'EMEA,SEPA,EUR,Corporate banking,CT,B2B'),
    ('PERI', 'PaymentWithERI', 'Credit transfer contains Extended Remittance Information (ERI) as defined within the applicable scheme.', 'Registered', '2019-02-01'::date, '2019-02-01'::date, NULL, 'EMEA,SEPA,EUR,Corporate banking,CT,B2B'),
    ('POP', 'PointOfPurchase', 'Transaction is related to point-of-purchase.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'WHEM,US,USD,NACHA,DD,Both'),
    ('POS', 'PointOfSale', 'Transaction is related to point-of-sale.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'WHEM,US,USD,NACHA,DD,Both'),
    ('PPD', 'PrearrangedPaymentOrDepositConsumerCounterparty', 'Transaction is related to prearranged payment or deposit consumer counterparty.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'WHEM,US,USD,NACHA,Both plus prenote.,Both'),
    ('RCK', 'RepresentedCheckEntry', 'Transaction is related to re-presented check entry.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'WHEM,US,USD,NACHA,CT,Both'),
    ('RDD', 'ReturnedDirectDebits', 'Transaction is related to returned direct debits.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'EMEA,AT,EUR,correspondent banking,DD'),
    ('RIBA', 'NonPreauthorisedDirectDebitRIBA', 'Transaction is related to a non-pre authorised collection (RIBA).', 'Registered', '2020-05-01'::date, '2012-02-09'::date, NULL, 'EMEA,IT,EUR, Domestic IT,DD,Both'),
    ('RIDO', 'PreauthorisedRevocableDirectDebit', 'Transaction is related to a direct debit that is pre authorised and revocable (RID Ordinario).', 'Registered', '2012-02-09'::date, '2012-02-09'::date, NULL, 'EMEA,IT,EUR,Domestic IT,DD,Both'),
    ('RIDV', 'PreauthorisedRevocableUrgentDirectDebit', 'Transaction is related to an urgent direct debit that is pre authorised and revocable (RID Veloce).', 'Registered', '2012-02-09'::date, '2012-02-09'::date, NULL, 'EMEA,IT,EUR,Domestic IT,DD,Both'),
    ('RTR', 'ReturnedCreditTransfers', 'Transaction is related to returned credit transfers.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'EMEA,AT,EUR,correspondent banking,CT'),
    ('SBTI', 'SettlementBankTransferInitiation', 'Indicates that the payment is submitted to move  liquidity to the technical account - dedicated to real-time settlement in an external system (for example ancillary system) . The payment is processed in a separate payment queue besides the normal processing.', 'Registered', '2018-05-01'::date, '2018-05-01'::date, NULL, 'EMEA,EU,All,EMIP,CT,B2B'),
    ('SCN', 'RevokedTruncatedChecks', 'Transaction is related to revoked truncated checks.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'EMEA,AT,EUR,correspondent banking,other'),
    ('SDCL', 'SameDayClearedPayments', 'Transaction is related to New Zealand High Value Clearing System (HVCS) same day clearing payments.', 'Registered', '2021-08-31'::date, '2010-12-01'::date, NULL, 'EMEA,SEPA,EUR,Corporate banking,CT,B2B-Originator: CGI-4Q2010 CR0053-Updated: CR1056-Payments NZ.'),
    ('SDD', 'RevokedDirectDebits', 'Transaction is related to revoked direct debits.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'EMEA,AT,EUR,correspondent banking,other'),
    ('SDN', 'PaymentsViaStandaardDigitaleNota', 'Transaction is related to payments via a ''Standaard Digitale Nota'' InvoiceAcceptgiro payment.', 'Registered', '2010-12-06'::date, '2010-12-06'::date, NULL, 'EMEA,NL,EUR,All,CT'),
    ('SGT', 'RevokedTruncatedCreditTransfers', 'Transaction is related to revoked truncated credit transfers.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'EMEA,AT,EUR,correspondent banking,other'),
    ('SOP', 'StandingOrderPayment', 'Standing Orders are regular payments of a fixed amount paid to the same recipient on a specified date, for example, to pay rent.', 'Registered', '2023-08-31'::date, '2023-08-31'::date, NULL, NULL),
    ('SRD', 'RevokedReturnedDirectDebits', 'Transaction is related to revoked returned direct debits.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'EMEA,AT,EUR,correspondent banking,other'),
    ('SRT', 'RevokedReturnedCreditTransfers', 'Transaction is related to revoked returned credit transfers', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'EMEA,AT,EUR,correspondent banking,other'),
    ('STR', 'RevokedCreditTransfers', 'Transaction is related to revoked credit transfers', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'EMEA,AT,EUR,correspondent banking,other'),
    ('SVC', 'NonValueServiceMessage', 'Transaction is related to non-value service message.', 'Obsolete', '2018-11-01'::date, '2009-04-01'::date, NULL, 'Retired code. Do not use'),
    ('TEL', 'TelephoneInitiatedEntry', 'Transaction is related to telephone initiated entry.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'WHEM,US,USD,NACHA,DD,Both'),
    ('TRF', 'CreditTransfers', 'Transaction is related to credit transfers', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'EMEA,AT,All,correspondent banking,CT'),
    ('UDD', 'UnauthenticatedDirectDebit', 'Transaction is unauthenticated direct debit for domestic use.', 'Registered', '2019-11-01'::date, '2016-11-18'::date, NULL, 'GLOBAL,GLOBAL,All,All,DD,Both'),
    ('WEB', 'InternetInitiatedEntry', 'Transaction is related to internet initiated entry.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'WHEM,US,USD,NACHA,DD,Both')
ON CONFLICT ("Code") DO NOTHING;
-- Seed: ExternalMandateSetupReason1CodeValues (0 codes)
-- No codes currently published for ExternalMandateSetupReason1Code in the 1Q2026 registry --
-- it is a registered/defined code set with zero enumerated values
-- this quarter (confirmed via the registry's "CodeSetsDefinition" sheet,
-- Status: Registered). Table intentionally left empty.
-- Seed: ExternalOrganisationIdentification1CodeValues (15 codes)
INSERT INTO public."ExternalOrganisationIdentification1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('BANK', 'BankPartyIdentification', 'Unique and unambiguous assignment made by a specific bank or similar financial institution to identify a relationship as defined between the bank and its client.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('BDID', 'BusinessDomainIdentifier', 'Identifier of the business domain in which the organisation is active.', 'Registered', '2021-11-30'::date, '2021-11-30'::date, NULL, 'CR1066'),
    ('BOID', 'BusinessOtherIdentification', 'Other identification of the organisation.', 'Registered', '2021-11-30'::date, '2021-11-30'::date, NULL, 'CR1066'),
    ('CBID', 'CentralBankIdentificationNumber', 'A unique identification number assigned by a central bank to identify an organisation.', 'Registered', '2010-12-06'::date, '2010-12-06'::date, NULL, NULL),
    ('CHID', 'ClearingIdentificationNumber', 'A unique identification number assigned by a clearing house to identify an organisation', 'Registered', '2010-12-06'::date, '2010-12-06'::date, NULL, NULL),
    ('CINC', 'CertificateOfIncorporationNumber', 'A unique identification number assigned by a designated authority to a certificate of incorporation and used to identify an organisation.', 'Registered', '2017-02-08'::date, '2017-02-01'::date, NULL, NULL),
    ('COID', 'CountryIdentificationCode', 'Country authority given organisation identification (e.g., corporate registration number)', 'Registered', '2011-02-14'::date, '2011-02-14'::date, NULL, NULL),
    ('CUST', 'CustomerNumber', 'Number assigned by an issuer to identify a customer.
Number assigned by a party to identify a creditor or debtor relationship.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('DUNS', 'DataUniversalNumberingSystem', 'A unique identification number provided by Dun & Bradstreet to identify an organisation.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('EMPL', 'EmployerIdentificationNumber', 'Number assigned by a registration authority to an employer.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('GS1G', 'GS1GLNIdentifier', 'Global Location Number. A non-significant reference number used to identify legal entities, functional entities, or physical entities according to GS1 numbering scheme rules.The number is used to retrieve detailed information that is linked to it.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('SREN', 'SIREN', 'The SIREN number is a 9 digit code assigned by INSEE, the French National Institute for Statistics and Economic Studies, to identify an organisation in France.', 'Registered', '2010-12-06'::date, '2010-12-06'::date, NULL, NULL),
    ('SRET', 'SIRET', 'The SIRET number is a 14 digit code assigned by INSEE, the French National Institute for Statistics and Economic Studies, to identify an organisation unit in France. It consists of the SIREN number, followed by a five digit classification number, to identify the local geographical unit of that entity', 'Registered', '2010-12-06'::date, '2010-12-06'::date, NULL, NULL),
    ('TXID', 'TaxIdentificationNumber', 'Number assigned by a tax authority to identify an organisation.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('USID', 'UniqueSuperannuationIdentifier', 'Unique identifier assigned to a pension/superannuation fund, product, or scheme to which a superannuation contribution payment is directed.', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, 'In the Australian superannuation context, this identifier may be represented by the Unique Superannuation Identifier (USI) used to identify the relevant superannuation fund or product.')
ON CONFLICT ("Code") DO NOTHING;
-- Seed: ExternalPaymentGroupStatus1CodeValues (13 codes)
INSERT INTO public."ExternalPaymentGroupStatus1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('ACCC', 'AcceptedSettlementCompletedCreditorAccount', 'Settlement on the creditor''s account has been completed.', 'Registered', '2020-05-01'::date, '2018-03-01'::date, NULL, NULL),
    ('ACCP', 'AcceptedCustomerProfile', 'Preceding check of technical validation was successful. Customer profile check was also successful.', 'Registered', '2017-02-08'::date, '2017-01-01'::date, NULL, NULL),
    ('ACSC', 'AcceptedSettlementCompletedDebitorAccount', 'Settlement on the debtor''s account has been completed.
Usage : this can be used by the first agent to report to the debtor that the transaction has been completed. 
Warning : this status is provided for transaction status reasons, not for financial information. It can only be used after bilateral agreement', 'Registered', '2020-05-01'::date, '2017-02-08'::date, NULL, NULL),
    ('ACSP', 'AcceptedSettlementInProcess', 'All preceding checks such as technical validation and customer profile were successful and therefore the payment initiation has been accepted for execution.', 'Registered', '2017-02-08'::date, '2017-01-01'::date, NULL, NULL),
    ('ACTC', 'AcceptedTechnicalValidation', 'Authentication and syntactical and semantical validation are successful', 'Registered', '2017-02-08'::date, '2017-01-01'::date, NULL, NULL),
    ('ACWC', 'AcceptedWithChange', 'Instruction is accepted but a change will be made, such as date or remittance not sent.', 'Registered', '2017-02-08'::date, '2017-01-01'::date, NULL, NULL),
    ('PART', 'PartiallyAccepted', 'A number of transactions have been accepted, whereas another number of transactions have not yet achieved
''accepted'' status.', 'Registered', '2017-02-08'::date, '2017-01-01'::date, NULL, NULL),
    ('PDNG', 'Pending', 'Payment initiation or individual transaction included in the payment initiation is pending. Further checks and status update will be performed.', 'Registered', '2017-02-08'::date, '2017-01-01'::date, NULL, NULL),
    ('RCVC', 'ReceivedVerificationCompleted', 'Verification of Payee check have been applied to received transactions stating to be complete without mismatching data.', 'Registered', '2025-02-28'::date, '2025-02-28'::date, NULL, NULL),
    ('RCVD', 'Received', 'Payment initiation has been received by the receiving agent', 'Registered', '2017-02-08'::date, '2017-01-01'::date, NULL, NULL),
    ('RJCT', 'Rejected', 'Payment initiation or individual transaction included in the payment initiation has been rejected.', 'Registered', '2017-02-08'::date, '2017-01-01'::date, NULL, NULL),
    ('RVCM', 'ReceivedVerificationCompletedWithMismatches', 'Verification of Payee checks have been applied to received transactions stating to be complete containing mismatching data.', 'Registered', '2025-02-28'::date, '2025-02-28'::date, NULL, NULL),
    ('RVNC', 'ReceivedVerificationNotCompleted', 'Verification of party check on transactions received is not yet completed.', 'Registered', '2025-02-28'::date, '2025-02-28'::date, NULL, NULL)
ON CONFLICT ("Code") DO NOTHING;
-- Seed: ExternalPaymentTransactionStatus1CodeValues (25 codes)
INSERT INTO public."ExternalPaymentTransactionStatus1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('ACCC', 'AcceptedSettlementCompletedCreditorAccount', 'Settlement on the creditor''s account has been completed.', 'Registered', '2020-05-01'::date, '2018-03-01'::date, NULL, NULL),
    ('ACCP', 'AcceptedCustomerProfile', 'Preceding check of technical validation was successful. Customer profile check was also successful.', 'Registered', '2017-02-08'::date, '2017-01-01'::date, NULL, NULL),
    ('ACFC', 'AcceptedFundsChecked', 'Preceding check of technical validation and customer profile was successful and an automatic funds check was positive.', 'Registered', '2019-02-01'::date, '2019-02-01'::date, NULL, NULL),
    ('ACFW', 'AcceptedFundsCheckedWaitingConfirmation', 'Preceding check of technical validation and customer profile was successful, and an automatic funds check was positive, but an explicit confirmation by the initiating party is outstanding.', 'Registered', '2025-02-28'::date, '2025-02-28'::date, NULL, NULL),
    ('ACIS', 'AcceptedandChequeIssued', 'Payment instruction to issue a cheque has been accepted, and the cheque has been issued but not yet been deposited or cleared.', 'Registered', '2021-05-01'::date, '2021-05-01'::date, NULL, NULL),
    ('ACPD', 'AcceptedClearingProcessed', 'Status of transaction released from the Debtor Agent and accepted by the clearing.', 'Registered', '2022-05-31'::date, '2022-05-31'::date, NULL, NULL),
    ('ACSC', 'AcceptedSettlementCompletedDebitorAccount', 'Settlement completed.
Usage : this can be used by a Market Infrastructure reporting to Infrastructure Participant or an Account Servicer to Account Owner to report that the transaction account entry has been completed.
Warning : this status is provided for transaction status reasons, not for financial information. It can only be used after bilateral agreement', 'Registered', '2020-08-01'::date, '2017-02-08'::date, NULL, NULL),
    ('ACSP', 'AcceptedSettlementInProcess', 'All preceding checks such as technical validation and customer profile were successful and therefore the payment instruction has been accepted for execution.', 'Registered', '2020-08-01'::date, '2017-02-08'::date, NULL, NULL),
    ('ACTC', 'AcceptedTechnicalValidation', 'Authentication and syntactical and semantical validation are successful', 'Registered', '2017-02-08'::date, '2017-01-01'::date, NULL, NULL),
    ('ACWC', 'AcceptedWithChange', 'Instruction is accepted but a change will be made, such as date or remittance not sent.', 'Registered', '2017-02-08'::date, '2017-01-01'::date, NULL, NULL),
    ('ACWP', 'AcceptedWithoutPosting', 'Payment instruction included in the credit transfer is accepted without being posted to the creditor customer''s account.', 'Registered', '2017-05-01'::date, '2017-05-01'::date, NULL, NULL),
    ('BLCK', 'Blocked', 'Payment transaction previously reported with status ''ACWP'' is blocked, for example, funds will neither be posted to the Creditor''s account, nor be returned to the Debtor.', 'Registered', '2021-02-01'::date, '2021-02-01'::date, NULL, NULL),
    ('CANC', 'Cancelled', 'Payment initiation has been successfully cancelled after having received a request for cancellation.
Usage: code to be used in the context of APIs only.', 'Registered', '2019-02-01'::date, '2019-02-01'::date, NULL, NULL),
    ('CPUC', 'CashPickedUpByCreditor', 'Cash has been picked up by the Creditor.', 'Registered', '2021-05-01'::date, '2021-05-01'::date, NULL, NULL),
    ('PATC', 'PartiallyAcceptedTechnicalCorrect', 'Payment initiation needs multiple authentications, where some but not yet all have been performed. Syntactical and semantical validations are successful.', 'Registered', '2019-02-01'::date, '2019-02-01'::date, NULL, NULL),
    ('PDNG', 'Pending', 'Payment instruction is pending. Further checks and status update will be performed.', 'Registered', '2020-08-01'::date, '2017-02-08'::date, NULL, NULL),
    ('PRES', 'Presented', 'Request for Payment has been presented to the Debtor.', 'Registered', '2020-11-01'::date, '2020-11-01'::date, NULL, NULL),
    ('RCVC', 'ReceivedVerificationCompleted', 'Verification of Payee check has been applied to received transaction stating to be complete without mismatching data.', 'Registered', '2025-02-28'::date, '2025-02-28'::date, NULL, NULL),
    ('RCVD', 'Received', 'Payment instruction has been received.', 'Registered', '2020-08-01'::date, '2017-05-01'::date, NULL, NULL),
    ('RJCT', 'Rejected', 'Payment instruction has been rejected.', 'Registered', '2020-08-01'::date, '2017-02-08'::date, NULL, NULL),
    ('RVCM', 'ReceivedVerificationCompletedWithMismatches', 'Verification of Payee checks have been applied to received transaction stating to be completed containing mismatching data.', 'Registered', '2025-02-28'::date, '2025-02-28'::date, NULL, NULL),
    ('RVMC', 'ReceivedVerificationCompletedMatchClosely', 'Verification of Payee check has been applied to received transaction stating to be complete with data matching closely.', 'Registered', '2025-02-28'::date, '2025-02-28'::date, NULL, NULL),
    ('RVNA', 'ReceivedVerificationCompletedNotApplicable', 'Verification of Payee check has been applied to received transaction stating to be complete with not applicable data.', 'Registered', '2025-02-28'::date, '2025-02-28'::date, NULL, NULL),
    ('RVNC', 'ReceivedVerificationNotCompleted', 'Verification of party check on the transaction is not yet completed.', 'Registered', '2025-02-28'::date, '2025-02-28'::date, NULL, NULL),
    ('RVNM', 'ReceivedVerificationCompletedNoMatch', 'Verification of Payee check has been applied to received transaction stating to be complete with mismatching data.', 'Registered', '2025-02-28'::date, '2025-02-28'::date, NULL, NULL)
ON CONFLICT ("Code") DO NOTHING;
-- Seed: ExternalPersonIdentification1CodeValues (11 codes)
INSERT INTO public."ExternalPersonIdentification1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('ARNU', 'AlienRegistrationNumber', 'Number assigned by a social security agency to identify a non-resident person.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('BANK', 'BankPartyIdentification', 'Unique and unambiguous assignment made by a specific bank or similar financial institution to identify a relationship as defined between the bank and its client.', 'Registered', '2025-02-28'::date, '2025-02-28'::date, NULL, NULL),
    ('CCPT', 'PassportNumber', 'Number assigned by an authority to identify the passport number of a person.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('CUST', 'CustomerIdentificationNumber', 'Number assigned by an issuer to identify a customer.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('DRLC', 'DriversLicenseNumber', 'Number assigned by an authority to identify a driver''s license.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('EMPL', 'EmployeeIdentificationNumber', 'Number assigned by a registration authority to an employee.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('NIDN', 'NationalIdentityNumber', 'Number assigned by an authority to identify the national identity number of a person.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('POID', 'PersonCommercialIdentification', 'Commercial identification of the person.', 'Registered', '2021-11-30'::date, '2021-11-30'::date, NULL, 'CR1065'),
    ('SOSE', 'SocialSecurityNumber', 'Number assigned by an authority to identify the social security number of a person.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('TELE', 'TelephoneNumber', 'Number assigned by a telephone or mobile phone operator to identify a person. A person may have multiple phone numbers.', 'Registered', '2021-05-01'::date, '2021-05-01'::date, NULL, NULL),
    ('TXID', 'TaxIdentificationNumber', 'Number assigned by a tax authority to identify a person.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL)
ON CONFLICT ("Code") DO NOTHING;
-- Seed: ExternalProxyAccountType1CodeValues (22 codes)
INSERT INTO public."ExternalProxyAccountType1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('BIID', 'BillerSubscriberIdentification', 'Billers of specific utilities could register for a Biller Identification as supported in the clearing scheme, and use this identification for collections (applied for corporate account proxy).', 'Registered', '2022-03-04'::date, '2022-03-04'::date, NULL, NULL),
    ('CCPT', 'PassportNumber', 'Unique government-issued Identification  used as account proxy to  identify the individual  (for example for government charges, road taxes, vaccination charges) and typically linked to the individual''s bank account
(applied for  individual account proxy).', 'Registered', '2022-03-04'::date, '2022-03-04'::date, NULL, NULL),
    ('CINC', 'CertificateOfIncorporationNumber', 'Corporate Identification issued by a national  institution or regulator, used as account proxy. 
(applied for corporate account proxy).', 'Registered', '2022-03-04'::date, '2022-03-04'::date, NULL, NULL),
    ('COID', 'CountryAuthorityIdentification', 'Identification issued by a national  institution or regulator (different from a national scheme like a clearing provider), used as account proxy (applied for corporate or individual account proxy).', 'Registered', '2022-03-04'::date, '2022-03-04'::date, NULL, NULL),
    ('COTX', 'CorporateTaxIdentification', 'Unique government-issued tax Identification used as account proxy to identify the corporate (for example for government tax) and typically linked to the corporate bank account (applied for corporate account proxy).', 'Registered', '2022-03-04'::date, '2022-03-04'::date, NULL, NULL),
    ('CUST', 'CustomerIdentificationNumber', 'Any other customer identification number issued by a corporate, bank or other organization, used as account proxy.
(applied for corporate or individual account proxy).', 'Registered', '2022-03-04'::date, '2022-03-04'::date, NULL, NULL),
    ('DNAM', 'DomainName', 'Internationalised internet domain name.', 'Registered', '2018-11-01'::date, '2018-11-01'::date, NULL, NULL),
    ('DRLC', 'DriverLicenseNumber', 'Unique government-issued Identification used as account proxy to  identify the individual  (for example for government charges, road taxes and tolls,vaccination charges) and typically linked to the individual''s bank account (applied for  individual account proxy).', 'Registered', '2022-03-04'::date, '2022-03-04'::date, NULL, NULL),
    ('EIDN', 'ElectronicIdentification', 'Government-issued Identification (different from a passport Identification or a national Identification). Used as account proxy to  identify the individual (for example for public benefits) and typically linked to the individual''s bank account (applied for  individual account proxy).', 'Registered', '2022-03-04'::date, '2022-03-04'::date, NULL, NULL),
    ('EMAL', 'EmailAddress', 'Internationalised address of an electronic mail box for internet messages.', 'Registered', '2018-11-01'::date, '2018-11-01'::date, NULL, NULL),
    ('EWAL', 'EWalletIdentification', 'Market-adopted prepaid instruments like e-Wallets, payments to / from e-wallets from / to bank accounts (applied for corporate or individual account proxy).', 'Registered', '2022-03-04'::date, '2022-03-04'::date, NULL, NULL),
    ('LEIC', 'LegalEntityIdentifierCode', 'Legal Entity Identifier used as account proxy (applied for corporate account proxy).
Use cases: Can be used by corporates as a "government-issued" Identification for registration with payment schemes as a proxy. The proxy may be further used for payments and collections using the underlying instant payment rails for a variety of corporate use cases.', 'Registered', '2022-03-04'::date, '2022-03-04'::date, NULL, NULL),
    ('MBNO', 'MobilePhoneNumber', 'Mobile phone number in the format specified by the "The international public telecommunication numbering plan ITU- T E 164" (applied for corporate or individual account proxy).', 'Registered', '2022-03-04'::date, '2022-03-04'::date, NULL, NULL),
    ('NIDN', 'NationalIdentificationNumber', 'Unique government-issued Identification  used as account proxy to  identify the individual  or corporate for example for public benefits, government subsidies) and typically linked to the individual''s / corporate bank account.
(applied for corporate or individual account proxy).', 'Registered', '2022-03-04'::date, '2022-03-04'::date, NULL, NULL),
    ('OSID', 'OtherSchemeIdentificationNumber', 'Additional scheme identifier used to complement the primary scheme identification so that banks can apply respective validations of the proxy value as per the Type code provided.', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, NULL),
    ('PVTX', 'IndividualTaxIdentification', 'Unique government-issued  tax Identification  used as account proxy to  identify the individual  for example for government tax) and typically linked to the individual''s bank account (applied for  individual account proxy).', 'Registered', '2022-03-04'::date, '2022-03-04'::date, NULL, NULL),
    ('SHID', 'SchemeIdentificationNumber', 'Account proxy issued by a payment scheme (applied for corporate or individual account proxy).
Use cases: Any proxies issued by clearing systems, for example VPA (India), FPS Identifier (Hong Kong), Jompay (Malaysia) CCIN (Canada).', 'Registered', '2022-03-04'::date, '2022-03-04'::date, NULL, NULL),
    ('SOSE', 'SocialSecurityNumber', 'Unique government-issued Identification  used as account proxy to identify the individual  (for example for public benefits) and typically linked to the individual''s bank account (applied for individual account proxy).', 'Registered', '2022-03-04'::date, '2022-03-04'::date, NULL, NULL),
    ('TELE', 'TelephoneNumber', 'A telephone number in the format specified by the ''The international public telecommunication numbering plan ITU-T E.164.', 'Registered', '2018-11-01'::date, '2018-11-01'::date, NULL, NULL),
    ('TOKN', 'TokenIdentification', 'Electronic Identification used, for example, to mask an account number as a means of data secrecy.
(applied for corporate or individual account proxy).', 'Registered', '2022-03-04'::date, '2022-03-04'::date, NULL, NULL),
    ('UBIL', 'UtilitiesSubscriptionIdentification', 'Subscriber Identification for utilities and services. As opposed to a biller Identification, this identification is used for the subscriber of the service (applied for corporate or individual account proxy).', 'Registered', '2022-03-04'::date, '2022-03-04'::date, NULL, NULL),
    ('VIPN', 'VehicleIdentificationPlateNumber', 'Account proxy for receiving insurance claims, pay insurance premium, road tax payments, traffic tickets etc.(applied for corporate or individual account proxy).', 'Registered', '2022-03-04'::date, '2022-03-04'::date, NULL, NULL)
ON CONFLICT ("Code") DO NOTHING;
-- Seed: ExternalPurpose1CodeValues (366 codes)
INSERT INTO public."ExternalPurpose1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('ACCT', 'AccountManagement', 'Transaction moves funds between 2 accounts of same account holder at the same bank.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Cash Mgmt'),
    ('ACTF', 'AccountFunding', 'Account transfer funding a bank account (Demand Deposit (DDA) and savings accounts).', 'Registered', '2026-05-22'::date, '2026-05-22'::date, NULL, NULL),
    ('ADCS', 'AdvisoryDonationCopyrightServices', 'Payments for donation, sponsorship, advisory, intellectual and other copyright services.', 'Registered', '2015-11-27'::date, '2015-11-27'::date, NULL, 'Salary & Benefits'),
    ('ADMG', 'AdministrativeManagement', 'Transaction is related to a payment associated with administrative management.', 'Registered', '2012-02-09'::date, '2012-02-09'::date, NULL, 'General'),
    ('ADVA', 'AdvancePayment', 'Transaction is an advance payment.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'General'),
    ('AEMP', 'ActiveEmploymentPolicy', 'Payment concerning active employment policy.', 'Registered', '2012-07-16'::date, '2012-07-16'::date, NULL, 'Salary & Benefits'),
    ('AGRT', 'AgriculturalTransfer', 'Transaction is related to the agricultural domain.', 'Registered', '2009-04-01'::date, '2007-09-01'::date, NULL, 'Commercial'),
    ('AIRB', 'Air', 'Transaction is a payment for air transport related business.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, 'Transport'),
    ('ALDS', 'AutoLoanDisbursement', 'Disbursement of funds for vehicle purchases including cars, trucks, motorcycles, boats, RVs/motorhomes, ATVs/UTVs, jet skis, snowmobiles, commercial vehicles, and trailers.', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, 'Finance'),
    ('ALLW', 'Allowance', 'Transaction is the payment of allowances.', 'Registered', '2013-05-07'::date, '2013-05-06'::date, NULL, 'Salary & Benefits'),
    ('ALMY', 'AlimonyPayment', 'Transaction is the payment of alimony.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Salary & Benefits'),
    ('AMEX', 'Amex', 'Card Settlement-Settlement of AMEX transactions.', 'Registered', '2021-08-31'::date, '2021-08-23'::date, NULL, 'CR1045'),
    ('ANNI', 'Annuity', 'Transaction settles annuity related to credit, insurance, investments, other.n', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Investment'),
    ('ANTS', 'AnesthesiaServices', 'Transaction is a payment for anesthesia services.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Medical'),
    ('AREN', 'AccountsReceivablesEntry', 'Transaction is related to a payment associated with an Account Receivable Entry', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, 'Commercial'),
    ('AUCO', 'AuthenticatedCollections', 'Utilities-Settlement of Authenticated Collections transactions.', 'Registered', '2021-08-31'::date, '2021-08-23'::date, NULL, 'CR1045'),
    ('B112', 'TrailerFeePayment', 'US mutual fund trailer fee (12b-1) payment', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Trailer Fee'),
    ('BBSC', 'BabyBonusScheme', 'Transaction is related to a payment made as incentive to encourage parents to have more children', 'Registered', '2013-05-07'::date, '2013-05-06'::date, NULL, 'Salary & Benefits'),
    ('BCDM', 'BearerChequeDomestic', 'Transaction is the payment of a domestic bearer cheque.', 'Registered', '2015-08-31'::date, '2015-08-31'::date, NULL, 'General'),
    ('BCFG', 'BearerChequeForeign', 'Transaction is the payment of a foreign bearer cheque.', 'Registered', '2015-08-31'::date, '2015-08-31'::date, NULL, 'General'),
    ('BECH', 'ChildBenefit', 'Transaction is related to a payment made to assist parent/guardian to maintain child.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Salary & Benefits'),
    ('BENE', 'UnemploymentDisabilityBenefit', 'Transaction is related to a payment to a person who is unemployed/disabled.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Salary & Benefits'),
    ('BEXP', 'BusinessExpenses', 'Transaction is related to a payment of business expenses.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Commercial'),
    ('BFWD', 'BondForward', 'Cash collateral related to any securities traded out beyond 3 days which include treasury notes, JGBs and Gilts.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('BKDF', 'BankLoanDelayedDrawFunding', 'Delayed draw funding. Certain issuers may utilize delayed draw loans whereby the lender is committed to fund cash within a specified period once a call is made by the issuer. The lender receives a fee for entering into such a commitment.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Bank Debt'),
    ('BKFE', 'BankLoanFees', 'Bank loan fees. Cash activity related to specific bank loan fees, including (a) agent / assignment fees; (b) amendment fees; (c) commitment fees; (d) consent fees; (e) cost of carry fees; (f) delayed compensation fees; (g) facility fees; (h) fronting fees; (i) funding fees; (j) letter of credit assignment fees.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Bank Debt'),
    ('BKFM', 'BankLoanFundingMemo', 'Bank loan funding memo. Net cash movement for the loan contract final notification when sent separately from the loan contract final notification instruction.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Bank Debt'),
    ('BKIP', 'BankLoanAccruedInterestPayment', 'Accrued interest payments. Specific to bank loans.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Bank Debt'),
    ('BKPP', 'BankLoanPrincipalPaydown', 'Principal paydowns. Specific to bank loans', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Bank Debt'),
    ('BLDM', 'BuildingMaintenance', 'Transaction is related to a payment associated with building maintenance.', 'Registered', '2012-02-09'::date, '2012-02-09'::date, NULL, 'General'),
    ('BLDS', 'BusinessLoanDisbursement', 'Business Loan Disbursement, e.g., disbursing capital for business expansion, equipment purchase, or operational expenses.', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, 'Finance'),
    ('BNET', 'BondForwardNetting', 'Bond Forward pair-off cash net movement.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'General'),
    ('BNPL', 'BuyNowPayLater', 'Buy Now Pay Later Payments, e.g., point-of-sale financing options allowing installment payments for retail purchases.', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, 'Finance'),
    ('BOCE', 'BackOfficeConversionEntry', 'Transaction is related to a payment associated with a Back Office Conversion Entry', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, 'Commercial'),
    ('BOND', 'Bonds', 'Securities Lending-Settlement of Bond transaction.', 'Registered', '2021-08-31'::date, '2021-08-23'::date, NULL, 'CR1045'),
    ('BONU', 'BonusPayment.', 'Transaction is related to payment of a bonus.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Salary & Benefits'),
    ('BR12', 'TrailerFeeRebate', 'US mutual fund trailer fee (12b-1) rebate payment', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Trailer Fee'),
    ('BROK', 'BrokerageFunding', 'Account transfer funding a brokerage account.', 'Registered', '2026-05-22'::date, '2026-05-22'::date, NULL, NULL),
    ('BUSB', 'Bus', 'Transaction is a payment for bus transport related business.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, 'Transport'),
    ('CABD', 'CorporateActions-Bonds', 'Securities Lending-Settlement of Corporate Actions: Bonds transactions.', 'Registered', '2021-08-31'::date, '2021-08-23'::date, NULL, 'CR1045')
ON CONFLICT ("Code") DO NOTHING;
INSERT INTO public."ExternalPurpose1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('CAEQ', 'CorporateActions-Equities', 'Securities Lending-Settlement of Corporate Actions: Equities transactions.', 'Registered', '2021-08-31'::date, '2021-08-23'::date, NULL, 'CR1045'),
    ('CAFI', 'CustodianManagementFeeInhouse', 'Transaction is the payment of custodian account management fee where custodian bank and current account servicing bank coincide.', 'Registered', '2012-10-08'::date, '2012-10-08'::date, NULL, 'Investment'),
    ('CARL', 'CarLeaseRental', 'Car Rentals, e.g., short-term vehicle rentals.', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, 'Transport'),
    ('CASH', 'CashManagementTransfer', 'Transaction is a general cash management instruction.', 'Registered', '2009-04-01'::date, '2007-09-01'::date, NULL, 'Cash Mgmt'),
    ('CBCR', 'CreditCard', 'Card Settlement-Settlement of Credit Card transactions.', 'Registered', '2021-08-31'::date, '2021-08-23'::date, NULL, 'CR1045'),
    ('CBFF', 'CapitalBuilding', 'Transaction is related to capital building fringe fortune, ie capital building in general.', 'Registered', '2014-01-16'::date, '2009-04-01'::date, NULL, 'General'),
    ('CBFR', 'CapitalBuildingRetirement', 'Transaction is related to capital building fringe fortune for retirement.', 'Registered', '2014-01-16'::date, '2014-01-16'::date, NULL, 'General'),
    ('CBLK', 'CardBulkClearing', 'A Service that is settling money for a bulk of card transactions, while referring to a specific transaction file or other information like terminal ID, card acceptor ID or other transaction details.', 'Registered', '2012-10-08'::date, '2012-10-08'::date, NULL, 'Card Settlement'),
    ('CBTV', 'CableTVBill', 'Transaction is related to a payment of cable TV bill.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Utilities'),
    ('CCHD', 'CashCompensationHelplessnessDisability', 'Payments made by Government institute related to cash compensation, helplessness, disability. These payments are made by the Government institution as a social benefit in addition to regularly paid salary or pension.', 'Registered', '2016-05-01'::date, '2016-04-01'::date, NULL, 'Salary & Benefits'),
    ('CCIR', 'CrossCurrencyIRS', 'Cash Collateral related to a Cross Currency Interest Rate Swap, indicating the exchange of fixed interest payments in one currency for those in another.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('CCPC', 'CCPClearedInitialMargin', 'Cash Collateral associated with an ISDA or Central Clearing Agreement that is covering the initial margin requirements for OTC trades clearing through a CCP.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('CCPM', 'CCPClearedVariationMargin', 'Cash Collateral associated with an ISDA or Central Clearing Agreement that is covering the variation margin requirements for OTC trades clearing through a CCP.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('CCRD', 'CreditCardPayment', 'Transaction is related to a payment of credit card account.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'General'),
    ('CCSM', 'CCPClearedInitialMarginSegregatedCash', 'CCP Segregated initial margin: Initial margin on OTC Derivatives cleared through a CCP that requires segregation.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('CDBL', 'CreditCardBill', 'Transaction is related to a payment of credit card bill.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, 'General'),
    ('CDCB', 'CardPaymentWithCashBack', 'Purchase of Goods and Services with additional Cash disbursement at the POI (Cashback).', 'Registered', '2010-01-01'::date, '2010-01-01'::date, NULL, 'Card Settlement'),
    ('CDCD', 'CashDisbursementCashSettlement', 'ATM Cash Withdrawal in an unattended or Cash Advance in an attended environment (POI or bank counter).', 'Registered', '2020-05-01'::date, '2010-01-01'::date, NULL, 'Card Settlement'),
    ('CDCS', 'CashDisbursementWithSurcharging', 'ATM Cash Withdrawal in an unattended or Cash Advance in an attended environment (POI or bank counter) with surcharging.', 'Registered', '2012-02-09'::date, '2012-02-09'::date, NULL, 'Card Settlement'),
    ('CDDP', 'CardDeferredPayment', 'A combined service which enables the card acceptor to perform an authorisation for a temporary amount and a completion for the final amount within a limited time frame. Deferred Payment is only available in the unattended environment. Examples where this service is widely used are unattended petrol pumps and phone booths.', 'Registered', '2013-01-11'::date, '2013-01-11'::date, NULL, 'Card Settlement'),
    ('CDEP', 'CreditDefaultEventPayment', 'Payment related to a credit default event.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'OTC Derivatives'),
    ('CDOC', 'OriginalCredit', 'A service which allows the card acceptor to effect a credit to a cardholder'' account. Unlike a Merchant Refund, an Original Credit is not preceded by a card payment. This service is used for example for crediting winnings from gaming.', 'Registered', '2010-01-01'::date, '2010-01-01'::date, NULL, 'Card Settlement'),
    ('CDQC', 'QuasiCash', 'Purchase of Goods which are equivalent to cash like coupons in casinos.', 'Registered', '2010-01-01'::date, '2010-01-01'::date, NULL, 'Card Settlement'),
    ('CFDI', 'CapitalFallingDueInhouse', 'Transaction is the payment of capital falling due where custodian bank and current account servicing bank coincide.', 'Registered', '2012-10-08'::date, '2012-10-08'::date, NULL, 'Investment'),
    ('CFEE', 'CancellationFee', 'Transaction is related to a payment of cancellation fee.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'General'),
    ('CGDD', 'CardGeneratedDirectDebit', 'Transaction is related to a direct debit where the mandate was generated by using data from a payment card at the point of sale.', 'Registered', '2014-01-16'::date, '2014-01-16'::date, NULL, 'General'),
    ('CHAR', 'CharityPayment', 'Transaction is a payment for charity reasons.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Consumer'),
    ('CHCP', 'CharitableDonationCorporate', 'Charitable donation being processed on behalf of a Corporate entity.', 'Registered', '2026-05-22'::date, '2026-05-22'::date, NULL, NULL),
    ('CHDF', 'CharitableDonationDAF', 'Charitable donation being processed on behalf of a Donor Advised Fund (DAF).', 'Registered', '2026-05-22'::date, '2026-05-22'::date, NULL, NULL),
    ('CHFN', 'CharitableDonationFoundation', 'Charitable donation being processed on behalf of a Foundation (purpose-driven entity).', 'Registered', '2026-05-22'::date, '2026-05-22'::date, NULL, NULL),
    ('CLDS', 'ConstructionLoanDisbursement', 'Construction Loan Disbursement, e.g., phased disbursements for construction projects based on completion milestones.', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, 'Finance'),
    ('CLPR', 'CarLoanPrincipalRepayment', 'Transaction is a payment of car loan principal payment.', 'Registered', '2009-04-01'::date, '2007-09-01'::date, NULL, 'Finance'),
    ('CMDT', 'CommodityTransfer', 'Transaction is payment of commodities.', 'Registered', '2009-04-01'::date, '2007-09-01'::date, NULL, 'Investment'),
    ('COLL', 'CollectionPayment', 'Transaction is a collection of funds initiated via a credit transfer or direct debit.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Cash Mgmt'),
    ('COMC', 'CommercialPayment', 'Transaction is related to a payment of commercial credit or debit. (formerly CommercialCredit).', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Commercial'),
    ('COMM', 'Commission', 'Transaction is payment of commission.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Salary & Benefits'),
    ('COMP', 'CompensationPayment', 'Transaction is related to the payment of a compensation relating to interest loss/value date adjustment and can include fees.', 'Registered', '2017-11-01'::date, '2017-11-01'::date, NULL, 'Finance'),
    ('COMT', 'ConsumerThirdPartyConsolidatedPayment', 'Transaction is a payment used by a third party who can collect funds to pay on behalf of consumers, ie credit counseling or bill payment companies.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Consumer'),
    ('CORT', 'TradeSettlementPayment', 'Transaction is related to settlement of a trade, e.g. a foreign exchange deal or a securities transaction.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'General'),
    ('COST', 'Costs', 'Transaction is related to payment of costs.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'General')
ON CONFLICT ("Code") DO NOTHING;
INSERT INTO public."ExternalPurpose1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('CPEN', 'CashPenalties', 'Cash penalties related to securities transaction, including CSDR Settlement Discipline Regime.', 'Registered', '2022-05-31'::date, '2022-05-31'::date, NULL, NULL),
    ('CPKC', 'CarparkCharges', 'Transaction is related to carpark charges.', 'Registered', '2013-05-07'::date, '2013-05-06'::date, NULL, 'General'),
    ('CPYR', 'Copyright', 'Transaction is payment of copyright.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Commercial'),
    ('CRDS', 'CreditDefaultSwap', 'Cash collateral related to trading of credit default swap.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('CRPR', 'CrossProduct', 'Cash collateral related to a combination of various types of trades.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('CRSP', 'CreditSupport', 'Cash collateral related to cash lending/borrowing; letter of Credit; signing of master agreement.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('CRTL', 'CreditLine', 'Cash collateral related to opening of a credit line before trading.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('CRYP', 'CryptoAssets', 'Transaction is related to the purchase or sale of crypto assets.', 'Registered', '2026-05-22'::date, '2026-05-22'::date, NULL, 'To be used within payment initiations, so the paying and/or paid agent is aware of the nature of the transaction.'),
    ('CSDB', 'CashDisbursementCashManagement', 'Transaction is related to cash disbursement.', 'Registered', '2020-05-01'::date, '2009-04-01'::date, NULL, 'Cash Mgmt'),
    ('CSLP', 'CompanySocialLoanPaymentToBank', 'Transaction is a payment by a company to a bank for financing social loans to employees.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, 'Salary & Benefits'),
    ('CVCF', 'ConvalescentCareFacility', 'Transaction is a payment for convalescence care facility services.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Medical'),
    ('DBCR', 'DebitCard', 'Card Settlement-Settlement of Debit Card transactions.', 'Registered', '2021-08-31'::date, '2021-08-23'::date, NULL, 'CR1045'),
    ('DBTC', 'DebitCollectionPayment', 'Collection of funds initiated via a debit transfer.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, 'Finance'),
    ('DCRD', 'DebitCardPayment', 'Transaction is related to a debit card payment.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'General'),
    ('DEBT', 'ChargesBorneByDebtor', 'Purpose of payment is the settlement of charges payable by the debtor in relation to an underlying customer credit transfer.', 'Registered', '2023-11-30'::date, '2023-11-30'::date, NULL, NULL),
    ('DEPD', 'DependentSupportPayment', 'Transaction is related to a payment concerning dependent support, for example child support or support for a person substantially financially dependent on the support provider.', 'Registered', '2023-03-23'::date, '2023-03-23'::date, NULL, 'Distinct from BECH (Child Benefit - Transaction is related to a payment made to assist parent/guardian to maintain child) whereas DEPD is broader.'),
    ('DEPT', 'Deposit', 'Transaction is releted to a payment of deposit.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, 'Cash Mgmt'),
    ('DERI', 'Derivatives', 'Transaction is related to a derivatives transaction.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Investment'),
    ('DICL', 'Diners', 'Card Settlement-Settlement of Diners transactions.', 'Registered', '2021-08-31'::date, '2021-08-23'::date, NULL, 'CR1045'),
    ('DIVD', 'Dividend', 'Transaction is payment of dividends.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Investment'),
    ('DMEQ', 'DurableMedicaleEquipment', 'Transaction is a payment is for use of durable medical equipment.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Medical'),
    ('DNTS', 'DentalServices', 'Transaction is a payment for dental services.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Medical'),
    ('DSMT', 'PrintedOrderDisbursement', 'Transaction is the payment of a disbursement due to a specific type of printed order for a payment of a  specified sum, issued by a bank or a post office (Zahlungsanweisung zur Verrechnung)', 'Registered', '2015-08-31'::date, '2015-08-31'::date, NULL, 'General'),
    ('DVPM', 'DeliverAgainstPayment', 'Code used to pre-advise the account servicer of a forthcoming deliver against payment instruction.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'General'),
    ('ECPG', 'GuaranteedEPayment', 'E-Commerce payment with payment guarantee of the issuing bank.', 'Registered', '2014-12-26'::date, '2014-12-26'::date, NULL, 'E-Commerce'),
    ('ECPR', 'EPaymentReturn', 'E-Commerce payment return.', 'Registered', '2014-12-26'::date, '2014-12-26'::date, NULL, 'E-Commerce'),
    ('ECPU', 'NonGuaranteedEPayment', 'E-Commerce payment without payment guarantee of the issuing bank.', 'Registered', '2014-12-26'::date, '2014-12-26'::date, NULL, 'E-Commerce'),
    ('EDUC', 'Education', 'Transaction is related to a payment of study/tuition fees.', 'Registered', '2013-05-07'::date, '2013-05-06'::date, NULL, 'General'),
    ('EFTC', 'LowValueCredit', 'Utilities-Settlement of Low value Credit transactions.', 'Registered', '2021-08-31'::date, '2021-08-23'::date, NULL, 'CR1045'),
    ('EFTD', 'LowValueDebit', 'Utilities-Settlement of Low value Debit transactions.', 'Registered', '2021-08-31'::date, '2021-08-23'::date, NULL, 'CR1045'),
    ('ELEC', 'ElectricityBill', 'Transaction is related to a payment of electricity bill.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Utilities'),
    ('ENRG', 'Energies', 'Transaction is related to a utility operation.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Utilities'),
    ('EPAY', 'Epayment', 'Transaction is related to ePayment.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'E-Commerce'),
    ('EQPT', 'EquityOption', 'Cash collateral related to trading of equity option (Also known as stock options).', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('EQTS', 'Equities', 'Securities Lending-Settlement of Equities transactions.', 'Registered', '2021-08-31'::date, '2021-08-23'::date, NULL, 'CR1045'),
    ('EQUS', 'EquitySwap', 'Cash collateral related to equity swap trades where the return of an equity is exchanged for either a fixed or a floating rate of interest.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('ERPM', 'EmergencyReliefPayment', 'Emergency relief payments, e.g., receiving assistance after natural disasters, COVID relief payments, or emergency aid disbursements.', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, 'General'),
    ('ESCR', 'EscrowPayment', 'Financial intermediation services via an escrow account, e.g., real estate transactions, online marketplace purchases, business acquisitions, construction projects, legal settlements.', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, 'Finance'),
    ('ESTX', 'EstateTax', 'Transaction is related to a payment of estate tax.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Tax'),
    ('ETUP', 'EPurseTopUp', 'Transaction is related to a Service that is first reserving money from a card account and then is loading an e-purse application by this amount.', 'Registered', '2012-05-31'::date, '2012-05-31'::date, NULL, 'Card Settlement')
ON CONFLICT ("Code") DO NOTHING;
INSERT INTO public."ExternalPurpose1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('EXPT', 'ExoticOption', 'Cash collateral related to trading of an exotic option for example a non-standard option.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('EXTD', 'ExchangeTradedDerivatives', 'Cash collateral related to trading of exchanged traded derivatives in general (Opposite to Over the Counter (OTC)).', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('FACT', 'FactorUpdateRelatedPayment', 'Payment related to a factor update', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'General'),
    ('FAND', 'FinancialAidInCaseOfNaturalDisaster', 'Financial aid by State authorities for abolition of consequences of natural disasters.', 'Registered', '2012-07-16'::date, '2012-07-16'::date, NULL, 'General'),
    ('FCOL', 'FeeCollection', 'A Service that is settling card transaction related fees between two parties.', 'Registered', '2012-10-08'::date, '2012-10-08'::date, NULL, 'Card Settlement'),
    ('FCPM', 'LatePaymentOfFeesAndCharges', 'Transaction is the payment for late fees & charges. E.g Credit card charges', 'Registered', '2013-05-07'::date, '2013-05-06'::date, NULL, 'General'),
    ('FEES', 'PaymentOfFees', 'Payment of fees/charges.', 'Registered', '2017-11-01'::date, '2016-04-01'::date, NULL, 'General'),
    ('FERB', 'Ferry', 'Transaction is a payment for ferry related business.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Transport'),
    ('FGDL', 'FoodGroceryDelivery', 'Food/Grocery Delivery, e.g., delivery fees and payments through app-based food delivery services.', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, 'Subscriptions & Services'),
    ('FIXI', 'FixedIncome', 'Cash collateral related to a fixed income instrument', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('FLCR', 'FleetCard', 'Card Settlement-Settlement of Fleet transactions.', 'Registered', '2021-08-31'::date, '2021-08-23'::date, NULL, 'CR1045'),
    ('FNET', 'FuturesNettingPayment', 'Cash associated with a netting of futures payments. Refer to CCPM codeword for netting of initial and variation margin through a CCP', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Listed Derivatives'),
    ('FORW', 'ForwardForeignExchange', 'FX trades with a value date in the future.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Foreign Exchange'),
    ('FREX', 'ForeignExchange', 'Transaction is related to a foreign exchange operation.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Investment'),
    ('FUEL', 'Fuel', 'Fuel/Gas, e.g., purchases at gas stations for vehicle fuel or at charging stations for electric vehicles.', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, 'Transport'),
    ('FUTR', 'Futures', 'Cash related to futures trading activity.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Listed Derivatives'),
    ('FWBC', 'ForwardBrokerOwnedCashCollateral', 'Cash collateral payment against a Master Forward Agreement (MFA) where the cash is held in a segregated account and is not available for use by the client. Includes any instruments with a forward settling date such TBAs, repurchase agreements and bond forwards', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('FWCC', 'ForwardClientOwnedCashCollateral', 'Cash collateral payment against a Master Forward Agreement (MFA) where the cash is owned and may be used by the client when returned. Includes any instruments with a forward settling date such TBAs, repurchase agreements and bond forwards', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('FWLV', 'ForeignWorkerLevy', 'Transaction is related to a payment of Foreign Worker Levy', 'Registered', '2013-05-07'::date, '2013-05-06'::date, NULL, 'Tax'),
    ('FWSB', 'ForwardBrokerOwnedCashCollateralSegregated', 'Any cash payment related to the collateral for a Master Agreement forward, which is segregated, and not available for use by the client. Example master agreement forwards include TBA, repo and Bond Forwards.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('FWSC', 'ForwardClientOwnedSegregatedCashCollateral', 'Any cash payment related to the collateral for a Master agreement forward, which is owned by the client and is available for use by the client when it is returned to them from the segregated account. Example master agreement forwards include TBA, repo and Bond Forwards.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('FXNT', 'ForeignExchangeRelatedNetting', 'FX netting if cash is moved by separate wire instead of within the closing FX instruction', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Foreign Exchange'),
    ('GAFA', 'GovernmentFamilyAllowance', 'Salary and Benefits-Allowance from government to support family.', 'Registered', '2021-08-31'::date, '2021-08-24'::date, NULL, 'CR1052'),
    ('GAHO', 'GovernmentHousingAllowance', 'Salary and Benefits-Allowance from government to individuals to support payments of housing.', 'Registered', '2021-08-31'::date, '2021-08-24'::date, NULL, 'CR1052'),
    ('GAMB', 'GamblingOrWageringPayment', 'General-Payments towards a purchase or winnings received from gambling, betting or other wagering activities.', 'Registered', '2021-08-31'::date, '2021-08-24'::date, NULL, 'CR1049'),
    ('GASB', 'GasBill', 'Transaction is related to a payment of gas bill.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Utilities'),
    ('GDDS', 'PurchaseSaleOfGoods', 'Transaction is related to purchase and sale of goods.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Commercial'),
    ('GDSV', 'PurchaseSaleOfGoodsAndServices', 'Transaction is related to purchase and sale of goods and services.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, 'Commercial'),
    ('GFRP', 'GuaranteeFundRightsPayment', 'Compensation to unemployed persons during insolvency procedures.', 'Registered', '2012-07-16'::date, '2012-07-16'::date, NULL, 'Salary & Benefits'),
    ('GIFT', 'Gift', 'Payment with no commercial or statutory purpose.', 'Registered', '2021-05-01'::date, '2021-05-01'::date, NULL, 'General'),
    ('GOVG', 'GovernmentGrants', 'Government Grants, e.g., receiving funds for academic research, small business development, educational programs, or community initiatives.', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, 'General'),
    ('GOVI', 'GovernmentInsurance', 'Transaction is related to a payment of government insurance.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Finance'),
    ('GOVT', 'GovernmentPayment', 'Transaction is a payment to or from a government department.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'General'),
    ('GSCB', 'PurchaseSaleOfGoodsAndServicesWithCashBack', 'Transaction is related to purchase and sale of goods and services with cash back.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, 'Commercial'),
    ('GSTX', 'GoodsServicesTax', 'Transaction is the payment of Goods & Services Tax', 'Registered', '2013-05-07'::date, '2013-05-06'::date, NULL, 'Tax'),
    ('GVEA', 'AustrianGovernmentEmployeesCategoryA', 'Transaction is payment to category A Austrian government employees.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, 'Salary & Benefits'),
    ('GVEB', 'AustrianGovernmentEmployeesCategoryB', 'Transaction is payment to category B Austrian government employees.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, 'Salary & Benefits'),
    ('GVEC', 'AustrianGovernmentEmployeesCategoryC', 'Transaction is payment to category C Austrian government employees.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, 'Salary & Benefits'),
    ('GVED', 'AustrianGovernmentEmployeesCategoryD', 'Transaction is payment to category D Austrian government employees.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, 'Salary & Benefits'),
    ('GWLT', 'GovermentWarLegislationTransfer', 'Payment to victims of war violence and to disabled soldiers.', 'Registered', '2012-07-16'::date, '2012-07-16'::date, NULL, 'Salary & Benefits')
ON CONFLICT ("Code") DO NOTHING;
INSERT INTO public."ExternalPurpose1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('GYMM', 'GymMembership', 'Gym Membership, e.g., monthly or annual fees for fitness centers or health clubs.', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, 'Subscriptions & Services'),
    ('HEDG', 'Hedging', 'Transaction is related to a hedging operation.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Investment'),
    ('HLRP', 'PropertyLoanRepayment', 'Transaction is related to a payment of property loan.', 'Registered', '2021-08-31'::date, '2007-09-01'::date, NULL, 'Finance-Originator: Payments Harmonisation 2006 External Code List-Updated: CR1048-Bank of England'),
    ('HLST', 'PropertyLoanSettlement', 'Transaction is related to the settlement of a property loan.', 'Registered', '2021-08-31'::date, '2018-05-01'::date, NULL, 'Finance-Originator: CR0711/SADC-Updated: CR1048/Bank of England'),
    ('HLTC', 'HomeHealthCare', 'Transaction is a payment for home health care services.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Medical'),
    ('HLTI', 'HealthInsurance', 'Transaction is a payment of health insurance.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Medical'),
    ('HMMS', 'HomeMaintenanceServices', 'Home Maintenance Related, e.g., regular services for home cleaning, lawn care, pest control, or pool maintenance.', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, 'Subscriptions & Services'),
    ('HREC', 'HousingRelatedContribution', 'Transaction is a contribution by an employer to the housing expenditures (purchase, construction, renovation) of the employees within a tax free fringe benefit system.', 'Registered', '2014-11-28'::date, '2014-11-28'::date, NULL, 'Salary & Benefits'),
    ('HRPS', 'HomeRepairServices', 'Home Repair, e.g., one-time or emergency repairs for washer/dryer, damaged floors, plumbing issues, or electrical problems.', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, 'Subscriptions & Services'),
    ('HSPC', 'HospitalCare', 'Transaction is a payment for hospital care services.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Medical'),
    ('HSTX', 'HousingTax', 'Transaction is related to a payment of housing tax.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Tax'),
    ('ICCP', 'IrrevocableCreditCardPayment', 'Transaction is reimbursement of credit card payment.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, 'General'),
    ('ICRF', 'IntermediateCareFacility', 'Transaction is a payment for intermediate care facility services.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Medical'),
    ('IDCP', 'IrrevocableDebitCardPayment', 'Transaction is reimbursement of debit card payment.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, 'General'),
    ('IHRP', 'InstalmentHirePurchaseAgreement', 'Transaction is payment for an installment/hire-purchase agreement.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'General'),
    ('INBC', 'InterbankCharges', 'Settlement of charges in response to a prior interbank charge request.', 'Registered', '2025-08-29'::date, '2025-08-29'::date, NULL, NULL),
    ('INPC', 'InsurancePremiumCar', 'Transaction is a payment of car insurance premium.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, 'Finance'),
    ('INPR', 'InsurancePremiumRefund', 'Transaction is related to an insurance premium refund.', 'Registered', '2018-05-01'::date, '2018-05-01'::date, NULL, 'Finance'),
    ('INSC', 'PaymentOfInsuranceClaim', 'Transaction is related to the payment of an insurance claim.', 'Registered', '2018-05-01'::date, '2018-05-01'::date, NULL, 'Finance'),
    ('INSM', 'Installment', 'Transaction is related to a payment of an installment.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'General'),
    ('INSU', 'InsurancePremium', 'Transaction is payment of an insurance premium.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Finance'),
    ('INTC', 'IntraCompanyPayment', 'Transaction is an intra-company payment, ie, a payment between two companies belonging to the same group.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Cash Mgmt'),
    ('INTE', 'Interest', 'Transaction is payment of interest.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Finance'),
    ('INTP', 'IntraPartyPayment', 'Transaction is a payment between two accounts belonging to the same party (intra-party payment), where party is a natural person (identified by a private ID, not organisation ID).', 'Registered', '2021-05-01'::date, '2021-05-01'::date, NULL, 'Cash Mgmt'),
    ('INTX', 'IncomeTax', 'Transaction is related to a payment of income tax.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Tax'),
    ('INVS', 'InvestmentAndSecurities', 'Transaction is for the payment of mutual funds, investment products and shares', 'Registered', '2013-05-07'::date, '2013-05-06'::date, NULL, 'Investment'),
    ('IPAY', 'InstantPayments', 'Transaction in which the amount is available to the payee immediately.', 'Registered', '2018-08-01'::date, '2018-08-01'::date, NULL, 'Instant Payments'),
    ('IPCA', 'InstantPaymentsCancellation', 'Transaction in which the Return of the amount is fully returned.', 'Registered', '2018-08-01'::date, '2018-08-01'::date, NULL, 'Instant Payments'),
    ('IPDO', 'InstantPaymentsForDonations', 'Transaction in which the amount is available to the payee immediately, done for donations, with sending the address data of the payer.', 'Registered', '2018-08-01'::date, '2018-08-01'::date, NULL, 'Instant Payments'),
    ('IPEA', 'InstantPaymentsInECommerceWithoutAddressData', 'Transaction in which the amount is available to the payee immediately, done in E-commerce, without sending the address data of the payer.', 'Registered', '2018-08-01'::date, '2018-08-01'::date, NULL, 'Instant Payments'),
    ('IPEC', 'InstantPaymentsInECommerceWithAddressData', 'Transaction in which the amount is available to the payee immediately, done in E-commerce, with sending the address data of the payer.', 'Registered', '2018-08-01'::date, '2018-08-01'::date, NULL, 'Instant Payments'),
    ('IPEW', 'InstantPaymentsInECommerce', 'Transaction in which the amount is available to the payee immediately, done in E-commerce.', 'Registered', '2018-08-01'::date, '2018-08-01'::date, NULL, 'Instant Payments'),
    ('IPPS', 'InstantPaymentsAtPOS', 'Transaction in which the amount is available to the payee immediately, done at POS.', 'Registered', '2018-08-01'::date, '2018-08-01'::date, NULL, 'Instant Payments'),
    ('IPRT', 'InstantPaymentsReturn', 'Transaction in which the Return of the amount is fully or partial returned.', 'Registered', '2018-08-01'::date, '2018-08-01'::date, NULL, 'Instant Payments'),
    ('IPU2', 'InstantPaymentsUnattendedVendingMachineWith2FA', 'Transaction is made via an unattending vending machine by using 2-factor-authentification.', 'Registered', '2018-08-01'::date, '2018-08-01'::date, NULL, 'Instant Payments'),
    ('IPUW', 'InstantPaymentsUnattendedVendingMachineWithout2FA', 'Transaction is made via an unattending vending machine by without using 2-factor-authentification.', 'Registered', '2018-08-01'::date, '2018-08-01'::date, NULL, 'Instant Payments'),
    ('IVPT', 'InvoicePayment', 'Transaction is the payment for invoices.', 'Registered', '2013-05-07'::date, '2013-05-06'::date, NULL, 'General'),
    ('LBIN', 'LendingBuyInNetting', 'Net payment related to a buy-in. When an investment manager is bought in on a sell trade that fails due to a failed securities lending recall, the IM may seize the underlying collateral to pay for the buy-in. Any difference between the value of the collateral and the sell proceeds would be paid or received under this code', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Securities Lending'),
    ('LBRI', 'LaborInsurance', 'Transaction is a payment of labor insurance.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Finance'),
    ('LBXX', 'LongBoxTransfer', 'Transaction is related to a cash transfer from an underlying fund to a holding collateralization account (ie. Longbox) for potential further use as collateral or back to the fund in case it is not required anymore.', 'Registered', '2025-11-30'::date, '2025-11-30'::date, NULL, NULL)
ON CONFLICT ("Code") DO NOTHING;
INSERT INTO public."ExternalPurpose1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('LCOL', 'LendingCashCollateralFreeMovement', 'Free movement of cash collateral. Cash collateral paid by the borrower is done separately from the delivery of the shares at loan opening or return of collateral done separately from return of the loaned security. Note: common when the currency of the security is different the currency of the cash collateral.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Securities Lending'),
    ('LFEE', 'LendingFees', 'Fee payments, other than rebates, for securities lending. Includes (a) exclusive fees; (b) transaction fees; (c)
custodian fees; (d) minimum balance fees', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Securities Lending'),
    ('LICF', 'LicenseFee', 'Transaction is payment of a license fee.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Commercial'),
    ('LIFI', 'LifeInsurance', 'Transaction is a payment of life insurance.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Finance'),
    ('LIMA', 'LiquidityManagement', 'Bank initiated account transfer to support zero target balance management, pooling or sweeping.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Cash Mgmt'),
    ('LMEQ', 'LendingEquityMarkedToMarketCashCollateral', 'Cash collateral payments resulting from the marked-to-market of a portfolio of loaned equity securities', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Securities Lending'),
    ('LMFI', 'LendingFixedIncomeMarkedToMarketCashCollateral', 'Cash collateral payments resulting from the marked-to-market of a portfolio of loaned fixed income securities', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Securities Lending'),
    ('LMRK', 'LendingUnspecifiedTypeOfMarkedToMarketCashCollateral', 'Cash collateral payments resulting from the marked-to-market of a portfolio of loaned securities where the instrument
types are not specified', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Securities Lending'),
    ('LOAN', 'Loan', 'Transaction is related to transfer of loan to borrower.', 'Registered', '2009-04-01'::date, '2007-09-01'::date, NULL, 'Finance'),
    ('LOAR', 'LoanRepayment', 'Transaction is related to repayment of loan to lender.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Finance'),
    ('LOTT', 'LotteryPayment', 'General-Payment towards a purchase or winnings received from lottery activities.', 'Registered', '2021-08-31'::date, '2021-08-24'::date, NULL, 'CR1049'),
    ('LREB', 'LendingRebatePayments', 'Securities lending rebate payments', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Securities Lending'),
    ('LREV', 'LendingRevenuePayments', 'Revenue payments made by the lending agent to the client', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Securities Lending'),
    ('LSFL', 'LendingClaimPayment', 'Payments made by a borrower to a lending agent to satisfy claims made by the investment manager related to sell fails from late loan recall deliveries', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Securities Lending'),
    ('LTCF', 'LongTermCareFacility', 'Transaction is a payment for long-term care facility services.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Medical'),
    ('MAFC', 'MedicalAidFundContribution', 'Transaction is contribution to medical aid fund.', 'Registered', '2016-11-18'::date, '2016-09-01'::date, NULL, 'Medical'),
    ('MARF', 'MedicalAidRefund', 'Transaction is related to a medical aid refund.', 'Registered', '2018-05-01'::date, '2018-05-01'::date, NULL, 'Medical'),
    ('MARG', 'DailyMarginOnListedDerivatives', 'Daily margin on listed derivatives - not segregated as collateral associated with an FCM agreement. Examples include listed futures and options margin payments; premiums for listed options not covered in the MT54X message.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('MBSB', 'MBSBrokerOwnedCashCollateral', 'MBS Broker Owned Segregated (40Act/Dodd Frank) Cash Collateral - Any cash payment related to the collateral for a Mortgage Back Security, which is segregated, and not available for use by the client.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('MBSC', 'MBSClientOwnedCashCollateral', 'MBS Client Owned Cash Segregated (40Act/Dodd Frank) Cash Collateral - Any cash payment related to the collateral for a Mortgage Back Security, which is owned by the client and is available for use by the client when it is returned to them from the segregated account', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('MCDM', 'MultiCurrenyChequeDomestic', 'Transaction is the payment of a domestic multi-currency cheque', 'Registered', '2015-08-31'::date, '2015-08-31'::date, NULL, 'General'),
    ('MCFG', 'MultiCurrenyChequeForeign', 'Transaction is the payment of a foreign multi-currency cheque', 'Registered', '2015-08-31'::date, '2015-08-31'::date, NULL, 'General'),
    ('MDCS', 'MedicalServices', 'Transaction is a payment for medical care services.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Medical'),
    ('MDEP', 'MicroDeposit', 'Transaction is a small deposit, e.g., for account verification purposes.', 'Registered', '2026-05-22'::date, '2026-05-22'::date, NULL, NULL),
    ('MFSR', 'MutualFundSubscriptionRedemption', 'Payment related to shares settlement of a subscription or redemption order.', 'Registered', '2025-11-30'::date, '2025-11-30'::date, NULL, NULL),
    ('MGCC', 'FuturesInitialMargin', 'Initial futures margin. Where such payment is owned by the client and is available for use by them on return', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('MGSC', 'FuturesInitialMarginClientOwnedSegregatedCashCollateral', 'Margin Client Owned Segregated Cash Collateral - Any cash payment related to the collateral for initial futures margin, which is owned by the client and is available for use by the client when it is returned to them from the segregated account.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('MOMA', 'MoneyMarket', 'Securities Lending-ettlement of Money Market PCH.', 'Registered', '2021-08-31'::date, '2021-08-23'::date, NULL, 'CR1045'),
    ('MP2B', 'MobileP2BPayment', 'A service which enables a user to use an app on its mobile to pay a merchant or other business payees by initiating a payment message. Within this context, the account information or an alias of the payee might be transported through different channels to the app, for example QR Code, NFC, Bluetooth, other Networks.', 'Registered', '2017-05-01'::date, '2017-05-01'::date, NULL, 'Commercial'),
    ('MP2P', 'MobileP2PPayment', 'A service which enables a user to use an app on its mobile to initiate moving funds from his/her bank account to another person''s bank account while not using the account number  but an alias information like an MSISDN as account addressing information in his/her app.', 'Registered', '2017-05-01'::date, '2017-05-01'::date, NULL, 'Consumer'),
    ('MSVC', 'MultipleServiceTypes', 'Transaction is related to a payment for multiple service types.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'General'),
    ('MTUP', 'MobileTopUp', 'A Service that is first reserving money from a card account and then is loading a prepaid mobile phone amount by this amount.', 'Registered', '2012-02-09'::date, '2012-02-09'::date, NULL, 'Card Settlement'),
    ('NETT', 'Netting', 'Transaction is related to a netting operation.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Cash Mgmt'),
    ('NITX', 'NetIncomeTax', 'Transaction is related to a payment of net income tax.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, 'Tax'),
    ('NOWS', 'NotOtherwiseSpecified', 'Transaction is related to a payment for type of services not specified elsewhere.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'General'),
    ('NWCH', 'NetworkCharge', 'Transaction is related to a payment of network charges.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Utilities'),
    ('NWCM', 'NetworkCommunication', 'Transaction is related to a payment of network communication.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Utilities'),
    ('OCCC', 'ClientOwnedOCCPledgedCollateral', 'Client owned collateral identified as eligible for OCC pledging.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('OCDM', 'OrderChequeDomestic', 'Transaction is the payment of a domestic order cheque', 'Registered', '2015-08-31'::date, '2015-08-31'::date, NULL, 'General'),
    ('OCFG', 'OrderChequeForeign', 'Transaction is the payment of a foreign order cheque', 'Registered', '2015-08-31'::date, '2015-08-31'::date, NULL, 'General')
ON CONFLICT ("Code") DO NOTHING;
INSERT INTO public."ExternalPurpose1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('ODPY', 'OnDemandPayment', 'On demand/Real-time payments, e.g., Same-day wage access, gig economy payouts.', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, 'Salary & Benefits'),
    ('OFEE', 'OpeningFee', 'Transaction is related to a payment of opening fee.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'General'),
    ('OPBC', 'OTCOptionBrokerOwnedCashCollateral', 'Cash collateral payment for OTC options associated with an FCM agreement. Where such payment is segregated and not available for use by the client', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('OPCC', 'OTCOptionClientOwnedCashCollateral', 'Cash collateral payment for OTC options associated with an FCM agreement. Where such payment is not segregated and is available for use by the client upon return', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('OPSB', 'OTCOptionBrokerOwnedSegregatedCashCollateral', 'Option Broker Owned Segregated Cash Collateral - Any cash payment related to the collateral for an OTC option, which is segregated, and not available for use by the client.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('OPSC', 'OTCOptionClientOwnedCashSegregatedCashCollateral', 'Option Client Owned Cash Segregated Cash Collateral - Any cash payment related to the collateral for an OTC option, which is owned by the client and is available for use by the client when it is returned to them from the segregated account', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('OPTN', 'FXOption', 'Cash collateral related to trading of option on Foreign Exchange.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('OTCD', 'OTCDerivatives', 'Cash collateral related to Over-the-counter (OTC) Derivatives in general for example contracts which are traded and privately negotiated.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('OTHR', 'Other', 'Other payment purpose.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'General'),
    ('OTLC', 'OtherTelecomRelatedBill', 'Transaction is related to a payment of other telecom related bill.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Utilities'),
    ('PADD', 'PreauthorizedDebit', 'Transaction is related to a pre-authorized debit origination', 'Registered', '2009-04-01'::date, '2007-09-01'::date, NULL, 'General'),
    ('PAYR', 'Payroll', 'Transaction is related to the payment of payroll.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, 'Salary & Benefits'),
    ('PCOM', 'PropertyCompletionPayment', 'Final payment to complete the purchase of a property.', 'Registered', '2021-09-24'::date, '2021-09-23'::date, NULL, 'Classification: Finance'),
    ('PDEP', 'PropertyDeposit', 'Payment of the deposit required towards purchase of a property.', 'Registered', '2021-09-24'::date, '2021-09-23'::date, NULL, 'Classification: Finance'),
    ('PDLN', 'PayDayLoan', 'Pay Day Loan, e.g., short-term, high-interest loans typically due on borrower''s next payday.', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, 'Finance'),
    ('PEFC', 'PensionFundContribution', 'Transaction is contribution to pension fund.', 'Registered', '2016-11-18'::date, '2016-09-01'::date, NULL, 'Salary & Benefits'),
    ('PENO', 'PaymentBasedOnEnforcementOrder', 'Payment based on enforcement orders except those arising from judicial alimony decrees.', 'Registered', '2012-07-16'::date, '2012-07-16'::date, NULL, 'Finance'),
    ('PENS', 'PensionPayment', 'Transaction is the payment of pension.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Salary & Benefits'),
    ('PHON', 'TelephoneBill', 'Transaction is related to a payment of telephone bill.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Utilities'),
    ('PLDS', 'PropertyLoanDisbursement', 'Payment of funds from a lender as part of the issuance of a property loan.', 'Registered', '2021-09-24'::date, '2021-09-23'::date, NULL, 'Classification: Finance'),
    ('PLRF', 'PropertyLoanRefinancing', 'Transfer or extension of a property financing arrangement to a new deal or loan provider, without change of ownership of property.', 'Registered', '2021-09-24'::date, '2021-09-23'::date, NULL, 'Classification: Finance'),
    ('POPE', 'PointOfPurchaseEntry', 'Transaction is related to a payment associated with a Point of Purchase Entry.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, 'Commercial'),
    ('PPTI', 'PropertyInsurance', 'Transaction is a payment of property insurance.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Finance'),
    ('PRCP', 'PricePayment', 'Transaction is related to a payment of a price.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Salary & Benefits'),
    ('PRME', 'PreciousMetal', 'Transaction is related to a precious metal operation.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Investment'),
    ('PSDS', 'PersonalLoanDisbursement', 'Personal Loan Disbursement, e.g., disbursing funds for debt consolidation, home improvement, or major purchases.', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, 'Finance'),
    ('PTSP', 'PaymentTerms', 'Transaction is related to payment terms specifications', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'General'),
    ('PTXP', 'PropertyTax', 'Transaction is related to a payment of property tax.', 'Registered', '2013-05-07'::date, '2013-05-06'::date, NULL, 'Tax'),
    ('RAPI', 'RapidPaymentInstruction', 'Instant Payments-Settlement of Rapid Payment Instruction (RPI) transactions.', 'Registered', '2021-08-31'::date, '2021-08-23'::date, NULL, 'CR1045'),
    ('RCKE', 'RepresentedCheckEntry', 'Transaction is related to a payment associated with a re-presented check entry', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, 'General'),
    ('RCPT', 'ReceiptPayment', 'Transaction is related to a payment of receipt.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'General'),
    ('RDTX', 'RoadTax', 'Transaction is related to a payment of road tax.', 'Registered', '2013-05-07'::date, '2013-05-06'::date, NULL, 'Tax'),
    ('REBT', 'Rebate', 'Transaction is the payment of a rebate.', 'Registered', '2013-05-07'::date, '2013-05-06'::date, NULL, 'General'),
    ('REFU', 'Refund', 'Transaction is the payment of a refund.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, 'General'),
    ('RELG', 'RentalLeaseGeneral', 'Transaction is for general rental/lease.', 'Registered', '2016-11-18'::date, '2016-09-01'::date, NULL, 'Finance'),
    ('RENT', 'Rent', 'Transaction is the payment of rent.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'General'),
    ('REOD', 'AccountOverdraftRepayment', 'Transaction is for account overdraft repayment', 'Registered', '2016-11-18'::date, '2016-09-01'::date, NULL, 'General'),
    ('REPO', 'RepurchaseAgreement', 'Cash collateral related to a repurchase agreement transaction.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('RETL', 'RetailPayment', 'Retail payment including e-commerce and online shopping.', 'Registered', '2023-03-23'::date, '2023-03-23'::date, NULL, 'Retail Payment is a common business / financial classification, and distinct from existing codes GDDS (Purchase Sale Of Goods) and GDSV (Purchase Sale Of Goods And Services).'),
    ('RHBS', 'RehabilitationSupport', 'Benefit for the duration of occupational rehabilitation.', 'Registered', '2012-07-16'::date, '2012-07-16'::date, NULL, 'Salary & Benefits')
ON CONFLICT ("Code") DO NOTHING;
INSERT INTO public."ExternalPurpose1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('RHSV', 'RideHailingServices', 'Ride-hailing/Delivery Service, e.g., payments for app-based rides.', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, 'Subscriptions & Services'),
    ('RIMB', 'ReimbursementOfAPreviousErroneousTransaction', 'Transaction is related to a reimbursement of a previous erroneous transaction.', 'Registered', '2013-12-02'::date, '2013-11-29'::date, NULL, 'General'),
    ('RINP', 'RecurringInstallmentPayment', 'Transaction is related to a payment of a recurring installment made at regular intervals.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Finance'),
    ('RLWY', 'Railway', 'Transaction is a payment for railway transport related business.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Transport'),
    ('RMCO', 'RegisteredMandate', 'Utilities-Settlement of Unauthenticated Collections transactions.', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('ROYA', 'Royalties', 'Transaction is the payment of royalties.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Commercial'),
    ('RPBC', 'BilateralRepoBrokerOwnedCollateral', 'Bi-lateral repo broker owned collateral associated with a repo master agreement - GMRA or MRA Master Repo Agreements.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('RPCC', 'RepoClientOwnedCollateral', 'Repo client owned collateral associated with a repo master agreement - GMRA or MRA Master Repo Agreements', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('RPNT', 'BilateralRepoInternetNetting', 'Bi-lateral repo interest net/bulk payment at rollover/pair-off or other closing scenarios where applicable.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'General'),
    ('RPSB', 'BilateralRepoBrokerOwnedSegregatedCashCollateral', 'Bi-lateral repo broker owned segregated cash collateral associated with a repo master agreement.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('RPSC', 'BilateralRepoClientOwnedSegregatedCashCollateral', 'Repo client owned segregated collateral associated with a repo master agreement.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('RRBN', 'RoundRobin', 'Cash payment resulting from a Round Robin', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'General'),
    ('RRCT', 'ReimbursementReceivedCreditTransfer', 'Transaction is related to a reimbursement for commercial reasons of a correctly received credit transfer.', 'Registered', '2018-11-01'::date, '2018-11-01'::date, NULL, 'General'),
    ('RRTP', 'RelatedRequestToPay', 'Transaction is related to a Request to Pay.', 'Registered', '2021-02-01'::date, '2021-02-01'::date, NULL, 'General'),
    ('RVPM', 'ReceiveAgainstPayment', 'Code used to pre-advise the account servicer of a forthcoming receive against payment instruction.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'General'),
    ('RVPO', 'ReverseRepurchaseAgreement', 'Cash collateral related to a reverse repurchase agreement transaction.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('SALA', 'SalaryPayment', 'Transaction is the payment of salaries.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Salary & Benefits'),
    ('SASW', 'ATM', 'Card Settlement-Settlement of ATM transactions.', 'Registered', '2021-08-31'::date, '2021-08-23'::date, NULL, 'CR1045'),
    ('SAVG', 'Savings', 'Transfer to / from savings or to retirement account.', 'Registered', '2024-08-30'::date, '2007-09-01'::date, NULL, 'Investment'),
    ('SBSC', 'SecuritiesBuySellSellBuyBack', 'Cash collateral related to a Securities Buy Sell Sell Buy Back', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('SCAC', 'SchoolActivities', 'Transaction is related to payment for school activities, extracurricular programs.', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, 'General'),
    ('SCIE', 'SingleCurrencyIRSExotic', 'Cash collateral related to Exotic single currency interest rate swap.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('SCIR', 'SingleCurrencyIRS', 'Cash collateral related to Single Currency Interest Rate Swap.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('SCRP', 'SecuritiesCrossProducts', 'Cash collateral related to Combination of securities-related exposure types.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('SCVE', 'PurchaseSaleOfServices', 'Transaction is related to purchase and sale of services.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Commercial'),
    ('SECU', 'Securities', 'Transaction is the payment of securities.', 'Registered', '2009-04-01'::date, '2007-09-01'::date, NULL, 'Investment'),
    ('SEPI', 'SecuritiesPurchaseInhouse', 'Transaction is the payment of a purchase of securities where custodian bank and current account servicing bank coincide', 'Registered', '2012-10-08'::date, '2012-10-08'::date, NULL, 'Investment'),
    ('SERV', 'ServiceCharges', 'Transaction is related to service charges charged by a service provider.', 'Registered', '2018-05-01'::date, '2018-05-01'::date, NULL, 'Commercial'),
    ('SHBC', 'BrokerOwnedCollateralShortSale', 'Short Sale broker owned collateral associated with a prime broker agreement.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('SHCC', 'ClientOwnedCollateralShortSale', 'Short Sale client owned collateral associated with a prime brokerage agreement.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('SHSL', 'ShortSell', 'Cash Collateral related to a Short Sell', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('SLDS', 'StudentLoanDisbursement', 'Student Loan Disbursement, e.g., disbursing tuition funds to educational institutions or directly to students.', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, 'Finance'),
    ('SLEB', 'SecuritiesLendingAndBorrowing', 'Cash collateral related to Securities lending and borrowing.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('SLOA', 'SecuredLoan', 'Cash collateral related to a Secured loan.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('SLPI', 'PaymentSlipInstruction', 'Transaction is payment of a well formatted payment slip.', 'Registered', '2016-05-11'::date, '2016-04-01'::date, NULL, 'General'),
    ('SPLT', 'SplitPayments', 'Split payments. To be used when cash and security movements for a security trade settlement are instructed
separately.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'General'),
    ('SPSP', 'SalaryPensionSumPayment', 'Salary or pension payment for more months in one amount or a delayed payment of salaries or pensions.', 'Registered', '2018-11-01'::date, '2018-11-01'::date, NULL, 'Salary & Benefits'),
    ('SSBE', 'SocialSecurityBenefit', 'Transaction is a social security benefit, ie payment made by a government to support individuals.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Salary & Benefits'),
    ('STDY', 'Study', 'Transaction is related to a payment of study/tuition costs.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'General'),
    ('STRM', 'StreamingServices', 'Streaming Services, e.g., monthly subscriptions to digital content platforms.', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, 'Subscriptions & Services')
ON CONFLICT ("Code") DO NOTHING;
INSERT INTO public."ExternalPurpose1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('SUBS', 'Subscription', 'Transaction is related to a payment of information or entertainment services either in printed or electronic form.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Commercial'),
    ('SUPP', 'SupplierPayment', 'Transaction is related to a payment to a supplier.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Commercial'),
    ('SWBC', 'SwapBrokerOwnedCashCollateral', 'Cash collateral payment for swaps associated with an ISDA agreement. . Where such payment is segregated and
not available for use by the client. Includes any cash collateral payments made under the terms of a CSA agreement
for instruments such as swaps and FX forwards.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('SWCC', 'SwapClientOwnedCashCollateral', 'Cash collateral payment for swaps associated with an ISDA agreement. Where such payment is not segregated and
is available for use by the client upon return. Includes any cash collateral payments made under the terms of a CSA
agreement for instruments such as swaps and FX forwards.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('SWFP', 'SwapContractFinalPayment', 'Final payments for a swap contract', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'OTC Derivatives'),
    ('SWPP', 'SwapContractPartialPayment', 'Partial payment for a swap contract', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'OTC Derivatives'),
    ('SWPT', 'Swaption', 'Cash collateral related to an option on interest rate swap.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('SWRS', 'SwapContractResetPayment', 'Reset payment for a swap contract', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'OTC Derivatives'),
    ('SWSB', 'SwapsBrokerOwnedSegregatedCashCollateral', 'Swaps Broker Owned Segregated Cash Collateral - Any cash payment related to the collateral for Swap margin ,
which is segregated, and not available for use by the client. This includes any collateral identified in a CSA
agreement such as Swap or FX Forward collateral.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('SWSC', 'SwapsClientOwnedSegregatedCashCollateral', 'Swaps Client Owned Segregated Cash Collateral - Any cash payment related to the collateral for Swap margin,
which is owned by the client and is available for use by the client when returned from the segregated account. This
includes any collateral identified in a CSA agreement such as Swap or FX Forward collateral.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('SWUF', 'SwapContractUpfrontPayment', 'Upfront payment for a swap contract', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'OTC Derivatives'),
    ('TAXR', 'TaxRefund', 'Transaction is the refund of a tax payment or obligation.', 'Registered', '2012-02-09'::date, '2012-02-09'::date, NULL, 'Tax'),
    ('TAXS', 'TaxPayment', 'Transaction is the payment of taxes.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Tax'),
    ('TBAN', 'TBAPairOffNetting', 'TBA pair-off cash wire net movement', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'General'),
    ('TBAS', 'ToBeAnnounced', 'Cash collateral related to a To Be Announced (TBA)', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('TBBC', 'TBABrokerOwnedCashCollateral', 'Cash collateral payment (segregated) for TBA securities associated with a TBA Master Agreement. Where such payment is segregated and not available for use by the client.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('TBCC', 'TBAClientOwnedCashCollateral', 'Cash collateral payment (for use by client)for TBA securities associated with a TBA Master Agreement. Where such payment is not segregated and is available for use by the client upon return.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('TBIL', 'TelecommunicationsBill', 'Transaction is related to a payment of telecommunications related bill.', 'Registered', '2013-05-07'::date, '2013-05-06'::date, NULL, 'General'),
    ('TCSC', 'TownCouncilServiceCharges', 'Transaction is related to a payment associated with charges levied by a town council.', 'Registered', '2013-05-07'::date, '2013-05-06'::date, NULL, 'General'),
    ('TELI', 'TelephoneInitiatedTransaction', 'Transaction is related to a payment initiated via telephone.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, 'General'),
    ('TIPS', 'TipsGratuity', 'Tip/Gratuity, e.g., additional payments for service workers at restaurants, hotels, salons, or through digital tipping platforms.', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, 'General'),
    ('TLRF', 'NonUSMutualFundTrailerFeePayment', 'Any non-US mutual fund trailer fee (retrocession) payment (use ISIN to determine onshore versus offshore designation)', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Trailer Fee'),
    ('TLRR', 'NonUSMutualFundTrailerFeeRebatePayment', 'Any non-US mutual fund trailer fee (retrocession) rebate payment (use ISIN to determine onshore versus offshore designation)', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Trailer Fee'),
    ('TMPG', 'TMPGClaimPayment', 'Cash payment resulting from a TMPG Claim', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'General'),
    ('TNTP', 'TaxNeutralPensionTransfer', 'Transaction is a tax-neutral transfer of existing pension balance.', 'Registered', '2026-05-22'::date, '2026-05-22'::date, NULL, NULL),
    ('TOLL', 'Tolls', 'Tolls, e.g., payments for road tolls, bridges, tunnels, or electronic toll collection systems.', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, 'Transport'),
    ('TPRI', 'TriPartyRepoInterest', 'Tri-Party Repo related interest', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'General'),
    ('TPRP', 'TriPartyRepoNetting', 'Tri-party Repo related net gain/loss cash movement', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'General'),
    ('TRAD', 'Commercial', 'Transaction is related to a trade services operation.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Commercial'),
    ('TRCP', 'TreasuryCrossProduct', 'Cash collateral related to a combination of treasury-related exposure types.', 'Registered', '2016-04-01'::date, '2016-01-01'::date, NULL, 'Collateral'),
    ('TREA', 'TreasuryPayment', 'Transaction is related to treasury operations.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Investment'),
    ('TRFD', 'TrustFund', 'Transaction is related to a payment of a trust fund.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Finance'),
    ('TRNC', 'TruncatedPaymentSlip', 'Transaction is payment of a beneficiary prefilled payment slip where beneficiary to payer information is truncated.', 'Registered', '2016-05-11'::date, '2016-04-01'::date, NULL, 'General'),
    ('TRPT', 'RoadPricing', 'Transaction is for the payment to top-up pre-paid card and electronic road pricing for the purpose of transportation', 'Registered', '2013-05-07'::date, '2013-05-06'::date, NULL, 'Transport'),
    ('TRVC', 'TravellerCheque', 'Transaction is the payment of a travellers cheque', 'Registered', '2015-08-31'::date, '2015-08-31'::date, NULL, 'General'),
    ('TRVL', 'TravelAndHospitality', 'Generic code for travel and hospitality related transactions, e.g., hotel bookings, vacation rentals, travel packages, or direct hotel reservations.', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, 'Travel & Hospitality'),
    ('UBIL', 'Utilities', 'Transaction is for the payment to common utility provider that provide gas, water and/or electricity.', 'Registered', '2013-05-07'::date, '2013-05-06'::date, NULL, 'Utilities'),
    ('UNIT', 'UnitTrustPurchase', 'Transaction is purchase of Unit Trust', 'Registered', '2016-11-18'::date, '2016-09-01'::date, NULL, 'Investment'),
    ('VATX', 'ValueAddedTaxPayment', 'Transaction is the payment of value added tax.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Tax'),
    ('VIEW', 'VisionCare', 'Transaction is a payment for vision care services.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Medical')
ON CONFLICT ("Code") DO NOTHING;
INSERT INTO public."ExternalPurpose1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('WALM', 'WalletFundingMultiUse', 'Account transfer funding a multi-use wallet.', 'Registered', '2026-05-22'::date, '2026-05-22'::date, NULL, NULL),
    ('WALS', 'WalletFundingSingle', 'Account transfer funding a single purpose wallet.', 'Registered', '2026-05-22'::date, '2026-05-22'::date, NULL, NULL),
    ('WALT', 'WalletTransactions', 'Transaction is related to digital wallet funding or defunding.', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, 'Digital Wallets'),
    ('WEBI', 'InternetInitiatedTransaction', 'Transaction is related to a payment initiated via internet.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, 'General'),
    ('WHLD', 'WithHolding', 'Transaction is related to a payment of withholding tax.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, 'Tax'),
    ('WTER', 'WaterBill', 'Transaction is related to a payment of water bill.', 'Registered', '2007-09-01'::date, '2007-09-01'::date, NULL, 'Utilities')
ON CONFLICT ("Code") DO NOTHING;
-- Seed: ExternalReturnReason1CodeValues (104 codes)
INSERT INTO public."ExternalReturnReason1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('AC01', 'IncorrectAccountNumber', 'Format of the account number specified is not correct', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('AC02', 'InvalidDebtorAccountNumber', 'Debtor account number invalid or missing.', 'Registered', '2021-08-31'::date, '2021-08-23'::date, NULL, 'CR0965'),
    ('AC03', 'InvalidCreditorAccountNumber', 'Wrong IBAN in SCT', 'Registered', '2012-10-08'::date, '2012-10-08'::date, NULL, NULL),
    ('AC04', 'ClosedAccountNumber', 'Account number specified has been closed on the bank of account''s books', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('AC06', 'BlockedAccount', 'Account specified is blocked, prohibiting posting of transactions against it.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('AC07', 'ClosedCreditorAccountNumber', 'Creditor account number closed.', 'Registered', '2021-08-31'::date, '2021-08-23'::date, NULL, 'CR0965'),
    ('AC13', 'InvalidDebtorAccountType', 'Debtor account type is missing or invalid', 'Registered', '2013-05-07'::date, '2013-05-06'::date, NULL, NULL),
    ('AC14', 'InvalidAgent', 'An agent in the payment chain is invalid.', 'Registered', '2016-11-18'::date, '2016-09-01'::date, NULL, NULL),
    ('AC15', 'AccountDetailsChanged', 'Account details have changed.', 'Registered', '2019-02-01'::date, '2019-02-01'::date, NULL, NULL),
    ('AC16', 'AccountInSequestration', 'Account is in sequestration.', 'Registered', '2019-02-01'::date, '2019-02-01'::date, NULL, NULL),
    ('AC17', 'AccountInLiquidation', 'Account is in liquidation.', 'Registered', '2019-02-01'::date, '2019-02-01'::date, NULL, NULL),
    ('AG01', 'TransactionForbidden', 'Transaction forbidden on this type of account (formerly NoAgreement)', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('AG02', 'InvalidBankOperationCode', 'Bank Operation code specified in the message is not valid for receiver', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('AG07', 'UnsuccesfulDirectDebit', 'Debtor account cannot be debited for a generic reason.
Usage: Code value may be used in general purposes and as a replacement for AM04 if debtor bank does not reveal its customer''s insufficient funds for privacy reasons.', 'Registered', '2021-08-31'::date, '2021-08-23'::date, NULL, 'CR0965'),
    ('AGNT', 'IncorrectAgent', 'Agent in the payment workflow is incorrect.', 'Registered', '2021-08-31'::date, '2021-08-23'::date, NULL, 'CR0965'),
    ('AM01', 'ZeroAmount', 'Specified message amount is equal to zero', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('AM02', 'NotAllowedAmount', 'Specific transaction/message amount is greater than allowed maximum', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('AM03', 'NotAllowedCurrency', 'Specified message amount is an non processable currency outside of existing agreement', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('AM04', 'InsufficientFunds', 'Amount of funds available to cover specified message amount is insufficient.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('AM05', 'Duplication', 'Duplication', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('AM06', 'TooLowAmount', 'Specified transaction amount is less than agreed minimum.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('AM07', 'BlockedAmount', 'Amount specified in message has been blocked by regulatory authorities.', 'Registered', '2020-11-01'::date, '2009-04-01'::date, NULL, NULL),
    ('AM09', 'WrongAmount', 'Amount received is not the amount agreed or expected', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('AM10', 'InvalidControlSum', 'Sum of instructed amounts does not equal the control sum.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('ARDT', 'AlreadyReturnedTransaction', 'Already returned original SCT', 'Registered', '2012-10-08'::date, '2012-10-08'::date, NULL, NULL),
    ('BE01', 'InconsistentWithEndCustomer', 'Identification of end customer is not consistent with associated account number, organisation ID or private ID.', 'Registered', '2021-05-01'::date, '2009-04-01'::date, NULL, NULL),
    ('BE04', 'MissingCreditorAddress', 'Specification of creditor''s address, which is required for payment, is missing/not correct (formerly IncorrectCreditorAddress).', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('BE05', 'UnrecognisedInitiatingParty', 'Party who initiated the message is not recognised by the end customer', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('BE06', 'UnknownEndCustomer', 'End customer specified is not known at associated Sort/National Bank Code or does no longer exist in the books', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('BE07', 'MissingDebtorAddress', 'Specification of debtor''s address, which is required for payment, is missing/not correct.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('BE08', 'BankError', 'Returned as a result of a bank error.', 'Registered', '2016-04-01'::date, '2016-03-01'::date, NULL, NULL),
    ('BE10', 'InvalidDebtorCountry', 'Debtor country code is missing or invalid.', 'Registered', '2021-08-31'::date, '2021-08-23'::date, NULL, 'CR0965'),
    ('BE11', 'InvalidCreditorCountry', 'Creditor country code is missing or invalid.', 'Registered', '2021-08-31'::date, '2021-08-23'::date, NULL, 'CR0965'),
    ('BE16', 'InvalidDebtorIdentificationCode', 'Debtor or Ultimate Debtor identification code missing or invalid.', 'Registered', '2021-08-31'::date, '2021-08-23'::date, NULL, 'CR0965'),
    ('BE17', 'InvalidCreditorIdentificationCode', 'Creditor or Ultimate Creditor identification code missing or invalid.', 'Registered', '2021-08-31'::date, '2021-08-23'::date, NULL, 'CR0965'),
    ('CN01', 'AuthorisationCancelled', 'Authorisation is cancelled.', 'Registered', '2019-02-01'::date, '2019-02-01'::date, NULL, NULL),
    ('CNOR', 'CreditorBankIsNotRegistered', 'Creditor bank is not registered under this BIC in the CSM', 'Registered', '2012-07-16'::date, '2012-07-16'::date, NULL, NULL),
    ('CNPC', 'CashNotPickedUp', 'Cash not picked up by Creditor or cash could not be delivered to Creditor', 'Registered', '2021-05-01'::date, '2021-05-01'::date, NULL, NULL),
    ('CURR', 'IncorrectCurrency', 'Currency of the payment is incorrect', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('CUST', 'RequestedByCustomer', 'Cancellation requested by the Debtor', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL)
ON CONFLICT ("Code") DO NOTHING;
INSERT INTO public."ExternalReturnReason1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('DC04', 'NoCustomerCreditTransferReceived', 'Return of Covering Settlement due to the underlying Credit Transfer details not being received.', 'Registered', '2022-05-31'::date, '2022-05-31'::date, NULL, NULL),
    ('DNOR', 'DebtorBankIsNotRegistered', 'Debtor bank is not registered under this BIC in the CSM', 'Registered', '2012-07-16'::date, '2012-07-16'::date, NULL, NULL),
    ('DS28', 'ReturnForTechnicalReason', 'Return following technical problems resulting in erroneous transaction.', 'Registered', '2016-11-18'::date, '2016-09-01'::date, NULL, NULL),
    ('DT01', 'InvalidDate', 'Invalid date (eg, wrong settlement date)', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('DT02', 'ChequeExpired', 'Cheque has been issued but not deposited and is considered expired.', 'Registered', '2021-05-01'::date, '2021-05-01'::date, NULL, NULL),
    ('DT04', 'FutureDateNotSupported', 'Future date not supported.', 'Registered', '2023-03-23'::date, '2023-03-23'::date, NULL, NULL),
    ('DUPL', 'DuplicatePayment', 'Payment is a duplicate of another payment.', 'Registered', '2023-03-23'::date, '2023-03-23'::date, NULL, NULL),
    ('ED01', 'CorrespondentBankNotPossible', 'Correspondent bank not possible.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('ED03', 'BalanceInfoRequest', 'Balance of payments complementary info is requested', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('ED05', 'SettlementFailed', 'Settlement of the transaction has failed.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('EMVL', 'EMVLiabilityShift', 'The card payment is fraudulent and was not processed with EMV technology for an EMV card.', 'Registered', '2012-02-09'::date, '2012-02-09'::date, NULL, NULL),
    ('ERIN', 'ERIOptionNotSupported', 'The Extended Remittance Information (ERI) option is not supported.', 'Registered', '2018-11-01'::date, '2018-11-01'::date, NULL, NULL),
    ('FF03', 'InvalidPaymentTypeInformation', 'Payment Type Information is missing or invalid.
Generic usage if cannot specify Service Level or Local Instrument code.', 'Registered', '2021-08-31'::date, '2021-08-23'::date, NULL, 'CR0965'),
    ('FF04', 'InvalidServiceLevelCode', 'Service Level code is missing or invalid.', 'Registered', '2021-08-31'::date, '2021-08-23'::date, NULL, 'CR0965'),
    ('FF05', 'InvalidLocalInstrumentCode', 'Local Instrument code is missing or invalid', 'Registered', '2013-05-07'::date, '2013-05-06'::date, NULL, NULL),
    ('FF06', 'InvalidCategoryPurposeCode', 'Category Purpose code is missing or invalid.', 'Registered', '2021-08-31'::date, '2021-08-23'::date, NULL, 'CR0965'),
    ('FF07', 'InvalidPurpose', 'Purpose is missing or invalid.', 'Registered', '2021-08-31'::date, '2021-08-23'::date, NULL, 'CR0965'),
    ('FOCR', 'FollowingCancellationRequest', 'Return following a cancellation request', 'Registered', '2010-01-01'::date, '2010-01-01'::date, NULL, NULL),
    ('FR01', 'Fraud', 'Returned as a result of fraud.', 'Registered', '2016-04-01'::date, '2016-03-01'::date, NULL, NULL),
    ('FRTR', 'FinalResponseMandateCancelled', 'Final response/tracking is recalled as mandate is cancelled.', 'Registered', '2016-11-18'::date, '2016-09-01'::date, NULL, NULL),
    ('G004', 'CreditPendingFunds', 'In a FIToFI Customer Credit Transfer: Credit to the creditor''s account is pending, status Originator is waiting for funds provided via a cover. Update will follow from the Status Originator.', 'Registered', '2021-08-31'::date, '2021-08-23'::date, NULL, 'CR0965'),
    ('MD01', 'NoMandate', 'No Mandate', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('MD02', 'MissingMandatoryInformationInMandate', 'Mandate related information data required by the scheme is missing.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('MD05', 'CollectionNotDue', 'Creditor or creditor''s agent should not have collected the direct debit.', 'Registered', '2021-08-31'::date, '2021-08-23'::date, NULL, 'CR0965'),
    ('MD06', 'RefundRequestByEndCustomer', 'Return of funds requested by end customer', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('MD07', 'EndCustomerDeceased', 'End customer is deceased.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('MS02', 'NotSpecifiedReasonCustomerGenerated', 'Reason has not been specified by end customer', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('MS03', 'NotSpecifiedReasonAgentGenerated', 'Reason has not been specified by agent.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('NARR', 'Narrative', 'Reason is provided as narrative information in the additional reason information.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('NOAS', 'NoAnswerFromCustomer', 'No response from Beneficiary', 'Registered', '2012-10-08'::date, '2012-10-08'::date, NULL, NULL),
    ('NOCM', 'NotCompliant', 'Customer account is not compliant with regulatory requirements, for example FICA (in South Africa) or any other regulatory requirements which render an account inactive for certain processing.', 'Registered', '2019-02-01'::date, '2019-02-01'::date, NULL, NULL),
    ('NOOR', 'NoOriginalTransactionReceived', 'Original SCT never received', 'Registered', '2012-10-08'::date, '2012-10-08'::date, NULL, NULL),
    ('PINL', 'PINLiabilityShift', 'The card payment is fraudulent (lost and stolen fraud) and was processed as EMV transaction without PIN verification.', 'Registered', '2012-02-09'::date, '2012-02-09'::date, NULL, NULL),
    ('RC01', 'BankIdentifierIncorrect', 'Bank Identifier code specified in the message has an incorrect format (formerly IncorrectFormatForRoutingCode).', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('RC03', 'InvalidDebtorBankIdentifier', 'Debtor bank identifier is invalid or missing.', 'Registered', '2023-03-23'::date, '2023-03-23'::date, NULL, NULL),
    ('RC04', 'InvalidCreditorBankIdentifier', 'Creditor bank identifier is invalid or missing.', 'Registered', '2023-03-23'::date, '2023-03-23'::date, NULL, NULL),
    ('RC07', 'InvalidCreditorBICIdentifier', 'Incorrrect BIC of the beneficiary Bank in the SCTR', 'Registered', '2012-10-08'::date, '2012-10-08'::date, NULL, NULL),
    ('RC08', 'InvalidClearingSystemMemberIdentifier', 'ClearingSystemMemberidentifier is invalid or missing.
Generic usage if cannot specify between debit or credit account.', 'Registered', '2021-08-31'::date, '2021-08-23'::date, NULL, 'CR0965'),
    ('RC11', 'InvalidIntermediaryAgent', 'Intermediary Agent is invalid or missing.', 'Registered', '2021-08-31'::date, '2021-08-23'::date, NULL, 'CR0965'),
    ('RF01', 'NotUniqueTransactionReference', 'Transaction reference is not unique within the message.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL)
ON CONFLICT ("Code") DO NOTHING;
INSERT INTO public."ExternalReturnReason1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('RR01', 'MissingDebtorAccountOrIdentification', 'Specification of the debtor''s account or unique identification needed for reasons of regulatory requirements is insufficient or missing', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('RR02', 'MissingDebtorNameOrAddress', 'Specification of the debtor''s name and/or address needed for regulatory requirements is insufficient or missing.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('RR03', 'MissingCreditorNameOrAddress', 'Specification of the creditor''s name and/or address needed for regulatory requirements is insufficient or missing.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('RR04', 'RegulatoryReason', 'Regulatory Reason', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('RR05', 'RegulatoryInformationInvalid', 'Regulatory or Central Bank Reporting information missing, incomplete or invalid.', 'Registered', '2021-08-31'::date, '2021-08-23'::date, NULL, 'CR0965'),
    ('RR06', 'TaxInformationInvalid', 'Tax information missing, incomplete or invalid.', 'Registered', '2021-08-31'::date, '2021-08-23'::date, NULL, 'CR0965'),
    ('RR07', 'RemittanceInformationInvalid', 'Remittance information structure does not comply with rules for payment type.', 'Registered', '2021-08-31'::date, '2021-08-23'::date, NULL, 'CR0965'),
    ('RR08', 'RemittanceInformationTruncated', 'Remittance information truncated to comply with rules for payment type.', 'Registered', '2021-08-31'::date, '2021-08-23'::date, NULL, 'CR0965'),
    ('RR09', 'InvalidStructuredCreditorReference', 'Structured creditor reference invalid or missing.', 'Registered', '2021-08-31'::date, '2021-08-23'::date, NULL, 'CR0965'),
    ('RR11', 'InvalidDebtorAgentServiceIdentification', 'Invalid or missing identification of a bank proprietary service.', 'Registered', '2021-08-31'::date, '2021-08-23'::date, NULL, 'CR0965'),
    ('RR12', 'InvalidPartyIdentification', 'Invalid or missing identification required within a particular country or payment type.', 'Registered', '2021-08-31'::date, '2021-08-23'::date, NULL, 'CR0965'),
    ('RUTA', 'ReturnUponUnableToApply', 'Return following investigation request and no remediation possible.', 'Registered', '2016-11-18'::date, '2016-09-01'::date, NULL, NULL),
    ('SL01', 'SpecificServiceOfferedByDebtorAgent', 'Due to specific service offered by the Debtor Agent', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('SL02', 'SpecificServiceOfferedByCreditorAgent', 'Due to specific service offered by the Creditor Agent', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('SL11', 'CreditorNotOnWhitelistOfDebtor', 'Whitelisting service offered by the Debtor Agent; Debtor has not included the Creditor on its "Whitelist" (yet). In the Whitelist the Debtor may list all allowed Creditors to debit Debtor bank account.', 'Registered', '2016-04-01'::date, '2016-03-01'::date, NULL, NULL),
    ('SL12', 'CreditorOnBlacklistOfDebtor', 'Blacklisting service offered by the Debtor Agent; Debtor included the Creditor on his "Blacklist". In the Blacklist the Debtor may list all Creditors not allowed to debit Debtor bank account.', 'Registered', '2016-04-01'::date, '2016-03-01'::date, NULL, NULL),
    ('SL13', 'MaximumNumberOfDirectDebitTransactionsExceeded', 'Due to Maximum allowed Direct Debit Transactions per period service offered by the Debtor Agent.', 'Registered', '2016-04-01'::date, '2016-03-01'::date, NULL, NULL),
    ('SL14', 'MaximumDirectDebitTransactionAmountExceeded', 'Due to Maximum allowed Direct Debit Transaction amount service offered by the Debtor Agent.', 'Registered', '2016-04-01'::date, '2016-03-01'::date, NULL, NULL),
    ('SP01', 'PaymentStopped', 'Payment is stopped by account holder.', 'Registered', '2019-02-01'::date, '2019-02-01'::date, NULL, NULL),
    ('SP02', 'PreviouslyStopped', 'Previously stopped by means of a stop payment advise.', 'Registered', '2019-02-01'::date, '2019-02-01'::date, NULL, NULL),
    ('SVNR', 'ServiceNotRendered', 'The card payment is returned since a cash amount rendered was not correct or goods or a service was not rendered to the customer, e.g. in an e-commerce situation.', 'Registered', '2012-02-09'::date, '2012-02-09'::date, NULL, NULL),
    ('TM01', 'CutOffTime', 'Associated message was received after agreed processing cut-off time.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('TRAC', 'RemovedFromTracking', 'Return following direct debit being removed from tracking process.', 'Registered', '2016-11-18'::date, '2016-09-01'::date, NULL, NULL),
    ('UPAY', 'UnduePayment', 'Payment is not justified.', 'Registered', '2016-11-18'::date, '2016-09-01'::date, NULL, NULL)
ON CONFLICT ("Code") DO NOTHING;
-- Seed: ExternalReversalReason1CodeValues (11 codes)
INSERT INTO public."ExternalReversalReason1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('AC03', 'InvalidCreditorAccountNumber', 'Wrong IBAN in  SCT', 'Registered', '2012-10-08'::date, '2012-10-08'::date, NULL, NULL),
    ('AC04', 'ClosedAccountNumber', 'Account number specified has been closed on the Receiver''s books', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('AG02', 'InvalidBankOperationCode', 'Bank Operation code specified in the message is not valid for receiver', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('AM05', 'Duplication', 'Duplication', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('AM09', 'WrongAmount', 'Wrong amount in SCT', 'Registered', '2012-10-08'::date, '2012-10-08'::date, NULL, NULL),
    ('MD01', 'NoMandate', 'No Mandate', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('MD05', 'CollectionNotDue', 'Creditor or creditor''s agent should not have collected the direct debit', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('MS02', 'NotSpecifiedReasonCustomerGenerated', 'Reason has not been specified by end customer', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('MS03', 'NotSpecifiedReasonAgentGenerated', 'Reason has not been specified by agent.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('RC07', 'InvalidCreditorBICIdentifier', 'Wrong BIC in SCT', 'Registered', '2012-10-08'::date, '2012-10-08'::date, NULL, NULL),
    ('TM01', 'CutOffTime', 'Associated message was received after agreed processing cut-off time.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL)
ON CONFLICT ("Code") DO NOTHING;
-- Seed: ExternalServiceLevel1CodeValues (29 codes)
INSERT INTO public."ExternalServiceLevel1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('BKTR', 'BookTransaction', 'Payment through internal book transfer.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('EAPS', 'EastAfricanPaymentSystem', 'Identifies payments executed under the East African Payment System (EAPS), the regional cross-border settlement scheme operated by EAC central banks.', 'Registered', '2025-11-30'::date, '2025-11-30'::date, NULL, 'Code used to tag EAPS scheme participation in ISO 20022 messages so the payment can be routed, processed, reported, and analyzed as an EAPS transaction.'),
    ('EOLO', 'EuroOneLegOut', 'Payment is executed following a Euro One-Leg Out Scheme.', 'Registered', '2023-05-31'::date, '2023-05-31'::date, NULL, NULL),
    ('G001', 'TrackedCustomerCreditTransfer', 'Tracked Customer Credit Transfer.', 'Registered', '2022-05-31'::date, '2018-08-01'::date, NULL, 'Usage:
Used in the pacs.008 to identify a tracked customer credit transfer.
Used in the pacs.009 to identify the tracked FI credit transfer used as a cover to settle the underlying pacs.008.'),
    ('G002', 'TrackedStopAndRecall', 'Tracked Stop and Recall.', 'Registered', '2018-08-01'::date, '2018-08-01'::date, NULL, NULL),
    ('G003', 'TrackedOutboundCorporateTransfer', 'Tracked Outbound Corporate Transfer.', 'Registered', '2022-05-31'::date, '2018-08-01'::date, NULL, 'usage: Used in the pain.001 to indicate a corporate''s request to track the subsequent customer credit transfer.'),
    ('G004', 'TrackedFinancialInstitutionTransfer', 'Tracked Financial Institution Transfer.', 'Registered', '2022-05-31'::date, '2018-08-01'::date, NULL, 'Usage: Used in the pacs.009 to identify a tracked FI credit transfer.'),
    ('G005', 'TrackedInstantCustomerCreditTransfer', 'Tracked Instant Customer Credit Transfer.', 'Registered', '2022-05-31'::date, '2022-05-31'::date, NULL, 'Usage: Used in the pacs.008 to identify a tracked instant customer credit transfer.'),
    ('G006', 'TrackedCaseManagement', 'Specifies the service conditions applicable to a tracked exceptions and investigations case.', 'Registered', '2022-05-31'::date, '2022-05-31'::date, NULL, 'Usage: API only.'),
    ('G007', 'TrackedInboundCustomerCreditTransfer', 'Specifies the service level for a tracked inbound customer credit transfer.', 'Registered', '2022-05-31'::date, '2022-05-31'::date, NULL, 'Usage: API only.'),
    ('G009', 'TrackedLowValueCrossBorderCustomerCreditTransfer', 'Specifies the service level for a tracked low-value cross-border customer credit transfer.', 'Registered', '2022-05-31'::date, '2022-05-31'::date, NULL, 'Usage: Used in the pacs.008 to identify a tracked low-value cross-border customer credit transfer.'),
    ('INST', 'InstantCreditTransferOrInstantDirectDebit', 'Used for payment initiation to identify that a Payment or Direct Debit initiation must be executed as an instant or real-time payment instrument.', 'Registered', '2021-11-30'::date, '2021-11-30'::date, NULL, 'CR1057'),
    ('IRCA', 'IcelandicRulebookCouncilArea', 'Payment must be executed following the Icelandic Rulebook Council Area (IRCA) scheme.', 'Registered', '2025-05-31'::date, '2025-05-31'::date, NULL, 'Used to identify that a payment uses the ICT Inst Scheme.'),
    ('NOLO', 'NPCOneLegOut', 'Payment is executed following the NPC One-Leg Out Scheme.', 'Registered', '2026-05-22'::date, '2026-05-22'::date, NULL, NULL),
    ('NPCA', 'NordicPaymentsCouncilAreaTransfer', 'Payments must be executed following the NPC Area Payment scheme.', 'Registered', '2020-08-01'::date, '2020-08-01'::date, NULL, NULL),
    ('NUGP', 'NonurgentPriorityPayment', 'Payment must be executed as a non-urgent transaction with priority settlement.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('NURG', 'NonurgentPayment', 'Payment must be executed as a non-urgent transaction, which is typically identified as an ACH or low value transaction.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('PRPT', 'EBAPriorityService', 'Transaction must be processed according to the EBA Priority Service.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('SD01', 'SwiftDigitalServiceSwiftLedger', 'Digital asset transactions must be processed according to the Swift Ledger rules.', 'Registered', '2026-05-22'::date, '2026-05-22'::date, NULL, 'To be used in pacs.008 between Debtor Agent and Creditor Agent for Swift Ledger-eligible payments.'),
    ('SDVA', 'SameDayValue', 'Payment must be executed with same day value to the creditor.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('SEPA', 'SingleEuroPaymentsArea', 'Payment must be executed following the Single Euro Payments Area scheme.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('SPLI', 'SplitPayment', 'A split payment is a payment that is split into several payments of lower value, namely with the purpose to comply with maximum amount thresholds applicable to some domestic Payment Market Infrastructures or to reduce counterparty liquidity risk.', 'Registered', '2024-02-28'::date, '2024-02-28'::date, NULL, NULL),
    ('SPSC', 'SwiftScheme', 'Transaction must be processed according to the Swift Scheme rulebook.', 'Registered', '2026-02-28'::date, '2026-02-28'::date, NULL, 'Usage: code used between agents which are participating in the Swift Scheme, to identify the rules under which the payment transaction should be processed. This Service Level may be used throughout the end-to-end transaction lifecycle (where the Scheme applies).'),
    ('SRTP', 'ServiceRequestToPay', 'Request to Pay (RTP) transaction refers to an RTP scheme (such as for example the SEPA Request to Pay (SRTP) scheme).', 'Registered', '2021-11-30'::date, '2021-11-30'::date, NULL, 'CR1063'),
    ('SVAT', 'ScheckVerarbeitungAustria', 'Scheck Verarbeitung Austria (Cheque Processing).', 'Registered', '2022-02-15'::date, '2022-02-15'::date, NULL, NULL),
    ('SVDE', 'DomesticChequeClearingAndSettlement', 'Payment execution following the cheque agreement and traveller cheque agreement of the German Banking Industry Committee (Die Deutsche Kreditwirtschaft - DK) and Deutsche Bundesbank - Scheck Verrechnung Deutschland', 'Registered', '2015-08-31'::date, '2015-08-31'::date, NULL, NULL),
    ('URGP', 'UrgentPayment', 'Payment must be executed as an urgent transaction cleared through a real-time gross settlement system, which is typically identified as a wire or high value transaction.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('URNS', 'UrgentPaymentNetSettlement', 'Payment must be executed as an urgent transaction cleared through a real-time net settlement system, which is typically identified as a wire or high value transaction.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('WFSM', 'WaitForSettlement', 'Transaction is to be treated as an advice and only applied to the account of the creditor or next agent after settlement of the cover has been confirmed.', 'Registered', '2022-11-30'::date, '2022-11-30'::date, NULL, NULL)
ON CONFLICT ("Code") DO NOTHING;
-- Seed: ExternalStatusReason1CodeValues (315 codes)
INSERT INTO public."ExternalStatusReason1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('AB01', 'AbortedClearingTimeout', 'Clearing process aborted due to timeout.', 'Registered', '2016-04-01'::date, '2016-03-01'::date, NULL, NULL),
    ('AB02', 'AbortedClearingFatalError', 'Clearing process aborted due to a fatal error.', 'Registered', '2016-04-01'::date, '2016-03-01'::date, NULL, NULL),
    ('AB03', 'AbortedSettlementTimeout', 'Settlement aborted due to timeout.', 'Registered', '2016-04-01'::date, '2016-03-01'::date, NULL, NULL),
    ('AB04', 'AbortedSettlementFatalError', 'Settlement process aborted due to a fatal error.', 'Registered', '2016-04-01'::date, '2016-03-01'::date, NULL, NULL),
    ('AB05', 'TimeoutCreditorAgent', 'Transaction stopped due to timeout at the Creditor Agent.', 'Registered', '2016-11-18'::date, '2016-11-01'::date, NULL, NULL),
    ('AB06', 'TimeoutInstructedAgent', 'Transaction stopped due to timeout at the Instructed Agent.', 'Registered', '2016-11-18'::date, '2016-11-01'::date, NULL, NULL),
    ('AB07', 'OfflineAgent', 'Agent of message is not online.
Generic usage if it cannot be determined who exactly is not online.', 'Registered', '2016-11-18'::date, '2016-11-01'::date, NULL, NULL),
    ('AB08', 'OfflineCreditorAgent', 'Creditor Agent is not online.', 'Registered', '2016-11-18'::date, '2016-11-01'::date, NULL, NULL),
    ('AB09', 'ErrorCreditorAgent', 'Transaction stopped due to error at the Creditor Agent.', 'Registered', '2016-11-18'::date, '2016-11-01'::date, NULL, NULL),
    ('AB10', 'ErrorInstructedAgent', 'Transaction stopped due to error at the Instructed Agent.', 'Registered', '2016-11-18'::date, '2016-11-01'::date, NULL, NULL),
    ('AB11', 'TimeoutDebtorAgent', 'Transaction stopped due to timeout at the Debtor Agent.', 'Registered', '2020-08-01'::date, '2020-08-01'::date, NULL, NULL),
    ('AB12', 'InvalidConcurrentBatch', 'Duplicate Concurrent Batch Sequence number- for Settlement Instructions.', 'Registered', '2024-05-31'::date, '2024-05-31'::date, NULL, NULL),
    ('AB13', 'InvalidRoutingCodeUtilised', 'Wrong Message Routing Type for Return-of-Funds.', 'Registered', '2024-05-31'::date, '2024-05-31'::date, NULL, NULL),
    ('AB15', 'InvalidAccountNumberForSettlementType', 'Instruction may not be placed on the Continuous Processing Line settlement processor.', 'Registered', '2024-05-31'::date, '2024-05-31'::date, NULL, NULL),
    ('AB21', 'InvalidSettlementAgreementNumberSpecified', 'Agreement number not valid (beneficiary).', 'Registered', '2024-05-31'::date, '2024-05-31'::date, NULL, NULL),
    ('AB26', 'InvalidBatchSettlementInstruction', 'Settlement Instruction does not exist.', 'Registered', '2024-05-31'::date, '2024-05-31'::date, NULL, NULL),
    ('AC01', 'IncorrectAccountNumber', 'Account number is invalid or missing.', 'Registered', '2010-08-01'::date, '2009-04-01'::date, NULL, NULL),
    ('AC02', 'InvalidDebtorAccountNumber', 'Debtor account number invalid or missing', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('AC03', 'InvalidCreditorAccountNumber', 'Creditor account number invalid or missing', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('AC04', 'ClosedAccountNumber', 'Account number specified has been closed on the bank of account''s books.', 'Registered', '2010-08-01'::date, '2009-04-01'::date, NULL, NULL),
    ('AC05', 'ClosedDebtorAccountNumber', 'Debtor account number closed.', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('AC06', 'BlockedAccount', 'Account specified is blocked, prohibiting posting of transactions against it.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('AC07', 'ClosedCreditorAccountNumber', 'Creditor account number closed', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('AC08', 'InvalidBranchCode', 'Branch code is invalid or missing', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('AC09', 'InvalidAccountCurrency', 'Account currency is invalid or missing', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('AC10', 'InvalidDebtorAccountCurrency', 'Debtor account currency is invalid or missing', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('AC11', 'InvalidCreditorAccountCurrency', 'Creditor account currency is invalid or missing', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('AC12', 'InvalidAccountType', 'Account type missing or invalid.
Generic usage if cannot specify between group and payment information levels', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('AC13', 'InvalidDebtorAccountType', 'Debtor account type missing or invalid', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('AC14', 'InvalidCreditorAccountType', 'Creditor account type missing or invalid', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('AC15', 'AccountDetailsChanged', 'The account details for the counterparty have changed.', 'Registered', '2018-11-01'::date, '2018-11-01'::date, NULL, NULL),
    ('AC16', 'CardNumberInvalid', 'Credit or debit card number is invalid.', 'Registered', '2021-05-01'::date, '2021-05-01'::date, NULL, NULL),
    ('AEML', 'AmountExceedsMaxLimit', 'Requested amount exceeds the limit set by Debtor (Agent)', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, NULL),
    ('AEXR', 'AlreadyExpiredRTP', 'Request-to-pay Expiry Date and Time has already passed.', 'Registered', '2021-11-30'::date, '2021-11-30'::date, NULL, 'CR1062'),
    ('AG01', 'TransactionForbidden', 'Transaction forbidden on this type of account (formerly NoAgreement)', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('AG02', 'InvalidBankOperationCode', 'Bank Operation code specified in the message is not valid for receiver', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('AG03', 'TransactionNotSupported', 'Transaction type not supported/authorized on this account.', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('AG04', 'InvalidAgentCountry', 'Agent country code is missing or invalid.
Generic usage if cannot specify between group and payment information levels.', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('AG05', 'InvalidDebtorAgentCountry', 'Debtor agent country code is missing or invalid', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('AG06', 'InvalidCreditorAgentCountry', 'Creditor agent country code is missing or invalid', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL)
ON CONFLICT ("Code") DO NOTHING;
INSERT INTO public."ExternalStatusReason1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('AG07', 'UnsuccesfulDirectDebit', 'Debtor account cannot be debited for a generic reason.
Code value may be used in general purposes and as a replacement for AM04 if debtor bank does not reveal its customer''s insufficient funds for privacy reasons', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('AG08', 'InvalidAccessRights', 'Transaction failed due to invalid or missing user or access right', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('AG09', 'PaymentNotReceived', 'Original payment never received.', 'Registered', '2016-11-18'::date, '2016-11-01'::date, NULL, NULL),
    ('AG10', 'AgentSuspended', 'Agent of message is suspended from the Real Time Payment system.
Generic usage if it cannot be determined who exactly is suspended.', 'Registered', '2016-11-18'::date, '2016-11-01'::date, NULL, NULL),
    ('AG11', 'CreditorAgentSuspended', 'Creditor Agent of message is suspended from the Real Time Payment system.', 'Registered', '2016-11-18'::date, '2016-11-01'::date, NULL, NULL),
    ('AG12', 'NotAllowedBookTransfer', 'Payment orders made by transferring funds from one account to another at the same financial institution (bank or payment institution) are not allowed.', 'Registered', '2020-08-01'::date, '2020-08-01'::date, NULL, NULL),
    ('AG13', 'ForbiddenReturnPayment', 'Returned payments derived from previously returned transactions are not allowed.', 'Registered', '2020-08-01'::date, '2020-08-01'::date, NULL, NULL),
    ('AGNT', 'IncorrectAgent', 'Agent in the payment workflow is incorrect', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('ALAC', 'AlreadyAcceptedRTP', 'Request-to-pay has already been accepted by the Debtor.', 'Registered', '2021-11-30'::date, '2021-11-30'::date, NULL, 'CR1062'),
    ('AM01', 'ZeroAmount', 'Specified message amount is equal to zero', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('AM02', 'NotAllowedAmount', 'Specific transaction/message amount is greater than allowed maximum', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('AM03', 'NotAllowedCurrency', 'Specified message amount is an non processable currency outside of existing agreement', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('AM04', 'InsufficientFunds', 'Amount of funds available to cover specified message amount is insufficient.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('AM05', 'Duplication', 'Duplication', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('AM06', 'TooLowAmount', 'Specified transaction amount is less than agreed minimum.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('AM07', 'BlockedAmount', 'Amount specified in message has been blocked by regulatory authorities.', 'Registered', '2020-11-01'::date, '2009-04-01'::date, NULL, NULL),
    ('AM09', 'WrongAmount', 'Amount received is not the amount agreed or expected', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('AM10', 'InvalidControlSum', 'Sum of instructed amounts does not equal the control sum.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('AM11', 'InvalidTransactionCurrency', 'Transaction currency is invalid or missing', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('AM12', 'InvalidAmount', 'Amount is invalid or missing', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('AM13', 'AmountExceedsClearingSystemLimit', 'Transaction amount exceeds limits set by clearing system', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('AM14', 'AmountExceedsAgreedLimit', 'Transaction amount exceeds limits agreed between bank and client', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('AM15', 'AmountBelowClearingSystemMinimum', 'Transaction amount below minimum set by clearing system', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('AM16', 'InvalidGroupControlSum', 'Control Sum at the Group level is invalid', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('AM17', 'InvalidPaymentInfoControlSum', 'Control Sum at the Payment Information level is invalid', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('AM18', 'InvalidNumberOfTransactions', 'Number of transactions is invalid or missing.
Generic usage if cannot specify between group and payment information levels.', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('AM19', 'InvalidGroupNumberOfTransactions', 'Number of transactions at the Group level is invalid or missing', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('AM20', 'InvalidPaymentInfoNumberOfTransactions', 'Number of transactions at the Payment Information level is invalid', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('AM21', 'LimitExceeded', 'Transaction amount exceeds limits agreed between bank and client.', 'Registered', '2011-02-14'::date, '2011-02-14'::date, NULL, NULL),
    ('AM22', 'ZeroAmountNotApplied', 'Unable to apply zero amount to designated account. For example, where the rules of a service allow the use of zero amount payments, however the back-office system is unable to apply the funds to the account. If the rules of a service prohibit the use of zero amount payments, then code AM01 is used to report the error condition.', 'Registered', '2016-04-01'::date, '2016-03-01'::date, NULL, NULL),
    ('AM23', 'AmountExceedsSettlementLimit', 'Transaction amount exceeds settlement limit.', 'Registered', '2016-11-18'::date, '2016-11-01'::date, NULL, NULL),
    ('AMSE', 'AttachmentMaximumSize', 'Size of the attachment exceeds the allowed maximum.', 'Registered', '2024-08-30'::date, '2024-08-30'::date, NULL, NULL),
    ('APAR', 'AlreadyPaidRTP', 'Request To Pay has already been paid by the Debtor.', 'Registered', '2023-08-31'::date, '2023-08-31'::date, NULL, NULL),
    ('ARFR', 'AlreadyRefusedRTP', 'Request-to-pay has already been refused by the Debtor.', 'Registered', '2021-11-30'::date, '2021-11-30'::date, NULL, 'CR1062'),
    ('ARJR', 'AlreadyRejectedRTP', 'Request-to-pay has already been rejected.', 'Registered', '2021-11-30'::date, '2021-11-30'::date, NULL, 'CR1062'),
    ('ATNS', 'AttachementsNotSupported', 'Attachments to the request-to-pay are not supported.', 'Registered', '2021-11-30'::date, '2021-11-30'::date, NULL, 'CR1062'),
    ('BDAY', 'NotBusinessDay', 'Settlement Cycle Day and Calendar day should be the same.', 'Registered', '2024-05-31'::date, '2024-05-31'::date, NULL, NULL),
    ('BE01', 'InconsistentWithEndCustomer', 'Identification of end customer is not consistent with associated account number. (formerly CreditorConsistency).', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('BE04', 'MissingCreditorAddress', 'Specification of creditor''s address, which is required for payment, is missing/not correct (formerly IncorrectCreditorAddress).', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('BE05', 'UnrecognisedInitiatingParty', 'Party who initiated the message is not recognised by the end customer', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL)
ON CONFLICT ("Code") DO NOTHING;
INSERT INTO public."ExternalStatusReason1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('BE06', 'UnknownEndCustomer', 'End customer specified is not known at associated Sort/National Bank Code or does no longer exist in the books', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('BE07', 'MissingDebtorAddress', 'Specification of debtor''s address, which is required for payment, is missing/not correct.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('BE08', 'MissingDebtorName', 'Debtor name is missing', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('BE09', 'InvalidCountry', 'Country code is missing or Invalid.
Generic usage if cannot specifically identify debtor or creditor', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('BE10', 'InvalidDebtorCountry', 'Debtor country code is missing or invalid', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('BE11', 'InvalidCreditorCountry', 'Creditor country code is missing or invalid', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('BE12', 'InvalidCountryOfResidence', 'Country code of residence is missing or Invalid.
Generic usage if cannot specifically identify debtor or creditor', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('BE13', 'InvalidDebtorCountryOfResidence', 'Country code of debtor''s residence is missing or Invalid', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('BE14', 'InvalidCreditorCountryOfResidence', 'Country code of creditor''s residence is missing or Invalid', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('BE15', 'InvalidIdentificationCode', 'Identification code missing or invalid.
Generic usage if cannot specifically identify debtor or creditor.', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('BE16', 'InvalidDebtorIdentificationCode', 'Debtor or Ultimate Debtor identification code missing or invalid', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('BE17', 'InvalidCreditorIdentificationCode', 'Creditor or Ultimate Creditor identification code missing or invalid', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('BE18', 'InvalidContactDetails', 'Contact details missing or invalid', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('BE19', 'InvalidChargeBearerCode', 'Charge bearer code for transaction type is invalid', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('BE20', 'InvalidNameLength', 'Name length exceeds local rules for payment type.', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('BE21', 'MissingName', 'Name missing or invalid.  Generic usage if cannot specifically identify debtor or creditor.', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('BE22', 'MissingCreditorName', 'Creditor name is missing', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('BE23', 'AccountProxyInvalid', 'Phone number or email address, or any other proxy, used as the account proxy is unknown or invalid.', 'Registered', '2021-05-01'::date, '2021-05-01'::date, NULL, NULL),
    ('CERI', 'CheckERI', 'Credit transfer is not tagged as an Extended Remittance Information (ERI) transaction but contains ERI.', 'Registered', '2018-11-01'::date, '2018-11-01'::date, NULL, NULL),
    ('CH03', 'RequestedExecutionDateOrRequestedCollectionDateTooFarInFuture', 'Value in Requested Execution Date or Requested Collection Date is too far in the future', 'Registered', '2012-12-17'::date, '2012-12-17'::date, NULL, NULL),
    ('CH04', 'RequestedExecutionDateOrRequestedCollectionDateTooFarInPast', 'Value in Requested Execution Date or Requested Collection Date is too far in the past', 'Registered', '2012-12-17'::date, '2012-12-17'::date, NULL, NULL),
    ('CH07', 'ElementIsNotToBeUsedAtB-andC-Level', 'Element is not to be used at B- and C-Level', 'Registered', '2012-12-17'::date, '2012-12-17'::date, NULL, NULL),
    ('CH09', 'MandateChangesNotAllowed', 'Mandate changes are not allowed', 'Registered', '2012-12-17'::date, '2012-12-17'::date, NULL, NULL),
    ('CH10', 'InformationOnMandateChangesMissing', 'Information on mandate changes are missing', 'Registered', '2012-12-17'::date, '2012-12-17'::date, NULL, NULL),
    ('CH11', 'CreditorIdentifierIncorrect', 'Value in Creditor Identifier is incorrect', 'Registered', '2012-12-17'::date, '2012-12-17'::date, NULL, NULL),
    ('CH12', 'CreditorIdentifierNotUnambiguouslyAtTransaction-Level', 'Creditor Identifier is ambiguous at Transaction Level', 'Registered', '2012-12-17'::date, '2012-12-17'::date, NULL, NULL),
    ('CH13', 'OriginalDebtorAccountIsNotToBeUsed', 'Original Debtor Account is not to be used', 'Registered', '2012-12-17'::date, '2012-12-17'::date, NULL, NULL),
    ('CH14', 'OriginalDebtorAgentIsNotToBeUsed', 'Original Debtor Agent  is not to be used', 'Registered', '2016-08-31'::date, '2012-12-17'::date, NULL, NULL),
    ('CH15', 'ElementContentIncludesMoreThan140Characters', 'Content Remittance Information/Structured includes more than 140 characters', 'Registered', '2012-12-17'::date, '2012-12-17'::date, NULL, NULL),
    ('CH16', 'ElementContentFormallyIncorrect', 'Content is incorrect', 'Registered', '2012-12-17'::date, '2012-12-17'::date, NULL, NULL),
    ('CH17', 'ElementNotAdmitted', 'Element is not allowed', 'Registered', '2012-12-17'::date, '2012-12-17'::date, NULL, NULL),
    ('CH19', 'ValuesWillBeSetToNextTARGETday', 'Values in Interbank Settlement Date or Requested Collection Date will be set to the next TARGET day', 'Registered', '2012-12-17'::date, '2012-12-17'::date, NULL, NULL),
    ('CH20', 'DecimalPointsNotCompatibleWithCurrency', 'Number of decimal points not compatible with the currency', 'Registered', '2012-12-17'::date, '2012-12-17'::date, NULL, NULL),
    ('CH21', 'RequiredCompulsoryElementMissing', 'Mandatory element is missing.', 'Registered', '2012-12-17'::date, '2012-12-17'::date, NULL, NULL),
    ('CH22', 'COREandB2BwithinOnemessage', 'SDD CORE and B2B not permitted within one message.', 'Registered', '2012-12-17'::date, '2012-12-17'::date, NULL, NULL),
    ('CHCO', 'UnacceptedChargeCodeType', 'Related to a Charge message to convey that the code in Charge Breakdown / Type / Code is not accepted by the receiving party.', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('CHQC', 'ChequeSettledOnCreditorAccount', 'Cheque has been presented in cheque clearing and settled on the creditor''s account.', 'Registered', '2021-05-01'::date, '2021-05-01'::date, NULL, NULL),
    ('CHRG', 'UnderlyingChargeBearerWasNotDebt', 'Related to a Charge message to convey that the charge bearer code used in the corresponding Payment message was not debt.', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('CN01', 'AuthorisationCancelled', 'Authorisation is cancelled.', 'Registered', '2021-08-31'::date, '2021-08-23'::date, NULL, 'CR0964'),
    ('CNNS', 'CreditNotesNotSupported', 'Credit notes are not supported.', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL)
ON CONFLICT ("Code") DO NOTHING;
INSERT INTO public."ExternalStatusReason1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('CNOR', 'CreditorBankIsNotRegistered', 'Creditor bank is not registered under this BIC in the CSM', 'Registered', '2012-07-16'::date, '2012-07-16'::date, NULL, NULL),
    ('CURR', 'IncorrectCurrency', 'Currency of the payment is incorrect', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('CUST', 'RequestedByCustomer', 'Cancellation requested by the Debtor', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('DC02', 'SettlementNotReceived', 'Rejection of a payment due to covering FI settlement not being received.', 'Registered', '2022-05-31'::date, '2022-05-31'::date, NULL, NULL),
    ('DNOR', 'DebtorBankIsNotRegistered', 'Debtor bank is not registered under this BIC in the CSM', 'Registered', '2012-07-16'::date, '2012-07-16'::date, NULL, NULL),
    ('DS01', 'ElectronicSignaturesCorrect', 'The electronic signature(s) is/are correct', 'Registered', '2011-02-14'::date, '2011-02-14'::date, NULL, NULL),
    ('DS02', 'OrderCancelled', 'An authorized user has cancelled the order', 'Registered', '2011-02-14'::date, '2011-02-14'::date, NULL, NULL),
    ('DS03', 'OrderNotCancelled', 'The user''s attempt to cancel the order was not successful.', 'Registered', '2011-02-14'::date, '2011-02-14'::date, NULL, NULL),
    ('DS04', 'OrderRejected', 'The order was rejected by the bank side (for reasons concerning content)', 'Registered', '2011-02-14'::date, '2011-02-14'::date, NULL, NULL),
    ('DS05', 'OrderForwardedForPostprocessing', 'The order was correct and could be forwarded for postprocessing', 'Registered', '2011-02-14'::date, '2011-02-14'::date, NULL, NULL),
    ('DS06', 'TransferOrder', 'The order was transferred to VEU', 'Registered', '2011-02-14'::date, '2011-02-14'::date, NULL, NULL),
    ('DS07', 'ProcessingOK', 'All actions concerning the order could be done by the EBICS bank server', 'Registered', '2011-02-14'::date, '2011-02-14'::date, NULL, NULL),
    ('DS08', 'DecompressionError', 'The decompression of the file was not successful', 'Registered', '2011-02-14'::date, '2011-02-14'::date, NULL, NULL),
    ('DS09', 'DecryptionError', 'The decryption of the file was not successful', 'Registered', '2011-02-14'::date, '2011-02-14'::date, NULL, NULL),
    ('DS0A', 'DataSignRequested', 'Data signature is required.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('DS0B', 'UnknownDataSignFormat', 'Data signature for the format is not available or invalid.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('DS0C', 'SignerCertificateRevoked', 'The signer certificate is revoked.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('DS0D', 'SignerCertificateNotValid', 'The signer certificate is not valid (revoked or not active).', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('DS0E', 'IncorrectSignerCertificate', 'The signer certificate is not present.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('DS0F', 'SignerCertificationAuthoritySignerNotValid', 'The authority of the signer certification sending the certificate is unknown.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('DS0G', 'NotAllowedPayment', 'Signer is not allowed to sign this operation type.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('DS0H', 'NotAllowedAccount', 'Signer is not allowed to sign for this account.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('DS0K', 'NotAllowedNumberOfTransaction', 'The number of transaction is over the number allowed for this signer.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('DS10', 'Signer1CertificateRevoked', 'The certificate is revoked for the first signer.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('DS11', 'Signer1CertificateNotValid', 'The certificate is not valid (revoked or not active) for the first signer.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('DS12', 'IncorrectSigner1Certificate', 'The certificate is not present for the first signer.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('DS13', 'SignerCertificationAuthoritySigner1NotValid', 'The authority of signer certification sending the certificate is unknown for the first signer.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('DS14', 'UserDoesNotExist', 'The user is unknown on the server', 'Registered', '2011-02-14'::date, '2011-02-14'::date, NULL, NULL),
    ('DS15', 'IdenticalSignatureFound', 'The same signature has already been sent to the bank', 'Registered', '2011-02-14'::date, '2011-02-14'::date, NULL, NULL),
    ('DS16', 'PublicKeyVersionIncorrect', 'The public key version is not correct. This code is returned when a customer sends signature files to the financial institution after conversion from an older program version (old ES format) to a new program version (new ES format) without having carried out re-initialisation with regard to a public key change.', 'Registered', '2011-02-14'::date, '2011-02-14'::date, NULL, NULL),
    ('DS17', 'DifferentOrderDataInSignatures', 'Order data and signatures don''t match', 'Registered', '2011-02-14'::date, '2011-02-14'::date, NULL, NULL),
    ('DS18', 'RepeatOrder', 'File cannot be tested, the complete order has to be repeated. This code is returned in the event of a malfunction during the signature check, e.g. not enough storage space.', 'Registered', '2011-02-14'::date, '2011-02-14'::date, NULL, NULL),
    ('DS19', 'ElectronicSignatureRightsInsufficient', 'The user''s rights (concerning his signature) are insufficient to execute the order', 'Registered', '2011-02-14'::date, '2011-02-14'::date, NULL, NULL),
    ('DS20', 'Signer2CertificateRevoked', 'The certificate is revoked for the second signer.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('DS21', 'Signer2CertificateNotValid', 'The certificate is not valid (revoked or not active) for the second signer.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('DS22', 'IncorrectSigner2Certificate', 'The certificate is not present for the second signer.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('DS23', 'SignerCertificationAuthoritySigner2NotValid', 'The authority of signer certification sending the certificate is unknown for the second signer.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('DS24', 'WaitingTimeExpired', 'Waiting time expired due to incomplete order', 'Registered', '2011-02-14'::date, '2011-02-14'::date, NULL, NULL),
    ('DS25', 'OrderFileDeleted', 'The order file was deleted by the bank server 
(for multiple reasons)', 'Registered', '2011-02-14'::date, '2011-02-14'::date, NULL, NULL),
    ('DS26', 'UserSignedMultipleTimes', 'The same user has signed multiple times', 'Registered', '2011-02-14'::date, '2011-02-14'::date, NULL, NULL)
ON CONFLICT ("Code") DO NOTHING;
INSERT INTO public."ExternalStatusReason1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('DS27', 'UserNotYetActivated', 'The user is not yet activated (technically)', 'Registered', '2011-02-14'::date, '2011-02-14'::date, NULL, NULL),
    ('DS28', 'ReturnForTechnicalReason', 'Message routed to the wrong environment.', 'Registered', '2024-05-31'::date, '2024-05-31'::date, NULL, NULL),
    ('DT01', 'InvalidDate', 'Invalid date (eg, wrong or missing settlement date)', 'Registered', '2010-08-01'::date, '2009-04-01'::date, NULL, NULL),
    ('DT02', 'InvalidCreationDate', 'Invalid creation date and time in Group Header (eg, historic date)', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('DT03', 'InvalidNonProcessingDate', 'Invalid non bank processing date (eg, weekend or local public holiday)', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('DT04', 'FutureDateNotSupported', 'Future date not supported', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('DT05', 'InvalidCutOffDate', 'Associated message, payment information block or transaction was received after agreed processing cut-off date, i.e., date in the past.', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('DT06', 'ExecutionDateChanged', 'Execution Date has been modified in order for transaction to be processed', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('DU01', 'DuplicateMessageID', 'Message Identification is not unique.', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('DU02', 'DuplicatePaymentInformationID', 'Payment Information Block is not unique.', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('DU03', 'DuplicateTransaction', 'Transaction is not unique.', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('DU04', 'DuplicateEndToEndID', 'End To End ID is not unique.', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('DU05', 'DuplicateInstructionID', 'Instruction ID is not unique.', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('DUPL', 'DuplicatePaymentOrCharge', 'Payment or charge is a duplicate of another payment or charge.', 'Registered', '2024-12-03'::date, '2009-04-01'::date, NULL, NULL),
    ('ED01', 'CorrespondentBankNotPossible', 'Correspondent bank not possible.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('ED03', 'BalanceInfoRequest', 'Balance of payments complementary info is requested', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('ED05', 'SettlementFailed', 'Settlement of the transaction has failed.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('ED06', 'SettlementSystemNotAvailable', 'Interbank settlement system not available.', 'Registered', '2016-04-01'::date, '2016-03-01'::date, NULL, NULL),
    ('EDNA', 'ExecutionDateNotAccepted', 'Requested execution date of the payment is not accepted.', 'Registered', '2024-08-30'::date, '2024-08-30'::date, NULL, NULL),
    ('EDTL', 'ExpiryDateTooLong', 'Expiry date time of the request-to-pay is too far in the future.', 'Registered', '2021-11-30'::date, '2021-11-30'::date, NULL, 'CR1062'),
    ('EDTR', 'ExpiryDateTimeReached', 'Expiry date time of the request-to-pay is already reached.', 'Registered', '2021-11-30'::date, '2021-11-30'::date, NULL, 'CR1062'),
    ('EOL1', 'EndOfLife', 'Expiration of the payment authorisation due to no use for too long.', 'Registered', '2025-02-28'::date, '2025-02-28'::date, NULL, NULL),
    ('ERIN', 'ERIOptionNotSupported', 'Extended Remittance Information (ERI) option is not supported.', 'Registered', '2018-11-01'::date, '2018-11-01'::date, NULL, NULL),
    ('FF01', 'InvalidFileFormat', 'File Format incomplete or invalid', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('FF02', 'SyntaxError', 'Syntax error reason is provided as narrative information in the additional reason information.', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('FF03', 'InvalidPaymentTypeInformation', 'Payment Type Information is missing or invalid.
Generic usage if cannot specify Service Level or Local Instrument code', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('FF04', 'InvalidServiceLevelCode', 'Service Level code is missing or invalid', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('FF05', 'InvalidLocalInstrumentCode', 'Local Instrument code is missing or invalid', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('FF06', 'InvalidCategoryPurposeCode', 'Category Purpose code is missing or invalid', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('FF07', 'InvalidPurpose', 'Purpose is missing or invalid', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('FF08', 'InvalidEndToEndId', 'End to End Id missing or invalid', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('FF09', 'InvalidChequeNumber', 'Cheque number missing or invalid', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('FF10', 'BankSystemProcessingError', 'File or transaction cannot be processed due to technical issues at the bank side', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('FF11', 'ClearingRequestAborted', 'Clearing request rejected due it being subject to an abort operation.', 'Registered', '2017-02-08'::date, '2016-04-01'::date, NULL, NULL),
    ('FF12', 'OriginalTransactionNotEligibleForRequestedReturn', 'Original payment is not eligible to be returned given its current status.', 'Registered', '2022-02-15'::date, '2022-02-15'::date, NULL, NULL),
    ('FF13', 'RequestForCancellationNotFound', 'No record of request for cancellation found.', 'Registered', '2022-02-15'::date, '2022-02-15'::date, NULL, NULL),
    ('FOCR', 'FollowingCancellationRequest', 'Return following a cancellation request.', 'Registered', '2021-08-31'::date, '2021-08-23'::date, NULL, 'CR0964'),
    ('FR01', 'Fraud', 'Returned as a result of fraud.', 'Registered', '2021-08-31'::date, '2021-08-23'::date, NULL, 'CR0964'),
    ('FRAD', 'FraudulentOrigin', 'Cancellation requested following a transaction that was originated fraudulently. The use of the FraudulentOrigin code should be governed by jurisdictions.', 'Registered', '2021-11-30'::date, '2021-11-30'::date, NULL, 'CR1062'),
    ('G000', 'PaymentTransferredAndTracked', 'In an FI To FI Customer Credit Transfer: The Status Originator transferred the payment to the next Agent or to a Market Infrastructure. The payment transfer is tracked. No further updates will follow from the Status Originator.

In a Financial Institution Credit Transfer with cover: The Status Originator performed the account booking and transferred the cover transaction to the next Reimbursement Agent or to a Market Infrastructure. The payment transfer is tracked. No further updates will follow from the Status Originator.', 'Registered', '2019-09-01'::date, '2018-08-01'::date, NULL, NULL)
ON CONFLICT ("Code") DO NOTHING;
INSERT INTO public."ExternalStatusReason1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('G001', 'PaymentTransferredAndNotTracked', 'In an FI To FI Customer Credit Transfer: The Status Originator transferred the payment to the next Agent or to a Market Infrastructure. The payment transfer is not tracked. No further updates will follow from the Status Originator.

In a Financial Institution Credit Transfer with cover: The Status Originator performed the account booking and transferred the cover transaction to the next Reimbursement Agent or to a Market Infrastructure. The payment transfer is not tracked. No further updates will follow from the Status Originator.', 'Registered', '2019-09-01'::date, '2018-08-01'::date, NULL, NULL),
    ('G002', 'CreditDebitNotConfirmed', 'In a FIToFI Customer Credit Transfer: Credit to the creditor''s account may not be confirmed same day. Update will follow from the Status Originator.
In a Financial Institution Credit Transfer with cover: Debit/credit to nostro account may not be confirmed same day or Financial Institution Credit Transfer may not be transferred same day. Update will follow from the Status Originator.', 'Registered', '2018-08-01'::date, '2018-08-01'::date, NULL, NULL),
    ('G003', 'CreditPendingDocuments', 'In a FIToFI Customer Credit Transfer: Credit to creditor''s account is pending receipt of required documents. The Status Originator has requested creditor to provide additional documentation. Update will follow from the Status Originator. 
In a Financial Institution Credit Transfer with cover: Status Originator has requested a previous Agent to provide additional information/correct information. Update will follow from the Status Originator.', 'Registered', '2018-08-01'::date, '2018-08-01'::date, NULL, NULL),
    ('G004', 'CreditPendingFunds', 'In a FIToFI Customer Credit Transfer: Credit to the creditor''s account is pending, status Originator is waiting for funds provided via a cover. Update will follow from the Status Originator.', 'Registered', '2018-08-01'::date, '2018-08-01'::date, NULL, NULL),
    ('G005', 'DeliveredWithServiceLevel', 'Payment has been delivered to creditor agent with service level.', 'Registered', '2018-08-01'::date, '2018-08-01'::date, NULL, NULL),
    ('G006', 'DeliveredWIthoutServiceLevel', 'Payment has been delivered to creditor agent without service level.', 'Registered', '2018-08-01'::date, '2018-08-01'::date, NULL, NULL),
    ('G007', 'PaymentPassedByPaymentMarketInfrastructure', 'The payment has been passed by the Payment Market Infrastructure to the next agent in the payment chain; receipt has not yet been confirmed.', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, NULL),
    ('G008', 'PaymentReceivedByNextAgentViaPaymentMarketInfrastructure', 'The payment has been received by the next agent via the Payment Market Infrastructure.', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, NULL),
    ('GUAG', 'GuaranteedAgreementBreached', 'Guaranteed Agreement with Correspondent, therefore Correspondent is the liable party', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, NULL),
    ('ID01', 'CorrespondingOriginalFileStillNotSent', 'Signature file was sent to the bank but the corresponding original file has not been sent yet.', 'Registered', '2011-02-14'::date, '2011-02-14'::date, NULL, NULL),
    ('IEDT', 'IncorrectExpiryDateTime', 'Expiry date time of the request-to-pay is incorrect.', 'Registered', '2021-11-30'::date, '2021-11-30'::date, NULL, 'CR1062'),
    ('IMCC', 'InvalidMerchantCategoryCode', 'Invalid Merchant Category Code', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, NULL),
    ('INAR', 'InvalidActivationReference', 'Payer''s activation reference is invalid.', 'Registered', '2024-08-30'::date, '2024-08-30'::date, NULL, NULL),
    ('INCT', 'InvalidChannelType', 'Invalid Channel Type', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, NULL),
    ('INDT', 'InvalidDetails', 'Details not valid for this field.', 'Registered', '2024-05-31'::date, '2024-05-31'::date, NULL, NULL),
    ('IPNS', 'InstalmentPaymentsNotSupported', 'Payments in instalments are not supported.', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('IRNR', 'InitialRTPNeverReceived', 'No initial request-to-pay has been received.', 'Registered', '2021-11-30'::date, '2021-11-30'::date, NULL, 'CR1062'),
    ('ISWS', 'InvalidSettlementWindow', 'Cannot schedule instruction for Night Window.', 'Registered', '2024-05-31'::date, '2024-05-31'::date, NULL, NULL),
    ('IUCT', 'InvalidUseCaseType', 'Invalid Use Case Type', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, NULL),
    ('MD01', 'NoMandate', 'No Mandate', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('MD02', 'MissingMandatoryInformationInMandate', 'Mandate related information data required by the scheme is missing.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('MD05', 'CollectionNotDue', 'Creditor or creditor''s agent should not have collected the direct debit', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('MD06', 'RefundRequestByEndCustomer', 'Return of funds requested by end customer', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('MD07', 'EndCustomerDeceased', 'End customer is deceased.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('MICT', 'MultipleIdenticalChargeTypes', 'Multiple identical Charge Types in Charge Breakdown', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, NULL),
    ('MINF', 'MissingInformation', 'Information missing for the field or cannot be empty.', 'Registered', '2024-05-31'::date, '2024-05-31'::date, NULL, NULL),
    ('MS02', 'NotSpecifiedReasonCustomerGenerated', 'Reason has not been specified by end customer', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('MS03', 'NotSpecifiedReasonAgentGenerated', 'Reason has not been specified by agent.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('NARR', 'Narrative', 'Reason is provided as narrative information in the additional reason information.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('NERI', 'NoERI', 'Credit transfer is tagged as an Extended Remittance Information (ERI) transaction but does not contain ERI.', 'Registered', '2018-11-01'::date, '2018-11-01'::date, NULL, NULL),
    ('NOAR', 'NonAgreedRTP', 'No existing agreement for receiving request-to-pay messages.', 'Registered', '2021-11-30'::date, '2021-11-30'::date, NULL, 'CR1062'),
    ('NOAS', 'NoAnswerFromCustomer', 'No response from Beneficiary.', 'Registered', '2021-08-31'::date, '2021-08-23'::date, NULL, 'CR0964'),
    ('NOCM', 'NotCompliantGeneric', 'Customer account is not compliant with regulatory requirements, for example FICA (in South Africa) or any other regulatory requirements which render an account inactive for certain processing.', 'Registered', '2021-08-31'::date, '2021-08-23'::date, NULL, 'CR0964'),
    ('NOFR', 'OutstandingFundingForSettlement', 'Continuous Processing Line on Hold Instruction.', 'Registered', '2024-05-31'::date, '2024-05-31'::date, NULL, NULL),
    ('NOPG', 'NoPaymentGuarantee', 'Requested payment guarantee (by Creditor) related to a request-to-pay cannot be provided.', 'Registered', '2021-11-30'::date, '2021-11-30'::date, NULL, 'CR1062'),
    ('NRCH', 'PayerOrPayerRTPSPNotReachable', 'Recipient side of the request-to-pay (payer or its request-to-pay service provider) is not reachable.', 'Registered', '2021-11-30'::date, '2021-11-30'::date, NULL, 'CR1062'),
    ('OBO1', 'SettlementCompletedReportedOnBehalfOfCreditorAgentWithAmount', 'Settlement of the transaction has been completed and is reported by an intermediary agent or Payment Market Infrastructure on behalf of the Creditor Agent. The credited amount is known.', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, NULL),
    ('OBO2', 'SettlementCompletedReportedOnBehalfOfCreditorAgentWithoutAmount', 'Settlement of the transaction has been completed and is reported by an intermediary agent or Payment Market Infrastructure on behalf of the Creditor Agent. The credited amount is not known.', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, NULL),
    ('OSNS', 'OptionalServiceNotSupported', 'Requested optional service (for example instalment payments) is not supported.', 'Registered', '2024-08-30'::date, '2024-08-30'::date, NULL, NULL),
    ('PINS', 'TypeOfPaymentInstrumentNotSupported', 'Type of payment requested in the request-to-pay is not supported by the payer.', 'Registered', '2021-11-30'::date, '2021-11-30'::date, NULL, 'CR1062')
ON CONFLICT ("Code") DO NOTHING;
INSERT INTO public."ExternalStatusReason1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('PNRT', 'PaymentNotAlignedWithRTPRequest', 'Error code used for RTP-initiated CTR when the pacs.008 details are not aligned with the pain.013 request.', 'Registered', '2026-02-28'::date, '2026-02-28'::date, NULL, NULL),
    ('RC01', 'BankIdentifierIncorrect', 'Bank identifier code specified in the message has an incorrect format (formerly IncorrectFormatForRoutingCode).', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('RC02', 'InvalidBankIdentifier', 'Bank identifier is invalid or missing.
Generic usage if cannot specify between debit or credit account', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('RC03', 'InvalidDebtorBankIdentifier', 'Debtor bank identifier is invalid or missing', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('RC04', 'InvalidCreditorBankIdentifier', 'Creditor bank identifier is invalid or missing', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('RC05', 'InvalidBICIdentifier', 'BIC identifier is invalid or missing.
Generic usage if cannot specify between debit or credit account.', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('RC06', 'InvalidDebtorBICIdentifier', 'Debtor BIC identifier is invalid or missing', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('RC07', 'InvalidCreditorBICIdentifier', 'Creditor BIC identifier is invalid or missing', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('RC08', 'InvalidClearingSystemMemberIdentifier', 'ClearingSystemMemberidentifier is invalid or missing.
Generic usage if cannot specify between debit or credit account', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('RC09', 'InvalidDebtorClearingSystemMemberIdentifier', 'Debtor ClearingSystemMember identifier is invalid or missing', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('RC10', 'InvalidCreditorClearingSystemMemberIdentifier', 'Creditor ClearingSystemMember identifier is invalid or missing', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('RC11', 'InvalidIntermediaryAgent', 'Intermediary Agent is invalid or missing', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('RC12', 'MissingCreditorSchemeId', 'Creditor Scheme Id is invalid or  missing', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('RC13', 'ParticipantNotAnActiveMemberofRTGS', 'Originator not active any more.', 'Registered', '2024-05-31'::date, '2024-05-31'::date, NULL, NULL),
    ('RC15', 'ParticipantNotActiveMemberSettlementType', 'Settlement agreement required.', 'Registered', '2024-05-31'::date, '2024-05-31'::date, NULL, NULL),
    ('RC16', 'ParticipantNotActiveMemberofSADCRTGS', 'Participant blocked from SADC-RTGS.', 'Registered', '2024-05-31'::date, '2024-05-31'::date, NULL, NULL),
    ('RCON', 'RMessageConflict', 'Conflict with R-Message', 'Registered', '2014-11-28'::date, '2014-11-28'::date, NULL, NULL),
    ('RECI', 'ReceiverCustomerInformation', 'Further information regarding the intended recipient.', 'Registered', '2019-11-01'::date, '2019-11-01'::date, NULL, NULL),
    ('REPR', 'RTPReceivedCanBeProcessed', 'Request-to-pay has been received and can be processed further.', 'Registered', '2021-11-30'::date, '2021-11-30'::date, NULL, 'CR1062'),
    ('RF01', 'NotUniqueTransactionReference', 'Transaction reference is not unique within the message.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('RQNR', 'RequestNotRecognized', 'Payer did not recognize the request from Payee Participant,', 'Registered', '2024-08-30'::date, '2024-08-30'::date, NULL, 'Used by the Payer Participant to decline the pain.013 request initiated by Payee Bank.'),
    ('RR01', 'MissingDebtorAccountOrIdentification', 'Specification of the debtor''s account or unique identification needed for reasons of regulatory requirements is insufficient or missing', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('RR02', 'MissingDebtorNameOrAddress', 'Specification of the debtor''s name and/or address needed for regulatory requirements is insufficient or missing.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('RR03', 'MissingCreditorNameOrAddress', 'Specification of the creditor''s name and/or address needed for regulatory requirements is insufficient or missing.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('RR04', 'RegulatoryReason', 'Regulatory Reason', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('RR05', 'RegulatoryInformationInvalid', 'Regulatory or Central Bank Reporting information missing, incomplete or invalid.', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('RR06', 'TaxInformationInvalid', 'Tax information missing, incomplete or invalid.', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('RR07', 'RemittanceInformationInvalid', 'Remittance information structure does not comply with rules for payment type.', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('RR08', 'RemittanceInformationTruncated', 'Remittance information truncated to comply with rules for payment type.', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('RR09', 'InvalidStructuredCreditorReference', 'Structured creditor reference invalid or missing.', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('RR10', 'InvalidCharacterSet', 'Character set supplied not valid for the country and payment type.', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('RR11', 'InvalidDebtorAgentServiceID', 'Invalid or missing identification of a bank proprietary service.', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('RR12', 'InvalidPartyID', 'Invalid or missing identification required within a particular country or payment type.', 'Registered', '2010-08-01'::date, '2010-08-01'::date, NULL, NULL),
    ('RTNS', 'RTPNotSupportedForDebtor', 'Debtor does not support request-to-pay transactions.', 'Registered', '2021-11-30'::date, '2021-11-30'::date, NULL, 'CR1062'),
    ('RUTA', 'ReturnUponUnableToApply', 'Return following investigation request and no remediation possible.', 'Registered', '2021-08-31'::date, '2021-08-23'::date, NULL, 'CR0964'),
    ('S000', 'ValidRequestForCancellationAcknowledged', 'Request for Cancellation is acknowledged following validation.', 'Registered', '2018-08-01'::date, '2018-08-01'::date, NULL, NULL),
    ('S001', 'UETRFlaggedForCancellation', 'Unique End-to-end Transaction Reference (UETR) relating to a payment has been identified as being associated with a Request for Cancellation.', 'Registered', '2018-08-01'::date, '2018-08-01'::date, NULL, NULL),
    ('S002', 'NetworkStopOfUETR', 'Unique End-to-end Transaction Reference (UETR) relating to a payment has been prevent from traveling across a messaging network.', 'Registered', '2018-08-01'::date, '2018-08-01'::date, NULL, NULL),
    ('S003', 'RequestForCancellationForwarded', 'Request for Cancellation has been forwarded to the payment processing/last payment processing agent.', 'Registered', '2018-08-01'::date, '2018-08-01'::date, NULL, NULL),
    ('S004', 'RequestForCancellationDeliveryAcknowledgement', 'Request for Cancellation has been acknowledged as delivered to payment processing/last payment processing agent.', 'Registered', '2018-08-01'::date, '2018-08-01'::date, NULL, NULL)
ON CONFLICT ("Code") DO NOTHING;
INSERT INTO public."ExternalStatusReason1CodeValues" ("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", "ReplacedBy", "AdditionalInformation") VALUES
    ('SBRN', 'SettlementBatchRemovalNotification', 'Remove Concurrent Batch Processing Line on hold instruction.', 'Registered', '2024-05-31'::date, '2024-05-31'::date, NULL, NULL),
    ('SL01', 'SpecificServiceOfferedByDebtorAgent', 'Due to specific service offered by the Debtor Agent.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('SL02', 'SpecificServiceOfferedByCreditorAgent', 'Due to specific service offered by the Creditor Agent.', 'Registered', '2009-04-01'::date, '2009-04-01'::date, NULL, NULL),
    ('SL03', 'ServiceofClearingSystem', 'Due to a specific service offered by the clearing system.', 'Registered', '2019-11-01'::date, '2019-11-01'::date, NULL, NULL),
    ('SL11', 'CreditorNotOnWhitelistOfDebtor', 'Whitelisting service offered by the Debtor Agent; Debtor has not included the Creditor on its "Whitelist" (yet). In the Whitelist the Debtor may list all allowed Creditors to debit Debtor bank account.', 'Registered', '2016-04-01'::date, '2016-03-01'::date, NULL, NULL),
    ('SL12', 'CreditorOnBlacklistOfDebtor', 'Blacklisting service offered by the Debtor Agent; Debtor included the Creditor on his "Blacklist". In the Blacklist the Debtor may list all Creditors not allowed to debit Debtor bank account.', 'Registered', '2016-04-01'::date, '2016-03-01'::date, NULL, NULL),
    ('SL13', 'MaximumNumberOfDirectDebitTransactionsExceeded', 'Due to Maximum allowed Direct Debit Transactions per period service offered by the Debtor Agent.', 'Registered', '2016-04-01'::date, '2016-03-01'::date, NULL, NULL),
    ('SL14', 'MaximumDirectDebitTransactionAmountExceeded', 'Due to Maximum allowed Direct Debit Transaction amount service offered by the Debtor Agent.', 'Registered', '2016-04-01'::date, '2016-03-01'::date, NULL, NULL),
    ('SL15', 'MaximumNumberOfCreditTransactionsExceeded', 'Maximum number of credit transactions allowed by the account servicer per service period exceeded.', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('SL16', 'MaximumCreditTransactionsAmountExceeded', 'Maximum total credit amount allowed by the account servicer per service period exceeded.', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('SL17', 'DebtorNotOnWhitelistOfCreditorSide', 'Whitelisting service offered by payment system operator or financial institution. Debtor is not included on the Creditor side whitelist.', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('SL18', 'DebtorOnBlacklistOfCreditorSide', 'Blacklisting service offered by payment system operator or financial institution. Debtor included on the Creditor side blacklist.', 'Registered', '2024-12-03'::date, '2024-12-03'::date, NULL, NULL),
    ('SNRD', 'ServiceNotRendered', 'Services are not yet rendered by the Payee Participant (Creditor).', 'Registered', '2024-08-30'::date, '2024-08-30'::date, NULL, 'Used by the Payer Participant (Creditor) to decline the pain.013 request initiated by Payee Bank.'),
    ('SPII', 'RTPServiceProviderIdentifierIncorrect', 'Identifier of the request-to-pay service provider is incorrect.', 'Registered', '2021-11-30'::date, '2021-11-30'::date, NULL, 'CR1062'),
    ('TA01', 'TransmissonAborted', 'The transmission of the file was not successful - it had to be aborted (for technical reasons)', 'Registered', '2011-02-14'::date, '2011-02-14'::date, NULL, NULL),
    ('TD01', 'NoDataAvailable', 'There is no data available (for download)', 'Registered', '2011-02-14'::date, '2011-02-14'::date, NULL, NULL),
    ('TD02', 'FileNonReadable', 'The file cannot be read (e.g. unknown format)', 'Registered', '2011-02-14'::date, '2011-02-14'::date, NULL, NULL),
    ('TD03', 'IncorrectFileStructure', 'The file format is incomplete or invalid', 'Registered', '2011-02-14'::date, '2011-02-14'::date, NULL, NULL),
    ('TK01', 'TokenInvalid', 'Token is invalid.', 'Registered', '2019-11-01'::date, '2019-11-01'::date, NULL, NULL),
    ('TK02', 'SenderTokenNotFound', 'Token used for the sender does not exist.', 'Registered', '2019-11-01'::date, '2019-11-01'::date, NULL, NULL),
    ('TK03', 'ReceiverTokenNotFound', 'Token used for the receiver does not exist.', 'Registered', '2019-11-01'::date, '2019-11-01'::date, NULL, NULL),
    ('TK09', 'TokenMissing', 'Token required for request is missing.', 'Registered', '2019-11-01'::date, '2019-11-01'::date, NULL, NULL),
    ('TKCM', 'TokenCounterpartyMismatch', 'Token found with counterparty mismatch.', 'Registered', '2019-11-01'::date, '2019-11-01'::date, NULL, NULL),
    ('TKSG', 'TokenSingleUse', 'Single Use Token already used.', 'Registered', '2019-11-01'::date, '2019-11-01'::date, NULL, NULL),
    ('TKSP', 'TokenSuspended', 'Token found with suspended status.', 'Registered', '2019-11-01'::date, '2019-11-01'::date, NULL, NULL),
    ('TKVE', 'TokenValueLimitExceeded', 'Token found with value limit rule violation.', 'Registered', '2019-11-01'::date, '2019-11-01'::date, NULL, NULL),
    ('TKXP', 'TokenExpired', 'Token expired.', 'Registered', '2019-11-01'::date, '2019-11-01'::date, NULL, NULL),
    ('TM01', 'InvalidCutOffTime', 'Associated message, payment information block, or transaction was received after agreed processing cut-off time.', 'Registered', '2010-08-01'::date, '2009-04-01'::date, NULL, 'Replace CutOffTime'),
    ('TS01', 'TransmissionSuccessful', 'The (technical) transmission of the file was successful.', 'Registered', '2011-02-14'::date, '2011-02-14'::date, NULL, NULL),
    ('TS04', 'TransferToSignByHand', 'The order was transferred to pass by accompanying note signed by hand', 'Registered', '2011-02-14'::date, '2011-02-14'::date, NULL, NULL),
    ('UCRD', 'UnknownCreditor', 'Unknown Creditor.', 'Registered', '2021-11-30'::date, '2021-11-30'::date, NULL, 'CR1062'),
    ('UPAY', 'UnduePayment', 'Payment is not justified.', 'Registered', '2021-08-31'::date, '2021-08-23'::date, NULL, 'CR0964'),
    ('UTNV', 'UnderlyingTransactionNotValid', 'Referenced transaction not found', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, NULL),
    ('WGDA', 'WrongDebtorAgent', 'Wrong Debtor Agent in charge request message', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, 'If pacs.008 is underlying transaction'),
    ('WGDB', 'WrongDebtor', 'Wrong Debtor in charge request message', 'Registered', '2026-08-28'::date, '2026-08-28'::date, NULL, 'If pacs.009 is underlying transaction')
ON CONFLICT ("Code") DO NOTHING;
-- Verification -- External*Code seed row counts.
SELECT 'ExternalAccountIdentification1CodeValues' AS "Table", count(*) AS "RowCount" FROM public."ExternalAccountIdentification1CodeValues" UNION ALL
SELECT 'ExternalCashAccountType1CodeValues' AS "Table", count(*) AS "RowCount" FROM public."ExternalCashAccountType1CodeValues" UNION ALL
SELECT 'ExternalCashClearingSystem1CodeValues' AS "Table", count(*) AS "RowCount" FROM public."ExternalCashClearingSystem1CodeValues" UNION ALL
SELECT 'ExternalCategoryPurpose1CodeValues' AS "Table", count(*) AS "RowCount" FROM public."ExternalCategoryPurpose1CodeValues" UNION ALL
SELECT 'ExternalChargeType1CodeValues' AS "Table", count(*) AS "RowCount" FROM public."ExternalChargeType1CodeValues" UNION ALL
SELECT 'ExternalClearingSystemIdentification1CodeValues' AS "Table", count(*) AS "RowCount" FROM public."ExternalClearingSystemIdentification1CodeValues" UNION ALL
SELECT 'ExternalCreditorAgentInstruction1CodeValues' AS "Table", count(*) AS "RowCount" FROM public."ExternalCreditorAgentInstruction1CodeValues" UNION ALL
SELECT 'ExternalCreditorReferenceType1CodeValues' AS "Table", count(*) AS "RowCount" FROM public."ExternalCreditorReferenceType1CodeValues" UNION ALL
SELECT 'ExternalDateType1CodeValues' AS "Table", count(*) AS "RowCount" FROM public."ExternalDateType1CodeValues" UNION ALL
SELECT 'ExternalDocumentAmountType1CodeValues' AS "Table", count(*) AS "RowCount" FROM public."ExternalDocumentAmountType1CodeValues" UNION ALL
SELECT 'ExternalDocumentLineType1CodeValues' AS "Table", count(*) AS "RowCount" FROM public."ExternalDocumentLineType1CodeValues" UNION ALL
SELECT 'ExternalDocumentType1CodeValues' AS "Table", count(*) AS "RowCount" FROM public."ExternalDocumentType1CodeValues" UNION ALL
SELECT 'ExternalFinancialInstitutionIdentification1CodeValues' AS "Table", count(*) AS "RowCount" FROM public."ExternalFinancialInstitutionIdentification1CodeValues" UNION ALL
SELECT 'ExternalGarnishmentType1CodeValues' AS "Table", count(*) AS "RowCount" FROM public."ExternalGarnishmentType1CodeValues" UNION ALL
SELECT 'ExternalLocalInstrument1CodeValues' AS "Table", count(*) AS "RowCount" FROM public."ExternalLocalInstrument1CodeValues" UNION ALL
SELECT 'ExternalMandateSetupReason1CodeValues' AS "Table", count(*) AS "RowCount" FROM public."ExternalMandateSetupReason1CodeValues" UNION ALL
SELECT 'ExternalOrganisationIdentification1CodeValues' AS "Table", count(*) AS "RowCount" FROM public."ExternalOrganisationIdentification1CodeValues" UNION ALL
SELECT 'ExternalPaymentGroupStatus1CodeValues' AS "Table", count(*) AS "RowCount" FROM public."ExternalPaymentGroupStatus1CodeValues" UNION ALL
SELECT 'ExternalPaymentTransactionStatus1CodeValues' AS "Table", count(*) AS "RowCount" FROM public."ExternalPaymentTransactionStatus1CodeValues" UNION ALL
SELECT 'ExternalPersonIdentification1CodeValues' AS "Table", count(*) AS "RowCount" FROM public."ExternalPersonIdentification1CodeValues" UNION ALL
SELECT 'ExternalProxyAccountType1CodeValues' AS "Table", count(*) AS "RowCount" FROM public."ExternalProxyAccountType1CodeValues" UNION ALL
SELECT 'ExternalPurpose1CodeValues' AS "Table", count(*) AS "RowCount" FROM public."ExternalPurpose1CodeValues" UNION ALL
SELECT 'ExternalReturnReason1CodeValues' AS "Table", count(*) AS "RowCount" FROM public."ExternalReturnReason1CodeValues" UNION ALL
SELECT 'ExternalReversalReason1CodeValues' AS "Table", count(*) AS "RowCount" FROM public."ExternalReversalReason1CodeValues" UNION ALL
SELECT 'ExternalServiceLevel1CodeValues' AS "Table", count(*) AS "RowCount" FROM public."ExternalServiceLevel1CodeValues" UNION ALL
SELECT 'ExternalStatusReason1CodeValues' AS "Table", count(*) AS "RowCount" FROM public."ExternalStatusReason1CodeValues";
-- ---------------------------------------------------------------------
-- PART 4 -- 10.2.2 Binary
-- ---------------------------------------------------------------------
-- Domain: Max10KBinary
DROP DOMAIN IF EXISTS public."Max10KBinary" CASCADE;
CREATE DOMAIN public."Max10KBinary" AS bytea
    CHECK (octet_length(VALUE) BETWEEN 1 AND 10240);
ALTER DOMAIN public."Max10KBinary" OWNER TO postgres;
COMMENT ON DOMAIN public."Max10KBinary" IS
'Definition: Binary data of 10K maximum.

Format: minLength 1, maxLength 10240 (bytes).

Note: modeled as bytea (native Postgres binary type); the CHECK enforces the MDR''s 1-10240 byte range.';
-- ---------------------------------------------------------------------
-- PART 5 -- 10.2.4 Date / 10.2.5 DateTime / 10.2.11 Time / 10.2.12 Year
-- ---------------------------------------------------------------------
-- Domain: ISODate
DROP DOMAIN IF EXISTS public."ISODate" CASCADE;
CREATE DOMAIN public."ISODate" AS date;
ALTER DOMAIN public."ISODate" OWNER TO postgres;
COMMENT ON DOMAIN public."ISODate" IS
'Definition: A particular point in the progression of time in a calendar year expressed in the YYYY-MM-DD format (XML Schema date, aligned with ISO 8601).

Note: native Postgres date already enforces calendar validity; no additional CHECK needed. Wrapped as a domain purely so the MDR semantics/documentation travel with the column type.';
-- Domain: ISODateTime
DROP DOMAIN IF EXISTS public."ISODateTime" CASCADE;
CREATE DOMAIN public."ISODateTime" AS timestamptz;
ALTER DOMAIN public."ISODateTime" OWNER TO postgres;
COMMENT ON DOMAIN public."ISODateTime" IS
'Definition: A particular point in time defined by a mandatory date and mandatory time component, expressed as UTC (YYYY-MM-DDThh:mm:ss.sssZ), local time with UTC offset (YYYY-MM-DDThh:mm:ss.sss+/-hh:mm), or local time with no offset (YYYY-MM-DDThh:mm:ss.sss). Aligned with ISO 8601.

Note on time format: 00:00:00 = beginning of a calendar day, 24:00:00 = end of a calendar day. Fractional seconds allowed, precision by agreement between parties.

MODELING CHOICE: mapped to timestamptz, which correctly handles the UTC and UTC-offset variants (stored internally as UTC, rendered in session timezone). The MDR''s third variant -- local time with NO offset info at all -- has no lossless native equivalent: timestamptz will interpret it using the session timezone at insert time. If your messages regularly omit the offset and that distinction matters downstream, consider timestamp (without time zone) instead and handle offset-bearing values explicitly. Flag if you want this changed before the component library is built on top of it.';
-- Domain: ISOTime
DROP DOMAIN IF EXISTS public."ISOTime" CASCADE;
CREATE DOMAIN public."ISOTime" AS timetz;
ALTER DOMAIN public."ISOTime" OWNER TO postgres;
COMMENT ON DOMAIN public."ISOTime" IS
'Definition: A particular point in time in a calendar day, expressed as UTC (hh:mm:ss.sssZ), local time with UTC offset (hh:mm:ss.sss+/-hh:mm), or local time with no offset (hh:mm:ss.sss). Aligned with ISO 8601.

Note on time format: 00:00:00 = beginning of a calendar day, 24:00:00 = end of a calendar day (Postgres time/timetz accept 24:00:00). Fractional seconds allowed, precision by agreement.

MODELING CHOICE: mapped to timetz to preserve an explicit UTC offset where present -- same no-offset caveat as ISODateTime above applies.';
-- Domain: ISOYear
DROP DOMAIN IF EXISTS public."ISOYear" CASCADE;
CREATE DOMAIN public."ISOYear" AS smallint
    CHECK (VALUE BETWEEN 0 AND 9999);
ALTER DOMAIN public."ISOYear" OWNER TO postgres;
COMMENT ON DOMAIN public."ISOYear" IS
'Definition: Year represented by YYYY (ISO 8601).

Note: modeled as smallint restricted to the 4-digit YYYY range (0-9999) implied by the format.';
-- ---------------------------------------------------------------------
-- PART 6 -- 10.2.6 IdentifierSet
-- ---------------------------------------------------------------------
-- Domain: AnyBICDec2014Identifier
DROP DOMAIN IF EXISTS public."AnyBICDec2014Identifier" CASCADE;
CREATE DOMAIN public."AnyBICDec2014Identifier" AS varchar(11)
    CHECK (VALUE ~ '^[A-Z0-9]{4}[A-Z]{2}[A-Z0-9]{2}([A-Z0-9]{3})?$');
ALTER DOMAIN public."AnyBICDec2014Identifier" OWNER TO postgres;
COMMENT ON DOMAIN public."AnyBICDec2014Identifier" IS
'Definition: Code allocated to a financial or non-financial institution by the ISO 9362 Registration Authority, as described in ISO 9362:2014 "Banking - Banking telecommunication messages - Business identifier code (BIC)".

Identification scheme: SWIFT; AnyBICIdentifier.

Format: pattern [A-Z0-9]{4,4}[A-Z]{2,2}[A-Z0-9]{2,2}([A-Z0-9]{3,3}){0,1} (8 or 11 characters).

Constraint - AnyBIC: Only a valid Business Identifier Code is allowed. BICs for financial or non-financial institutions are registered and published by the ISO 9362 Registration Authority in the ISO directory of BICs, and consist of eight (8) or eleven (11) contiguous characters.';
-- Domain: BICFIDec2014Identifier
DROP DOMAIN IF EXISTS public."BICFIDec2014Identifier" CASCADE;
CREATE DOMAIN public."BICFIDec2014Identifier" AS varchar(11)
    CHECK (VALUE ~ '^[A-Z0-9]{4}[A-Z]{2}[A-Z0-9]{2}([A-Z0-9]{3})?$');
ALTER DOMAIN public."BICFIDec2014Identifier" OWNER TO postgres;
COMMENT ON DOMAIN public."BICFIDec2014Identifier" IS
'Definition: Code allocated to a financial institution by the ISO 9362 Registration Authority as described in ISO 9362:2014 "Banking - Banking telecommunication messages - Business identifier code (BIC)".

Identification scheme: SWIFT; BICIdentifier.

Format: pattern [A-Z0-9]{4,4}[A-Z]{2,2}[A-Z0-9]{2,2}([A-Z0-9]{3,3}){0,1} (8 or 11 characters).

Constraint - BICFI: Valid BICs for financial institutions are registered and published by the ISO 9362 Registration Authority in the ISO directory of BICs, and consist of eight (8) or eleven (11) contiguous characters.';
-- Domain: IBAN2007Identifier
DROP DOMAIN IF EXISTS public."IBAN2007Identifier" CASCADE;
CREATE DOMAIN public."IBAN2007Identifier" AS varchar(34)
    CHECK (VALUE ~ '^[A-Z]{2}[0-9]{2}[a-zA-Z0-9]{1,30}$');
ALTER DOMAIN public."IBAN2007Identifier" OWNER TO postgres;
COMMENT ON DOMAIN public."IBAN2007Identifier" IS
'Definition: The International Bank Account Number is a code used internationally by financial institutions to uniquely identify the account of a customer at a financial institution, as described in the 2007 edition of ISO 13616 "Banking and related financial services - International Bank Account Number (IBAN)" and replaced by more recent editions of the standard.

Identification scheme: National Banking Association; International Bank Account Number (ISO 13616).

Format: pattern [A-Z]{2,2}[0-9]{2,2}[a-zA-Z0-9]{1,30} (up to 34 characters).

Constraint - IBAN: A valid IBAN consists of all three of the following components: Country Code, check digits and BBAN.

Note: this domain enforces FORMAT ONLY (structure/length); it does not verify the mod-97 check-digit algorithm.';
-- Domain: LEIIdentifier
DROP DOMAIN IF EXISTS public."LEIIdentifier" CASCADE;
CREATE DOMAIN public."LEIIdentifier" AS varchar(20)
    CHECK (VALUE ~ '^[A-Z0-9]{18}[0-9]{2}$');
ALTER DOMAIN public."LEIIdentifier" OWNER TO postgres;
COMMENT ON DOMAIN public."LEIIdentifier" IS
'Definition: Legal Entity Identifier is a code allocated to a party as described in ISO 17442 "Financial Services - Legal Entity Identifier (LEI)".

Identification scheme: Global LEI System; LEIIdentifier.

Format: pattern [A-Z0-9]{18,18}[0-9]{2,2} (fixed 20 characters).';
-- Domain: UUIDv4Identifier
DROP DOMAIN IF EXISTS public."UUIDv4Identifier" CASCADE;
CREATE DOMAIN public."UUIDv4Identifier" AS varchar(36)
    CHECK (VALUE ~ '^[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$');
ALTER DOMAIN public."UUIDv4Identifier" OWNER TO postgres;
COMMENT ON DOMAIN public."UUIDv4Identifier" IS
'Definition: Universally Unique IDentifier (UUID) version 4, as described in IETF RFC 4122 "Universally Unique IDentifier (UUID) URN Namespace".

Identification scheme: RFC4122; UUIDv4.

Format: pattern [a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}.

Note: Postgres has a native uuid type; this domain instead follows the MDRs own lowercase-hex-with-version/variant-nibble pattern literally over text, so a value that is syntactically a UUID but NOT specifically v4 (wrong version nibble) is rejected -- native uuid alone would accept any UUID version.';
-- ---------------------------------------------------------------------
-- PART 7 -- 10.2.7 Indicator
-- ---------------------------------------------------------------------
-- Domain: BatchBookingIndicator
DROP DOMAIN IF EXISTS public."BatchBookingIndicator" CASCADE;
CREATE DOMAIN public."BatchBookingIndicator" AS boolean;
ALTER DOMAIN public."BatchBookingIndicator" OWNER TO postgres;
COMMENT ON DOMAIN public."BatchBookingIndicator" IS
'Definition: Identifies whether the sending party requests a single debit or credit entry per individual transaction or a batch entry for the sum of the amounts of all transactions.

Meaning When True: Identifies that a batch entry for the sum of the amounts of all transactions in the batch or message is requested.

Meaning When False: Identifies that a single entry for each of the transactions in the batch or message is requested.';
-- Domain: TrueFalseIndicator
DROP DOMAIN IF EXISTS public."TrueFalseIndicator" CASCADE;
CREATE DOMAIN public."TrueFalseIndicator" AS boolean;
ALTER DOMAIN public."TrueFalseIndicator" OWNER TO postgres;
COMMENT ON DOMAIN public."TrueFalseIndicator" IS
'Definition: A flag indicating a True or False value.

Meaning When True: True.

Meaning When False: False.';
-- ---------------------------------------------------------------------
-- PART 8 -- 10.2.8 Quantity / 10.2.9 Rate
-- ---------------------------------------------------------------------
-- Domain: DecimalNumber
DROP DOMAIN IF EXISTS public."DecimalNumber" CASCADE;
CREATE DOMAIN public."DecimalNumber" AS numeric(18,17);
ALTER DOMAIN public."DecimalNumber" OWNER TO postgres;
COMMENT ON DOMAIN public."DecimalNumber" IS
'Definition: Number of objects represented as a decimal number, for example 0.75 or 45.6.

Format: totalDigits 18, fractionDigits 17.';
-- Domain: Number
DROP DOMAIN IF EXISTS public."Number" CASCADE;
CREATE DOMAIN public."Number" AS numeric(18,0);
ALTER DOMAIN public."Number" OWNER TO postgres;
COMMENT ON DOMAIN public."Number" IS
'Definition: Number of objects represented as an integer.

Format: totalDigits 18, fractionDigits 0.';
-- Domain: BaseOneRate
DROP DOMAIN IF EXISTS public."BaseOneRate" CASCADE;
CREATE DOMAIN public."BaseOneRate" AS numeric(11,10);
ALTER DOMAIN public."BaseOneRate" OWNER TO postgres;
COMMENT ON DOMAIN public."BaseOneRate" IS
'Definition: Rate expressed as a decimal, for example, 0.7 is 7/10 and 70%.

Format: totalDigits 11, fractionDigits 10, baseValue 1.0.';
-- Domain: PercentageRate
DROP DOMAIN IF EXISTS public."PercentageRate" CASCADE;
CREATE DOMAIN public."PercentageRate" AS numeric(11,10);
ALTER DOMAIN public."PercentageRate" OWNER TO postgres;
COMMENT ON DOMAIN public."PercentageRate" IS
'Definition: Rate expressed as a percentage, that is, in hundredths, for example, 0.7 is 7/10 of a percent, and 7.0 is 7%.

Format: totalDigits 11, fractionDigits 10, baseValue 100.0.';
-- ---------------------------------------------------------------------
-- PART 9 -- 10.2.10 Text
-- ---------------------------------------------------------------------
-- Domain: Exact2NumericText
DROP DOMAIN IF EXISTS public."Exact2NumericText" CASCADE;
CREATE DOMAIN public."Exact2NumericText" AS varchar(2)
    CHECK (VALUE ~ '^[0-9]{2}$');
ALTER DOMAIN public."Exact2NumericText" OWNER TO postgres;
COMMENT ON DOMAIN public."Exact2NumericText" IS
'Definition: Specifies a numeric string with an exact length of 2 digits.

Format: pattern ^[0-9]{2}$.';
-- Domain: Exact4AlphaNumericText
DROP DOMAIN IF EXISTS public."Exact4AlphaNumericText" CASCADE;
CREATE DOMAIN public."Exact4AlphaNumericText" AS varchar(4)
    CHECK (VALUE ~ '^[a-zA-Z0-9]{4}$');
ALTER DOMAIN public."Exact4AlphaNumericText" OWNER TO postgres;
COMMENT ON DOMAIN public."Exact4AlphaNumericText" IS
'Definition: Specifies an alphanumeric string with a length of 4 characters.

Format: pattern ^[a-zA-Z0-9]{4}$.';
-- Domain: HexBinaryText
DROP DOMAIN IF EXISTS public."HexBinaryText" CASCADE;
CREATE DOMAIN public."HexBinaryText" AS text
    CHECK (VALUE ~ '^[0-9a-fA-F]+$');
ALTER DOMAIN public."HexBinaryText" OWNER TO postgres;
COMMENT ON DOMAIN public."HexBinaryText" IS
'Definition: Specifies a character string with hexadecimal text characters. Used for hex binary data only, supports only characters A-F, a-f and 0-9.

Format: pattern ^[0-9a-fA-F]+$ (no explicit maxLength in the MDR).';
-- Domain: Max1025Text
DROP DOMAIN IF EXISTS public."Max1025Text" CASCADE;
CREATE DOMAIN public."Max1025Text" AS varchar(1025)
    CHECK (char_length(VALUE) >= 1);
ALTER DOMAIN public."Max1025Text" OWNER TO postgres;
COMMENT ON DOMAIN public."Max1025Text" IS
'Definition: Specifies a character string with a maximum length of 1025 characters.

Format: minLength 1, maxLength 1025.';
-- Domain: Max105Text
DROP DOMAIN IF EXISTS public."Max105Text" CASCADE;
CREATE DOMAIN public."Max105Text" AS varchar(105)
    CHECK (char_length(VALUE) >= 1);
ALTER DOMAIN public."Max105Text" OWNER TO postgres;
COMMENT ON DOMAIN public."Max105Text" IS
'Definition: Specifies a character string with a maximum length of 105 characters.

Format: minLength 1, maxLength 105.';
-- Domain: Max10Text
DROP DOMAIN IF EXISTS public."Max10Text" CASCADE;
CREATE DOMAIN public."Max10Text" AS varchar(10)
    CHECK (char_length(VALUE) >= 1);
ALTER DOMAIN public."Max10Text" OWNER TO postgres;
COMMENT ON DOMAIN public."Max10Text" IS
'Definition: Specifies a character string with a maximum length of 10 characters.

Format: minLength 1, maxLength 10.';
-- Domain: Max128Text
DROP DOMAIN IF EXISTS public."Max128Text" CASCADE;
CREATE DOMAIN public."Max128Text" AS varchar(128)
    CHECK (char_length(VALUE) >= 1);
ALTER DOMAIN public."Max128Text" OWNER TO postgres;
COMMENT ON DOMAIN public."Max128Text" IS
'Definition: Specifies a character string with a maximum length of 128 characters.

Format: minLength 1, maxLength 128.';
-- Domain: Max140Text
DROP DOMAIN IF EXISTS public."Max140Text" CASCADE;
CREATE DOMAIN public."Max140Text" AS varchar(140)
    CHECK (char_length(VALUE) >= 1);
ALTER DOMAIN public."Max140Text" OWNER TO postgres;
COMMENT ON DOMAIN public."Max140Text" IS
'Definition: Specifies a character string with a maximum length of 140 characters.

Format: minLength 1, maxLength 140.';
-- Domain: Max15NumericText
DROP DOMAIN IF EXISTS public."Max15NumericText" CASCADE;
CREATE DOMAIN public."Max15NumericText" AS varchar(15)
    CHECK (VALUE ~ '^[0-9]{1,15}$');
ALTER DOMAIN public."Max15NumericText" OWNER TO postgres;
COMMENT ON DOMAIN public."Max15NumericText" IS
'Definition: Specifies a numeric string with a maximum length of 15 digits.

Format: pattern ^[0-9]{1,15}$.';
-- Domain: Max16Text
DROP DOMAIN IF EXISTS public."Max16Text" CASCADE;
CREATE DOMAIN public."Max16Text" AS varchar(16)
    CHECK (char_length(VALUE) >= 1);
ALTER DOMAIN public."Max16Text" OWNER TO postgres;
COMMENT ON DOMAIN public."Max16Text" IS
'Definition: Specifies a character string with a maximum length of 16 characters.

Format: minLength 1, maxLength 16.';
-- Domain: Max2048Text
DROP DOMAIN IF EXISTS public."Max2048Text" CASCADE;
CREATE DOMAIN public."Max2048Text" AS varchar(2048)
    CHECK (char_length(VALUE) >= 1);
ALTER DOMAIN public."Max2048Text" OWNER TO postgres;
COMMENT ON DOMAIN public."Max2048Text" IS
'Definition: Specifies a character string with a maximum length of 2048 characters.

Format: minLength 1, maxLength 2048.';
-- Domain: Max210Text
DROP DOMAIN IF EXISTS public."Max210Text" CASCADE;
CREATE DOMAIN public."Max210Text" AS varchar(210)
    CHECK (char_length(VALUE) >= 1);
ALTER DOMAIN public."Max210Text" OWNER TO postgres;
COMMENT ON DOMAIN public."Max210Text" IS
'Definition: Specifies a character string with a maximum length of 210 characters.

Format: minLength 1, maxLength 210.';
-- Domain: Max256Text
DROP DOMAIN IF EXISTS public."Max256Text" CASCADE;
CREATE DOMAIN public."Max256Text" AS varchar(256)
    CHECK (char_length(VALUE) >= 1);
ALTER DOMAIN public."Max256Text" OWNER TO postgres;
COMMENT ON DOMAIN public."Max256Text" IS
'Definition: Specifies a character string with a maximum length of 256 characters.

Format: minLength 1, maxLength 256.';
-- Domain: Max34Text
DROP DOMAIN IF EXISTS public."Max34Text" CASCADE;
CREATE DOMAIN public."Max34Text" AS varchar(34)
    CHECK (char_length(VALUE) >= 1);
ALTER DOMAIN public."Max34Text" OWNER TO postgres;
COMMENT ON DOMAIN public."Max34Text" IS
'Definition: Specifies a character string with a maximum length of 34 characters.

Format: minLength 1, maxLength 34.';
-- Domain: Max350Text
DROP DOMAIN IF EXISTS public."Max350Text" CASCADE;
CREATE DOMAIN public."Max350Text" AS varchar(350)
    CHECK (char_length(VALUE) >= 1);
ALTER DOMAIN public."Max350Text" OWNER TO postgres;
COMMENT ON DOMAIN public."Max350Text" IS
'Definition: Specifies a character string with a maximum length of 350 characters.

Format: minLength 1, maxLength 350.';
-- Domain: Max35Text
DROP DOMAIN IF EXISTS public."Max35Text" CASCADE;
CREATE DOMAIN public."Max35Text" AS varchar(35)
    CHECK (char_length(VALUE) >= 1);
ALTER DOMAIN public."Max35Text" OWNER TO postgres;
COMMENT ON DOMAIN public."Max35Text" IS
'Definition: Specifies a character string with a maximum length of 35 characters.

Format: minLength 1, maxLength 35.';
-- Domain: Max4Text
DROP DOMAIN IF EXISTS public."Max4Text" CASCADE;
CREATE DOMAIN public."Max4Text" AS varchar(4)
    CHECK (char_length(VALUE) >= 1);
ALTER DOMAIN public."Max4Text" OWNER TO postgres;
COMMENT ON DOMAIN public."Max4Text" IS
'Definition: Specifies a character string with a maximum length of 4 characters.

Format: minLength 1, maxLength 4.';
-- Domain: Max52Text
DROP DOMAIN IF EXISTS public."Max52Text" CASCADE;
CREATE DOMAIN public."Max52Text" AS varchar(52)
    CHECK (char_length(VALUE) >= 1);
ALTER DOMAIN public."Max52Text" OWNER TO postgres;
COMMENT ON DOMAIN public."Max52Text" IS
'Definition: Specifies a character string with a maximum length of 52 characters.

Format: minLength 1, maxLength 52.';
-- Domain: Max70Text
DROP DOMAIN IF EXISTS public."Max70Text" CASCADE;
CREATE DOMAIN public."Max70Text" AS varchar(70)
    CHECK (char_length(VALUE) >= 1);
ALTER DOMAIN public."Max70Text" OWNER TO postgres;
COMMENT ON DOMAIN public."Max70Text" IS
'Definition: Specifies a character string with a maximum length of 70 characters.

Format: minLength 1, maxLength 70.';
-- Domain: PhoneNumber
DROP DOMAIN IF EXISTS public."PhoneNumber" CASCADE;
CREATE DOMAIN public."PhoneNumber" AS varchar(35)
    CHECK (VALUE ~ '^\+[0-9]{1,3}-[0-9()+\-]{1,30}$');
ALTER DOMAIN public."PhoneNumber" OWNER TO postgres;
COMMENT ON DOMAIN public."PhoneNumber" IS
'Definition: The collection of information which identifies a specific phone or FAX number as defined by telecom services. It consists of a "+" followed by the country code (1 to 3 characters) then a "-" and finally, any combination of numbers, "(", ")", "+" and "-" (up to 30 characters).

Format: pattern ^\+[0-9]{1,3}-[0-9()+\-]{1,30}$.';
-- Domain: SHA256SignatureText
DROP DOMAIN IF EXISTS public."SHA256SignatureText" CASCADE;
CREATE DOMAIN public."SHA256SignatureText" AS varchar(64)
    CHECK (VALUE ~ '^([0-9A-F]{2}){32}$');
ALTER DOMAIN public."SHA256SignatureText" OWNER TO postgres;
COMMENT ON DOMAIN public."SHA256SignatureText" IS
'Definition: Specifies a character string with an exact length of 32 binary bytes (64 hexadecimal text characters). Used only for hex binary data, supports only characters A-F and 0-9.

Format: pattern ^([0-9A-F]{2}){32}$.';
-- ---------------------------------------------------------------------
-- PART 10 -- 10.2.1 Amount: composite TYPE + validate_ function
-- (composite types cannot carry CHECK constraints directly -- mirrors
-- the DatePeriod2 / validate_date_period pattern)
-- ---------------------------------------------------------------------
-- Type: ActiveCurrencyAndAmount
DROP TYPE IF EXISTS public."ActiveCurrencyAndAmount" CASCADE;
CREATE TYPE public."ActiveCurrencyAndAmount" AS (
    "Amt" numeric(18,5),
    "Ccy" public."ActiveCurrencyCode"
);
ALTER TYPE public."ActiveCurrencyAndAmount" OWNER TO postgres;
COMMENT ON TYPE public."ActiveCurrencyAndAmount" IS
'Definition: A number of monetary units specified in an active currency where the unit of currency is explicit and compliant with ISO 4217.

XML attribute: Currency <Ccy>, datatype ActiveCurrencyCode.

Format: minInclusive 0, totalDigits 18, fractionDigits 5.

Constraint - ActiveCurrency: The currency code must be a valid active currency code, not yet withdrawn on the day the message containing the currency is exchanged.

Constraint - CurrencyAmount: The number of fractional digits (minor unit of currency) must comply with ISO 4217. Note: the decimal separator is a dot.';
-- FUNCTION: public.validate_active_currency_and_amount("ActiveCurrencyAndAmount")
-- DROP FUNCTION IF EXISTS public.validate_active_currency_and_amount(public."ActiveCurrencyAndAmount");
CREATE OR REPLACE FUNCTION public.validate_active_currency_and_amount(
    val public."ActiveCurrencyAndAmount")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN val."Amt" IS NOT NULL
        AND val."Amt" >= 0
        AND val."Ccy" IS NOT NULL;
END;
$BODY$;
ALTER FUNCTION public.validate_active_currency_and_amount(public."ActiveCurrencyAndAmount")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_active_currency_and_amount(public."ActiveCurrencyAndAmount") IS
'Validates a public."ActiveCurrencyAndAmount" value against MDR constraints ActiveCurrency (currency format checked by the ActiveCurrencyCode domain; active/withdrawn status is NOT checked here -- see that domains comment) and CurrencyAmount (Amt must be present and >= 0, per Format minInclusive 0).';
-- Type: ActiveOrHistoricCurrencyAndAmount
DROP TYPE IF EXISTS public."ActiveOrHistoricCurrencyAndAmount" CASCADE;
CREATE TYPE public."ActiveOrHistoricCurrencyAndAmount" AS (
    "Amt" numeric(18,5),
    "Ccy" public."ActiveOrHistoricCurrencyCode"
);
ALTER TYPE public."ActiveOrHistoricCurrencyAndAmount" OWNER TO postgres;
COMMENT ON TYPE public."ActiveOrHistoricCurrencyAndAmount" IS
'Definition: A number of monetary units specified in an active or a historic currency where the unit of currency is explicit and compliant with ISO 4217.

XML attribute: Currency <Ccy>, datatype ActiveOrHistoricCurrencyCode.

Format: minInclusive 0, totalDigits 18, fractionDigits 5.

Constraint - ActiveOrHistoricCurrency: The currency code must be registered, or have already been registered.

Constraint - CurrencyAmount: The number of fractional digits (minor unit of currency) must comply with ISO 4217. Note: the decimal separator is a dot.';
-- FUNCTION: public.validate_active_or_historic_currency_and_amount("ActiveOrHistoricCurrencyAndAmount")
-- DROP FUNCTION IF EXISTS public.validate_active_or_historic_currency_and_amount(public."ActiveOrHistoricCurrencyAndAmount");
CREATE OR REPLACE FUNCTION public.validate_active_or_historic_currency_and_amount(
    val public."ActiveOrHistoricCurrencyAndAmount")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN val."Amt" IS NOT NULL
        AND val."Amt" >= 0
        AND val."Ccy" IS NOT NULL;
END;
$BODY$;
ALTER FUNCTION public.validate_active_or_historic_currency_and_amount(public."ActiveOrHistoricCurrencyAndAmount")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_active_or_historic_currency_and_amount(public."ActiveOrHistoricCurrencyAndAmount") IS
'Validates a public."ActiveOrHistoricCurrencyAndAmount" value against MDR constraints ActiveOrHistoricCurrency (currency format checked by the ActiveOrHistoricCurrencyCode domain; registration status is NOT checked here) and CurrencyAmount (Amt must be present and >= 0, per Format minInclusive 0).';
