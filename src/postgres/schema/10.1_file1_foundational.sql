-- =====================================================================
-- ISO 20022 Message Definition Report - Part 2
-- Payments Clearing and Settlement - Maintenance 2024-2025 (Feb 2025)
-- Section 10.1 "Message Components" -- FILE 1 of 4: Foundational & standalone
--
-- Covers: Amount, Date Period, Date Time, Frequency, Identification
-- Information, Mandate, Miscellaneous, Payment, Payment Type, System
-- Identification, Tax. None of these depend on components outside this file.
--
-- Depends on: 10.2 Message Datatypes (domains/enums) only.
-- Load order across the 4 files: this file first, then Identity & Contact,
-- then Accounts & Financial Institutions, then Payment/Compliance.
-- =====================================================================
-- ---------------------------------------------------------------------
-- PART 1 -- Simple standalone composites
-- ---------------------------------------------------------------------
-- Type: DatePeriod2 (10.1.4.1)
DROP TYPE IF EXISTS public."DatePeriod2" CASCADE;
CREATE TYPE public."DatePeriod2" AS (
    "FromDate" public."ISODate",
    "ToDate" public."ISODate"
);
ALTER TYPE public."DatePeriod2" OWNER TO postgres;
COMMENT ON TYPE public."DatePeriod2" IS
'Definition: Range of time defined by a start date and an end date.

FromDate: Start date of the range.
ToDate: End date of the range.';
-- FUNCTION: validate_date_period("DatePeriod2")
DROP FUNCTION IF EXISTS public.validate_date_period(public."DatePeriod2");
CREATE OR REPLACE FUNCTION public.validate_date_period(
    period public."DatePeriod2")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN period."FromDate" IS NOT NULL
        AND period."ToDate" IS NOT NULL
        AND period."FromDate" <= period."ToDate";
END;
$BODY$;
ALTER FUNCTION public.validate_date_period(public."DatePeriod2")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_date_period(public."DatePeriod2") IS
'Validates a DatePeriod2 value: both dates present and FromDate <= ToDate. Reproduced to match the pre-existing convention this project was built on.';
-- Type: GenericIdentification3 (10.1.9.3)
DROP TYPE IF EXISTS public."GenericIdentification3" CASCADE;
CREATE TYPE public."GenericIdentification3" AS (
    "Identification" public."Max35Text",
    "Issuer" public."Max35Text"
);
ALTER TYPE public."GenericIdentification3" OWNER TO postgres;
COMMENT ON TYPE public."GenericIdentification3" IS
'Definition: Information related to an identification, for example, party identification or account identification.

Identification: [1..1] Name or number assigned by an entity to enable recognition of that entity, for example, account identifier.
Issuer: [0..1] Entity that assigns the identification.';
DROP FUNCTION IF EXISTS public.validate_generic_identification3(public."GenericIdentification3");
CREATE OR REPLACE FUNCTION public.validate_generic_identification3(
    val public."GenericIdentification3")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN val."Identification" IS NOT NULL;
END;
$BODY$;
ALTER FUNCTION public.validate_generic_identification3(public."GenericIdentification3")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_generic_identification3(public."GenericIdentification3") IS
'Checks the [1..1] mandatory field (Identification) is present.';
-- Type: GenericIdentification30 (10.1.9.4)
DROP TYPE IF EXISTS public."GenericIdentification30" CASCADE;
CREATE TYPE public."GenericIdentification30" AS (
    "Identification" public."Exact4AlphaNumericText",
    "Issuer" public."Max35Text",
    "SchemeName" public."Max35Text"
);
ALTER TYPE public."GenericIdentification30" OWNER TO postgres;
COMMENT ON TYPE public."GenericIdentification30" IS
'Definition: Information related to an identification, for example, party identification or account identification.

Identification: [1..1] Proprietary information, often a code, issued by the data source scheme issuer.
Issuer: [1..1] Entity that assigns the identification.
SchemeName: [0..1] Short textual description of the scheme.';
DROP FUNCTION IF EXISTS public.validate_generic_identification30(public."GenericIdentification30");
CREATE OR REPLACE FUNCTION public.validate_generic_identification30(
    val public."GenericIdentification30")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN val."Identification" IS NOT NULL
        AND val."Issuer" IS NOT NULL;
END;
$BODY$;
ALTER FUNCTION public.validate_generic_identification30(public."GenericIdentification30")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_generic_identification30(public."GenericIdentification30") IS
'Checks the [1..1] mandatory fields (Identification, Issuer) are present. Composite TYPEs cannot enforce per-field NOT NULL directly -- this function is how multiplicity is validated for this type.';
-- Type: References74Choice (10.1.9.1)
DROP TYPE IF EXISTS public."References74Choice" CASCADE;
CREATE TYPE public."References74Choice" AS (
    "SecuritiesSettlementTransactionIdentification" public."Max35Text",
    "IntraPositionMovementIdentification" public."Max35Text",
    "IntraBalanceMovementIdentification" public."Max35Text",
    "AccountServicerTransactionIdentification" public."Max35Text",
    "MarketInfrastructureTransactionIdentification" public."Max35Text",
    "CounterpartyMarketInfrastructureTransactionIdentification" public."Max35Text",
    "PoolIdentification" public."Max35Text",
    "CommonIdentification" public."Max35Text",
    "TradeIdentification" public."Max52Text",
    "OtherTransactionIdentification" public."Max35Text"
);
ALTER TYPE public."References74Choice" OWNER TO postgres;
COMMENT ON TYPE public."References74Choice" IS
'Definition: Choice between references.

