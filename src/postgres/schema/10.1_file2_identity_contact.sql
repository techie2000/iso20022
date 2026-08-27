-- =====================================================================
-- ISO 20022 Message Definition Report - Part 2
-- Payments Clearing and Settlement - Maintenance 2024-2025 (Feb 2025)
-- Section 10.1 "Message Components" -- FILE 2 of 4: Identity & Contact
--
-- Covers: Person Identification (Contact13), Postal Address
-- (PostalAddress27), Party Identification (PartyIdentification272).
--
-- Depends on: 10.2 Message Datatypes, and File 1 (GenericIdentification30).
-- Load order: 10.2 -> File 1 -> File 2 (this file) -> File 3 -> File 4.
-- =====================================================================
-- ---------------------------------------------------------------------
-- PART 1 -- 10.1.15 Person Identification
-- ---------------------------------------------------------------------
-- Type: OtherContact1 (inline, 10.1.15.1.12)
DROP TYPE IF EXISTS public."OtherContact1" CASCADE;
CREATE TYPE public."OtherContact1" AS (
    "ChannelType" public."Max4Text",
    "Identification" public."Max128Text"
);
ALTER TYPE public."OtherContact1" OWNER TO postgres;
COMMENT ON TYPE public."OtherContact1" IS
'Definition: Contact details in another form.

ChannelType: [1..1] Method used to contact the financial institutions contact for the specific tax region.
Identification: [0..1] Communication value such as phone number or email address.';
DROP FUNCTION IF EXISTS public.validate_other_contact1(public."OtherContact1");
CREATE OR REPLACE FUNCTION public.validate_other_contact1(
    val public."OtherContact1")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN (val."ChannelType" IS NOT NULL);
END;
$BODY$;
ALTER FUNCTION public.validate_other_contact1(public."OtherContact1")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_other_contact1(public."OtherContact1") IS
'Checks the [1..1] mandatory field(s) (ChannelType) are present.';
-- Type: Contact13 (10.1.15.1)
DROP TYPE IF EXISTS public."Contact13" CASCADE;
CREATE TYPE public."Contact13" AS (
    "NamePrefix" public."NamePrefix2Code",
    "Name" public."Max140Text",
    "PhoneNumber" public."PhoneNumber",
    "MobileNumber" public."PhoneNumber",
    "FaxNumber" public."PhoneNumber",
    "URLAddress" public."Max2048Text",
    "EmailAddress" public."Max256Text",
    "EmailPurpose" public."Max35Text",
    "JobTitle" public."Max35Text",
    "Responsibility" public."Max35Text",
    "Department" public."Max70Text",
    "Other" public."OtherContact1"[],
    "PreferredMethod" public."PreferredContactMethod2Code"
);
ALTER TYPE public."Contact13" OWNER TO postgres;
COMMENT ON TYPE public."Contact13" IS
'Definition: Specifies the details of the contact person.

All fields [0..1] except Other, which is [0..*] (repeatable, modeled as an array of OtherContact1 -- unbounded, no max given).

NamePrefix, Name, PhoneNumber, MobileNumber, FaxNumber, URLAddress, EmailAddress, EmailPurpose, JobTitle, Responsibility, Department: self-explanatory contact fields.
Other: [0..*] Contact details in another form.
PreferredMethod: [0..1] Preferred method used to reach the contact.

All fields optional -- no validate_ function needed at this level.';
-- ---------------------------------------------------------------------
-- PART 2 -- 10.1.16 Postal Address
-- ---------------------------------------------------------------------
-- Type: AddressType3Choice (inline, 10.1.16.1.1)
DROP TYPE IF EXISTS public."AddressType3Choice" CASCADE;
CREATE TYPE public."AddressType3Choice" AS (
    "Code" public."AddressType2Code",
    "Proprietary" public."GenericIdentification30"
);
ALTER TYPE public."AddressType3Choice" OWNER TO postgres;
COMMENT ON TYPE public."AddressType3Choice" IS
'Definition: Identifies the nature of the postal address.

