-- =====================================================================
-- ISO 20022 Message Definition Report - Part 2
-- Payments Clearing and Settlement - Maintenance 2024-2025 (Feb 2025)
-- Section 10.1 "Message Components" -- FILE 5 of 5: Remittance
--
-- Covers: RemittanceInformation22, StructuredRemittanceInformation18,
-- and their full 24-type dependency chain. This is the deepest and most
-- complex subsection in the component library (42 of 102 pages for just
-- 2 top-level types).
--
-- Depends on: 10.2 Message Datatypes, File 1 (DatePeriod2, TaxParty1,
-- TaxParty2), File 2 (PartyIdentification272, reused 4 times).
-- Load order: 10.2 -> File 1 -> File 2 -> File 3 -> File 4 -> File 5 (this file).
--
-- This completes Section 10.1 Message Components in full.
-- =====================================================================
-- ---------------------------------------------------------------------
-- PART 1 -- Referred Document reference chain
-- ---------------------------------------------------------------------
-- Type: DocumentType2Choice (inline, 10.1.18.2.1.1.1)
DROP TYPE IF EXISTS public."DocumentType2Choice" CASCADE;
CREATE TYPE public."DocumentType2Choice" AS (
    "Code" public."ExternalDocumentType1Code",
    "Proprietary" public."Max35Text"
);
ALTER TYPE public."DocumentType2Choice" OWNER TO postgres;
COMMENT ON TYPE public."DocumentType2Choice" IS
'Definition: Coded or proprietary format referred document type.

{Or}/{Or} choice -- exactly one branch must be set:
Code: Type of remittance document, as published in an external document type code set.
Proprietary: Type of remittance document, in a proprietary form.';
DROP FUNCTION IF EXISTS public.validate_document_type2_choice(public."DocumentType2Choice");
CREATE OR REPLACE FUNCTION public.validate_document_type2_choice(
    val public."DocumentType2Choice")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN ((val."Code" IS NOT NULL)::int + (val."Proprietary" IS NOT NULL)::int) = 1;
END;
$BODY$;
ALTER FUNCTION public.validate_document_type2_choice(public."DocumentType2Choice")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_document_type2_choice(public."DocumentType2Choice") IS
'Checks the {Or}/{Or} choice: exactly one of Code, Proprietary is set. Composite-typed branches use num_nonnulls() over their own fields rather than a plain IS NOT NULL.';
-- Type: DocumentType1 (10.1.18.2.1.1 (DocumentType1))
DROP TYPE IF EXISTS public."DocumentType1" CASCADE;
CREATE TYPE public."DocumentType1" AS (
    "CodeOrProprietary" public."DocumentType2Choice",
    "Issuer" public."Max35Text"
);
ALTER TYPE public."DocumentType1" OWNER TO postgres;
COMMENT ON TYPE public."DocumentType1" IS
'Definition: Specifies the type of referred document.

CodeOrProprietary: [1..1] Coded or proprietary format referred document type.
Issuer: [0..1] Identification of the issuer of the reference document type.';
DROP FUNCTION IF EXISTS public.validate_document_type1(public."DocumentType1");
CREATE OR REPLACE FUNCTION public.validate_document_type1(
    val public."DocumentType1")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN (num_nonnulls((val."CodeOrProprietary")."Code", (val."CodeOrProprietary")."Proprietary") > 0);
END;
$BODY$;
ALTER FUNCTION public.validate_document_type1(public."DocumentType1")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_document_type1(public."DocumentType1") IS
'Checks the [1..1] mandatory field(s) (CodeOrProprietary) are present.';
-- Type: DateType2Choice (inline, 10.1.18.2.1.3.1)
DROP TYPE IF EXISTS public."DateType2Choice" CASCADE;
CREATE TYPE public."DateType2Choice" AS (
    "Code" public."ExternalDateType1Code",
    "Proprietary" public."Max35Text"
);
ALTER TYPE public."DateType2Choice" OWNER TO postgres;
COMMENT ON TYPE public."DateType2Choice" IS
'Definition: Type of date associated with the referred document.

{Or}/{Or} choice -- exactly one branch must be set:
Code: Specifies the date type, as published in an external date type code set.
Proprietary: Specifies the date type, in a free-text form.';
DROP FUNCTION IF EXISTS public.validate_date_type2_choice(public."DateType2Choice");
CREATE OR REPLACE FUNCTION public.validate_date_type2_choice(
    val public."DateType2Choice")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN ((val."Code" IS NOT NULL)::int + (val."Proprietary" IS NOT NULL)::int) = 1;
