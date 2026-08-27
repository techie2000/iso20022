#!/usr/bin/env python3
"""
Generates PostgreSQL DDL for ISO 20022 MDR Part 2, Section 10.1 "Message
Components" -- FILE 2 of 4: Identity & Contact.

Covers: 10.1.15 Person Identification (Contact13), 10.1.16 Postal Address
(PostalAddress27), 10.1.12 Party Identification (PartyIdentification272).

Depends on: 10.2 Message Datatypes, and File 1 (GenericIdentification30).
Load order: after File 1, before Files 3-4.
"""

out = []

def emit(sql):
    out.append(sql.rstrip() + "\n")

def sqlstr(s):
    _normalize = {
        '\u2018': "'", '\u2019': "'", '\u201c': '"', '\u201d': '"',
        '\u2013': '-', '\u2014': '-', '\u2026': '...', '\u00a0': ' ',
    }
    for orig, repl in _normalize.items():
        s = s.replace(orig, repl)
    return "'" + s.replace("'", "''") + "'"

def snake(name):
    return 'validate_' + ''.join(
        ['_' + c.lower() if c.isupper() and i > 0 and not name[i-1].isupper() else c.lower()
         for i, c in enumerate(name)]
    ).lstrip('_')

import sys
sys.path.insert(0, '/home/claude')
from type_registry import load_registry, save_registry

TYPE_FIELDS = load_registry()

def strip_type(ft):
    """'public."Foo"' -> 'Foo'; arrays and non-composite refs -> None."""
    if ft.endswith('[]'):
        return None
    if ft.startswith('public."') and ft.endswith('"'):
        return ft[len('public."'):-1]
    return None

def branch_populated_expr(fn, ft):
    """
    Expression checking whether a Choice branch is meaningfully populated.
    Plain 'val."X" IS NOT NULL' is WRONG when X's type is itself a composite
    with a MIX of null/non-null fields: Postgres row-wise NULL semantics
    define composite IS NOT NULL as true only when EVERY field is non-null
    (and IS NULL as true only when EVERY field is null) -- so a composite
    with some-but-not-all fields set is neither NULL nor NOT NULL, and a
    naive IS NOT NULL check silently misses it. num_nonnulls() over the
    composite's own fields is the correct test.
    """
    inner = strip_type(ft)
    if inner and inner in TYPE_FIELDS:
        args = ", ".join(f'(val."{fn}")."{sf}"' for sf in TYPE_FIELDS[inner])
        return f'num_nonnulls({args}) > 0'
    return f'val."{fn}" IS NOT NULL'

def choice_type(name, branches, section_ref, definition, usage=None):
    emit(f'-- Type: {name} ({section_ref})')
    emit(f'DROP TYPE IF EXISTS public."{name}" CASCADE;')
    emit(f'CREATE TYPE public."{name}" AS (')
    emit(",\n".join(f'    "{fn}" {ft}' for fn, ft, _ in branches))
    emit(');')
    emit(f'ALTER TYPE public."{name}" OWNER TO postgres;')
    comment = f'Definition: {definition}\n\n'
    if usage:
        comment += f'Usage: {usage}\n\n'
    comment += '{Or}/{Or} choice -- exactly one branch must be set:\n'
    for fn, ft, bd in branches:
        comment += f'{fn}: {bd}\n'
    emit(f'COMMENT ON TYPE public."{name}" IS')
    emit(sqlstr(comment.strip()) + ';\n')
    fn_name = snake(name)
    emit(f'DROP FUNCTION IF EXISTS public.{fn_name}(public."{name}");')
    emit(f'CREATE OR REPLACE FUNCTION public.{fn_name}(')
    emit(f'    val public."{name}")')
    emit('    RETURNS boolean')
    emit("    LANGUAGE 'plpgsql'")
    emit('    COST 100')
    emit('    IMMUTABLE PARALLEL UNSAFE')
    emit('AS $BODY$')
    emit('BEGIN')
    checks = " + ".join(f'({branch_populated_expr(fn, ft)})::int' for fn, ft, _ in branches)
    emit(f'    RETURN ({checks}) = 1;')
    emit('END;')
    emit('$BODY$;')
    emit(f'ALTER FUNCTION public.{fn_name}(public."{name}")')
    emit('    OWNER TO postgres;')
    emit(f'COMMENT ON FUNCTION public.{fn_name}(public."{name}") IS')
    emit(sqlstr(f'Checks the {{Or}}/{{Or}} choice: exactly one of '
                f'{", ".join(fn for fn, _, _ in branches)} is set. Composite-typed branches use '
                f'num_nonnulls() over their own fields rather than a plain IS NOT NULL, since Postgres''s '
                f'row-wise NULL semantics make IS NOT NULL true only when ALL of a composite''s fields are '
                f'non-null -- wrong for a branch type whose fields are individually optional.') + ';\n')
    TYPE_FIELDS[name] = [fn for fn, _, _ in branches]
    return fn_name