{Or}/{Or} choice -- exactly one branch must be set:
SecuritiesSettlementTransactionIdentification: Unambiguous identification of a securities settlement transaction as known by the account owner.
IntraPositionMovementIdentification: Unambiguous identification of the intra-position movement transaction.
IntraBalanceMovementIdentification: Unambiguous identification of the intra balance movement transaction.
AccountServicerTransactionIdentification: Unambiguous identification of the transaction as known by the account servicer.
MarketInfrastructureTransactionIdentification: Identification of a transaction assigned by a market infrastructure other than a CSD.
CounterpartyMarketInfrastructureTransactionIdentification: Identification of a counterparty transaction assigned by a market infrastructure other than a CSD. (Source MDR marks this branch [0..1] rather than [1..1] like its siblings -- reproduced as-is.)
PoolIdentification: Collective reference identifying a set of messages.
CommonIdentification: Unique reference agreed upon by the two trade counterparties to identify the trade.
TradeIdentification: Reference assigned to the trade by the investor or the trading party.
OtherTransactionIdentification: Identification of a transaction that cannot be identified using a standard reference element.';
DROP FUNCTION IF EXISTS public.validate_references74_choice(public."References74Choice");
CREATE OR REPLACE FUNCTION public.validate_references74_choice(
    val public."References74Choice")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN ((val."SecuritiesSettlementTransactionIdentification" IS NOT NULL)::int + (val."IntraPositionMovementIdentification" IS NOT NULL)::int + (val."IntraBalanceMovementIdentification" IS NOT NULL)::int + (val."AccountServicerTransactionIdentification" IS NOT NULL)::int + (val."MarketInfrastructureTransactionIdentification" IS NOT NULL)::int + (val."CounterpartyMarketInfrastructureTransactionIdentification" IS NOT NULL)::int + (val."PoolIdentification" IS NOT NULL)::int + (val."CommonIdentification" IS NOT NULL)::int + (val."TradeIdentification" IS NOT NULL)::int + (val."OtherTransactionIdentification" IS NOT NULL)::int) = 1;
END;
$BODY$;
ALTER FUNCTION public.validate_references74_choice(public."References74Choice")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_references74_choice(public."References74Choice") IS
'Checks the {Or}/{Or} choice: exactly one of SecuritiesSettlementTransactionIdentification, IntraPositionMovementIdentification, IntraBalanceMovementIdentification, AccountServicerTransactionIdentification, MarketInfrastructureTransactionIdentification, CounterpartyMarketInfrastructureTransactionIdentification, PoolIdentification, CommonIdentification, TradeIdentification, OtherTransactionIdentification is set. Composite-typed branches use num_nonnulls() over their own fields rather than a plain IS NOT NULL -- see branch_populated_expr in the generator for why.';
-- Type: OriginalGroupInformation27 (10.1.11.1)
DROP TYPE IF EXISTS public."OriginalGroupInformation27" CASCADE;
CREATE TYPE public."OriginalGroupInformation27" AS (
    "OriginalMessageIdentification" public."Max35Text",
    "OriginalMessageNameIdentification" public."Max35Text",
    "OriginalCreationDateTime" public."ISODateTime",
    "OriginalNumberOfTransactions" public."Max15NumericText",
    "OriginalControlSum" public."DecimalNumber"
);
ALTER TYPE public."OriginalGroupInformation27" OWNER TO postgres;
COMMENT ON TYPE public."OriginalGroupInformation27" IS
'Definition: Set of elements used to provide information on the original group, to which the message refers.

OriginalMessageIdentification: [1..1] Point to point reference, as assigned by the original instructing party, to unambiguously identify the original message.
OriginalMessageNameIdentification: [1..1] Specifies the original message name identifier to which the message refers.
OriginalCreationDateTime: [0..1] Date and time at which the original message was created.
OriginalNumberOfTransactions: [0..1] Number of individual transactions contained in the original message.
OriginalControlSum: [0..1] Total of all individual amounts included in the original message, irrespective of currencies.';
DROP FUNCTION IF EXISTS public.validate_original_group_information27(public."OriginalGroupInformation27");
CREATE OR REPLACE FUNCTION public.validate_original_group_information27(
    val public."OriginalGroupInformation27")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN (val."OriginalMessageIdentification" IS NOT NULL)
        AND (val."OriginalMessageNameIdentification" IS NOT NULL);
END;
$BODY$;
ALTER FUNCTION public.validate_original_group_information27(public."OriginalGroupInformation27")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_original_group_information27(public."OriginalGroupInformation27") IS
'Checks the [1..1] mandatory field(s) (OriginalMessageIdentification, OriginalMessageNameIdentification) are present.';
-- Type: OriginalGroupInformation29 (10.1.11.7)
DROP TYPE IF EXISTS public."OriginalGroupInformation29" CASCADE;
CREATE TYPE public."OriginalGroupInformation29" AS (
    "OriginalMessageIdentification" public."Max35Text",
    "OriginalMessageNameIdentification" public."Max35Text",
    "OriginalCreationDateTime" public."ISODateTime"
);
ALTER TYPE public."OriginalGroupInformation29" OWNER TO postgres;
COMMENT ON TYPE public."OriginalGroupInformation29" IS
'Definition: Unique and unambiguous identifier of the group of transactions as assigned by the original instructing party.

OriginalMessageIdentification: [1..1] Point to point reference assigned by the original instructing party to unambiguously identify the original message.
OriginalMessageNameIdentification: [1..1] Specifies the original message name identifier to which the message refers, e.g. pacs.003.001.01 or MT103.
OriginalCreationDateTime: [0..1] Original date and time at which the message was created.';
DROP FUNCTION IF EXISTS public.validate_original_group_information29(public."OriginalGroupInformation29");
CREATE OR REPLACE FUNCTION public.validate_original_group_information29(
    val public."OriginalGroupInformation29")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN (val."OriginalMessageIdentification" IS NOT NULL)
        AND (val."OriginalMessageNameIdentification" IS NOT NULL);