{Or}/{Or} choice -- exactly one branch must be set:
Code: Type of address expressed as a code (ADDR/PBOX/HOME/BIZZ/MLTO/DLVY).
Proprietary: Type of address expressed as a proprietary code. Reuses GenericIdentification30 (File 1).';
DROP FUNCTION IF EXISTS public.validate_address_type3_choice(public."AddressType3Choice");
CREATE OR REPLACE FUNCTION public.validate_address_type3_choice(
    val public."AddressType3Choice")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN ((val."Code" IS NOT NULL)::int + (num_nonnulls((val."Proprietary")."Identification", (val."Proprietary")."Issuer", (val."Proprietary")."SchemeName") > 0)::int) = 1;
END;
$BODY$;
ALTER FUNCTION public.validate_address_type3_choice(public."AddressType3Choice")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_address_type3_choice(public."AddressType3Choice") IS
'Checks the {Or}/{Or} choice: exactly one of Code, Proprietary is set. Composite-typed branches use num_nonnulls() over their own fields rather than a plain IS NOT NULL, since Postgress row-wise NULL semantics make IS NOT NULL true only when ALL of a composites fields are non-null -- wrong for a branch type whose fields are individually optional.';
-- Type: PostalAddress27 (10.1.16.1)
DROP TYPE IF EXISTS public."PostalAddress27" CASCADE;
CREATE TYPE public."PostalAddress27" AS (
    "AddressType" public."AddressType3Choice",
    "CareOf" public."Max140Text",
    "Department" public."Max70Text",
    "SubDepartment" public."Max70Text",
    "StreetName" public."Max140Text",
    "BuildingNumber" public."Max16Text",
    "BuildingName" public."Max140Text",
    "Floor" public."Max70Text",
    "UnitNumber" public."Max16Text",
    "PostBox" public."Max16Text",
    "Room" public."Max70Text",
    "PostCode" public."Max16Text",
    "TownName" public."Max140Text",
    "TownLocationName" public."Max140Text",
    "DistrictName" public."Max140Text",
    "CountrySubDivision" public."Max140Text",
    "Country" public."CountryCode",
    "AddressLine" public."Max70Text"[]
);
ALTER TYPE public."PostalAddress27" OWNER TO postgres;
COMMENT ON TYPE public."PostalAddress27" IS
'Definition: Information that locates and identifies a specific address, as defined by postal services.

All fields [0..1] except AddressLine, which is [0..7] -- modeled as an array, bounded by the validate_ function below (Postgres arrays have no inherent max-length constraint).

Country: Constraint C10 "Country" applies (checked against the UN/ISO 3166 list -- see the CountryCode domain from 10.2, which enforces format only).

AddressLine: [0..7] Free-format address lines.';
DROP FUNCTION IF EXISTS public.validate_postal_address27(public."PostalAddress27");
CREATE OR REPLACE FUNCTION public.validate_postal_address27(
    val public."PostalAddress27")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN val."AddressLine" IS NULL OR array_length(val."AddressLine", 1) <= 7;
END;
$BODY$;
ALTER FUNCTION public.validate_postal_address27(public."PostalAddress27")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_postal_address27(public."PostalAddress27") IS
'Checks the AddressLine array does not exceed its [0..7] bound from the MDR (Postgres arrays have no inherent max-length constraint, unlike varchar(n)).';
-- ---------------------------------------------------------------------
-- PART 3 -- 10.1.12 Party Identification
-- ---------------------------------------------------------------------
-- Type: OrganisationIdentificationSchemeName1Choice (inline, 10.1.12.1.3.1.3.2)
DROP TYPE IF EXISTS public."OrganisationIdentificationSchemeName1Choice" CASCADE;
CREATE TYPE public."OrganisationIdentificationSchemeName1Choice" AS (
    "Code" public."ExternalOrganisationIdentification1Code",
    "Proprietary" public."Max35Text"
);
ALTER TYPE public."OrganisationIdentificationSchemeName1Choice" OWNER TO postgres;
COMMENT ON TYPE public."OrganisationIdentificationSchemeName1Choice" IS
'Definition: Name of the identification scheme.

