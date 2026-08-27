-- =====================================================================
-- ISO 20022 Message Definition Report - Part 2
-- Payments Clearing and Settlement - Maintenance 2024-2025 (Feb 2025)
-- Section 10.1 "Message Components" -- FILE 3 of 4: Accounts & Financial Institutions
--
-- Covers: Account (CashAccount40), Account Identification
-- (AccountIdentification4Choice), Financial Institution Identification
-- (BranchAndFinancialInstitutionIdentification8).
--
-- Depends on: 10.2 Message Datatypes, File 1 (ClearingSystemIdentification2Choice),
-- File 2 (PostalAddress27).
-- Load order: 10.2 -> File 1 -> File 2 -> File 3 (this file) -> File 4.
-- =====================================================================
-- ---------------------------------------------------------------------
-- PART 1 -- 10.1.1 Account / 10.1.2 Account Identification
-- ---------------------------------------------------------------------
-- Type: AccountSchemeName1Choice (inline, 10.1.1.4.2)
DROP TYPE IF EXISTS public."AccountSchemeName1Choice" CASCADE;
CREATE TYPE public."AccountSchemeName1Choice" AS (
    "Code" public."ExternalAccountIdentification1Code",
    "Proprietary" public."Max35Text"
);
ALTER TYPE public."AccountSchemeName1Choice" OWNER TO postgres;
COMMENT ON TYPE public."AccountSchemeName1Choice" IS
'Definition: Name of the identification scheme.

{Or}/{Or} choice -- exactly one branch must be set:
Code: Name of the identification scheme, in a coded form as published in an external list.
Proprietary: Name of the identification scheme, in a free text form.';
DROP FUNCTION IF EXISTS public.validate_account_scheme_name1_choice(public."AccountSchemeName1Choice");
CREATE OR REPLACE FUNCTION public.validate_account_scheme_name1_choice(
    val public."AccountSchemeName1Choice")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN ((val."Code" IS NOT NULL)::int + (val."Proprietary" IS NOT NULL)::int) = 1;
END;
$BODY$;
ALTER FUNCTION public.validate_account_scheme_name1_choice(public."AccountSchemeName1Choice")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_account_scheme_name1_choice(public."AccountSchemeName1Choice") IS
'Checks the {Or}/{Or} choice: exactly one of Code, Proprietary is set. Composite-typed branches use num_nonnulls() over their own fields rather than a plain IS NOT NULL.';
-- Type: GenericAccountIdentification1 (10.1.1.4)
DROP TYPE IF EXISTS public."GenericAccountIdentification1" CASCADE;
CREATE TYPE public."GenericAccountIdentification1" AS (
    "Identification" public."Max34Text",
    "SchemeName" public."AccountSchemeName1Choice",
    "Issuer" public."Max35Text"
);
ALTER TYPE public."GenericAccountIdentification1" OWNER TO postgres;
COMMENT ON TYPE public."GenericAccountIdentification1" IS
'Definition: Information related to a generic account identification.

Identification: [1..1] Identification assigned by an institution.
SchemeName: [0..1] Name of the identification scheme.
Issuer: [0..1] Entity that assigns the identification.';
DROP FUNCTION IF EXISTS public.validate_generic_account_identification1(public."GenericAccountIdentification1");
CREATE OR REPLACE FUNCTION public.validate_generic_account_identification1(
    val public."GenericAccountIdentification1")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN (val."Identification" IS NOT NULL);
END;
$BODY$;
ALTER FUNCTION public.validate_generic_account_identification1(public."GenericAccountIdentification1")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_generic_account_identification1(public."GenericAccountIdentification1") IS
'Checks the [1..1] mandatory field(s) (Identification) are present.';
-- Type: AccountIdentification4Choice (10.1.2.1)
DROP TYPE IF EXISTS public."AccountIdentification4Choice" CASCADE;
CREATE TYPE public."AccountIdentification4Choice" AS (
    "IBAN" public."IBAN2007Identifier",
    "Other" public."GenericAccountIdentification1"
);
ALTER TYPE public."AccountIdentification4Choice" OWNER TO postgres;
COMMENT ON TYPE public."AccountIdentification4Choice" IS
'Definition: Specifies the unique identification of an account as assigned by the account servicer.