END;
$BODY$;
ALTER FUNCTION public.validate_date_type2_choice(public."DateType2Choice")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_date_type2_choice(public."DateType2Choice") IS
'Checks the {Or}/{Or} choice: exactly one of Code, Proprietary is set. Composite-typed branches use num_nonnulls() over their own fields rather than a plain IS NOT NULL.';
-- Type: DateAndType1 (10.1.18.2.1.3 (DateAndType1))
DROP TYPE IF EXISTS public."DateAndType1" CASCADE;
CREATE TYPE public."DateAndType1" AS (
    "Type" public."DateType2Choice",
    "Date" public."ISODate"
);
ALTER TYPE public."DateAndType1" OWNER TO postgres;
COMMENT ON TYPE public."DateAndType1" IS
'Definition: Date and date type associated with the referred document.

Type: [1..1] Type of date associated with the referred document.
Date: [1..1] Date associated with the referred document.';
DROP FUNCTION IF EXISTS public.validate_date_and_type1(public."DateAndType1");
CREATE OR REPLACE FUNCTION public.validate_date_and_type1(
    val public."DateAndType1")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN (num_nonnulls((val."Type")."Code", (val."Type")."Proprietary") > 0) AND (val."Date" IS NOT NULL);
END;
$BODY$;
ALTER FUNCTION public.validate_date_and_type1(public."DateAndType1")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_date_and_type1(public."DateAndType1") IS
'Checks the [1..1] mandatory field(s) (Type, Date) are present.';
-- Type: DocumentLineType1Choice (inline, 10.1.18.2.1.4.1.1.1)
DROP TYPE IF EXISTS public."DocumentLineType1Choice" CASCADE;
CREATE TYPE public."DocumentLineType1Choice" AS (
    "Code" public."ExternalDocumentLineType1Code",
    "Proprietary" public."Max35Text"
);
ALTER TYPE public."DocumentLineType1Choice" OWNER TO postgres;
COMMENT ON TYPE public."DocumentLineType1Choice" IS
'Definition: Provides the type details of the referred document line identification.

{Or}/{Or} choice -- exactly one branch must be set:
Code: Line identification type in a coded form.
Proprietary: Proprietary identification of the type of the remittance document.';
DROP FUNCTION IF EXISTS public.validate_document_line_type1_choice(public."DocumentLineType1Choice");
CREATE OR REPLACE FUNCTION public.validate_document_line_type1_choice(
    val public."DocumentLineType1Choice")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN ((val."Code" IS NOT NULL)::int + (val."Proprietary" IS NOT NULL)::int) = 1;
END;
$BODY$;
ALTER FUNCTION public.validate_document_line_type1_choice(public."DocumentLineType1Choice")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_document_line_type1_choice(public."DocumentLineType1Choice") IS
'Checks the {Or}/{Or} choice: exactly one of Code, Proprietary is set. Composite-typed branches use num_nonnulls() over their own fields rather than a plain IS NOT NULL.';
-- Type: DocumentLineType1 (10.1.18.2.1.4.1.1 (DocumentLineType1))
DROP TYPE IF EXISTS public."DocumentLineType1" CASCADE;
CREATE TYPE public."DocumentLineType1" AS (
    "CodeOrProprietary" public."DocumentLineType1Choice",
    "Issuer" public."Max35Text"
);
ALTER TYPE public."DocumentLineType1" OWNER TO postgres;
COMMENT ON TYPE public."DocumentLineType1" IS
'Definition: Specifies the type of referred document line identification.

CodeOrProprietary: [1..1] Provides the type details of the referred document line identification.
Issuer: [0..1] Identification of the issuer of the reference document line identification type.';
DROP FUNCTION IF EXISTS public.validate_document_line_type1(public."DocumentLineType1");
CREATE OR REPLACE FUNCTION public.validate_document_line_type1(
    val public."DocumentLineType1")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN (num_nonnulls((val."CodeOrProprietary")."Code", (val."CodeOrProprietary")."Proprietary") > 0);
END;
$BODY$;
ALTER FUNCTION public.validate_document_line_type1(public."DocumentLineType1")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_document_line_type1(public."DocumentLineType1") IS
'Checks the [1..1] mandatory field(s) (CodeOrProprietary) are present.';
-- Type: DocumentLineIdentification1 (10.1.18.2.1.4.1 (DocumentLineIdentification1))
DROP TYPE IF EXISTS public."DocumentLineIdentification1" CASCADE;
CREATE TYPE public."DocumentLineIdentification1" AS (
    "Type" public."DocumentLineType1",
    "Number" public."Max35Text",
    "RelatedDate" public."ISODate"
);
ALTER TYPE public."DocumentLineIdentification1" OWNER TO postgres;
COMMENT ON TYPE public."DocumentLineIdentification1" IS
'Definition: Provides identification of the document line.

