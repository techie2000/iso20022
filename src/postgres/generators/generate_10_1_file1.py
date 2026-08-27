#!/usr/bin/env python3
"""
Generates PostgreSQL DDL for ISO 20022 MDR Part 2, Section 10.1 "Message
Components" -- FILE 1 of 4: foundational & standalone subsections (no
dependency on other 10.1 components).

Covers: 10.1.3 Amount, 10.1.4 Date Period, 10.1.5 Date Time, 10.1.8
Frequency, 10.1.9 Identification Information, 10.1.10 Mandate,
10.1.11 Miscellaneous, 10.1.13 Payment, 10.1.14 Payment Type,
10.1.19 System Identification, 10.1.20 Tax.

Source PDF pages: 748-750, 760-774, 784-791, 843-845 (interleaved with
other subsections not in this file).

Conventions (continuing from 10.2, with one change noted below):
  * schema public, exact MDR PascalCase names double-quoted, OWNER TO postgres
  * every object COMMENT-documented with the MDR's own text
  * {Or}/{Or} Choice groups -> composite TYPE (all branches nullable) +
    validate_ function checking exactly one branch is set
  * non-exclusive "at least one of" business rules -> composite TYPE +
    validate_ function checking the actual rule (not exactly-one)
  * repeatable elements ([0..n], [0..*]) -> Postgres array of the element
    type, since child tables need a TABLE parent with a PK, which doesn't
    exist at this pure-type-library layer (see project README)
  * active DROP ... IF EXISTS ... CASCADE before every CREATE (idempotent
    re-runs), matching the fix applied to 10.2
  * NAMING CHANGE from 10.2: composite type fields use the MDR's FULL
    element name (e.g. "FromDate", "InstructionIdentification"), not the
    XML tag abbreviation -- matching the user's own pre-existing
    DatePeriod2/validate_date_period code exactly, rather than the Amt/Ccy
    abbreviation style used for the two Amount+Currency types in 10.2.
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

HEADER = '''-- =====================================================================
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

'''
emit(HEADER)

# ---------------------------------------------------------------------
# PART 1 -- Simple standalone composites (no nested Choice sub-types)
# ---------------------------------------------------------------------
emit('-- ---------------------------------------------------------------------')
emit('-- PART 1 -- Simple standalone composites')
emit('-- ---------------------------------------------------------------------\n')

# DatePeriod2 -- reproduced to match the user's own pre-existing style exactly
emit('-- Type: DatePeriod2 (10.1.4.1)')
emit('DROP TYPE IF EXISTS public."DatePeriod2" CASCADE;')
emit('CREATE TYPE public."DatePeriod2" AS (')
emit('    "FromDate" public."ISODate",')
emit('    "ToDate" public."ISODate"')
emit(');')
emit('ALTER TYPE public."DatePeriod2" OWNER TO postgres;')
emit('COMMENT ON TYPE public."DatePeriod2" IS')
emit(sqlstr('Definition: Range of time defined by a start date and an end date.\n\n'
            'FromDate: Start date of the range.\n'
            'ToDate: End date of the range.') + ';\n')

emit('-- FUNCTION: validate_date_period("DatePeriod2")')
emit('DROP FUNCTION IF EXISTS public.validate_date_period(public."DatePeriod2");')
emit('CREATE OR REPLACE FUNCTION public.validate_date_period(')
emit('    period public."DatePeriod2")')
emit('    RETURNS boolean')
emit("    LANGUAGE 'plpgsql'")
emit('    COST 100')
emit('    IMMUTABLE PARALLEL UNSAFE')
emit('AS $BODY$')
emit('BEGIN')
emit('    RETURN period."FromDate" IS NOT NULL')
emit('        AND period."ToDate" IS NOT NULL')
emit('        AND period."FromDate" <= period."ToDate";')
emit('END;')
emit('$BODY$;')
emit('ALTER FUNCTION public.validate_date_period(public."DatePeriod2")')
emit('    OWNER TO postgres;')
emit('COMMENT ON FUNCTION public.validate_date_period(public."DatePeriod2") IS')
emit(sqlstr('Validates a DatePeriod2 value: both dates present and FromDate <= ToDate. '
            'Reproduced to match the pre-existing convention this project was built on.') + ';\n')

# GenericIdentification3 (10.1.9.3)
emit('-- Type: GenericIdentification3 (10.1.9.3)')
emit('DROP TYPE IF EXISTS public."GenericIdentification3" CASCADE;')
emit('CREATE TYPE public."GenericIdentification3" AS (')
emit('    "Identification" public."Max35Text",')
emit('    "Issuer" public."Max35Text"')
emit(');')
emit('ALTER TYPE public."GenericIdentification3" OWNER TO postgres;')
emit('COMMENT ON TYPE public."GenericIdentification3" IS')
emit(sqlstr('Definition: Information related to an identification, for example, party '
            'identification or account identification.\n\n'
            'Identification: [1..1] Name or number assigned by an entity to enable '
            'recognition of that entity, for example, account identifier.\n'
            'Issuer: [0..1] Entity that assigns the identification.') + ';\n')
emit('DROP FUNCTION IF EXISTS public.validate_generic_identification3(public."GenericIdentification3");')
emit('CREATE OR REPLACE FUNCTION public.validate_generic_identification3(')
emit('    val public."GenericIdentification3")')
emit('    RETURNS boolean')
emit("    LANGUAGE 'plpgsql'")
emit('    COST 100')
emit('    IMMUTABLE PARALLEL UNSAFE')
emit('AS $BODY$')
emit('BEGIN')
emit('    RETURN val."Identification" IS NOT NULL;')
emit('END;')
emit('$BODY$;')
emit('ALTER FUNCTION public.validate_generic_identification3(public."GenericIdentification3")')
emit('    OWNER TO postgres;')
emit('COMMENT ON FUNCTION public.validate_generic_identification3(public."GenericIdentification3") IS')
emit(sqlstr('Checks the [1..1] mandatory field (Identification) is present.') + ';\n')

# GenericIdentification30 (10.1.9.4)
emit('-- Type: GenericIdentification30 (10.1.9.4)')
emit('DROP TYPE IF EXISTS public."GenericIdentification30" CASCADE;')
emit('CREATE TYPE public."GenericIdentification30" AS (')
emit('    "Identification" public."Exact4AlphaNumericText",')
emit('    "Issuer" public."Max35Text",')
emit('    "SchemeName" public."Max35Text"')
emit(');')
emit('ALTER TYPE public."GenericIdentification30" OWNER TO postgres;')
emit('COMMENT ON TYPE public."GenericIdentification30" IS')
emit(sqlstr('Definition: Information related to an identification, for example, party '
            'identification or account identification.\n\n'
            'Identification: [1..1] Proprietary information, often a code, issued by '
            'the data source scheme issuer.\n'
            'Issuer: [1..1] Entity that assigns the identification.\n'
            'SchemeName: [0..1] Short textual description of the scheme.') + ';\n')
emit('DROP FUNCTION IF EXISTS public.validate_generic_identification30(public."GenericIdentification30");')
emit('CREATE OR REPLACE FUNCTION public.validate_generic_identification30(')
emit('    val public."GenericIdentification30")')
emit('    RETURNS boolean')
emit("    LANGUAGE 'plpgsql'")
emit('    COST 100')
emit('    IMMUTABLE PARALLEL UNSAFE')
emit('AS $BODY$')
emit('BEGIN')
emit('    RETURN val."Identification" IS NOT NULL')
emit('        AND val."Issuer" IS NOT NULL;')
emit('END;')
emit('$BODY$;')
emit('ALTER FUNCTION public.validate_generic_identification30(public."GenericIdentification30")')
emit('    OWNER TO postgres;')
emit('COMMENT ON FUNCTION public.validate_generic_identification30(public."GenericIdentification30") IS')
emit(sqlstr('Checks the [1..1] mandatory fields (Identification, Issuer) are present. '
            'Composite TYPEs cannot enforce per-field NOT NULL directly -- this '
            'function is how multiplicity is validated for this type.') + ';\n')

with open('/home/claude/sql_10_1_file1.sql', 'w') as f:
    f.writelines(out)
print("Part 1a done")

import sys
sys.path.insert(0, '/home/claude')
from type_registry import load_registry, save_registry

TYPE_FIELDS = load_registry()

def strip_type(ft):
    if ft.endswith('[]'):
        return None
    if ft.startswith('public."') and ft.endswith('"'):
        return ft[len('public."'):-1]
    return None

def branch_populated_expr(fn, ft):
    """See generate_10_1_file2.py for the full rationale: plain IS NOT NULL
    is wrong for composite-typed branches with a mix of null/non-null
    fields, due to Postgres row-wise NULL semantics. Use num_nonnulls()
    over the composite's own fields instead, when known."""
    inner = strip_type(ft)
    if inner and inner in TYPE_FIELDS:
        args = ", ".join(f'(val."{fn}")."{sf}"' for sf in TYPE_FIELDS[inner])
        return f'num_nonnulls({args}) > 0'
    return f'val."{fn}" IS NOT NULL'