END;
$BODY$;
ALTER FUNCTION public.validate_original_group_information29(public."OriginalGroupInformation29")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_original_group_information29(public."OriginalGroupInformation29") IS
'Checks the [1..1] mandatory field(s) (OriginalMessageIdentification, OriginalMessageNameIdentification) are present.';
-- Type: OriginalBusinessQuery1 (10.1.11.8)
DROP TYPE IF EXISTS public."OriginalBusinessQuery1" CASCADE;
CREATE TYPE public."OriginalBusinessQuery1" AS (
    "MessageIdentification" public."Max35Text",
    "MessageNameIdentification" public."Max35Text",
    "CreationDateTime" public."ISODateTime"
);
ALTER TYPE public."OriginalBusinessQuery1" OWNER TO postgres;
COMMENT ON TYPE public."OriginalBusinessQuery1" IS
'Definition: Unique identification, as assigned by the original requestor, to unambiguously identify the business query message.

MessageIdentification: [1..1] Point to point reference, as assigned by the original initiating party, to unambiguously identify the original query message.
MessageNameIdentification: [0..1] Specifies the query message name identifier to which the message refers.
CreationDateTime: [0..1] Date and time at which the message was created.';
DROP FUNCTION IF EXISTS public.validate_original_business_query1(public."OriginalBusinessQuery1");
CREATE OR REPLACE FUNCTION public.validate_original_business_query1(
    val public."OriginalBusinessQuery1")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN (val."MessageIdentification" IS NOT NULL);
END;
$BODY$;
ALTER FUNCTION public.validate_original_business_query1(public."OriginalBusinessQuery1")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_original_business_query1(public."OriginalBusinessQuery1") IS
'Checks the [1..1] mandatory field(s) (MessageIdentification) are present.';
-- Type: Authorisation1Choice (10.1.11.2)
DROP TYPE IF EXISTS public."Authorisation1Choice" CASCADE;
CREATE TYPE public."Authorisation1Choice" AS (
    "Code" public."Authorisation1Code",
    "Proprietary" public."Max128Text"
);
ALTER TYPE public."Authorisation1Choice" OWNER TO postgres;
COMMENT ON TYPE public."Authorisation1Choice" IS
'Definition: Provides the details on the user identification or any user key that allows to check if the initiating party is allowed to issue the transaction.

{Or}/{Or} choice -- exactly one branch must be set:
Code: Specifies the authorisation, in a coded form (AUTH/FDET/FSUM/ILEV).
Proprietary: Specifies the authorisation, in a free text form.';
DROP FUNCTION IF EXISTS public.validate_authorisation1_choice(public."Authorisation1Choice");
CREATE OR REPLACE FUNCTION public.validate_authorisation1_choice(
    val public."Authorisation1Choice")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN ((val."Code" IS NOT NULL)::int + (val."Proprietary" IS NOT NULL)::int) = 1;
END;
$BODY$;
ALTER FUNCTION public.validate_authorisation1_choice(public."Authorisation1Choice")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_authorisation1_choice(public."Authorisation1Choice") IS
'Checks the {Or}/{Or} choice: exactly one of Code, Proprietary is set. Composite-typed branches use num_nonnulls() over their own fields rather than a plain IS NOT NULL -- see branch_populated_expr in the generator for why.';
-- Type: SupplementaryData1 (10.1.11.3)
DROP TYPE IF EXISTS public."SupplementaryData1" CASCADE;
CREATE TYPE public."SupplementaryData1" AS (
    "PlaceAndName" public."Max350Text",
    "Envelope" text
);
ALTER TYPE public."SupplementaryData1" OWNER TO postgres;
COMMENT ON TYPE public."SupplementaryData1" IS
'Definition: Additional information that can not be captured in the structured fields and/or any other specific block.

PlaceAndName: [0..1] Unambiguous reference to the location where the supplementary data must be inserted in the message instance (an XPath, for XML).
Envelope: [1..1] Technical element wrapping the supplementary data. Type is "(External Schema)" in the MDR -- arbitrary ISO-20022-compliant XML content, not a fixed structure, so modeled as text/xml rather than a typed column. Constraint - SupplementaryDataRule: this component may not be used without explicit SEG approval and RA submission of the structure(s) used in this element -- a governance rule, not something a CHECK can enforce.';
DROP FUNCTION IF EXISTS public.validate_supplementary_data1(public."SupplementaryData1");
CREATE OR REPLACE FUNCTION public.validate_supplementary_data1(
    val public."SupplementaryData1")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN (val."Envelope" IS NOT NULL);
END;
$BODY$;
ALTER FUNCTION public.validate_supplementary_data1(public."SupplementaryData1")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_supplementary_data1(public."SupplementaryData1") IS
'Checks the [1..1] mandatory field(s) (Envelope) are present.';
-- Type: Purpose2Choice (10.1.11.4)
DROP TYPE IF EXISTS public."Purpose2Choice" CASCADE;
CREATE TYPE public."Purpose2Choice" AS (
    "Code" public."ExternalPurpose1Code",
    "Proprietary" public."Max35Text"
);
ALTER TYPE public."Purpose2Choice" OWNER TO postgres;
COMMENT ON TYPE public."Purpose2Choice" IS
'Definition: Specifies the underlying reason for the payment transaction.

Usage: Purpose is used by the end-customers to provide information concerning the nature of the payment; not used for processing by any agent in the payment chain.

{Or}/{Or} choice -- exactly one branch must be set:
Code: Underlying reason for the payment transaction, as published in an external purpose code list.
Proprietary: Purpose, in a proprietary form.';
DROP FUNCTION IF EXISTS public.validate_purpose2_choice(public."Purpose2Choice");
CREATE OR REPLACE FUNCTION public.validate_purpose2_choice(
    val public."Purpose2Choice")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN ((val."Code" IS NOT NULL)::int + (val."Proprietary" IS NOT NULL)::int) = 1;