{Or}/{Or} choice -- exactly one branch must be set:
Code: Name of the identification scheme, in a coded form as published in an external list.
Proprietary: Name of the identification scheme, in a free text form.';
DROP FUNCTION IF EXISTS public.validate_organisation_identification_scheme_name1_choice(public."OrganisationIdentificationSchemeName1Choice");
CREATE OR REPLACE FUNCTION public.validate_organisation_identification_scheme_name1_choice(
    val public."OrganisationIdentificationSchemeName1Choice")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN ((val."Code" IS NOT NULL)::int + (val."Proprietary" IS NOT NULL)::int) = 1;
END;
$BODY$;
ALTER FUNCTION public.validate_organisation_identification_scheme_name1_choice(public."OrganisationIdentificationSchemeName1Choice")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_organisation_identification_scheme_name1_choice(public."OrganisationIdentificationSchemeName1Choice") IS
'Checks the {Or}/{Or} choice: exactly one of Code, Proprietary is set. Composite-typed branches use num_nonnulls() over their own fields rather than a plain IS NOT NULL, since Postgress row-wise NULL semantics make IS NOT NULL true only when ALL of a composites fields are non-null -- wrong for a branch type whose fields are individually optional.';
-- Type: GenericOrganisationIdentification3 (inline, 10.1.12.1.3.1.3)
DROP TYPE IF EXISTS public."GenericOrganisationIdentification3" CASCADE;
CREATE TYPE public."GenericOrganisationIdentification3" AS (
    "Identification" public."Max256Text",
    "SchemeName" public."OrganisationIdentificationSchemeName1Choice",
    "Issuer" public."Max35Text"
);
ALTER TYPE public."GenericOrganisationIdentification3" OWNER TO postgres;
COMMENT ON TYPE public."GenericOrganisationIdentification3" IS
'Definition: Unique identification of an organisation, as assigned by an institution, using an identification scheme.

Identification: [1..1] Identification assigned by an institution.
SchemeName: [0..1] Name of the identification scheme.
Issuer: [0..1] Entity that assigns the identification.';
DROP FUNCTION IF EXISTS public.validate_generic_organisation_identification3(public."GenericOrganisationIdentification3");
CREATE OR REPLACE FUNCTION public.validate_generic_organisation_identification3(
    val public."GenericOrganisationIdentification3")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN (val."Identification" IS NOT NULL);
END;
$BODY$;
ALTER FUNCTION public.validate_generic_organisation_identification3(public."GenericOrganisationIdentification3")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_generic_organisation_identification3(public."GenericOrganisationIdentification3") IS
'Checks the [1..1] mandatory field(s) (Identification) are present.';
-- Type: OrganisationIdentification39 (inline, 10.1.12.1.3.1)
DROP TYPE IF EXISTS public."OrganisationIdentification39" CASCADE;
CREATE TYPE public."OrganisationIdentification39" AS (
    "AnyBIC" public."AnyBICDec2014Identifier",
    "LEI" public."LEIIdentifier",
    "Other" public."GenericOrganisationIdentification3"[]
);
ALTER TYPE public."OrganisationIdentification39" OWNER TO postgres;
COMMENT ON TYPE public."OrganisationIdentification39" IS
'Definition: Unique and unambiguous way to identify an organisation.

AnyBIC: [0..1] Business identification code of the organisation. Constraint C4 "AnyBIC" -- format already enforced by the AnyBICDec2014Identifier domain (10.2).
LEI: [0..1] Legal entity identification as an alternate identification for a party.
Other: [0..*] Unique identification using an identification scheme -- repeatable, modeled as an array of GenericOrganisationIdentification3 (unbounded).

All fields optional -- no validate_ function needed at this level.';
-- Type: DateAndPlaceOfBirth1 (inline, 10.1.12.1.3.2.1)
DROP TYPE IF EXISTS public."DateAndPlaceOfBirth1" CASCADE;
CREATE TYPE public."DateAndPlaceOfBirth1" AS (
    "BirthDate" public."ISODate",
    "ProvinceOfBirth" public."Max35Text",
    "CityOfBirth" public."Max35Text",
    "CountryOfBirth" public."CountryCode"
);
ALTER TYPE public."DateAndPlaceOfBirth1" OWNER TO postgres;
COMMENT ON TYPE public."DateAndPlaceOfBirth1" IS
'Definition: Date and place of birth of a person.