def snake(name):
    return 'validate_' + ''.join(
        ['_' + c.lower() if c.isupper() and i > 0 and not name[i-1].isupper() else c.lower()
         for i, c in enumerate(name)]
    ).lstrip('_')

def choice_type(name, branches, section_ref, definition, usage=None):
    """branches: list of (field_name, field_type, branch_definition)"""
    emit(f'-- Type: {name} ({section_ref})')
    emit(f'DROP TYPE IF EXISTS public."{name}" CASCADE;')
    emit(f'CREATE TYPE public."{name}" AS (')
    field_lines = [f'    "{fn}" {ft}' for fn, ft, _ in branches]
    emit(",\n".join(field_lines))
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
                f'num_nonnulls() over their own fields rather than a plain IS NOT NULL -- see '
                f'branch_populated_expr in the generator for why.') + ';\n')
    TYPE_FIELDS[name] = [fn for fn, _, _ in branches]
    return fn_name

def simple_type(name, fields, section_ref, definition, required, extra_comment=None):
    """fields: list of (field_name, field_type, field_comment). required: list of field_names that are [1..1]."""
    emit(f'-- Type: {name} ({section_ref})')
    emit(f'DROP TYPE IF EXISTS public."{name}" CASCADE;')
    emit(f'CREATE TYPE public."{name}" AS (')
    field_lines = [f'    "{fn}" {ft}' for fn, ft, _ in fields]
    emit(",\n".join(field_lines))
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
    TYPE_FIELDS[name] = [fn for fn, _, _ in fields]
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
        return fn_name
    return None