def simple_type(name, fields, section_ref, definition, required, extra_comment=None):
    emit(f'-- Type: {name} ({section_ref})')
    emit(f'DROP TYPE IF EXISTS public."{name}" CASCADE;')
    emit(f'CREATE TYPE public."{name}" AS (')
    emit(",\n".join(f'    "{fn}" {ft}' for fn, ft, _ in fields))
    emit(');')
    emit(f'ALTER TYPE public."{name}" OWNER TO postgres;')
    comment = f'Definition: {definition}\n\n'
    for fn, ft, fc in fields:
        mult = '[1..1]' if fn in required else '[0..1]'
        comment += f'{fn}: {mult} {fc}\n'
    if extra_comment:
        comment += '\n' + extra_comment
    emit(f'COMMENT ON TYPE public."{name}" IS')
    emit(sqlstr(comment.strip()) + ';\n')
    if required:
        fn_name = snake(name)
        emit(f'DROP FUNCTION IF EXISTS public.{fn_name}(public."{name}");')
        emit(f'CREATE OR REPLACE FUNCTION public.{fn_name}(')
        emit(f'    val public."{name}")')
        emit('    RETURNS boolean')
        emit("    LANGUAGE 'plpgsql'")
        emit('    COST 100')
        emit('    IMMUTABLE PARALLEL UNSAFE')
        emit('AS $BODY$')
        emit('BEGIN')
        checks = "\n        AND ".join(f'({branch_populated_expr(fn, ft)})'
                                        for fn, ft, _ in fields if fn in required)
        emit(f'    RETURN {checks};')
        emit('END;')
        emit('$BODY$;')
        emit(f'ALTER FUNCTION public.{fn_name}(public."{name}")')
        emit('    OWNER TO postgres;')
        emit(f'COMMENT ON FUNCTION public.{fn_name}(public."{name}") IS')
        emit(sqlstr(f'Checks the [1..1] mandatory field(s) ({", ".join(required)}) are present.') + ';\n')
        TYPE_FIELDS[name] = [fn for fn, _, _ in fields]
        return fn_name
    TYPE_FIELDS[name] = [fn for fn, _, _ in fields]
    return None

HEADER = '''-- =====================================================================
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

'''
emit(HEADER)

# ---------------------------------------------------------------------
# PART 1 -- 10.1.15 Person Identification: Contact13
# ---------------------------------------------------------------------
emit('-- ---------------------------------------------------------------------')
emit('-- PART 1 -- 10.1.15 Person Identification')
emit('-- ---------------------------------------------------------------------\n')

# OtherContact1 (inline, referenced from Contact13.Other, [0..*])
simple_type("OtherContact1", [
    ("ChannelType", 'public."Max4Text"', 'Method used to contact the financial institution''s contact for the specific tax region.'),
    ("Identification", 'public."Max128Text"', 'Communication value such as phone number or email address.'),
], "inline, 10.1.15.1.12", "Contact details in another form.",
   required=["ChannelType"])

# Contact13 (10.1.15.1)
emit('-- Type: Contact13 (10.1.15.1)')
emit('DROP TYPE IF EXISTS public."Contact13" CASCADE;')
emit('CREATE TYPE public."Contact13" AS (')
emit('    "NamePrefix" public."NamePrefix2Code",')
emit('    "Name" public."Max140Text",')
emit('    "PhoneNumber" public."PhoneNumber",')
emit('    "MobileNumber" public."PhoneNumber",')
emit('    "FaxNumber" public."PhoneNumber",')
emit('    "URLAddress" public."Max2048Text",')
emit('    "EmailAddress" public."Max256Text",')
emit('    "EmailPurpose" public."Max35Text",')
emit('    "JobTitle" public."Max35Text",')
emit('    "Responsibility" public."Max35Text",')
emit('    "Department" public."Max70Text",')
emit('    "Other" public."OtherContact1"[],')
emit('    "PreferredMethod" public."PreferredContactMethod2Code"')
emit(');')
emit('ALTER TYPE public."Contact13" OWNER TO postgres;')
emit('COMMENT ON TYPE public."Contact13" IS')
emit(sqlstr('Definition: Specifies the details of the contact person.\n\n'
            'All fields [0..1] except Other, which is [0..*] (repeatable, modeled as an array of '
            'OtherContact1 -- unbounded, no max given).\n\n'
            'NamePrefix, Name, PhoneNumber, MobileNumber, FaxNumber, URLAddress, EmailAddress, '
            'EmailPurpose, JobTitle, Responsibility, Department: self-explanatory contact fields.\n'
            'Other: [0..*] Contact details in another form.\n'
            'PreferredMethod: [0..1] Preferred method used to reach the contact.\n\n'
            'All fields optional -- no validate_ function needed at this level.') + ';\n')