{Or}/{Or} choice -- exactly one branch must be set:
IBAN: International Bank Account Number (IBAN). Constraint C15 "IBAN" -- structure/length already enforced by the IBAN2007Identifier domain (10.2); mod-97 check digit is NOT verified there.
Other: Unique identification of an account, as assigned by the account servicer, using an identification scheme.';
DROP FUNCTION IF EXISTS public.validate_account_identification4_choice(public."AccountIdentification4Choice");
CREATE OR REPLACE FUNCTION public.validate_account_identification4_choice(
    val public."AccountIdentification4Choice")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN ((val."IBAN" IS NOT NULL)::int + (num_nonnulls((val."Other")."Identification", (val."Other")."SchemeName", (val."Other")."Issuer") > 0)::int) = 1;
END;
$BODY$;
ALTER FUNCTION public.validate_account_identification4_choice(public."AccountIdentification4Choice")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_account_identification4_choice(public."AccountIdentification4Choice") IS
'Checks the {Or}/{Or} choice: exactly one of IBAN, Other is set. Composite-typed branches use num_nonnulls() over their own fields rather than a plain IS NOT NULL.';
-- Type: CashAccountType2Choice (10.1.1.3)
DROP TYPE IF EXISTS public."CashAccountType2Choice" CASCADE;
CREATE TYPE public."CashAccountType2Choice" AS (
    "Code" public."ExternalCashAccountType1Code",
    "Proprietary" public."Max35Text"
);
ALTER TYPE public."CashAccountType2Choice" OWNER TO postgres;
COMMENT ON TYPE public."CashAccountType2Choice" IS
'Definition: Nature or use of the account.

{Or}/{Or} choice -- exactly one branch must be set:
Code: Account type, in a coded form.
Proprietary: Nature or use of the account in a proprietary form.';
DROP FUNCTION IF EXISTS public.validate_cash_account_type2_choice(public."CashAccountType2Choice");
CREATE OR REPLACE FUNCTION public.validate_cash_account_type2_choice(
    val public."CashAccountType2Choice")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN ((val."Code" IS NOT NULL)::int + (val."Proprietary" IS NOT NULL)::int) = 1;
END;
$BODY$;
ALTER FUNCTION public.validate_cash_account_type2_choice(public."CashAccountType2Choice")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_cash_account_type2_choice(public."CashAccountType2Choice") IS
'Checks the {Or}/{Or} choice: exactly one of Code, Proprietary is set. Composite-typed branches use num_nonnulls() over their own fields rather than a plain IS NOT NULL.';
-- Type: ProxyAccountType1Choice (inline, 10.1.1.2.1)
DROP TYPE IF EXISTS public."ProxyAccountType1Choice" CASCADE;
CREATE TYPE public."ProxyAccountType1Choice" AS (
    "Code" public."ExternalProxyAccountType1Code",
    "Proprietary" public."Max35Text"
);
ALTER TYPE public."ProxyAccountType1Choice" OWNER TO postgres;
COMMENT ON TYPE public."ProxyAccountType1Choice" IS
'Definition: Type of the proxy identification.

{Or}/{Or} choice -- exactly one branch must be set:
Code: Name of the identification scheme, in a coded form as published in an external list.
Proprietary: Name of the identification scheme, in a free text form.';
DROP FUNCTION IF EXISTS public.validate_proxy_account_type1_choice(public."ProxyAccountType1Choice");
CREATE OR REPLACE FUNCTION public.validate_proxy_account_type1_choice(
    val public."ProxyAccountType1Choice")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN ((val."Code" IS NOT NULL)::int + (val."Proprietary" IS NOT NULL)::int) = 1;