END;
$BODY$;
ALTER FUNCTION public.validate_purpose2_choice(public."Purpose2Choice")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_purpose2_choice(public."Purpose2Choice") IS
'Checks the {Or}/{Or} choice: exactly one of Code, Proprietary is set. Composite-typed branches use num_nonnulls() over their own fields rather than a plain IS NOT NULL -- see branch_populated_expr in the generator for why.';
-- Type: NumberOfTransactionsPerStatus5 (10.1.11.5)
DROP TYPE IF EXISTS public."NumberOfTransactionsPerStatus5" CASCADE;
CREATE TYPE public."NumberOfTransactionsPerStatus5" AS (
    "DetailedNumberOfTransactions" public."Max15NumericText",
    "DetailedStatus" public."ExternalPaymentTransactionStatus1Code",
    "DetailedControlSum" public."DecimalNumber"
);
ALTER TYPE public."NumberOfTransactionsPerStatus5" OWNER TO postgres;
COMMENT ON TYPE public."NumberOfTransactionsPerStatus5" IS
'Definition: Set of elements used to provide detailed information on the number of transactions that are reported with a specific transaction status.

DetailedNumberOfTransactions: [1..1] Number of individual transactions contained in the message, detailed per status.
DetailedStatus: [1..1] Common transaction status for all individual transactions reported.
DetailedControlSum: [0..1] Total of all individual amounts included in the message, irrespective of currencies, detailed per status.';
DROP FUNCTION IF EXISTS public.validate_number_of_transactions_per_status5(public."NumberOfTransactionsPerStatus5");
CREATE OR REPLACE FUNCTION public.validate_number_of_transactions_per_status5(
    val public."NumberOfTransactionsPerStatus5")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN (val."DetailedNumberOfTransactions" IS NOT NULL)
        AND (val."DetailedStatus" IS NOT NULL);
END;
$BODY$;
ALTER FUNCTION public.validate_number_of_transactions_per_status5(public."NumberOfTransactionsPerStatus5")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_number_of_transactions_per_status5(public."NumberOfTransactionsPerStatus5") IS
'Checks the [1..1] mandatory field(s) (DetailedNumberOfTransactions, DetailedStatus) are present.';
-- Type: RemittanceInformation2 (10.1.11.6)
DROP TYPE IF EXISTS public."RemittanceInformation2" CASCADE;
CREATE TYPE public."RemittanceInformation2" AS (
    "Unstructured" public."Max140Text"[]
);
ALTER TYPE public."RemittanceInformation2" OWNER TO postgres;
COMMENT ON TYPE public."RemittanceInformation2" IS
'Definition: Information supplied to enable the matching of an entry with the items that the transfer is intended to settle.

Unstructured: [0..*] Information supplied to enable matching, e.g. commercial invoices in an accounts receivable system, in unstructured form. Modeled as an array (genuinely unbounded -- no upper limit given in the MDR, unlike PostalAddress27.AddressLine which caps at 7).';
-- Type: SettlementTimeRequest2 (10.1.13.1)
DROP TYPE IF EXISTS public."SettlementTimeRequest2" CASCADE;
CREATE TYPE public."SettlementTimeRequest2" AS (
    "CLSTime" public."ISOTime",
    "TillTime" public."ISOTime",
    "FromTime" public."ISOTime",
    "RejectTime" public."ISOTime"
);
ALTER TYPE public."SettlementTimeRequest2" OWNER TO postgres;
COMMENT ON TYPE public."SettlementTimeRequest2" IS
'Definition: Provides information on the requested settlement time(s) of the payment instruction.

CLSTime: [0..1] Time by which money must be credited, with confirmation, to the CLS Bank account at the central bank. Usage: expressed in CET.
TillTime: [0..1] Time until when the payment may be settled.
FromTime: [0..1] Time as from when the payment may be settled.
RejectTime: [0..1] Time by when the payment must be settled to avoid rejection.

All four fields are optional per the MDR -- no validate_ function needed (nothing to check).';
-- Type: InstructionForCreditorAgent3 (10.1.13.2)
DROP TYPE IF EXISTS public."InstructionForCreditorAgent3" CASCADE;
CREATE TYPE public."InstructionForCreditorAgent3" AS (
    "Code" public."ExternalCreditorAgentInstruction1Code",
    "InstructionInformation" public."Max140Text"
);
ALTER TYPE public."InstructionForCreditorAgent3" OWNER TO postgres;
COMMENT ON TYPE public."InstructionForCreditorAgent3" IS
'Definition: Further information related to the processing of the payment instruction that may need to be acted upon by the creditor agent.

Code: [0..1] Coded information for the creditor agent.
InstructionInformation: [0..1] Further free-text information complementing the coded instruction.

Both fields optional -- no validate_ function needed.';
-- Type: ClearingSystemIdentification2Choice (10.1.19.1)
DROP TYPE IF EXISTS public."ClearingSystemIdentification2Choice" CASCADE;
CREATE TYPE public."ClearingSystemIdentification2Choice" AS (
    "Code" public."ExternalClearingSystemIdentification1Code",
    "Proprietary" public."Max35Text"
);
ALTER TYPE public."ClearingSystemIdentification2Choice" OWNER TO postgres;
COMMENT ON TYPE public."ClearingSystemIdentification2Choice" IS
'Definition: Choice of a clearing system identifier.

{Or}/{Or} choice -- exactly one branch must be set:
Code: Identification of a clearing system, in coded form as published in an external list.
Proprietary: Identification code for a clearing system not yet identified in the list of clearing systems.';
DROP FUNCTION IF EXISTS public.validate_clearing_system_identification2_choice(public."ClearingSystemIdentification2Choice");
CREATE OR REPLACE FUNCTION public.validate_clearing_system_identification2_choice(
    val public."ClearingSystemIdentification2Choice")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN ((val."Code" IS NOT NULL)::int + (val."Proprietary" IS NOT NULL)::int) = 1;
