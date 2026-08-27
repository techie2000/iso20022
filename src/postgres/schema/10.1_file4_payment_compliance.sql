-- =====================================================================
-- ISO 20022 Message Definition Report - Part 2
-- Payments Clearing and Settlement - Maintenance 2024-2025 (Feb 2025)
-- Section 10.1 "Message Components" -- FILE 4 of 4: Payment Instructions & Compliance
--
-- Covers: Direct Debit (CreditTransferMandateData1), Regulatory Reporting
-- (RegulatoryReporting3).
--
-- Depends on: 10.2 Message Datatypes, File 1 (MandateTypeInformation2,
-- Frequency36Choice).
-- Load order: 10.2 -> File 1 -> File 2 -> File 3 -> File 4 (this file).
--
-- This completes Section 10.1 EXCEPT 10.1.18 Remittance (deferred --
-- 42 of 102 pages for 2 top-level types, by far the most complex part;
-- to be tackled as a separate follow-up).
-- =====================================================================
-- ---------------------------------------------------------------------
-- PART 1 -- 10.1.6 Direct Debit
-- ---------------------------------------------------------------------
-- Type: MandateSetupReason1Choice (inline, 10.1.6.1.9)
DROP TYPE IF EXISTS public."MandateSetupReason1Choice" CASCADE;
CREATE TYPE public."MandateSetupReason1Choice" AS (
    "Code" public."ExternalMandateSetupReason1Code",
    "Proprietary" public."Max70Text"
);
ALTER TYPE public."MandateSetupReason1Choice" OWNER TO postgres;
COMMENT ON TYPE public."MandateSetupReason1Choice" IS
'Definition: Reason for the setup of the credit transfer mandate.

Usage: Allows the user to distinguish between different mandates for the same creditor.

{Or}/{Or} choice -- exactly one branch must be set:
Code: Reason for the mandate setup, as published in an external reason code list.
Proprietary: Reason for the mandate setup, in a proprietary form.';
DROP FUNCTION IF EXISTS public.validate_mandate_setup_reason1_choice(public."MandateSetupReason1Choice");
CREATE OR REPLACE FUNCTION public.validate_mandate_setup_reason1_choice(
    val public."MandateSetupReason1Choice")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN ((val."Code" IS NOT NULL)::int + (val."Proprietary" IS NOT NULL)::int) = 1;
END;
$BODY$;
ALTER FUNCTION public.validate_mandate_setup_reason1_choice(public."MandateSetupReason1Choice")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_mandate_setup_reason1_choice(public."MandateSetupReason1Choice") IS
'Checks the {Or}/{Or} choice: exactly one of Code, Proprietary is set. Composite-typed branches use num_nonnulls() over their own fields rather than a plain IS NOT NULL.';
-- Type: CreditTransferMandateData1 (10.1.6.1)
DROP TYPE IF EXISTS public."CreditTransferMandateData1" CASCADE;
CREATE TYPE public."CreditTransferMandateData1" AS (
    "MandateIdentification" public."Max35Text",
    "Type" public."MandateTypeInformation2",
    "DateOfSignature" public."ISODate",
    "DateOfVerification" public."ISODateTime",
    "ElectronicSignature" public."Max10KBinary",
    "FirstPaymentDate" public."ISODate",
    "FinalPaymentDate" public."ISODate",
    "Frequency" public."Frequency36Choice",
    "Reason" public."MandateSetupReason1Choice"
);
ALTER TYPE public."CreditTransferMandateData1" OWNER TO postgres;
COMMENT ON TYPE public."CreditTransferMandateData1" IS
'Definition: Provides further details related to a credit transfer mandate signed between the creditor and the debtor.