# References74Choice (10.1.9.1) -- 10-way exclusive choice
choice_type("References74Choice", [
    ("SecuritiesSettlementTransactionIdentification", 'public."Max35Text"',
     'Unambiguous identification of a securities settlement transaction as known by the account owner.'),
    ("IntraPositionMovementIdentification", 'public."Max35Text"',
     'Unambiguous identification of the intra-position movement transaction.'),
    ("IntraBalanceMovementIdentification", 'public."Max35Text"',
     'Unambiguous identification of the intra balance movement transaction.'),
    ("AccountServicerTransactionIdentification", 'public."Max35Text"',
     'Unambiguous identification of the transaction as known by the account servicer.'),
    ("MarketInfrastructureTransactionIdentification", 'public."Max35Text"',
     'Identification of a transaction assigned by a market infrastructure other than a CSD.'),
    ("CounterpartyMarketInfrastructureTransactionIdentification", 'public."Max35Text"',
     'Identification of a counterparty transaction assigned by a market infrastructure other than a CSD. '
     '(Source MDR marks this branch [0..1] rather than [1..1] like its siblings -- reproduced as-is.)'),
    ("PoolIdentification", 'public."Max35Text"', 'Collective reference identifying a set of messages.'),
    ("CommonIdentification", 'public."Max35Text"',
     'Unique reference agreed upon by the two trade counterparties to identify the trade.'),
    ("TradeIdentification", 'public."Max52Text"',
     'Reference assigned to the trade by the investor or the trading party.'),
    ("OtherTransactionIdentification", 'public."Max35Text"',
     'Identification of a transaction that cannot be identified using a standard reference element.'),
], "10.1.9.1", "Choice between references.")

# OriginalGroupInformation27 (10.1.11.1)
simple_type("OriginalGroupInformation27", [
    ("OriginalMessageIdentification", 'public."Max35Text"',
     'Point to point reference, as assigned by the original instructing party, to unambiguously identify the original message.'),
    ("OriginalMessageNameIdentification", 'public."Max35Text"',
     'Specifies the original message name identifier to which the message refers.'),
    ("OriginalCreationDateTime", 'public."ISODateTime"', 'Date and time at which the original message was created.'),
    ("OriginalNumberOfTransactions", 'public."Max15NumericText"', 'Number of individual transactions contained in the original message.'),
    ("OriginalControlSum", 'public."DecimalNumber"', 'Total of all individual amounts included in the original message, irrespective of currencies.'),
], "10.1.11.1", "Set of elements used to provide information on the original group, to which the message refers.",
   required=["OriginalMessageIdentification", "OriginalMessageNameIdentification"])

# OriginalGroupInformation29 (10.1.11.7)
simple_type("OriginalGroupInformation29", [
    ("OriginalMessageIdentification", 'public."Max35Text"',
     'Point to point reference assigned by the original instructing party to unambiguously identify the original message.'),
    ("OriginalMessageNameIdentification", 'public."Max35Text"',
     'Specifies the original message name identifier to which the message refers, e.g. pacs.003.001.01 or MT103.'),
    ("OriginalCreationDateTime", 'public."ISODateTime"', 'Original date and time at which the message was created.'),
], "10.1.11.7", "Unique and unambiguous identifier of the group of transactions as assigned by the original instructing party.",
   required=["OriginalMessageIdentification", "OriginalMessageNameIdentification"])

# OriginalBusinessQuery1 (10.1.11.8)
simple_type("OriginalBusinessQuery1", [
    ("MessageIdentification", 'public."Max35Text"',
     'Point to point reference, as assigned by the original initiating party, to unambiguously identify the original query message.'),
    ("MessageNameIdentification", 'public."Max35Text"', 'Specifies the query message name identifier to which the message refers.'),
    ("CreationDateTime", 'public."ISODateTime"', 'Date and time at which the message was created.'),
], "10.1.11.8", "Unique identification, as assigned by the original requestor, to unambiguously identify the business query message.",
   required=["MessageIdentification"])

# Authorisation1Choice (10.1.11.2)
choice_type("Authorisation1Choice", [
    ("Code", 'public."Authorisation1Code"', 'Specifies the authorisation, in a coded form (AUTH/FDET/FSUM/ILEV).'),
    ("Proprietary", 'public."Max128Text"', 'Specifies the authorisation, in a free text form.'),
], "10.1.11.2", "Provides the details on the user identification or any user key that allows to check if the "
   "initiating party is allowed to issue the transaction.")

# SupplementaryData1 (10.1.11.3)
simple_type("SupplementaryData1", [
    ("PlaceAndName", 'public."Max350Text"',
     'Unambiguous reference to the location where the supplementary data must be inserted in the message instance (an XPath, for XML).'),
    ("Envelope", 'text',
     'Technical element wrapping the supplementary data. Type is "(External Schema)" in the MDR -- arbitrary '
     'ISO-20022-compliant XML content, not a fixed structure, so modeled as text/xml rather than a typed column. '
     'Constraint - SupplementaryDataRule: this component may not be used without explicit SEG approval and RA '
     'submission of the structure(s) used in this element -- a governance rule, not something a CHECK can enforce.'),
], "10.1.11.3", "Additional information that can not be captured in the structured fields and/or any other specific block.",
   required=["Envelope"])