END;
$BODY$;
ALTER FUNCTION public.validate_clearing_system_identification2_choice(public."ClearingSystemIdentification2Choice")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_clearing_system_identification2_choice(public."ClearingSystemIdentification2Choice") IS
'Checks the {Or}/{Or} choice: exactly one of Code, Proprietary is set. Composite-typed branches use num_nonnulls() over their own fields rather than a plain IS NOT NULL -- see branch_populated_expr in the generator for why.';
-- Type: TaxAuthorisation1 (inline sub-type of TaxParty2.Authorisation, 10.1.20.1.4)
DROP TYPE IF EXISTS public."TaxAuthorisation1" CASCADE;
CREATE TYPE public."TaxAuthorisation1" AS (
    "Title" public."Max35Text",
    "Name" public."Max140Text"
);
ALTER TYPE public."TaxAuthorisation1" OWNER TO postgres;
COMMENT ON TYPE public."TaxAuthorisation1" IS
'Definition: Details of the authorised tax paying party.

Title: [0..1] Title or position of debtor or the debtors authorised representative.
Name: [0..1] Name of debtor or the debtors authorised representative.

Both fields optional -- no validate_ function needed. Named "TaxAuthorisation1" per the MDRs own in-text reference ("contains the following TaxAuthorisation1 elements") though it has no top-level heading.';
-- Type: TaxParty2 (10.1.20.1)
DROP TYPE IF EXISTS public."TaxParty2" CASCADE;
CREATE TYPE public."TaxParty2" AS (
    "TaxIdentification" public."Max35Text",
    "RegistrationIdentification" public."Max35Text",
    "TaxType" public."Max35Text",
    "Authorisation" public."TaxAuthorisation1"
);
ALTER TYPE public."TaxParty2" OWNER TO postgres;
COMMENT ON TYPE public."TaxParty2" IS
'Definition: Details about the entity involved in the tax paid or to be paid.

TaxIdentification: [0..1] Tax identification number of the debtor.
RegistrationIdentification: [0..1] Unique identification, as assigned by an organisation, to unambiguously identify a party.
TaxType: [0..1] Type of tax payer.
Authorisation: [0..1] Details of the authorised tax paying party.

All fields optional -- no validate_ function needed.';
-- Type: TaxParty1 (10.1.20.2)
DROP TYPE IF EXISTS public."TaxParty1" CASCADE;
CREATE TYPE public."TaxParty1" AS (
    "TaxIdentification" public."Max35Text",
    "RegistrationIdentification" public."Max35Text",
    "TaxType" public."Max35Text"
);
ALTER TYPE public."TaxParty1" OWNER TO postgres;
COMMENT ON TYPE public."TaxParty1" IS
'Definition: Details about the entity involved in the tax paid or to be paid.

TaxIdentification: [0..1] Tax identification number of the creditor.
RegistrationIdentification: [0..1] Unique identification, as assigned by an organisation.
TaxType: [0..1] Type of tax payer.

All fields optional -- no validate_ function needed.';
-- Type: MandateClassification1Choice (10.1.10.1)
DROP TYPE IF EXISTS public."MandateClassification1Choice" CASCADE;
CREATE TYPE public."MandateClassification1Choice" AS (
    "Code" public."MandateClassification1Code",
    "Proprietary" public."Max35Text"
);
ALTER TYPE public."MandateClassification1Choice" OWNER TO postgres;
COMMENT ON TYPE public."MandateClassification1Choice" IS
'Definition: Specifies the high level purpose of the instruction based on a set of pre-defined categories.

Usage: Used by the initiating party to provide processing information; likely to trigger special processing by agents in the payment chain.

{Or}/{Or} choice -- exactly one branch must be set:
Code: Category purpose (FIXE/USGB/VARI).
Proprietary: Category purpose, in a proprietary form.';
DROP FUNCTION IF EXISTS public.validate_mandate_classification1_choice(public."MandateClassification1Choice");
CREATE OR REPLACE FUNCTION public.validate_mandate_classification1_choice(
    val public."MandateClassification1Choice")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN ((val."Code" IS NOT NULL)::int + (val."Proprietary" IS NOT NULL)::int) = 1;
END;
$BODY$;
ALTER FUNCTION public.validate_mandate_classification1_choice(public."MandateClassification1Choice")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_mandate_classification1_choice(public."MandateClassification1Choice") IS
'Checks the {Or}/{Or} choice: exactly one of Code, Proprietary is set. Composite-typed branches use num_nonnulls() over their own fields rather than a plain IS NOT NULL -- see branch_populated_expr in the generator for why.';
-- ---------------------------------------------------------------------
-- PART 2 -- PaymentIdentification13 (10.1.9.2): inclusive-or business rule
-- ---------------------------------------------------------------------
-- Type: PaymentIdentification13 (10.1.9.2)
DROP TYPE IF EXISTS public."PaymentIdentification13" CASCADE;
CREATE TYPE public."PaymentIdentification13" AS (
    "InstructionIdentification" public."Max35Text",
    "EndToEndIdentification" public."Max35Text",
    "TransactionIdentification" public."Max35Text",
    "UETR" public."UUIDv4Identifier",
    "ClearingSystemReference" public."Max35Text"
);
ALTER TYPE public."PaymentIdentification13" OWNER TO postgres;
COMMENT ON TYPE public."PaymentIdentification13" IS
'Definition: Provides further means of referencing a payment transaction.

InstructionIdentification: [0..1] Unique ID assigned by an instructing party for an instructed party to unambiguously identify the instruction.
EndToEndIdentification: [1..1] Unique ID assigned by the initiating party, passed on unchanged throughout the entire end-to-end chain.
TransactionIdentification: [0..1] Unique ID assigned by the first instructing agent, passed on unchanged throughout the entire interbank chain.
UETR: [0..1] Universally unique identifier providing an end-to-end reference of a payment transaction.
ClearingSystemReference: [0..1] Unique reference, as assigned by a clearing system.