MandateIdentification: [0..1] Unique identification, as assigned by the creditor, to unambiguously identify the mandate.
Type: [0..1] Specifies the type of mandate, such as paper, electronic or scheme. Reuses MandateTypeInformation2 (File 1).
DateOfSignature: [0..1] Date on which the credit transfer mandate has been signed by the debtor.
DateOfVerification: [0..1] Date on which the credit transfer mandate has been verified.
ElectronicSignature: [0..1] Additional security provisions, such as a digital signature, as provided by the debtor.
FirstPaymentDate: [0..1] Date of the first payment of a recurrent credit transfer as per the mandate.
FinalPaymentDate: [0..1] Date of the final payment of a recurrent credit transfer as per the mandate.
Frequency: [0..1] Regularity with which credit transfer instructions are to be created and processed. Reuses Frequency36Choice (File 1).
Reason: [0..1] Reason for the setup of the credit transfer mandate.';
-- ---------------------------------------------------------------------
-- PART 2 -- 10.1.17 Regulatory Reporting
-- ---------------------------------------------------------------------
-- Type: RegulatoryAuthority2 (inline, 10.1.17.1.2)
DROP TYPE IF EXISTS public."RegulatoryAuthority2" CASCADE;
CREATE TYPE public."RegulatoryAuthority2" AS (
    "Name" public."Max140Text",
    "Country" public."CountryCode"
);
ALTER TYPE public."RegulatoryAuthority2" OWNER TO postgres;
COMMENT ON TYPE public."RegulatoryAuthority2" IS
'Definition: Entity requiring the regulatory reporting information.

Name: [0..1] Name of the entity requiring the regulatory reporting information.
Country: [0..1] Country of the entity that requires the regulatory reporting information. Constraint C10 "Country" -- format enforced by the domain.';
-- Type: StructuredRegulatoryReporting3 (inline, 10.1.17.1.3)
DROP TYPE IF EXISTS public."StructuredRegulatoryReporting3" CASCADE;
CREATE TYPE public."StructuredRegulatoryReporting3" AS (
    "Type" public."Max35Text",
    "Date" public."ISODate",
    "Country" public."CountryCode",
    "Code" public."Max10Text",
    "Amount" public."ActiveOrHistoricCurrencyAndAmount",
    "Information" public."Max35Text"[]
);
ALTER TYPE public."StructuredRegulatoryReporting3" OWNER TO postgres;
COMMENT ON TYPE public."StructuredRegulatoryReporting3" IS
'Definition: Set of elements used to provide details on the regulatory reporting information.

Type: [0..1] Type of the information supplied in the regulatory reporting details.
Date: [0..1] Date related to the specified type of regulatory reporting details.
Country: [0..1] Constraint C10 "Country" -- format enforced by the domain.
Code: [0..1] Nature/purpose/reason for the transaction, coded form.
Amount: [0..1] Amount of money to be reported. Constraints C2/C12 -- format/precision enforced by the ActiveOrHistoricCurrencyAndAmount composite type (10.2).
Information: [0..*] Additional free-text details for domestic regulatory requirements -- repeatable, modeled as an array (unbounded).

All fields optional -- no validate_ function needed at this level.';
-- Type: RegulatoryReporting3 (10.1.17.1)
DROP TYPE IF EXISTS public."RegulatoryReporting3" CASCADE;
CREATE TYPE public."RegulatoryReporting3" AS (
    "DebitCreditReportingIndicator" public."RegulatoryReportingType1Code",
    "Authority" public."RegulatoryAuthority2",
    "Details" public."StructuredRegulatoryReporting3"[]
);
ALTER TYPE public."RegulatoryReporting3" OWNER TO postgres;
COMMENT ON TYPE public."RegulatoryReporting3" IS
'Definition: Information needed due to regulatory and/or statutory requirements.

DebitCreditReportingIndicator: [0..1] Whether the information applies to debit, credit, or both sides.
Authority: [0..1] Entity requiring the regulatory reporting information.
Details: [0..*] Set of elements providing details -- repeatable, modeled as an array of StructuredRegulatoryReporting3 (unbounded).

All fields optional -- no validate_ function needed at this level.';