# Purpose2Choice (10.1.11.4)
choice_type("Purpose2Choice", [
    ("Code", 'public."ExternalPurpose1Code"', 'Underlying reason for the payment transaction, as published in an external purpose code list.'),
    ("Proprietary", 'public."Max35Text"', 'Purpose, in a proprietary form.'),
], "10.1.11.4", "Specifies the underlying reason for the payment transaction.",
   usage="Purpose is used by the end-customers to provide information concerning the nature of the payment; "
         "not used for processing by any agent in the payment chain.")

# NumberOfTransactionsPerStatus5 (10.1.11.5)
simple_type("NumberOfTransactionsPerStatus5", [
    ("DetailedNumberOfTransactions", 'public."Max15NumericText"', 'Number of individual transactions contained in the message, detailed per status.'),
    ("DetailedStatus", 'public."ExternalPaymentTransactionStatus1Code"', 'Common transaction status for all individual transactions reported.'),
    ("DetailedControlSum", 'public."DecimalNumber"', 'Total of all individual amounts included in the message, irrespective of currencies, detailed per status.'),
], "10.1.11.5", "Set of elements used to provide detailed information on the number of transactions that are reported with a specific transaction status.",
   required=["DetailedNumberOfTransactions", "DetailedStatus"])

# RemittanceInformation2 (10.1.11.6) -- unbounded repeatable, array, no required fields
emit('-- Type: RemittanceInformation2 (10.1.11.6)')
emit('DROP TYPE IF EXISTS public."RemittanceInformation2" CASCADE;')
emit('CREATE TYPE public."RemittanceInformation2" AS (')
emit('    "Unstructured" public."Max140Text"[]')
emit(');')
emit('ALTER TYPE public."RemittanceInformation2" OWNER TO postgres;')
emit('COMMENT ON TYPE public."RemittanceInformation2" IS')
emit(sqlstr('Definition: Information supplied to enable the matching of an entry with the items that the '
            'transfer is intended to settle.\n\n'
            'Unstructured: [0..*] Information supplied to enable matching, e.g. commercial invoices in an '
            'accounts receivable system, in unstructured form. Modeled as an array (genuinely unbounded -- '
            'no upper limit given in the MDR, unlike PostalAddress27.AddressLine which caps at 7).') + ';\n')

# SettlementTimeRequest2 (10.1.13.1) -- all optional, no validate needed
emit('-- Type: SettlementTimeRequest2 (10.1.13.1)')
emit('DROP TYPE IF EXISTS public."SettlementTimeRequest2" CASCADE;')
emit('CREATE TYPE public."SettlementTimeRequest2" AS (')
emit('    "CLSTime" public."ISOTime",')
emit('    "TillTime" public."ISOTime",')
emit('    "FromTime" public."ISOTime",')
emit('    "RejectTime" public."ISOTime"')
emit(');')
emit('ALTER TYPE public."SettlementTimeRequest2" OWNER TO postgres;')
emit('COMMENT ON TYPE public."SettlementTimeRequest2" IS')
emit(sqlstr('Definition: Provides information on the requested settlement time(s) of the payment instruction.\n\n'
            'CLSTime: [0..1] Time by which money must be credited, with confirmation, to the CLS Bank account at the central bank. Usage: expressed in CET.\n'
            'TillTime: [0..1] Time until when the payment may be settled.\n'
            'FromTime: [0..1] Time as from when the payment may be settled.\n'
            'RejectTime: [0..1] Time by when the payment must be settled to avoid rejection.\n\n'
            'All four fields are optional per the MDR -- no validate_ function needed (nothing to check).') + ';\n')

# InstructionForCreditorAgent3 (10.1.13.2) -- all optional
emit('-- Type: InstructionForCreditorAgent3 (10.1.13.2)')
emit('DROP TYPE IF EXISTS public."InstructionForCreditorAgent3" CASCADE;')
emit('CREATE TYPE public."InstructionForCreditorAgent3" AS (')
emit('    "Code" public."ExternalCreditorAgentInstruction1Code",')
emit('    "InstructionInformation" public."Max140Text"')
emit(');')
emit('ALTER TYPE public."InstructionForCreditorAgent3" OWNER TO postgres;')
emit('COMMENT ON TYPE public."InstructionForCreditorAgent3" IS')
emit(sqlstr('Definition: Further information related to the processing of the payment instruction that may need '
            'to be acted upon by the creditor agent.\n\n'
            'Code: [0..1] Coded information for the creditor agent.\n'
            'InstructionInformation: [0..1] Further free-text information complementing the coded instruction.\n\n'
            'Both fields optional -- no validate_ function needed.') + ';\n')

# ClearingSystemIdentification2Choice (10.1.19.1)
choice_type("ClearingSystemIdentification2Choice", [
    ("Code", 'public."ExternalClearingSystemIdentification1Code"', 'Identification of a clearing system, in coded form as published in an external list.'),
    ("Proprietary", 'public."Max35Text"', 'Identification code for a clearing system not yet identified in the list of clearing systems.'),
], "10.1.19.1", "Choice of a clearing system identifier.")