Type: [0..1] Specifies the type of referred document line identification.
Number: [0..1] Identification of the type specified for the referred document line.
RelatedDate: [0..1] Date associated with the referred document line.';
-- Type: DocumentAmountType1Choice (inline, 10.1.18.2.1.4.3.1.1 / 10.1.18.2.2.1.1)
DROP TYPE IF EXISTS public."DocumentAmountType1Choice" CASCADE;
CREATE TYPE public."DocumentAmountType1Choice" AS (
    "Code" public."ExternalDocumentAmountType1Code",
    "Proprietary" public."Max35Text"
);
ALTER TYPE public."DocumentAmountType1Choice" OWNER TO postgres;
COMMENT ON TYPE public."DocumentAmountType1Choice" IS
'Definition: Defines the type of amount.

{Or}/{Or} choice -- exactly one branch must be set:
Code: Specifies the amount type, as published in an external referred amount code set.
Proprietary: Specifies the amount type, in a free-text form.';
DROP FUNCTION IF EXISTS public.validate_document_amount_type1_choice(public."DocumentAmountType1Choice");
CREATE OR REPLACE FUNCTION public.validate_document_amount_type1_choice(
    val public."DocumentAmountType1Choice")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN ((val."Code" IS NOT NULL)::int + (val."Proprietary" IS NOT NULL)::int) = 1;
END;
$BODY$;
ALTER FUNCTION public.validate_document_amount_type1_choice(public."DocumentAmountType1Choice")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_document_amount_type1_choice(public."DocumentAmountType1Choice") IS
'Checks the {Or}/{Or} choice: exactly one of Code, Proprietary is set. Composite-typed branches use num_nonnulls() over their own fields rather than a plain IS NOT NULL.';
-- Type: DocumentAmount1 (10.1.18.2.1.4.3.1 / 10.1.18.2.2.1 (DocumentAmount1))
DROP TYPE IF EXISTS public."DocumentAmount1" CASCADE;
CREATE TYPE public."DocumentAmount1" AS (
    "Type" public."DocumentAmountType1Choice",
    "Amount" public."ActiveOrHistoricCurrencyAndAmount"
);
ALTER TYPE public."DocumentAmount1" OWNER TO postgres;
COMMENT ON TYPE public."DocumentAmount1" IS
'Definition: Type and amount of money for the referred document.

Type: [1..1] Defines the type of amount.
Amount: [1..1] Amount of money for the referred document.';
DROP FUNCTION IF EXISTS public.validate_document_amount1(public."DocumentAmount1");
CREATE OR REPLACE FUNCTION public.validate_document_amount1(
    val public."DocumentAmount1")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN (num_nonnulls((val."Type")."Code", (val."Type")."Proprietary") > 0) AND (num_nonnulls((val."Amount")."Amt", (val."Amount")."Ccy") > 0);
END;
$BODY$;
ALTER FUNCTION public.validate_document_amount1(public."DocumentAmount1")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_document_amount1(public."DocumentAmount1") IS
'Checks the [1..1] mandatory field(s) (Type, Amount) are present.';
-- Type: DocumentAdjustment1 (10.1.18.2.1.4.3.2 / 10.1.18.2.2.2 (DocumentAdjustment1))
DROP TYPE IF EXISTS public."DocumentAdjustment1" CASCADE;
CREATE TYPE public."DocumentAdjustment1" AS (
    "Amount" public."ActiveOrHistoricCurrencyAndAmount",
    "CreditDebitIndicator" public."CreditDebitCode",
    "Reason" public."Max4Text",
    "AdditionalInformation" public."Max140Text"
);
ALTER TYPE public."DocumentAdjustment1" OWNER TO postgres;
COMMENT ON TYPE public."DocumentAdjustment1" IS
'Definition: Specifies detailed information on the amount and reason of the adjustment.

Amount: [1..1] Amount of money of the document adjustment.
CreditDebitIndicator: [0..1] Specifies whether the adjustment must be subtracted or added to the total amount.
Reason: [0..1] Specifies the reason for the adjustment.
AdditionalInformation: [0..1] Provides further details on the document adjustment.';
DROP FUNCTION IF EXISTS public.validate_document_adjustment1(public."DocumentAdjustment1");
CREATE OR REPLACE FUNCTION public.validate_document_adjustment1(
    val public."DocumentAdjustment1")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN (num_nonnulls((val."Amount")."Amt", (val."Amount")."Ccy") > 0);
END;
$BODY$;
ALTER FUNCTION public.validate_document_adjustment1(public."DocumentAdjustment1")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_document_adjustment1(public."DocumentAdjustment1") IS
'Checks the [1..1] mandatory field(s) (Amount) are present.';
-- Type: RemittanceAmount4 (10.1.18.2.1.4.3 / 10.1.18.2.2 (RemittanceAmount4))
DROP TYPE IF EXISTS public."RemittanceAmount4" CASCADE;
CREATE TYPE public."RemittanceAmount4" AS (
    "RemittanceAmountAndType" public."DocumentAmount1"[],
    "AdjustmentAmountAndReason" public."DocumentAdjustment1"[]
);
ALTER TYPE public."RemittanceAmount4" OWNER TO postgres;
COMMENT ON TYPE public."RemittanceAmount4" IS
'Definition: Provides details on the amounts of the document line / referred document.