Constraint - TransactionIdentificationPresenceRule: TransactionIdentification or UETR must be present (both may be present) -- an inclusive-or, not the exactly-one {Or}/{Or} pattern used elsewhere in this library.';
DROP FUNCTION IF EXISTS public.validate_payment_identification13(public."PaymentIdentification13");
CREATE OR REPLACE FUNCTION public.validate_payment_identification13(
    val public."PaymentIdentification13")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN val."EndToEndIdentification" IS NOT NULL
        AND (val."TransactionIdentification" IS NOT NULL OR val."UETR" IS NOT NULL);
END;
$BODY$;
ALTER FUNCTION public.validate_payment_identification13(public."PaymentIdentification13")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_payment_identification13(public."PaymentIdentification13") IS
'Checks EndToEndIdentification (the [1..1] mandatory field) is present, AND the TransactionIdentificationPresenceRule: at least one of TransactionIdentification/UETR is present (inclusive-or -- both may be set, unlike an exclusive {Or}/{Or} choice).';
-- ---------------------------------------------------------------------
-- PART 3 -- Reusable Code/Proprietary Choice sub-components
-- Referenced from Mandate (10.1.10) and Payment Type (10.1.14)
-- ---------------------------------------------------------------------
-- Type: ServiceLevel8Choice (inline, e.g. 10.1.10.2.1 / 10.1.14.1.3)
DROP TYPE IF EXISTS public."ServiceLevel8Choice" CASCADE;
CREATE TYPE public."ServiceLevel8Choice" AS (
    "Code" public."ExternalServiceLevel1Code",
    "Proprietary" public."Max35Text"
);
ALTER TYPE public."ServiceLevel8Choice" OWNER TO postgres;
COMMENT ON TYPE public."ServiceLevel8Choice" IS
'Definition: Agreement under which or rules under which the transaction should be processed.

{Or}/{Or} choice -- exactly one branch must be set:
Code: Specifies a pre-agreed service or level of service between the parties, as published in an external service level code list.
Proprietary: Specifies a pre-agreed service or level of service between the parties, as a proprietary code.';
DROP FUNCTION IF EXISTS public.validate_service_level8_choice(public."ServiceLevel8Choice");
CREATE OR REPLACE FUNCTION public.validate_service_level8_choice(
    val public."ServiceLevel8Choice")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN ((val."Code" IS NOT NULL)::int + (val."Proprietary" IS NOT NULL)::int) = 1;
END;
$BODY$;
ALTER FUNCTION public.validate_service_level8_choice(public."ServiceLevel8Choice")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_service_level8_choice(public."ServiceLevel8Choice") IS
'Checks the {Or}/{Or} choice: exactly one of Code, Proprietary is set. Composite-typed branches use num_nonnulls() over their own fields rather than a plain IS NOT NULL -- see branch_populated_expr in the generator for why.';
-- Type: LocalInstrument2Choice (inline, e.g. 10.1.10.2.2 / 10.1.14.1.4)
DROP TYPE IF EXISTS public."LocalInstrument2Choice" CASCADE;
CREATE TYPE public."LocalInstrument2Choice" AS (
    "Code" public."ExternalLocalInstrument1Code",
    "Proprietary" public."Max35Text"
);
ALTER TYPE public."LocalInstrument2Choice" OWNER TO postgres;
COMMENT ON TYPE public."LocalInstrument2Choice" IS
'Definition: User community specific instrument.

Usage: Used to specify a local instrument, local clearing option and/or further qualify the service or service level.

{Or}/{Or} choice -- exactly one branch must be set:
Code: Specifies the local instrument, as published in an external local instrument code list.
Proprietary: Specifies the local instrument, as a proprietary code.';
DROP FUNCTION IF EXISTS public.validate_local_instrument2_choice(public."LocalInstrument2Choice");
CREATE OR REPLACE FUNCTION public.validate_local_instrument2_choice(
    val public."LocalInstrument2Choice")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN ((val."Code" IS NOT NULL)::int + (val."Proprietary" IS NOT NULL)::int) = 1;
END;
$BODY$;
ALTER FUNCTION public.validate_local_instrument2_choice(public."LocalInstrument2Choice")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_local_instrument2_choice(public."LocalInstrument2Choice") IS
'Checks the {Or}/{Or} choice: exactly one of Code, Proprietary is set. Composite-typed branches use num_nonnulls() over their own fields rather than a plain IS NOT NULL -- see branch_populated_expr in the generator for why.';
-- Type: CategoryPurpose1Choice (inline, e.g. 10.1.10.2.3 / 10.1.14.1.5)
DROP TYPE IF EXISTS public."CategoryPurpose1Choice" CASCADE;
CREATE TYPE public."CategoryPurpose1Choice" AS (
    "Code" public."ExternalCategoryPurpose1Code",
    "Proprietary" public."Max35Text"
);
ALTER TYPE public."CategoryPurpose1Choice" OWNER TO postgres;
COMMENT ON TYPE public."CategoryPurpose1Choice" IS
'Definition: Specifies the high level purpose of the mandate/instruction based on a set of pre-defined categories.

{Or}/{Or} choice -- exactly one branch must be set:
Code: Category purpose, as published in an external category purpose code list.
Proprietary: Category purpose, in a proprietary form.';
DROP FUNCTION IF EXISTS public.validate_category_purpose1_choice(public."CategoryPurpose1Choice");
CREATE OR REPLACE FUNCTION public.validate_category_purpose1_choice(
    val public."CategoryPurpose1Choice")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN ((val."Code" IS NOT NULL)::int + (val."Proprietary" IS NOT NULL)::int) = 1;