# TaxAuthorisation1 (inline, referenced from TaxParty2.Authorisation) -- all optional
emit('-- Type: TaxAuthorisation1 (inline sub-type of TaxParty2.Authorisation, 10.1.20.1.4)')
emit('DROP TYPE IF EXISTS public."TaxAuthorisation1" CASCADE;')
emit('CREATE TYPE public."TaxAuthorisation1" AS (')
emit('    "Title" public."Max35Text",')
emit('    "Name" public."Max140Text"')
emit(');')
emit('ALTER TYPE public."TaxAuthorisation1" OWNER TO postgres;')
emit('COMMENT ON TYPE public."TaxAuthorisation1" IS')
emit(sqlstr('Definition: Details of the authorised tax paying party.\n\n'
            'Title: [0..1] Title or position of debtor or the debtor''s authorised representative.\n'
            'Name: [0..1] Name of debtor or the debtor''s authorised representative.\n\n'
            'Both fields optional -- no validate_ function needed. Named "TaxAuthorisation1" per the MDR''s own '
            'in-text reference ("contains the following TaxAuthorisation1 elements") though it has no top-level heading.') + ';\n')

# TaxParty2 (10.1.20.1) -- all optional
emit('-- Type: TaxParty2 (10.1.20.1)')
emit('DROP TYPE IF EXISTS public."TaxParty2" CASCADE;')
emit('CREATE TYPE public."TaxParty2" AS (')
emit('    "TaxIdentification" public."Max35Text",')
emit('    "RegistrationIdentification" public."Max35Text",')
emit('    "TaxType" public."Max35Text",')
emit('    "Authorisation" public."TaxAuthorisation1"')
emit(');')
emit('ALTER TYPE public."TaxParty2" OWNER TO postgres;')
emit('COMMENT ON TYPE public."TaxParty2" IS')
emit(sqlstr('Definition: Details about the entity involved in the tax paid or to be paid.\n\n'
            'TaxIdentification: [0..1] Tax identification number of the debtor.\n'
            'RegistrationIdentification: [0..1] Unique identification, as assigned by an organisation, to unambiguously identify a party.\n'
            'TaxType: [0..1] Type of tax payer.\n'
            'Authorisation: [0..1] Details of the authorised tax paying party.\n\n'
            'All fields optional -- no validate_ function needed.') + ';\n')

# TaxParty1 (10.1.20.2) -- all optional
emit('-- Type: TaxParty1 (10.1.20.2)')
emit('DROP TYPE IF EXISTS public."TaxParty1" CASCADE;')
emit('CREATE TYPE public."TaxParty1" AS (')
emit('    "TaxIdentification" public."Max35Text",')
emit('    "RegistrationIdentification" public."Max35Text",')
emit('    "TaxType" public."Max35Text"')
emit(');')
emit('ALTER TYPE public."TaxParty1" OWNER TO postgres;')
emit('COMMENT ON TYPE public."TaxParty1" IS')
emit(sqlstr('Definition: Details about the entity involved in the tax paid or to be paid.\n\n'
            'TaxIdentification: [0..1] Tax identification number of the creditor.\n'
            'RegistrationIdentification: [0..1] Unique identification, as assigned by an organisation.\n'
            'TaxType: [0..1] Type of tax payer.\n\n'
            'All fields optional -- no validate_ function needed.') + ';\n')

# MandateClassification1Choice (10.1.10.1)
choice_type("MandateClassification1Choice", [
    ("Code", 'public."MandateClassification1Code"', 'Category purpose (FIXE/USGB/VARI).'),
    ("Proprietary", 'public."Max35Text"', 'Category purpose, in a proprietary form.'),
], "10.1.10.1", "Specifies the high level purpose of the instruction based on a set of pre-defined categories.",
   usage="Used by the initiating party to provide processing information; likely to trigger special processing "
         "by agents in the payment chain.")

with open('/home/claude/sql_10_1_file1.sql', 'w') as f:
    f.writelines(out)
print("Part 1 complete")

# ---------------------------------------------------------------------
# PART 2 -- PaymentIdentification13: NOT a {Or}/{Or} exclusive choice --
# has a named business-rule constraint that's inclusive-or, not exactly-one.
# ---------------------------------------------------------------------
emit('-- ---------------------------------------------------------------------')
emit('-- PART 2 -- PaymentIdentification13 (10.1.9.2): inclusive-or business rule')
emit('-- ---------------------------------------------------------------------\n')

emit('-- Type: PaymentIdentification13 (10.1.9.2)')
emit('DROP TYPE IF EXISTS public."PaymentIdentification13" CASCADE;')
emit('CREATE TYPE public."PaymentIdentification13" AS (')
emit('    "InstructionIdentification" public."Max35Text",')
emit('    "EndToEndIdentification" public."Max35Text",')
emit('    "TransactionIdentification" public."Max35Text",')
emit('    "UETR" public."UUIDv4Identifier",')
emit('    "ClearingSystemReference" public."Max35Text"')
emit(');')
emit('ALTER TYPE public."PaymentIdentification13" OWNER TO postgres;')
emit('COMMENT ON TYPE public."PaymentIdentification13" IS')
emit(sqlstr('Definition: Provides further means of referencing a payment transaction.\n\n'
            'InstructionIdentification: [0..1] Unique ID assigned by an instructing party for an instructed '
            'party to unambiguously identify the instruction.\n'
            'EndToEndIdentification: [1..1] Unique ID assigned by the initiating party, passed on unchanged '
            'throughout the entire end-to-end chain.\n'
            'TransactionIdentification: [0..1] Unique ID assigned by the first instructing agent, passed on '
            'unchanged throughout the entire interbank chain.\n'
            'UETR: [0..1] Universally unique identifier providing an end-to-end reference of a payment transaction.\n'
            'ClearingSystemReference: [0..1] Unique reference, as assigned by a clearing system.\n\n'
            'Constraint - TransactionIdentificationPresenceRule: TransactionIdentification or UETR must be '
            'present (both may be present) -- an inclusive-or, not the exactly-one {Or}/{Or} pattern used '
            'elsewhere in this library.') + ';\n')