RemittanceAmountAndType: [0..1] Type and amount of money for the referred document -- repeatable, unbounded.
AdjustmentAmountAndReason: [0..1] Specifies detailed information on the amount and reason of the adjustment -- repeatable, unbounded.

Constraint - RemittanceAmountAndTypeGuideline: if Type/Code is equal to CREN, DUPA or REMI for RemittanceAmountAndType, RemittanceAmountAndType must not be repeated. This is a data-dependent array-content rule (checking specific code VALUES inside array elements, not just cardinality) -- documented here rather than enforced by a validate_ function, consistent with this projects approach to governance/business rules that arent simple presence or bound checks (see SupplementaryDataRule in File 1).';
-- Type: DocumentLineInformation2 (10.1.18.2.1.4 (DocumentLineInformation2))
DROP TYPE IF EXISTS public."DocumentLineInformation2" CASCADE;
CREATE TYPE public."DocumentLineInformation2" AS (
    "Identification" public."DocumentLineIdentification1"[],
    "Description" public."Max2048Text",
    "Amount" public."RemittanceAmount4"
);
ALTER TYPE public."DocumentLineInformation2" OWNER TO postgres;
COMMENT ON TYPE public."DocumentLineInformation2" IS
'Definition: Set of elements used to provide the content of the referred document line.

Identification: [0..1] Provides identification of the document line -- repeatable, [1..*] (at least one required).
Description: [0..1] Description associated with the document line.
Amount: [0..1] Provides details on the amounts of the document line.

Identification is [1..*] (unlike most repeatable elements in this library, which are [0..*] or bounded [0..n]) -- at least one element is mandatory, checked by the validate_ function below.';
DROP FUNCTION IF EXISTS public.validate_document_line_information2(public."DocumentLineInformation2");
CREATE OR REPLACE FUNCTION public.validate_document_line_information2(
    val public."DocumentLineInformation2")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN (val."Identification" IS NOT NULL AND COALESCE(array_length(val."Identification", 1), 0) >= 1);
END;
$BODY$;
ALTER FUNCTION public.validate_document_line_information2(public."DocumentLineInformation2")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_document_line_information2(public."DocumentLineInformation2") IS
'Checks additional constraints.';
-- Type: ReferredDocumentInformation8 (10.1.18.2.1 (ReferredDocumentInformation8))
DROP TYPE IF EXISTS public."ReferredDocumentInformation8" CASCADE;
CREATE TYPE public."ReferredDocumentInformation8" AS (
    "Type" public."DocumentType1",
    "Number" public."Max35Text",
    "RelatedDate" public."DateAndType1",
    "LineDetails" public."DocumentLineInformation2"[]
);
ALTER TYPE public."ReferredDocumentInformation8" OWNER TO postgres;
COMMENT ON TYPE public."ReferredDocumentInformation8" IS
'Definition: Provides the identification and the content of the referred document.

Type: [0..1] Specifies the type of referred document.
Number: [0..1] Unique and unambiguous identification of the referred document.
RelatedDate: [0..1] Date and date type associated with the referred document.
LineDetails: [0..1] Set of elements used to provide the content of the referred document line -- repeatable, unbounded.';
-- ---------------------------------------------------------------------
-- PART 2 -- Creditor Reference Information
-- ---------------------------------------------------------------------
-- Type: CreditorReferenceType2Choice (inline, 10.1.18.2.3.1.1)
DROP TYPE IF EXISTS public."CreditorReferenceType2Choice" CASCADE;
CREATE TYPE public."CreditorReferenceType2Choice" AS (
    "Code" public."ExternalCreditorReferenceType1Code",
    "Proprietary" public."Max35Text"
);
ALTER TYPE public."CreditorReferenceType2Choice" OWNER TO postgres;
COMMENT ON TYPE public."CreditorReferenceType2Choice" IS
'Definition: Coded or proprietary format creditor reference type.

{Or}/{Or} choice -- exactly one branch must be set:
Code: Type of creditor reference, as published in an external creditor reference type code set.
Proprietary: Type of creditor reference, in a proprietary form.';
DROP FUNCTION IF EXISTS public.validate_creditor_reference_type2_choice(public."CreditorReferenceType2Choice");
CREATE OR REPLACE FUNCTION public.validate_creditor_reference_type2_choice(
    val public."CreditorReferenceType2Choice")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN ((val."Code" IS NOT NULL)::int + (val."Proprietary" IS NOT NULL)::int) = 1;