TYPE_FIELDS["Contact13"] = ["NamePrefix", "Name", "PhoneNumber", "MobileNumber", "FaxNumber",
                            "URLAddress", "EmailAddress", "EmailPurpose", "JobTitle",
                            "Responsibility", "Department", "Other", "PreferredMethod"]

with open('/home/claude/sql_10_1_file2.sql', 'w') as f:
    f.writelines(out)
print("Part 1 complete")

# ---------------------------------------------------------------------
# PART 2 -- 10.1.16 Postal Address: PostalAddress27
# ---------------------------------------------------------------------
emit('-- ---------------------------------------------------------------------')
emit('-- PART 2 -- 10.1.16 Postal Address')
emit('-- ---------------------------------------------------------------------\n')

# AddressType3Choice (inline, referenced from PostalAddress27.AddressType)
choice_type("AddressType3Choice", [
    ("Code", 'public."AddressType2Code"', 'Type of address expressed as a code (ADDR/PBOX/HOME/BIZZ/MLTO/DLVY).'),
    ("Proprietary", 'public."GenericIdentification30"', 'Type of address expressed as a proprietary code. Reuses GenericIdentification30 (File 1).'),
], "inline, 10.1.16.1.1", "Identifies the nature of the postal address.")

# PostalAddress27 (10.1.16.1)
emit('-- Type: PostalAddress27 (10.1.16.1)')
emit('DROP TYPE IF EXISTS public."PostalAddress27" CASCADE;')
emit('CREATE TYPE public."PostalAddress27" AS (')
emit('    "AddressType" public."AddressType3Choice",')
emit('    "CareOf" public."Max140Text",')
emit('    "Department" public."Max70Text",')
emit('    "SubDepartment" public."Max70Text",')
emit('    "StreetName" public."Max140Text",')
emit('    "BuildingNumber" public."Max16Text",')
emit('    "BuildingName" public."Max140Text",')
emit('    "Floor" public."Max70Text",')
emit('    "UnitNumber" public."Max16Text",')
emit('    "PostBox" public."Max16Text",')
emit('    "Room" public."Max70Text",')
emit('    "PostCode" public."Max16Text",')
emit('    "TownName" public."Max140Text",')
emit('    "TownLocationName" public."Max140Text",')
emit('    "DistrictName" public."Max140Text",')
emit('    "CountrySubDivision" public."Max140Text",')
emit('    "Country" public."CountryCode",')
emit('    "AddressLine" public."Max70Text"[]')
emit(');')
emit('ALTER TYPE public."PostalAddress27" OWNER TO postgres;')
emit('COMMENT ON TYPE public."PostalAddress27" IS')
emit(sqlstr('Definition: Information that locates and identifies a specific address, as defined by postal services.\n\n'
            'All fields [0..1] except AddressLine, which is [0..7] -- modeled as an array, bounded by the '
            'validate_ function below (Postgres arrays have no inherent max-length constraint).\n\n'
            'Country: Constraint C10 "Country" applies (checked against the UN/ISO 3166 list -- see the '
            'CountryCode domain from 10.2, which enforces format only).\n\n'
            'AddressLine: [0..7] Free-format address lines.') + ';\n')

emit('DROP FUNCTION IF EXISTS public.validate_postal_address27(public."PostalAddress27");')
emit('CREATE OR REPLACE FUNCTION public.validate_postal_address27(')
emit('    val public."PostalAddress27")')
emit('    RETURNS boolean')
emit("    LANGUAGE 'plpgsql'")
emit('    COST 100')
emit('    IMMUTABLE PARALLEL UNSAFE')
emit('AS $BODY$')
emit('BEGIN')
emit('    RETURN val."AddressLine" IS NULL OR array_length(val."AddressLine", 1) <= 7;')
emit('END;')
emit('$BODY$;')
emit('ALTER FUNCTION public.validate_postal_address27(public."PostalAddress27")')
emit('    OWNER TO postgres;')
emit('COMMENT ON FUNCTION public.validate_postal_address27(public."PostalAddress27") IS')
emit(sqlstr('Checks the AddressLine array does not exceed its [0..7] bound from the MDR '
            '(Postgres arrays have no inherent max-length constraint, unlike varchar(n)).') + ';\n')