END;
$BODY$;
ALTER FUNCTION public.validate_category_purpose1_choice(public."CategoryPurpose1Choice")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_category_purpose1_choice(public."CategoryPurpose1Choice") IS
'Checks the {Or}/{Or} choice: exactly one of Code, Proprietary is set. Composite-typed branches use num_nonnulls() over their own fields rather than a plain IS NOT NULL -- see branch_populated_expr in the generator for why.';
-- ---------------------------------------------------------------------
-- PART 4 -- 10.1.8 Frequency
-- ---------------------------------------------------------------------
-- Type: FrequencyPeriod1 (inline, 10.1.8.1.2)
DROP TYPE IF EXISTS public."FrequencyPeriod1" CASCADE;
CREATE TYPE public."FrequencyPeriod1" AS (
    "Type" public."Frequency6Code",
    "CountPerPeriod" public."DecimalNumber"
);
ALTER TYPE public."FrequencyPeriod1" OWNER TO postgres;
COMMENT ON TYPE public."FrequencyPeriod1" IS
'Definition: Specifies a frequency in terms of a count per period within a specified period type.

Type: [1..1] Period for which the number of instructions are to be created and processed.
CountPerPeriod: [1..1] Number of instructions to be created and processed during the specified period.';
DROP FUNCTION IF EXISTS public.validate_frequency_period1(public."FrequencyPeriod1");
CREATE OR REPLACE FUNCTION public.validate_frequency_period1(
    val public."FrequencyPeriod1")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN (val."Type" IS NOT NULL)
        AND (val."CountPerPeriod" IS NOT NULL);
END;
$BODY$;
ALTER FUNCTION public.validate_frequency_period1(public."FrequencyPeriod1")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_frequency_period1(public."FrequencyPeriod1") IS
'Checks the [1..1] mandatory field(s) (Type, CountPerPeriod) are present.';
-- Type: FrequencyAndMoment1 (inline, 10.1.8.1.3)
DROP TYPE IF EXISTS public."FrequencyAndMoment1" CASCADE;
CREATE TYPE public."FrequencyAndMoment1" AS (
    "Type" public."Frequency6Code",
    "PointInTime" public."Exact2NumericText"
);
ALTER TYPE public."FrequencyAndMoment1" OWNER TO postgres;
COMMENT ON TYPE public."FrequencyAndMoment1" IS
'Definition: Specifies a frequency in terms of an exact point in time or moment within a specified period type.

Type: [1..1] Period for which the number of instructions are to be created and processed.
PointInTime: [1..1] Further information on the exact point in time the event should take place.';
DROP FUNCTION IF EXISTS public.validate_frequency_and_moment1(public."FrequencyAndMoment1");
CREATE OR REPLACE FUNCTION public.validate_frequency_and_moment1(
    val public."FrequencyAndMoment1")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN (val."Type" IS NOT NULL)
        AND (val."PointInTime" IS NOT NULL);
END;
$BODY$;
ALTER FUNCTION public.validate_frequency_and_moment1(public."FrequencyAndMoment1")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_frequency_and_moment1(public."FrequencyAndMoment1") IS
'Checks the [1..1] mandatory field(s) (Type, PointInTime) are present.';
-- Type: Frequency36Choice (10.1.8.1)
DROP TYPE IF EXISTS public."Frequency36Choice" CASCADE;
CREATE TYPE public."Frequency36Choice" AS (
    "Type" public."Frequency6Code",
    "Period" public."FrequencyPeriod1",
    "PointInTime" public."FrequencyAndMoment1"
);
ALTER TYPE public."Frequency36Choice" OWNER TO postgres;
COMMENT ON TYPE public."Frequency36Choice" IS
'Definition: Choice of format for a frequency, for example, the frequency of payment.

{Or}/{Or} choice -- exactly one branch must be set:
Type: Specifies a frequency in terms of a specified period type.
Period: Specifies a frequency in terms of a count per period within a specified period type.
PointInTime: Specifies a frequency in terms of an exact point in time or moment within a specified period type.';
DROP FUNCTION IF EXISTS public.validate_frequency36_choice(public."Frequency36Choice");
CREATE OR REPLACE FUNCTION public.validate_frequency36_choice(
    val public."Frequency36Choice")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN ((val."Type" IS NOT NULL)::int + (num_nonnulls((val."Period")."Type", (val."Period")."CountPerPeriod") > 0)::int + (num_nonnulls((val."PointInTime")."Type", (val."PointInTime")."PointInTime") > 0)::int) = 1;
END;
$BODY$;
ALTER FUNCTION public.validate_frequency36_choice(public."Frequency36Choice")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_frequency36_choice(public."Frequency36Choice") IS
'Checks the {Or}/{Or} choice: exactly one of Type, Period, PointInTime is set. Composite-typed branches use num_nonnulls() over their own fields rather than a plain IS NOT NULL -- see branch_populated_expr in the generator for why.';
-- ---------------------------------------------------------------------
-- PART 5 -- MandateTypeInformation2 (10.1.10.2)
-- ---------------------------------------------------------------------
-- Type: MandateTypeInformation2 (10.1.10.2)
DROP TYPE IF EXISTS public."MandateTypeInformation2" CASCADE;
CREATE TYPE public."MandateTypeInformation2" AS (
    "ServiceLevel" public."ServiceLevel8Choice",
    "LocalInstrument" public."LocalInstrument2Choice",
    "CategoryPurpose" public."CategoryPurpose1Choice",
    "Classification" public."MandateClassification1Choice"
);
ALTER TYPE public."MandateTypeInformation2" OWNER TO postgres;
COMMENT ON TYPE public."MandateTypeInformation2" IS
'Definition: Set of elements used to further detail the information related to the type of payment.

ServiceLevel: [0..1] Agreement/rules under which the mandate resides.
LocalInstrument: [0..1] User community specific instrument.
CategoryPurpose: [0..1] High level purpose of the mandate.
Classification: [0..1] Type of direct debit instruction (reuses MandateClassification1Choice).