END;
$BODY$;
ALTER FUNCTION public.validate_creditor_reference_type2_choice(public."CreditorReferenceType2Choice")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_creditor_reference_type2_choice(public."CreditorReferenceType2Choice") IS
'Checks the {Or}/{Or} choice: exactly one of Code, Proprietary is set. Composite-typed branches use num_nonnulls() over their own fields rather than a plain IS NOT NULL.';
-- Type: CreditorReferenceType3 (10.1.18.2.3.1 (CreditorReferenceType3))
DROP TYPE IF EXISTS public."CreditorReferenceType3" CASCADE;
CREATE TYPE public."CreditorReferenceType3" AS (
    "CodeOrProprietary" public."CreditorReferenceType2Choice",
    "Issuer" public."Max35Text"
);
ALTER TYPE public."CreditorReferenceType3" OWNER TO postgres;
COMMENT ON TYPE public."CreditorReferenceType3" IS
'Definition: Specifies the type of creditor reference.

CodeOrProprietary: [1..1] Coded or proprietary format creditor reference type.
Issuer: [0..1] Entity that assigns the credit reference type.';
DROP FUNCTION IF EXISTS public.validate_creditor_reference_type3(public."CreditorReferenceType3");
CREATE OR REPLACE FUNCTION public.validate_creditor_reference_type3(
    val public."CreditorReferenceType3")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN (num_nonnulls((val."CodeOrProprietary")."Code", (val."CodeOrProprietary")."Proprietary") > 0);
END;
$BODY$;
ALTER FUNCTION public.validate_creditor_reference_type3(public."CreditorReferenceType3")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_creditor_reference_type3(public."CreditorReferenceType3") IS
'Checks the [1..1] mandatory field(s) (CodeOrProprietary) are present.';
-- Type: CreditorReferenceInformation3 (10.1.18.2.3 (CreditorReferenceInformation3))
DROP TYPE IF EXISTS public."CreditorReferenceInformation3" CASCADE;
CREATE TYPE public."CreditorReferenceInformation3" AS (
    "Type" public."CreditorReferenceType3",
    "Reference" public."Max35Text"
);
ALTER TYPE public."CreditorReferenceInformation3" OWNER TO postgres;
COMMENT ON TYPE public."CreditorReferenceInformation3" IS
'Definition: Reference information provided by the creditor to allow the identification of the underlying documents.

Type: [0..1] Specifies the type of creditor reference.
Reference: [0..1] Unique reference, as assigned by the creditor, to unambiguously refer to the payment transaction. Usage: if the business context requires a creditor reference or payment remit identification and only one identifier can be passed through the end-to-end chain, it should be quoted in the end-to-end transaction identification instead.';
-- ---------------------------------------------------------------------
-- PART 3 -- Tax Remittance
-- ---------------------------------------------------------------------
-- Type: TaxPeriod3 (10.1.18.2.6.11.7 / 10.1.18.2.6.11.8.4.1 (TaxPeriod3))
DROP TYPE IF EXISTS public."TaxPeriod3" CASCADE;
CREATE TYPE public."TaxPeriod3" AS (
    "Year" public."ISOYear",
    "Type" public."TaxRecordPeriod1Code",
    "FromToDate" public."DatePeriod2"
);
ALTER TYPE public."TaxPeriod3" OWNER TO postgres;
COMMENT ON TYPE public."TaxPeriod3" IS
'Definition: Set of elements used to provide details on the period of time related to the tax payment.

Year: [0..1] Year related to the tax payment.
Type: [0..1] Identification of the period related to the tax payment.
FromToDate: [0..1] Range of time between a start date and an end date for which the tax report is provided. Reuses DatePeriod2 (File 1).';
-- Type: TaxRecordDetails3 (10.1.18.2.6.11.8.4 (TaxRecordDetails3))
DROP TYPE IF EXISTS public."TaxRecordDetails3" CASCADE;
CREATE TYPE public."TaxRecordDetails3" AS (
    "Period" public."TaxPeriod3",
    "Amount" public."ActiveOrHistoricCurrencyAndAmount"
);
ALTER TYPE public."TaxRecordDetails3" OWNER TO postgres;
COMMENT ON TYPE public."TaxRecordDetails3" IS
'Definition: Set of elements used to provide details on the tax period and amount.

Period: [0..1] Set of elements used to provide details on the period of time related to the tax payment.
Amount: [1..1] Underlying tax amount related to the specified period.';
DROP FUNCTION IF EXISTS public.validate_tax_record_details3(public."TaxRecordDetails3");
CREATE OR REPLACE FUNCTION public.validate_tax_record_details3(
    val public."TaxRecordDetails3")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN (num_nonnulls((val."Amount")."Amt", (val."Amount")."Ccy") > 0);