TYPE_FIELDS["PostalAddress27"] = ["AddressType", "CareOf", "Department", "SubDepartment", "StreetName",
                                  "BuildingNumber", "BuildingName", "Floor", "UnitNumber", "PostBox",
                                  "Room", "PostCode", "TownName", "TownLocationName", "DistrictName",
                                  "CountrySubDivision", "Country", "AddressLine"]

with open('/home/claude/sql_10_1_file2.sql', 'w') as f:
    f.writelines(out)
print("Part 2 complete")

# ---------------------------------------------------------------------
# PART 3 -- 10.1.12 Party Identification: PartyIdentification272 and its
# full dependency chain (9 types deep, all inline sub-types named per the
# MDR's own in-text references).
# ---------------------------------------------------------------------
emit('-- ---------------------------------------------------------------------')
emit('-- PART 3 -- 10.1.12 Party Identification')
emit('-- ---------------------------------------------------------------------\n')

# 1. OrganisationIdentificationSchemeName1Choice
choice_type("OrganisationIdentificationSchemeName1Choice", [
    ("Code", 'public."ExternalOrganisationIdentification1Code"', 'Name of the identification scheme, in a coded form as published in an external list.'),
    ("Proprietary", 'public."Max35Text"', 'Name of the identification scheme, in a free text form.'),
], "inline, 10.1.12.1.3.1.3.2", "Name of the identification scheme.")

# 2. GenericOrganisationIdentification3
simple_type("GenericOrganisationIdentification3", [
    ("Identification", 'public."Max256Text"', 'Identification assigned by an institution.'),
    ("SchemeName", 'public."OrganisationIdentificationSchemeName1Choice"', 'Name of the identification scheme.'),
    ("Issuer", 'public."Max35Text"', 'Entity that assigns the identification.'),
], "inline, 10.1.12.1.3.1.3", "Unique identification of an organisation, as assigned by an institution, using an identification scheme.",
   required=["Identification"])

# 3. OrganisationIdentification39
emit('-- Type: OrganisationIdentification39 (inline, 10.1.12.1.3.1)')
emit('DROP TYPE IF EXISTS public."OrganisationIdentification39" CASCADE;')
emit('CREATE TYPE public."OrganisationIdentification39" AS (')
emit('    "AnyBIC" public."AnyBICDec2014Identifier",')
emit('    "LEI" public."LEIIdentifier",')
emit('    "Other" public."GenericOrganisationIdentification3"[]')
emit(');')
emit('ALTER TYPE public."OrganisationIdentification39" OWNER TO postgres;')
emit('COMMENT ON TYPE public."OrganisationIdentification39" IS')
emit(sqlstr('Definition: Unique and unambiguous way to identify an organisation.\n\n'
            'AnyBIC: [0..1] Business identification code of the organisation. Constraint C4 "AnyBIC" -- '
            'format already enforced by the AnyBICDec2014Identifier domain (10.2).\n'
            'LEI: [0..1] Legal entity identification as an alternate identification for a party.\n'
            'Other: [0..*] Unique identification using an identification scheme -- repeatable, modeled as an '
            'array of GenericOrganisationIdentification3 (unbounded).\n\n'
            'All fields optional -- no validate_ function needed at this level.') + ';\n')
TYPE_FIELDS["OrganisationIdentification39"] = ["AnyBIC", "LEI", "Other"]

# 4. DateAndPlaceOfBirth1
simple_type("DateAndPlaceOfBirth1", [
    ("BirthDate", 'public."ISODate"', 'Date on which a person is born.'),
    ("ProvinceOfBirth", 'public."Max35Text"', 'Province where a person was born.'),
    ("CityOfBirth", 'public."Max35Text"', 'City where a person was born.'),
    ("CountryOfBirth", 'public."CountryCode"', 'Country where a person was born. Constraint C10 "Country" -- '
     'format already enforced by the CountryCode domain (10.2).'),
], "inline, 10.1.12.1.3.2.1", "Date and place of birth of a person.",
   required=["BirthDate", "CityOfBirth", "CountryOfBirth"])