emit('DROP FUNCTION IF EXISTS public.validate_payment_identification13(public."PaymentIdentification13");')
emit('CREATE OR REPLACE FUNCTION public.validate_payment_identification13(')
emit('    val public."PaymentIdentification13")')
emit('    RETURNS boolean')
emit("    LANGUAGE 'plpgsql'")
emit('    COST 100')
emit('    IMMUTABLE PARALLEL UNSAFE')
emit('AS $BODY$')
emit('BEGIN')
emit('    RETURN val."EndToEndIdentification" IS NOT NULL')
emit('        AND (val."TransactionIdentification" IS NOT NULL OR val."UETR" IS NOT NULL);')
emit('END;')
emit('$BODY$;')
emit('ALTER FUNCTION public.validate_payment_identification13(public."PaymentIdentification13")')
emit('    OWNER TO postgres;')
emit('COMMENT ON FUNCTION public.validate_payment_identification13(public."PaymentIdentification13") IS')
emit(sqlstr('Checks EndToEndIdentification (the [1..1] mandatory field) is present, AND the '
            'TransactionIdentificationPresenceRule: at least one of TransactionIdentification/UETR is present '
            '(inclusive-or -- both may be set, unlike an exclusive {Or}/{Or} choice).') + ';\n')

with open('/home/claude/sql_10_1_file1.sql', 'w') as f:
    f.writelines(out)
print("Part 2 complete")

# ---------------------------------------------------------------------
# PART 3 -- Reusable Code/Proprietary Choice sub-components. These recur
# verbatim (same two branches) across Mandate, Payment Type, etc. in the
# MDR without their own top-level heading -- named here per the MDR's own
# in-text references ("...contains one of the following XChoice elements")
# and defined once, referenced everywhere they're used.
# ---------------------------------------------------------------------
emit('-- ---------------------------------------------------------------------')
emit('-- PART 3 -- Reusable Code/Proprietary Choice sub-components')
emit('-- Referenced from Mandate (10.1.10) and Payment Type (10.1.14)')
emit('-- ---------------------------------------------------------------------\n')

choice_type("ServiceLevel8Choice", [
    ("Code", 'public."ExternalServiceLevel1Code"',
     'Specifies a pre-agreed service or level of service between the parties, as published in an external service level code list.'),
    ("Proprietary", 'public."Max35Text"',
     'Specifies a pre-agreed service or level of service between the parties, as a proprietary code.'),
], "inline, e.g. 10.1.10.2.1 / 10.1.14.1.3", "Agreement under which or rules under which the transaction should be processed.")

choice_type("LocalInstrument2Choice", [
    ("Code", 'public."ExternalLocalInstrument1Code"', 'Specifies the local instrument, as published in an external local instrument code list.'),
    ("Proprietary", 'public."Max35Text"', 'Specifies the local instrument, as a proprietary code.'),
], "inline, e.g. 10.1.10.2.2 / 10.1.14.1.4", "User community specific instrument.",
   usage="Used to specify a local instrument, local clearing option and/or further qualify the service or service level.")

choice_type("CategoryPurpose1Choice", [
    ("Code", 'public."ExternalCategoryPurpose1Code"', 'Category purpose, as published in an external category purpose code list.'),
    ("Proprietary", 'public."Max35Text"', 'Category purpose, in a proprietary form.'),
], "inline, e.g. 10.1.10.2.3 / 10.1.14.1.5", "Specifies the high level purpose of the mandate/instruction based on a set of pre-defined categories.")

with open('/home/claude/sql_10_1_file1.sql', 'w') as f:
    f.writelines(out)
print("Part 3 complete")

# ---------------------------------------------------------------------
# PART 4 -- Frequency (10.1.8): a 3-way choice where two of the three
# branches are themselves inline composite sub-types (named in-text:
# FrequencyPeriod1, FrequencyAndMoment1), not top-level MDR headings.
# ---------------------------------------------------------------------
emit('-- ---------------------------------------------------------------------')
emit('-- PART 4 -- 10.1.8 Frequency')
emit('-- ---------------------------------------------------------------------\n')

# FrequencyPeriod1 (inline, referenced from Frequency36Choice.Period)
simple_type("FrequencyPeriod1", [
    ("Type", 'public."Frequency6Code"', 'Period for which the number of instructions are to be created and processed.'),
    ("CountPerPeriod", 'public."DecimalNumber"', 'Number of instructions to be created and processed during the specified period.'),
], "inline, 10.1.8.1.2", "Specifies a frequency in terms of a count per period within a specified period type.",
   required=["Type", "CountPerPeriod"])