END;
$BODY$;
ALTER FUNCTION public.validate_tax_record_details3(public."TaxRecordDetails3")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_tax_record_details3(public."TaxRecordDetails3") IS
'Checks the [1..1] mandatory field(s) (Amount) are present.';
-- Type: TaxAmount3 (10.1.18.2.6.11.8 (TaxAmount3))
DROP TYPE IF EXISTS public."TaxAmount3" CASCADE;
CREATE TYPE public."TaxAmount3" AS (
    "Rate" public."PercentageRate",
    "TaxableBaseAmount" public."ActiveOrHistoricCurrencyAndAmount",
    "TotalAmount" public."ActiveOrHistoricCurrencyAndAmount",
    "Details" public."TaxRecordDetails3"[]
);
ALTER TYPE public."TaxAmount3" OWNER TO postgres;
COMMENT ON TYPE public."TaxAmount3" IS
'Definition: Set of elements used to provide information on the amount of the tax record.

Rate: [0..1] Rate used to calculate the tax.
TaxableBaseAmount: [0..1] Amount of money on which the tax is based.
TotalAmount: [0..1] Total amount that is the result of the calculation of the tax.
Details: [0..1] Set of elements used to provide details on the tax period and amount -- repeatable, unbounded.';
-- Type: TaxRecord3 (10.1.18.2.6.11 (TaxRecord3))
DROP TYPE IF EXISTS public."TaxRecord3" CASCADE;
CREATE TYPE public."TaxRecord3" AS (
    "Type" public."Max35Text",
    "Category" public."Max35Text",
    "CategoryDetails" public."Max35Text",
    "DebtorStatus" public."Max35Text",
    "CertificateIdentification" public."Max35Text",
    "FormsCode" public."Max35Text",
    "Period" public."TaxPeriod3",
    "TaxAmount" public."TaxAmount3",
    "AdditionalInformation" public."Max140Text"
);
ALTER TYPE public."TaxRecord3" OWNER TO postgres;
COMMENT ON TYPE public."TaxRecord3" IS
'Definition: Record of tax details.

Type: [0..1] High level code to identify the type of tax details.
Category: [0..1] Specifies the tax code as published by the tax authority.
CategoryDetails: [0..1] Provides further details of the category tax code.
DebtorStatus: [0..1] Code provided by local authority to identify the status of the party that has drawn up the settlement document.
CertificateIdentification: [0..1] Identification number of the tax report as assigned by the taxing authority.
FormsCode: [0..1] Identifies, in a coded form, on which template the tax report is to be provided.
Period: [0..1] Set of elements used to provide details on the period of time related to the tax payment.
TaxAmount: [0..1] Set of elements used to provide information on the amount of the tax record.
AdditionalInformation: [0..1] Further details of the tax record.';
-- Type: TaxData1 (10.1.18.2.6 (TaxData1))
DROP TYPE IF EXISTS public."TaxData1" CASCADE;
CREATE TYPE public."TaxData1" AS (
    "Creditor" public."TaxParty1",
    "Debtor" public."TaxParty2",
    "UltimateDebtor" public."TaxParty2",
    "AdministrationZone" public."Max35Text",
    "ReferenceNumber" public."Max140Text",
    "Method" public."Max35Text",
    "TotalTaxableBaseAmount" public."ActiveOrHistoricCurrencyAndAmount",
    "TotalTaxAmount" public."ActiveOrHistoricCurrencyAndAmount",
    "Date" public."ISODate",
    "SequenceNumber" public."Number",
    "Record" public."TaxRecord3"[]
);
ALTER TYPE public."TaxData1" OWNER TO postgres;
COMMENT ON TYPE public."TaxData1" IS
'Definition: Provides remittance information about a payment made for tax-related purposes.

Creditor: [0..1] Party on the credit side of the transaction to which the tax applies. Reuses TaxParty1 (File 1).
Debtor: [0..1] Party on the debit side of the transaction to which the tax applies. Reuses TaxParty2 (File 1).
UltimateDebtor: [0..1] Ultimate party that owes an amount of money to the (ultimate) creditor. Reuses TaxParty2 (File 1).
AdministrationZone: [0..1] Territorial part of a country to which the tax payment is related.
ReferenceNumber: [0..1] Tax reference information that is specific to a taxing agency.
Method: [0..1] Method used to indicate the underlying business or how the tax is paid.
TotalTaxableBaseAmount: [0..1] Total amount of money on which the tax is based.
TotalTaxAmount: [0..1] Total amount of money as result of the calculation of the tax.
Date: [0..1] Date by which tax is due.
SequenceNumber: [0..1] Sequential number of the tax report.
Record: [0..1] Record of tax details -- repeatable, unbounded.';
-- ---------------------------------------------------------------------
-- PART 4 -- Garnishment Remittance
-- ---------------------------------------------------------------------
-- Type: GarnishmentType1Choice (inline, 10.1.18.2.7.1.1)
DROP TYPE IF EXISTS public."GarnishmentType1Choice" CASCADE;
CREATE TYPE public."GarnishmentType1Choice" AS (
    "Code" public."ExternalGarnishmentType1Code",
    "Proprietary" public."Max35Text"
);
ALTER TYPE public."GarnishmentType1Choice" OWNER TO postgres;
COMMENT ON TYPE public."GarnishmentType1Choice" IS
'Definition: Provides the type details of the garnishment.