END;
$BODY$;
ALTER FUNCTION public.validate_proxy_account_type1_choice(public."ProxyAccountType1Choice")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_proxy_account_type1_choice(public."ProxyAccountType1Choice") IS
'Checks the {Or}/{Or} choice: exactly one of Code, Proprietary is set. Composite-typed branches use num_nonnulls() over their own fields rather than a plain IS NOT NULL.';
-- Type: ProxyAccountIdentification1 (10.1.1.2)
DROP TYPE IF EXISTS public."ProxyAccountIdentification1" CASCADE;
CREATE TYPE public."ProxyAccountIdentification1" AS (
    "Type" public."ProxyAccountType1Choice",
    "Identification" public."Max2048Text"
);
ALTER TYPE public."ProxyAccountIdentification1" OWNER TO postgres;
COMMENT ON TYPE public."ProxyAccountIdentification1" IS
'Definition: Information related to a proxy identification of the account.

Type: [0..1] Type of the proxy identification.
Identification: [1..1] Identification used to indicate the account identification under another specified name.';
DROP FUNCTION IF EXISTS public.validate_proxy_account_identification1(public."ProxyAccountIdentification1");
CREATE OR REPLACE FUNCTION public.validate_proxy_account_identification1(
    val public."ProxyAccountIdentification1")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN (val."Identification" IS NOT NULL);
END;
$BODY$;
ALTER FUNCTION public.validate_proxy_account_identification1(public."ProxyAccountIdentification1")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_proxy_account_identification1(public."ProxyAccountIdentification1") IS
'Checks the [1..1] mandatory field(s) (Identification) are present.';
-- Type: CashAccount40 (10.1.1.1)
DROP TYPE IF EXISTS public."CashAccount40" CASCADE;
CREATE TYPE public."CashAccount40" AS (
    "Identification" public."AccountIdentification4Choice",
    "Type" public."CashAccountType2Choice",
    "Currency" public."ActiveOrHistoricCurrencyCode",
    "Name" public."Max70Text",
    "Proxy" public."ProxyAccountIdentification1"
);
ALTER TYPE public."CashAccount40" OWNER TO postgres;
COMMENT ON TYPE public."CashAccount40" IS
'Definition: Provides the details to identify an account.

Identification: [0..1] AccountIdentification4Choice (IBAN or Other).
Type: [0..1] Nature or use of the account.
Currency: [0..1] Currency in which the account is held. Constraint C2 "ActiveOrHistoricCurrency" -- format enforced by the domain.
Name: [0..1] Name of the account, as assigned by the account servicer.
Proxy: [0..1] Alternate assumed name for the identification of the account.

Constraint - IdentificationAndProxyGuideline: if the account identification is not a conventional identifier (email, mobile number), Proxy should be used instead. (Guidance, not a hard rule -- not enforced by the validate_ function below.)

Constraint - IdentificationOrProxyPresenceRule: Identification must be present OR Proxy must be present (both may be present) -- an inclusive-or, like PaymentIdentification13s rule in File 1, not the exactly-one {Or}/{Or} pattern.';
DROP FUNCTION IF EXISTS public.validate_cash_account40(public."CashAccount40");
CREATE OR REPLACE FUNCTION public.validate_cash_account40(
    val public."CashAccount40")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN (num_nonnulls((val."Identification")."IBAN", (val."Identification")."Other") > 0)
        OR (num_nonnulls((val."Proxy")."Type", (val."Proxy")."Identification") > 0);
END;
$BODY$;
ALTER FUNCTION public.validate_cash_account40(public."CashAccount40")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_cash_account40(public."CashAccount40") IS
'Checks the IdentificationOrProxyPresenceRule: at least one of Identification/Proxy is populated (inclusive-or). Uses num_nonnulls-based checks since both are optional-field composite types, not plain scalars.';
-- ---------------------------------------------------------------------
-- PART 2 -- 10.1.7 Financial Institution Identification
-- ---------------------------------------------------------------------
-- Type: ClearingSystemMemberIdentification2 (10.1.7.1)
DROP TYPE IF EXISTS public."ClearingSystemMemberIdentification2" CASCADE;
CREATE TYPE public."ClearingSystemMemberIdentification2" AS (
    "ClearingSystemIdentification" public."ClearingSystemIdentification2Choice",
    "MemberIdentification" public."Max35Text"
);
ALTER TYPE public."ClearingSystemMemberIdentification2" OWNER TO postgres;
COMMENT ON TYPE public."ClearingSystemMemberIdentification2" IS
'Definition: Unique identification, as assigned by a clearing system, to unambiguously identify a member of the clearing system.