BirthDate: [1..1] Date on which a person is born.
ProvinceOfBirth: [0..1] Province where a person was born.
CityOfBirth: [1..1] City where a person was born.
CountryOfBirth: [1..1] Country where a person was born. Constraint C10 "Country" -- format already enforced by the CountryCode domain (10.2).';
DROP FUNCTION IF EXISTS public.validate_date_and_place_of_birth1(public."DateAndPlaceOfBirth1");
CREATE OR REPLACE FUNCTION public.validate_date_and_place_of_birth1(
    val public."DateAndPlaceOfBirth1")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN (val."BirthDate" IS NOT NULL)
        AND (val."CityOfBirth" IS NOT NULL)
        AND (val."CountryOfBirth" IS NOT NULL);
END;
$BODY$;
ALTER FUNCTION public.validate_date_and_place_of_birth1(public."DateAndPlaceOfBirth1")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_date_and_place_of_birth1(public."DateAndPlaceOfBirth1") IS
'Checks the [1..1] mandatory field(s) (BirthDate, CityOfBirth, CountryOfBirth) are present.';
-- Type: PersonIdentificationSchemeName1Choice (inline, 10.1.12.1.3.2.2.2)
DROP TYPE IF EXISTS public."PersonIdentificationSchemeName1Choice" CASCADE;
CREATE TYPE public."PersonIdentificationSchemeName1Choice" AS (
    "Code" public."ExternalPersonIdentification1Code",
    "Proprietary" public."Max35Text"
);
ALTER TYPE public."PersonIdentificationSchemeName1Choice" OWNER TO postgres;
COMMENT ON TYPE public."PersonIdentificationSchemeName1Choice" IS
'Definition: Name of the identification scheme.

{Or}/{Or} choice -- exactly one branch must be set:
Code: Name of the identification scheme, in a coded form as published in an external list.
Proprietary: Name of the identification scheme, in a free text form.';
DROP FUNCTION IF EXISTS public.validate_person_identification_scheme_name1_choice(public."PersonIdentificationSchemeName1Choice");
CREATE OR REPLACE FUNCTION public.validate_person_identification_scheme_name1_choice(
    val public."PersonIdentificationSchemeName1Choice")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN ((val."Code" IS NOT NULL)::int + (val."Proprietary" IS NOT NULL)::int) = 1;
END;
$BODY$;
ALTER FUNCTION public.validate_person_identification_scheme_name1_choice(public."PersonIdentificationSchemeName1Choice")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_person_identification_scheme_name1_choice(public."PersonIdentificationSchemeName1Choice") IS
'Checks the {Or}/{Or} choice: exactly one of Code, Proprietary is set. Composite-typed branches use num_nonnulls() over their own fields rather than a plain IS NOT NULL, since Postgress row-wise NULL semantics make IS NOT NULL true only when ALL of a composites fields are non-null -- wrong for a branch type whose fields are individually optional.';
-- Type: GenericPersonIdentification2 (inline, 10.1.12.1.3.2.2)
DROP TYPE IF EXISTS public."GenericPersonIdentification2" CASCADE;
CREATE TYPE public."GenericPersonIdentification2" AS (
    "Identification" public."Max256Text",
    "SchemeName" public."PersonIdentificationSchemeName1Choice",
    "Issuer" public."Max35Text"
);
ALTER TYPE public."GenericPersonIdentification2" OWNER TO postgres;
COMMENT ON TYPE public."GenericPersonIdentification2" IS
'Definition: Unique identification of a person, as assigned by an institution, using an identification scheme.

Identification: [1..1] Unique and unambiguous identification of a person.
SchemeName: [0..1] Name of the identification scheme.
Issuer: [0..1] Entity that assigns the identification.';
DROP FUNCTION IF EXISTS public.validate_generic_person_identification2(public."GenericPersonIdentification2");
CREATE OR REPLACE FUNCTION public.validate_generic_person_identification2(
    val public."GenericPersonIdentification2")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN (val."Identification" IS NOT NULL);