{Or}/{Or} choice -- exactly one branch must be set:
Code: Garnishment type in a coded form. The MDR suggests (not formally, as embedded values) codes such as GNCS (garnishment from a third-party payer for child support), GNDP (garnishment from a direct payer for child support), GTPP (garnishment from a third-party payer to a taxing agency) -- these are illustrative only; the actual list is externally maintained (see ExternalGarnishmentType1Code, 10.2).
Proprietary: Proprietary identification of the type of garnishment.';
DROP FUNCTION IF EXISTS public.validate_garnishment_type1_choice(public."GarnishmentType1Choice");
CREATE OR REPLACE FUNCTION public.validate_garnishment_type1_choice(
    val public."GarnishmentType1Choice")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN ((val."Code" IS NOT NULL)::int + (val."Proprietary" IS NOT NULL)::int) = 1;
END;
$BODY$;
ALTER FUNCTION public.validate_garnishment_type1_choice(public."GarnishmentType1Choice")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_garnishment_type1_choice(public."GarnishmentType1Choice") IS
'Checks the {Or}/{Or} choice: exactly one of Code, Proprietary is set. Composite-typed branches use num_nonnulls() over their own fields rather than a plain IS NOT NULL.';
-- Type: GarnishmentType1 (10.1.18.2.7.1 (GarnishmentType1))
DROP TYPE IF EXISTS public."GarnishmentType1" CASCADE;
CREATE TYPE public."GarnishmentType1" AS (
    "CodeOrProprietary" public."GarnishmentType1Choice",
    "Issuer" public."Max35Text"
);
ALTER TYPE public."GarnishmentType1" OWNER TO postgres;
COMMENT ON TYPE public."GarnishmentType1" IS
'Definition: Specifies the type of garnishment.

CodeOrProprietary: [1..1] Provides the type details of the garnishment.
Issuer: [0..1] Identification of the issuer of the garnishment type.';
DROP FUNCTION IF EXISTS public.validate_garnishment_type1(public."GarnishmentType1");
CREATE OR REPLACE FUNCTION public.validate_garnishment_type1(
    val public."GarnishmentType1")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN (num_nonnulls((val."CodeOrProprietary")."Code", (val."CodeOrProprietary")."Proprietary") > 0);
END;
$BODY$;
ALTER FUNCTION public.validate_garnishment_type1(public."GarnishmentType1")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_garnishment_type1(public."GarnishmentType1") IS
'Checks the [1..1] mandatory field(s) (CodeOrProprietary) are present.';
-- Type: Garnishment4 (10.1.18.2.7 (Garnishment4))
DROP TYPE IF EXISTS public."Garnishment4" CASCADE;
CREATE TYPE public."Garnishment4" AS (
    "Type" public."GarnishmentType1",
    "Garnishee" public."PartyIdentification272",
    "GarnishmentAdministrator" public."PartyIdentification272",
    "ReferenceNumber" public."Max140Text",
    "Date" public."ISODate",
    "RemittedAmount" public."ActiveOrHistoricCurrencyAndAmount",
    "FamilyMedicalInsuranceIndicator" public."TrueFalseIndicator",
    "EmployeeTerminationIndicator" public."TrueFalseIndicator"
);
ALTER TYPE public."Garnishment4" OWNER TO postgres;
COMMENT ON TYPE public."Garnishment4" IS
'Definition: Provides remittance information about a payment for garnishment-related purposes.

Type: [1..1] Specifies the type of garnishment.
Garnishee: [0..1] Ultimate party that owes an amount of money to the (ultimate) creditor, in this case, to the garnisher. Reuses PartyIdentification272 (File 2).
GarnishmentAdministrator: [0..1] Party on the credit side of the transaction who administers the garnishment on behalf of the ultimate beneficiary. Reuses PartyIdentification272 (File 2).
ReferenceNumber: [0..1] Reference information that is specific to the agency receiving the garnishment.
Date: [0..1] Date of payment which garnishment was taken from.
RemittedAmount: [0..1] Amount of money remitted for the referred document.
FamilyMedicalInsuranceIndicator: [0..1] Indicates if the person to whom the garnishment applies (the ultimate debtor) has family medical insurance coverage available.
EmployeeTerminationIndicator: [0..1] Indicates if the employment of the person to whom the garnishment applies (the ultimate debtor) has been terminated.';
DROP FUNCTION IF EXISTS public.validate_garnishment4(public."Garnishment4");
CREATE OR REPLACE FUNCTION public.validate_garnishment4(
    val public."Garnishment4")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN (num_nonnulls((val."Type")."CodeOrProprietary", (val."Type")."Issuer") > 0);