# FrequencyAndMoment1 (inline, referenced from Frequency36Choice.PointInTime)
simple_type("FrequencyAndMoment1", [
    ("Type", 'public."Frequency6Code"', 'Period for which the number of instructions are to be created and processed.'),
    ("PointInTime", 'public."Exact2NumericText"', 'Further information on the exact point in time the event should take place.'),
], "inline, 10.1.8.1.3", "Specifies a frequency in terms of an exact point in time or moment within a specified period type.",
   required=["Type", "PointInTime"])

# Frequency36Choice (10.1.8.1) -- 3-way choice, 2 of 3 branches are composite sub-types
choice_type("Frequency36Choice", [
    ("Type", 'public."Frequency6Code"', 'Specifies a frequency in terms of a specified period type.'),
    ("Period", 'public."FrequencyPeriod1"', 'Specifies a frequency in terms of a count per period within a specified period type.'),
    ("PointInTime", 'public."FrequencyAndMoment1"', 'Specifies a frequency in terms of an exact point in time or moment within a specified period type.'),
], "10.1.8.1", "Choice of format for a frequency, for example, the frequency of payment.")

with open('/home/claude/sql_10_1_file1.sql', 'w') as f:
    f.writelines(out)
print("Part 4 complete")

# ---------------------------------------------------------------------
# PART 5 -- MandateTypeInformation2 (10.1.10.2): 4 independent optional
# fields (not a {Or}/{Or} choice among them), reusing Part 3's choices
# plus the already-defined MandateClassification1Choice.
# ---------------------------------------------------------------------
emit('-- ---------------------------------------------------------------------')
emit('-- PART 5 -- MandateTypeInformation2 (10.1.10.2)')
emit('-- ---------------------------------------------------------------------\n')

emit('-- Type: MandateTypeInformation2 (10.1.10.2)')
emit('DROP TYPE IF EXISTS public."MandateTypeInformation2" CASCADE;')
emit('CREATE TYPE public."MandateTypeInformation2" AS (')
emit('    "ServiceLevel" public."ServiceLevel8Choice",')
emit('    "LocalInstrument" public."LocalInstrument2Choice",')
emit('    "CategoryPurpose" public."CategoryPurpose1Choice",')
emit('    "Classification" public."MandateClassification1Choice"')
emit(');')
emit('ALTER TYPE public."MandateTypeInformation2" OWNER TO postgres;')
emit('COMMENT ON TYPE public."MandateTypeInformation2" IS')
emit(sqlstr('Definition: Set of elements used to further detail the information related to the type of payment.\n\n'
            'ServiceLevel: [0..1] Agreement/rules under which the mandate resides.\n'
            'LocalInstrument: [0..1] User community specific instrument.\n'
            'CategoryPurpose: [0..1] High level purpose of the mandate.\n'
            'Classification: [0..1] Type of direct debit instruction (reuses MandateClassification1Choice).\n\n'
            'All four fields are independently optional (not a {Or}/{Or} choice among them) -- no '
            'validate_ function needed at this level; each field''s own composite type carries its own '
            'exactly-one-branch validation.') + ';\n')

with open('/home/claude/sql_10_1_file1.sql', 'w') as f:
    f.writelines(out)
print("Part 5 complete")

# ---------------------------------------------------------------------
# PART 6 -- Payment Type (10.1.14): both types reuse Part 3's choices,
# with ServiceLevel repeatable ([0..*] -> array).
# ---------------------------------------------------------------------
emit('-- ---------------------------------------------------------------------')
emit('-- PART 6 -- 10.1.14 Payment Type')
emit('-- ---------------------------------------------------------------------\n')

emit('-- Type: PaymentTypeInformation28 (10.1.14.1)')
emit('DROP TYPE IF EXISTS public."PaymentTypeInformation28" CASCADE;')
emit('CREATE TYPE public."PaymentTypeInformation28" AS (')
emit('    "InstructionPriority" public."Priority2Code",')
emit('    "ClearingChannel" public."ClearingChannel2Code",')
emit('    "ServiceLevel" public."ServiceLevel8Choice"[],')
emit('    "LocalInstrument" public."LocalInstrument2Choice",')
emit('    "CategoryPurpose" public."CategoryPurpose1Choice"')
emit(');')
emit('ALTER TYPE public."PaymentTypeInformation28" OWNER TO postgres;')
emit('COMMENT ON TYPE public."PaymentTypeInformation28" IS')
emit(sqlstr('Definition: Provides further details of the type of payment.\n\n'
            'InstructionPriority: [0..1] Urgency/importance the instructing party wants applied to processing.\n'
            'ClearingChannel: [0..1] Clearing channel to be used to process the payment instruction.\n'
            'ServiceLevel: [0..*] Agreement/rules under which the transaction should be processed -- repeatable, '
            'modeled as an array of ServiceLevel8Choice (unbounded, no max given).\n'
            'LocalInstrument: [0..1] User community specific instrument.\n'
            'CategoryPurpose: [0..1] High level purpose of the instruction.\n\n'
            'All fields optional -- no validate_ function needed at this level.') + ';\n')