END;
$BODY$;
ALTER FUNCTION public.validate_generic_person_identification2(public."GenericPersonIdentification2")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_generic_person_identification2(public."GenericPersonIdentification2") IS
'Checks the [1..1] mandatory field(s) (Identification) are present.';
-- Type: PersonIdentification18 (inline, 10.1.12.1.3.2)
DROP TYPE IF EXISTS public."PersonIdentification18" CASCADE;
CREATE TYPE public."PersonIdentification18" AS (
    "DateAndPlaceOfBirth" public."DateAndPlaceOfBirth1",
    "Other" public."GenericPersonIdentification2"[]
);
ALTER TYPE public."PersonIdentification18" OWNER TO postgres;
COMMENT ON TYPE public."PersonIdentification18" IS
'Definition: Unique and unambiguous identification of a person, for example a passport.

DateAndPlaceOfBirth: [0..1] Date and place of birth of a person.
Other: [0..*] Unique identification using an identification scheme -- repeatable, modeled as an array of GenericPersonIdentification2 (unbounded).

Both fields optional -- no validate_ function needed at this level (DateAndPlaceOfBirth1s own required fields are checked by validate_date_and_place_of_birth1).';
-- Type: Party52Choice (inline, 10.1.12.1.3)
DROP TYPE IF EXISTS public."Party52Choice" CASCADE;
CREATE TYPE public."Party52Choice" AS (
    "OrganisationIdentification" public."OrganisationIdentification39",
    "PrivateIdentification" public."PersonIdentification18"
);
ALTER TYPE public."Party52Choice" OWNER TO postgres;
COMMENT ON TYPE public."Party52Choice" IS
'Definition: Unique and unambiguous identification of a party.

{Or}/{Or} choice -- exactly one branch must be set:
OrganisationIdentification: Unique and unambiguous way to identify an organisation.
PrivateIdentification: Unique and unambiguous identification of a person, for example a passport.';
DROP FUNCTION IF EXISTS public.validate_party52_choice(public."Party52Choice");
CREATE OR REPLACE FUNCTION public.validate_party52_choice(
    val public."Party52Choice")
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
    RETURN ((num_nonnulls((val."OrganisationIdentification")."AnyBIC", (val."OrganisationIdentification")."LEI", (val."OrganisationIdentification")."Other") > 0)::int + (num_nonnulls((val."PrivateIdentification")."DateAndPlaceOfBirth", (val."PrivateIdentification")."Other") > 0)::int) = 1;
END;
$BODY$;
ALTER FUNCTION public.validate_party52_choice(public."Party52Choice")
    OWNER TO postgres;
COMMENT ON FUNCTION public.validate_party52_choice(public."Party52Choice") IS
'Checks the {Or}/{Or} choice: exactly one of OrganisationIdentification, PrivateIdentification is set. Composite-typed branches use num_nonnulls() over their own fields rather than a plain IS NOT NULL, since Postgress row-wise NULL semantics make IS NOT NULL true only when ALL of a composites fields are non-null -- wrong for a branch type whose fields are individually optional.';
-- Type: PartyIdentification272 (10.1.12.1)
DROP TYPE IF EXISTS public."PartyIdentification272" CASCADE;
CREATE TYPE public."PartyIdentification272" AS (
    "Name" public."Max140Text",
    "PostalAddress" public."PostalAddress27",
    "Identification" public."Party52Choice",
    "CountryOfResidence" public."CountryCode",
    "ContactDetails" public."Contact13"
);
ALTER TYPE public."PartyIdentification272" OWNER TO postgres;
COMMENT ON TYPE public."PartyIdentification272" IS
'Definition: Specifies the identification of a person or an organisation.

Name: [0..1] Name by which a party is known.
PostalAddress: [0..1] Reuses PostalAddress27.
Identification: [0..1] Party52Choice -- exclusive choice between OrganisationIdentification and PrivateIdentification paths.
CountryOfResidence: [0..1] Constraint C10 "Country" -- format enforced by the CountryCode domain.
ContactDetails: [0..1] Reuses Contact13.

All top-level fields are optional -- no validate_ function needed at the PartyIdentification272 level itself. Its sub-fields carry their own validation: validate_party52_choice for the exactly-one-of Identification rule if populated, validate_postal_address27 for the AddressLine bound, and the required-field checks on the nested Generic*Identification/DateAndPlaceOfBirth1 types.';