END;
$BODY$;
ALTER FUNCTION public.validate_garnishment4(public."Garnishment4")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_garnishment4(public."Garnishment4") IS
'Checks the [1..1] mandatory field(s) (Type) are present.';
-- ---------------------------------------------------------------------
-- PART 5 -- Top-level Remittance types
-- ---------------------------------------------------------------------
-- Type: StructuredRemittanceInformation18 (10.1.18.2 (StructuredRemittanceInformation18))
DROP TYPE IF EXISTS public."StructuredRemittanceInformation18" CASCADE;
CREATE TYPE public."StructuredRemittanceInformation18" AS (
    "ReferredDocumentInformation" public."ReferredDocumentInformation8"[],
    "ReferredDocumentAmount" public."RemittanceAmount4",
    "CreditorReferenceInformation" public."CreditorReferenceInformation3",
    "Invoicer" public."PartyIdentification272",
    "Invoicee" public."PartyIdentification272",
    "TaxRemittance" public."TaxData1",
    "GarnishmentRemittance" public."Garnishment4",
    "AdditionalRemittanceInformation" public."Max140Text"[]
);
ALTER TYPE public."StructuredRemittanceInformation18" OWNER TO postgres;
COMMENT ON TYPE public."StructuredRemittanceInformation18" IS
'Definition: Information supplied to enable the matching/reconciliation of an entry with the items that the payment is intended to settle, such as commercial invoices in an accounts'' receivable system, in a structured form.

ReferredDocumentInformation: [0..1] Provides the identification and the content of the referred document -- repeatable, unbounded.
ReferredDocumentAmount: [0..1] Provides details on the amounts of the referred document.
CreditorReferenceInformation: [0..1] Reference information provided by the creditor to allow the identification of the underlying documents.
Invoicer: [0..1] Identification of the organisation issuing the invoice, when different from the creditor or ultimate creditor. Reuses PartyIdentification272 (File 2).
Invoicee: [0..1] Identification of the party to whom an invoice is issued, when different from the debtor or ultimate debtor. Reuses PartyIdentification272 (File 2).
TaxRemittance: [0..1] Provides remittance information about a payment made for tax-related purposes.
GarnishmentRemittance: [0..1] Provides remittance information about a payment for garnishment-related purposes.
AdditionalRemittanceInformation: [0..1] Additional information, in free text form, to complement the structured remittance information -- repeatable, bounded [0..3] (unlike most repeatables in this library, which are [0..*] unbounded).

AdditionalRemittanceInformation is [0..3] -- bounded, unlike ReferredDocumentInformation ([0..*] unbounded). The validate_ function below enforces this bound (Postgres arrays have no inherent max-length constraint), matching the pattern used for PostalAddress27.AddressLine (File 2) and its empty-array COALESCE fix.';
DROP FUNCTION IF EXISTS public.validate_structured_remittance_information18(public."StructuredRemittanceInformation18");
CREATE OR REPLACE FUNCTION public.validate_structured_remittance_information18(
    val public."StructuredRemittanceInformation18")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN (val."AdditionalRemittanceInformation" IS NULL OR COALESCE(array_length(val."AdditionalRemittanceInformation", 1), 0) <= 3);
END;
$BODY$;
ALTER FUNCTION public.validate_structured_remittance_information18(public."StructuredRemittanceInformation18")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_structured_remittance_information18(public."StructuredRemittanceInformation18") IS
'Checks additional constraints.';
-- Type: RemittanceInformation22 (10.1.18.1 (RemittanceInformation22))
DROP TYPE IF EXISTS public."RemittanceInformation22" CASCADE;
CREATE TYPE public."RemittanceInformation22" AS (
    "Unstructured" public."Max140Text"[],
    "Structured" public."StructuredRemittanceInformation18"[]
);
ALTER TYPE public."RemittanceInformation22" OWNER TO postgres;
COMMENT ON TYPE public."RemittanceInformation22" IS
'Definition: Information supplied to enable the matching/reconciliation of an entry with the items that the payment is intended to settle, such as commercial invoices in an accounts'' receivable system.

Unstructured: [0..1] Information supplied to enable the matching/reconciliation of an entry with the items that the payment is intended to settle, in unstructured form -- repeatable, unbounded.
Structured: [0..1] Information supplied to enable the matching/reconciliation of an entry with the items that the payment is intended to settle, in structured form -- repeatable, unbounded.';