ClearingSystemIdentification: [0..1] Specification of a pre-agreed offering between clearing agents or the channel through which the payment instruction is processed.
MemberIdentification: [1..1] Identification of a member of a clearing system.';
DROP FUNCTION IF EXISTS public.validate_clearing_system_member_identification2(public."ClearingSystemMemberIdentification2");
CREATE OR REPLACE FUNCTION public.validate_clearing_system_member_identification2(
    val public."ClearingSystemMemberIdentification2")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN (val."MemberIdentification" IS NOT NULL);
END;
$BODY$;
ALTER FUNCTION public.validate_clearing_system_member_identification2(public."ClearingSystemMemberIdentification2")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_clearing_system_member_identification2(public."ClearingSystemMemberIdentification2") IS
'Checks the [1..1] mandatory field(s) (MemberIdentification) are present.';
-- Type: FinancialIdentificationSchemeName1Choice (inline, 10.1.7.2.2)
DROP TYPE IF EXISTS public."FinancialIdentificationSchemeName1Choice" CASCADE;
CREATE TYPE public."FinancialIdentificationSchemeName1Choice" AS (
    "Code" public."ExternalFinancialInstitutionIdentification1Code",
    "Proprietary" public."Max35Text"
);
ALTER TYPE public."FinancialIdentificationSchemeName1Choice" OWNER TO postgres;
COMMENT ON TYPE public."FinancialIdentificationSchemeName1Choice" IS
'Definition: Name of the identification scheme.

{Or}/{Or} choice -- exactly one branch must be set:
Code: Name of the identification scheme, in a coded form as published in an external list.
Proprietary: Name of the identification scheme, in a free text form.';
DROP FUNCTION IF EXISTS public.validate_financial_identification_scheme_name1_choice(public."FinancialIdentificationSchemeName1Choice");
CREATE OR REPLACE FUNCTION public.validate_financial_identification_scheme_name1_choice(
    val public."FinancialIdentificationSchemeName1Choice")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN ((val."Code" IS NOT NULL)::int + (val."Proprietary" IS NOT NULL)::int) = 1;
END;
$BODY$;
ALTER FUNCTION public.validate_financial_identification_scheme_name1_choice(public."FinancialIdentificationSchemeName1Choice")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_financial_identification_scheme_name1_choice(public."FinancialIdentificationSchemeName1Choice") IS
'Checks the {Or}/{Or} choice: exactly one of Code, Proprietary is set. Composite-typed branches use num_nonnulls() over their own fields rather than a plain IS NOT NULL.';
-- Type: GenericFinancialIdentification1 (10.1.7.2)
DROP TYPE IF EXISTS public."GenericFinancialIdentification1" CASCADE;
CREATE TYPE public."GenericFinancialIdentification1" AS (
    "Identification" public."Max35Text",
    "SchemeName" public."FinancialIdentificationSchemeName1Choice",
    "Issuer" public."Max35Text"
);
ALTER TYPE public."GenericFinancialIdentification1" OWNER TO postgres;
COMMENT ON TYPE public."GenericFinancialIdentification1" IS
'Definition: Information related to an identification of a financial institution.

Identification: [1..1] Unique and unambiguous identification of a person.
SchemeName: [0..1] Name of the identification scheme.
Issuer: [0..1] Entity that assigns the identification.';
DROP FUNCTION IF EXISTS public.validate_generic_financial_identification1(public."GenericFinancialIdentification1");
CREATE OR REPLACE FUNCTION public.validate_generic_financial_identification1(
    val public."GenericFinancialIdentification1")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN (val."Identification" IS NOT NULL);