emit('-- Type: PaymentTypeInformation27 (10.1.14.2)')
emit('DROP TYPE IF EXISTS public."PaymentTypeInformation27" CASCADE;')
emit('CREATE TYPE public."PaymentTypeInformation27" AS (')
emit('    "InstructionPriority" public."Priority2Code",')
emit('    "ClearingChannel" public."ClearingChannel2Code",')
emit('    "ServiceLevel" public."ServiceLevel8Choice"[],')
emit('    "LocalInstrument" public."LocalInstrument2Choice",')
emit('    "SequenceType" public."SequenceType3Code",')
emit('    "CategoryPurpose" public."CategoryPurpose1Choice"')
emit(');')
emit('ALTER TYPE public."PaymentTypeInformation27" OWNER TO postgres;')
emit('COMMENT ON TYPE public."PaymentTypeInformation27" IS')
emit(sqlstr('Definition: Provides further details of the type of payment.\n\n'
            'Same as PaymentTypeInformation28, plus:\n'
            'SequenceType: [0..1] Identifies the direct debit sequence (first/recurrent/final/one-off/represented).\n\n'
            'All fields optional -- no validate_ function needed at this level.') + ';\n')

with open('/home/claude/sql_10_1_file1.sql', 'w') as f:
    f.writelines(out)
print("Part 6 complete")

# ---------------------------------------------------------------------
# PART 7 -- Amount (10.1.3): AmountType4Choice is a 2-way choice where one
# branch is an inline composite (EquivalentAmount2, named in-text, no
# top-level heading) with its own [1..1] required fields.
# ---------------------------------------------------------------------
emit('-- ---------------------------------------------------------------------')
emit('-- PART 7 -- 10.1.3 Amount')
emit('-- ---------------------------------------------------------------------\n')

simple_type("EquivalentAmount2", [
    ("Amount", 'public."ActiveOrHistoricCurrencyAndAmount"',
     "Amount of money to be moved between debtor and creditor, before deduction of charges, expressed in the "
     "currency of the debtor's account, to be moved in a different currency. Usage: the first agent converts "
     "the equivalent amount into the amount to be moved."),
    ("CurrencyOfTransfer", 'public."ActiveOrHistoricCurrencyCode"',
     "Currency of the to-be-transferred amount, different from the currency of the debtor's account."),
], "inline, 10.1.3.1.2", "Amount of money to be moved between the debtor and creditor, expressed in the "
   "currency of the debtor's account, and the currency in which the amount is to be moved.",
   required=["Amount", "CurrencyOfTransfer"])

choice_type("AmountType4Choice", [
    ("InstructedAmount", 'public."ActiveOrHistoricCurrencyAndAmount"',
     'Amount of money to be moved between debtor and creditor, before deduction of charges, expressed in the '
     'currency as ordered by the initiating party. Usage: transported unchanged through the transaction chain.'),
    ("EquivalentAmount", 'public."EquivalentAmount2"',
     "Amount of money to be moved, expressed in the currency of the debtor's account and the currency in "
     "which the amount is to be moved."),
], "10.1.3.1", "Specifies the amount of money to be moved between the debtor and creditor, before deduction "
   "of charges, expressed in the currency as ordered by the initiating party.")

# ---------------------------------------------------------------------
# Register hand-written types (bypassed simple_type()/choice_type(), so
# didn't auto-register) for forward compatibility with later files whose
# Choice types may reference these as branches.
# ---------------------------------------------------------------------
TYPE_FIELDS["DatePeriod2"] = ["FromDate", "ToDate"]
TYPE_FIELDS["GenericIdentification3"] = ["Identification", "Issuer"]
TYPE_FIELDS["GenericIdentification30"] = ["Identification", "Issuer", "SchemeName"]
TYPE_FIELDS["RemittanceInformation2"] = ["Unstructured"]
TYPE_FIELDS["SettlementTimeRequest2"] = ["CLSTime", "TillTime", "FromTime", "RejectTime"]
TYPE_FIELDS["InstructionForCreditorAgent3"] = ["Code", "InstructionInformation"]
TYPE_FIELDS["TaxAuthorisation1"] = ["Title", "Name"]
TYPE_FIELDS["TaxParty2"] = ["TaxIdentification", "RegistrationIdentification", "TaxType", "Authorisation"]
TYPE_FIELDS["TaxParty1"] = ["TaxIdentification", "RegistrationIdentification", "TaxType"]
TYPE_FIELDS["PaymentIdentification13"] = ["InstructionIdentification", "EndToEndIdentification",
                                          "TransactionIdentification", "UETR", "ClearingSystemReference"]
TYPE_FIELDS["MandateTypeInformation2"] = ["ServiceLevel", "LocalInstrument", "CategoryPurpose", "Classification"]
TYPE_FIELDS["PaymentTypeInformation28"] = ["InstructionPriority", "ClearingChannel", "ServiceLevel",
                                           "LocalInstrument", "CategoryPurpose"]
TYPE_FIELDS["PaymentTypeInformation27"] = ["InstructionPriority", "ClearingChannel", "ServiceLevel",
                                           "LocalInstrument", "SequenceType", "CategoryPurpose"]

with open('/home/claude/sql_10_1_file1.sql', 'w') as f:
    f.writelines(out)
save_registry(TYPE_FIELDS)
print("Part 7 complete -- FILE 1 GENERATION DONE")
