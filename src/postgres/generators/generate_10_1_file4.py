#!/usr/bin/env python3
"""
Generates PostgreSQL DDL for ISO 20022 MDR Part 2, Section 10.1 "Message
Components" -- FILE 4 of 4: Payment Instructions & Compliance.

Covers: 10.1.6 Direct Debit (CreditTransferMandateData1), 10.1.17
Regulatory Reporting (RegulatoryReporting3).

Depends on: 10.2 Message Datatypes, File 1 (MandateTypeInformation2,
Frequency36Choice).
Load order: 10.2 -> File 1 -> File 2 -> File 3 -> File 4 (this file).

This completes Section 10.1 Message Components EXCEPT 10.1.18 Remittance
(deferred as a separate follow-up per prior agreement -- by far the most
complex subsection, 42 of the 102 pages, for just 2 top-level types).
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
                f'num_nonnulls() over their own fields rather than a plain IS NOT NULL.') + ';\n')
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

HEADER = '''-- =====================================================================
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

'''
emit(HEADER)

# ---------------------------------------------------------------------
# PART 1 -- 10.1.6 Direct Debit
# ---------------------------------------------------------------------
emit('-- ---------------------------------------------------------------------')
emit('-- PART 1 -- 10.1.6 Direct Debit')
emit('-- ---------------------------------------------------------------------\n')

# MandateSetupReason1Choice (inline, CreditTransferMandateData1.Reason)
choice_type("MandateSetupReason1Choice", [
    ("Code", 'public."ExternalMandateSetupReason1Code"', 'Reason for the mandate setup, as published in an external reason code list.'),
    ("Proprietary", 'public."Max70Text"', 'Reason for the mandate setup, in a proprietary form.'),
], "inline, 10.1.6.1.9", "Reason for the setup of the credit transfer mandate.",
   usage="Allows the user to distinguish between different mandates for the same creditor.")

# CreditTransferMandateData1 (10.1.6.1) -- reuses MandateTypeInformation2 and Frequency36Choice from File 1
simple_type("CreditTransferMandateData1", [
    ("MandateIdentification", 'public."Max35Text"', 'Unique identification, as assigned by the creditor, to unambiguously identify the mandate.'),
    ("Type", 'public."MandateTypeInformation2"', 'Specifies the type of mandate, such as paper, electronic or scheme. Reuses MandateTypeInformation2 (File 1).'),
    ("DateOfSignature", 'public."ISODate"', 'Date on which the credit transfer mandate has been signed by the debtor.'),
    ("DateOfVerification", 'public."ISODateTime"', 'Date on which the credit transfer mandate has been verified.'),
    ("ElectronicSignature", 'public."Max10KBinary"', 'Additional security provisions, such as a digital signature, as provided by the debtor.'),
    ("FirstPaymentDate", 'public."ISODate"', 'Date of the first payment of a recurrent credit transfer as per the mandate.'),
    ("FinalPaymentDate", 'public."ISODate"', 'Date of the final payment of a recurrent credit transfer as per the mandate.'),
    ("Frequency", 'public."Frequency36Choice"', 'Regularity with which credit transfer instructions are to be created and processed. Reuses Frequency36Choice (File 1).'),
    ("Reason", 'public."MandateSetupReason1Choice"', 'Reason for the setup of the credit transfer mandate.'),
], "10.1.6.1", "Provides further details related to a credit transfer mandate signed between the creditor and the debtor.",
   required=[])

with open('/home/claude/sql_10_1_file4.sql', 'w') as f:
    f.writelines(out)
print("Part 1 complete")

# ---------------------------------------------------------------------
# PART 2 -- 10.1.17 Regulatory Reporting
# ---------------------------------------------------------------------
emit('-- ---------------------------------------------------------------------')
emit('-- PART 2 -- 10.1.17 Regulatory Reporting')
emit('-- ---------------------------------------------------------------------\n')

# RegulatoryAuthority2 (inline, RegulatoryReporting3.Authority)
simple_type("RegulatoryAuthority2", [
    ("Name", 'public."Max140Text"', 'Name of the entity requiring the regulatory reporting information.'),
    ("Country", 'public."CountryCode"', 'Country of the entity that requires the regulatory reporting information. '
     'Constraint C10 "Country" -- format enforced by the domain.'),
], "inline, 10.1.17.1.2", "Entity requiring the regulatory reporting information.",
   required=[])

# StructuredRegulatoryReporting3 (inline, RegulatoryReporting3.Details, [0..*])
emit('-- Type: StructuredRegulatoryReporting3 (inline, 10.1.17.1.3)')
emit('DROP TYPE IF EXISTS public."StructuredRegulatoryReporting3" CASCADE;')
emit('CREATE TYPE public."StructuredRegulatoryReporting3" AS (')
emit('    "Type" public."Max35Text",')
emit('    "Date" public."ISODate",')
emit('    "Country" public."CountryCode",')
emit('    "Code" public."Max10Text",')
emit('    "Amount" public."ActiveOrHistoricCurrencyAndAmount",')
emit('    "Information" public."Max35Text"[]')
emit(');')
emit('ALTER TYPE public."StructuredRegulatoryReporting3" OWNER TO postgres;')
emit('COMMENT ON TYPE public."StructuredRegulatoryReporting3" IS')
emit(sqlstr('Definition: Set of elements used to provide details on the regulatory reporting information.\n\n'
            'Type: [0..1] Type of the information supplied in the regulatory reporting details.\n'
            'Date: [0..1] Date related to the specified type of regulatory reporting details.\n'
            'Country: [0..1] Constraint C10 "Country" -- format enforced by the domain.\n'
            'Code: [0..1] Nature/purpose/reason for the transaction, coded form.\n'
            'Amount: [0..1] Amount of money to be reported. Constraints C2/C12 -- format/precision enforced '
            'by the ActiveOrHistoricCurrencyAndAmount composite type (10.2).\n'
            'Information: [0..*] Additional free-text details for domestic regulatory requirements -- '
            'repeatable, modeled as an array (unbounded).\n\n'
            'All fields optional -- no validate_ function needed at this level.') + ';\n')
TYPE_FIELDS["StructuredRegulatoryReporting3"] = ["Type", "Date", "Country", "Code", "Amount", "Information"]

# RegulatoryReporting3 (10.1.17.1) -- top-level, Details is [0..*] -> array
emit('-- Type: RegulatoryReporting3 (10.1.17.1)')
emit('DROP TYPE IF EXISTS public."RegulatoryReporting3" CASCADE;')
emit('CREATE TYPE public."RegulatoryReporting3" AS (')
emit('    "DebitCreditReportingIndicator" public."RegulatoryReportingType1Code",')
emit('    "Authority" public."RegulatoryAuthority2",')
emit('    "Details" public."StructuredRegulatoryReporting3"[]')
emit(');')
emit('ALTER TYPE public."RegulatoryReporting3" OWNER TO postgres;')
emit('COMMENT ON TYPE public."RegulatoryReporting3" IS')
emit(sqlstr('Definition: Information needed due to regulatory and/or statutory requirements.\n\n'
            'DebitCreditReportingIndicator: [0..1] Whether the information applies to debit, credit, or both sides.\n'
            'Authority: [0..1] Entity requiring the regulatory reporting information.\n'
            'Details: [0..*] Set of elements providing details -- repeatable, modeled as an array of '
            'StructuredRegulatoryReporting3 (unbounded).\n\n'
            'All fields optional -- no validate_ function needed at this level.') + ';\n')
TYPE_FIELDS["RegulatoryReporting3"] = ["DebitCreditReportingIndicator", "Authority", "Details"]

with open('/home/claude/sql_10_1_file4.sql', 'w') as f:
    f.writelines(out)
save_registry(TYPE_FIELDS)
print("Part 2 complete -- FILE 4 GENERATION DONE (10.1 complete except Remittance)")