All four fields are independently optional (not a {Or}/{Or} choice among them) -- no validate_ function needed at this level; each fields own composite type carries its own exactly-one-branch validation.';
-- ---------------------------------------------------------------------
-- PART 6 -- 10.1.14 Payment Type
-- ---------------------------------------------------------------------
-- Type: PaymentTypeInformation28 (10.1.14.1)
DROP TYPE IF EXISTS public."PaymentTypeInformation28" CASCADE;
CREATE TYPE public."PaymentTypeInformation28" AS (
    "InstructionPriority" public."Priority2Code",
    "ClearingChannel" public."ClearingChannel2Code",
    "ServiceLevel" public."ServiceLevel8Choice"[],
    "LocalInstrument" public."LocalInstrument2Choice",
    "CategoryPurpose" public."CategoryPurpose1Choice"
);
ALTER TYPE public."PaymentTypeInformation28" OWNER TO postgres;
COMMENT ON TYPE public."PaymentTypeInformation28" IS
'Definition: Provides further details of the type of payment.

InstructionPriority: [0..1] Urgency/importance the instructing party wants applied to processing.
ClearingChannel: [0..1] Clearing channel to be used to process the payment instruction.
ServiceLevel: [0..*] Agreement/rules under which the transaction should be processed -- repeatable, modeled as an array of ServiceLevel8Choice (unbounded, no max given).
LocalInstrument: [0..1] User community specific instrument.
CategoryPurpose: [0..1] High level purpose of the instruction.

All fields optional -- no validate_ function needed at this level.';
-- Type: PaymentTypeInformation27 (10.1.14.2)
DROP TYPE IF EXISTS public."PaymentTypeInformation27" CASCADE;
CREATE TYPE public."PaymentTypeInformation27" AS (
    "InstructionPriority" public."Priority2Code",
    "ClearingChannel" public."ClearingChannel2Code",
    "ServiceLevel" public."ServiceLevel8Choice"[],
    "LocalInstrument" public."LocalInstrument2Choice",
    "SequenceType" public."SequenceType3Code",
    "CategoryPurpose" public."CategoryPurpose1Choice"
);
ALTER TYPE public."PaymentTypeInformation27" OWNER TO postgres;
COMMENT ON TYPE public."PaymentTypeInformation27" IS
'Definition: Provides further details of the type of payment.

Same as PaymentTypeInformation28, plus:
SequenceType: [0..1] Identifies the direct debit sequence (first/recurrent/final/one-off/represented).

All fields optional -- no validate_ function needed at this level.';
-- ---------------------------------------------------------------------
-- PART 7 -- 10.1.3 Amount
-- ---------------------------------------------------------------------
-- Type: EquivalentAmount2 (inline, 10.1.3.1.2)
DROP TYPE IF EXISTS public."EquivalentAmount2" CASCADE;
CREATE TYPE public."EquivalentAmount2" AS (
    "Amount" public."ActiveOrHistoricCurrencyAndAmount",
    "CurrencyOfTransfer" public."ActiveOrHistoricCurrencyCode"
);
ALTER TYPE public."EquivalentAmount2" OWNER TO postgres;
COMMENT ON TYPE public."EquivalentAmount2" IS
'Definition: Amount of money to be moved between the debtor and creditor, expressed in the currency of the debtor''s account, and the currency in which the amount is to be moved.

Amount: [1..1] Amount of money to be moved between debtor and creditor, before deduction of charges, expressed in the currency of the debtor''s account, to be moved in a different currency. Usage: the first agent converts the equivalent amount into the amount to be moved.
CurrencyOfTransfer: [1..1] Currency of the to-be-transferred amount, different from the currency of the debtor''s account.';
DROP FUNCTION IF EXISTS public.validate_equivalent_amount2(public."EquivalentAmount2");
CREATE OR REPLACE FUNCTION public.validate_equivalent_amount2(
    val public."EquivalentAmount2")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN (num_nonnulls((val."Amount")."Amt", (val."Amount")."Ccy") > 0)
        AND (val."CurrencyOfTransfer" IS NOT NULL);
END;
$BODY$;
ALTER FUNCTION public.validate_equivalent_amount2(public."EquivalentAmount2")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_equivalent_amount2(public."EquivalentAmount2") IS
'Checks the [1..1] mandatory field(s) (Amount, CurrencyOfTransfer) are present.';
-- Type: AmountType4Choice (10.1.3.1)
DROP TYPE IF EXISTS public."AmountType4Choice" CASCADE;
CREATE TYPE public."AmountType4Choice" AS (
    "InstructedAmount" public."ActiveOrHistoricCurrencyAndAmount",
    "EquivalentAmount" public."EquivalentAmount2"
);
ALTER TYPE public."AmountType4Choice" OWNER TO postgres;
COMMENT ON TYPE public."AmountType4Choice" IS
'Definition: Specifies the amount of money to be moved between the debtor and creditor, before deduction of charges, expressed in the currency as ordered by the initiating party.

{Or}/{Or} choice -- exactly one branch must be set:
InstructedAmount: Amount of money to be moved between debtor and creditor, before deduction of charges, expressed in the currency as ordered by the initiating party. Usage: transported unchanged through the transaction chain.
EquivalentAmount: Amount of money to be moved, expressed in the currency of the debtor''s account and the currency in which the amount is to be moved.';
DROP FUNCTION IF EXISTS public.validate_amount_type4_choice(public."AmountType4Choice");
CREATE OR REPLACE FUNCTION public.validate_amount_type4_choice(
    val public."AmountType4Choice")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN ((num_nonnulls((val."InstructedAmount")."Amt", (val."InstructedAmount")."Ccy") > 0)::int + (num_nonnulls((val."EquivalentAmount")."Amount", (val."EquivalentAmount")."CurrencyOfTransfer") > 0)::int) = 1;
END;
$BODY$;
ALTER FUNCTION public.validate_amount_type4_choice(public."AmountType4Choice")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_amount_type4_choice(public."AmountType4Choice") IS
'Checks the {Or}/{Or} choice: exactly one of InstructedAmount, EquivalentAmount is set. Composite-typed branches use num_nonnulls() over their own fields rather than a plain IS NOT NULL -- see branch_populated_expr in the generator for why.';