END;
$BODY$;
ALTER FUNCTION public.validate_generic_financial_identification1(public."GenericFinancialIdentification1")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_generic_financial_identification1(public."GenericFinancialIdentification1") IS
'Checks the [1..1] mandatory field(s) (Identification) are present.';
-- Type: FinancialInstitutionIdentification23 (inline, 10.1.7.3.1)
DROP TYPE IF EXISTS public."FinancialInstitutionIdentification23" CASCADE;
CREATE TYPE public."FinancialInstitutionIdentification23" AS (
    "BICFI" public."BICFIDec2014Identifier",
    "ClearingSystemMemberIdentification" public."ClearingSystemMemberIdentification2",
    "LEI" public."LEIIdentifier",
    "Name" public."Max140Text",
    "PostalAddress" public."PostalAddress27",
    "Other" public."GenericFinancialIdentification1"
);
ALTER TYPE public."FinancialInstitutionIdentification23" OWNER TO postgres;
COMMENT ON TYPE public."FinancialInstitutionIdentification23" IS
'Definition: Unique and unambiguous identification of a financial institution, as assigned under an internationally recognised or proprietary identification scheme.

BICFI: [0..1] Constraint C5 "BICFI" -- format already enforced by the BICFIDec2014Identifier domain.
ClearingSystemMemberIdentification: [0..1] Reuses ClearingSystemMemberIdentification2.
LEI: [0..1] Legal entity identifier of the financial institution.
Name: [0..1] Name by which an agent is known.
PostalAddress: [0..1] Reuses PostalAddress27 (File 2).
Other: [0..1] Reuses GenericFinancialIdentification1 -- note: [0..1] here, NOT repeatable (unlike some other "Other" fields elsewhere in this library which are [0..*]).

All fields optional -- no validate_ function needed at this level.';
-- Type: BranchData5 (inline, 10.1.7.3.2)
DROP TYPE IF EXISTS public."BranchData5" CASCADE;
CREATE TYPE public."BranchData5" AS (
    "Identification" public."Max35Text",
    "LEI" public."LEIIdentifier",
    "Name" public."Max140Text",
    "PostalAddress" public."PostalAddress27"
);
ALTER TYPE public."BranchData5" OWNER TO postgres;
COMMENT ON TYPE public."BranchData5" IS
'Definition: Identifies a specific branch of a financial institution.

Usage: This component should be used in case the identification information in the financial institution component does not provide identification up to branch level.

Identification: [0..1] Unique identification of a branch of a financial institution.
LEI: [0..1] Legal entity identifier.
Name: [0..1] Name of the branch.
PostalAddress: [0..1] Reuses PostalAddress27 (File 2).

All fields optional -- no validate_ function needed at this level.';
-- Type: BranchAndFinancialInstitutionIdentification8 (10.1.7.3)
DROP TYPE IF EXISTS public."BranchAndFinancialInstitutionIdentification8" CASCADE;
CREATE TYPE public."BranchAndFinancialInstitutionIdentification8" AS (
    "FinancialInstitutionIdentification" public."FinancialInstitutionIdentification23",
    "BranchIdentification" public."BranchData5"
);
ALTER TYPE public."BranchAndFinancialInstitutionIdentification8" OWNER TO postgres;
COMMENT ON TYPE public."BranchAndFinancialInstitutionIdentification8" IS
'Definition: Unique and unambiguous identification of a financial institution or a branch of a financial institution.

FinancialInstitutionIdentification: [1..1] Unique and unambiguous identification of a financial institution.
BranchIdentification: [0..1] Identifies a specific branch of a financial institution.';
DROP FUNCTION IF EXISTS public.validate_branch_and_financial_institution_identification8(public."BranchAndFinancialInstitutionIdentification8");
CREATE OR REPLACE FUNCTION public.validate_branch_and_financial_institution_identification8(
    val public."BranchAndFinancialInstitutionIdentification8")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN (num_nonnulls((val."FinancialInstitutionIdentification")."BICFI", (val."FinancialInstitutionIdentification")."ClearingSystemMemberIdentification", (val."FinancialInstitutionIdentification")."LEI", (val."FinancialInstitutionIdentification")."Name", (val."FinancialInstitutionIdentification")."PostalAddress", (val."FinancialInstitutionIdentification")."Other") > 0);
END;
$BODY$;
ALTER FUNCTION public.validate_branch_and_financial_institution_identification8(public."BranchAndFinancialInstitutionIdentification8")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_branch_and_financial_institution_identification8(public."BranchAndFinancialInstitutionIdentification8") IS
'Checks the [1..1] mandatory field(s) (FinancialInstitutionIdentification) are present.';