# 5. PersonIdentificationSchemeName1Choice
choice_type("PersonIdentificationSchemeName1Choice", [
    ("Code", 'public."ExternalPersonIdentification1Code"', 'Name of the identification scheme, in a coded form as published in an external list.'),
    ("Proprietary", 'public."Max35Text"', 'Name of the identification scheme, in a free text form.'),
], "inline, 10.1.12.1.3.2.2.2", "Name of the identification scheme.")

# 6. GenericPersonIdentification2
simple_type("GenericPersonIdentification2", [
    ("Identification", 'public."Max256Text"', 'Unique and unambiguous identification of a person.'),
    ("SchemeName", 'public."PersonIdentificationSchemeName1Choice"', 'Name of the identification scheme.'),
    ("Issuer", 'public."Max35Text"', 'Entity that assigns the identification.'),
], "inline, 10.1.12.1.3.2.2", "Unique identification of a person, as assigned by an institution, using an identification scheme.",
   required=["Identification"])

# 7. PersonIdentification18
emit('-- Type: PersonIdentification18 (inline, 10.1.12.1.3.2)')
emit('DROP TYPE IF EXISTS public."PersonIdentification18" CASCADE;')
emit('CREATE TYPE public."PersonIdentification18" AS (')
emit('    "DateAndPlaceOfBirth" public."DateAndPlaceOfBirth1",')
emit('    "Other" public."GenericPersonIdentification2"[]')
emit(');')
emit('ALTER TYPE public."PersonIdentification18" OWNER TO postgres;')
emit('COMMENT ON TYPE public."PersonIdentification18" IS')
emit(sqlstr('Definition: Unique and unambiguous identification of a person, for example a passport.\n\n'
            'DateAndPlaceOfBirth: [0..1] Date and place of birth of a person.\n'
            'Other: [0..*] Unique identification using an identification scheme -- repeatable, modeled as an '
            'array of GenericPersonIdentification2 (unbounded).\n\n'
            'Both fields optional -- no validate_ function needed at this level (DateAndPlaceOfBirth1''s own '
            'required fields are checked by validate_date_and_place_of_birth1).') + ';\n')
TYPE_FIELDS["PersonIdentification18"] = ["DateAndPlaceOfBirth", "Other"]

# 8. Party52Choice -- exclusive choice between the two identification paths
choice_type("Party52Choice", [
    ("OrganisationIdentification", 'public."OrganisationIdentification39"', 'Unique and unambiguous way to identify an organisation.'),
    ("PrivateIdentification", 'public."PersonIdentification18"', 'Unique and unambiguous identification of a person, for example a passport.'),
], "inline, 10.1.12.1.3", "Unique and unambiguous identification of a party.")

# 9. PartyIdentification272 -- the top-level component
emit('-- Type: PartyIdentification272 (10.1.12.1)')
emit('DROP TYPE IF EXISTS public."PartyIdentification272" CASCADE;')
emit('CREATE TYPE public."PartyIdentification272" AS (')
emit('    "Name" public."Max140Text",')
emit('    "PostalAddress" public."PostalAddress27",')
emit('    "Identification" public."Party52Choice",')
emit('    "CountryOfResidence" public."CountryCode",')
emit('    "ContactDetails" public."Contact13"')
emit(');')
emit('ALTER TYPE public."PartyIdentification272" OWNER TO postgres;')
emit('COMMENT ON TYPE public."PartyIdentification272" IS')
emit(sqlstr('Definition: Specifies the identification of a person or an organisation.\n\n'
            'Name: [0..1] Name by which a party is known.\n'
            'PostalAddress: [0..1] Reuses PostalAddress27.\n'
            'Identification: [0..1] Party52Choice -- exclusive choice between OrganisationIdentification and '
            'PrivateIdentification paths.\n'
            'CountryOfResidence: [0..1] Constraint C10 "Country" -- format enforced by the CountryCode domain.\n'
            'ContactDetails: [0..1] Reuses Contact13.\n\n'
            'All top-level fields are optional -- no validate_ function needed at the PartyIdentification272 '
            'level itself. Its sub-fields carry their own validation: validate_party52_choice for the exactly-'
            'one-of Identification rule if populated, validate_postal_address27 for the AddressLine bound, '
            'and the required-field checks on the nested Generic*Identification/DateAndPlaceOfBirth1 types.') + ';\n')
TYPE_FIELDS["PartyIdentification272"] = ["Name", "PostalAddress", "Identification", "CountryOfResidence", "ContactDetails"]

with open('/home/claude/sql_10_1_file2.sql', 'w') as f:
    f.writelines(out)
save_registry(TYPE_FIELDS)
print("Part 3 complete -- FILE 2 GENERATION DONE")
