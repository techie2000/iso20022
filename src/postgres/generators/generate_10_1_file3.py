#!/usr/bin/env python3
"""
Generates PostgreSQL DDL for ISO 20022 MDR Part 2, Section 10.1 "Message
Components" -- FILE 3 of 4: Accounts & Financial Institutions.

Covers: 10.1.1 Account (CashAccount40), 10.1.2 Account Identification
(AccountIdentification4Choice), 10.1.7 Financial Institution
Identification (BranchAndFinancialInstitutionIdentification8).

Depends on: 10.2 Message Datatypes, File 1 (ClearingSystemIdentification2Choice),
File 2 (PostalAddress27).
Load order: 10.2 -> File 1 -> File 2 -> File 3 (this file) -> File 4.
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

'''
emit(HEADER)

# ---------------------------------------------------------------------
# PART 1 -- 10.1.1 Account / 10.1.2 Account Identification
# ---------------------------------------------------------------------
emit('-- ---------------------------------------------------------------------')
emit('-- PART 1 -- 10.1.1 Account / 10.1.2 Account Identification')
emit('-- ---------------------------------------------------------------------\n')

# AccountSchemeName1Choice (inline, GenericAccountIdentification1.SchemeName)
choice_type("AccountSchemeName1Choice", [
    ("Code", 'public."ExternalAccountIdentification1Code"', 'Name of the identification scheme, in a coded form as published in an external list.'),
    ("Proprietary", 'public."Max35Text"', 'Name of the identification scheme, in a free text form.'),
], "inline, 10.1.1.4.2", "Name of the identification scheme.")

# GenericAccountIdentification1 (10.1.1.4)
simple_type("GenericAccountIdentification1", [
    ("Identification", 'public."Max34Text"', 'Identification assigned by an institution.'),
    ("SchemeName", 'public."AccountSchemeName1Choice"', 'Name of the identification scheme.'),
    ("Issuer", 'public."Max35Text"', 'Entity that assigns the identification.'),
], "10.1.1.4", "Information related to a generic account identification.",
   required=["Identification"])

# AccountIdentification4Choice (10.1.2.1)
choice_type("AccountIdentification4Choice", [
    ("IBAN", 'public."IBAN2007Identifier"',
     'International Bank Account Number (IBAN). Constraint C15 "IBAN" -- structure/length already enforced '
     'by the IBAN2007Identifier domain (10.2); mod-97 check digit is NOT verified there.'),
    ("Other", 'public."GenericAccountIdentification1"',
     'Unique identification of an account, as assigned by the account servicer, using an identification scheme.'),
], "10.1.2.1", "Specifies the unique identification of an account as assigned by the account servicer.")

# CashAccountType2Choice (10.1.1.3)
choice_type("CashAccountType2Choice", [
    ("Code", 'public."ExternalCashAccountType1Code"', 'Account type, in a coded form.'),
    ("Proprietary", 'public."Max35Text"', 'Nature or use of the account in a proprietary form.'),
], "10.1.1.3", "Nature or use of the account.")

# ProxyAccountType1Choice (inline, ProxyAccountIdentification1.Type)
choice_type("ProxyAccountType1Choice", [
    ("Code", 'public."ExternalProxyAccountType1Code"', 'Name of the identification scheme, in a coded form as published in an external list.'),
    ("Proprietary", 'public."Max35Text"', 'Name of the identification scheme, in a free text form.'),
], "inline, 10.1.1.2.1", "Type of the proxy identification.")

# ProxyAccountIdentification1 (10.1.1.2)
simple_type("ProxyAccountIdentification1", [
    ("Type", 'public."ProxyAccountType1Choice"', 'Type of the proxy identification.'),
    ("Identification", 'public."Max2048Text"', 'Identification used to indicate the account identification under another specified name.'),
], "10.1.1.2", "Information related to a proxy identification of the account.",
   required=["Identification"])

# CashAccount40 (10.1.1.1) -- inclusive-or business rule (not exclusive)
emit('-- Type: CashAccount40 (10.1.1.1)')
emit('DROP TYPE IF EXISTS public."CashAccount40" CASCADE;')
emit('CREATE TYPE public."CashAccount40" AS (')
emit('    "Identification" public."AccountIdentification4Choice",')
emit('    "Type" public."CashAccountType2Choice",')
emit('    "Currency" public."ActiveOrHistoricCurrencyCode",')
emit('    "Name" public."Max70Text",')
emit('    "Proxy" public."ProxyAccountIdentification1"')
emit(');')
emit('ALTER TYPE public."CashAccount40" OWNER TO postgres;')
emit('COMMENT ON TYPE public."CashAccount40" IS')
emit(sqlstr('Definition: Provides the details to identify an account.\n\n'
            'Identification: [0..1] AccountIdentification4Choice (IBAN or Other).\n'
            'Type: [0..1] Nature or use of the account.\n'
            'Currency: [0..1] Currency in which the account is held. Constraint C2 '
            '"ActiveOrHistoricCurrency" -- format enforced by the domain.\n'
            'Name: [0..1] Name of the account, as assigned by the account servicer.\n'
            'Proxy: [0..1] Alternate assumed name for the identification of the account.\n\n'
            'Constraint - IdentificationAndProxyGuideline: if the account identification is not a '
            'conventional identifier (email, mobile number), Proxy should be used instead. (Guidance, '
            'not a hard rule -- not enforced by the validate_ function below.)\n\n'
            'Constraint - IdentificationOrProxyPresenceRule: Identification must be present OR Proxy must '
            'be present (both may be present) -- an inclusive-or, like PaymentIdentification13''s rule in '
            'File 1, not the exactly-one {Or}/{Or} pattern.') + ';\n')

emit('DROP FUNCTION IF EXISTS public.validate_cash_account40(public."CashAccount40");')
emit('CREATE OR REPLACE FUNCTION public.validate_cash_account40(')
emit('    val public."CashAccount40")')
emit('    RETURNS boolean')
emit("    LANGUAGE 'plpgsql'")
emit('    COST 100')
emit('    IMMUTABLE PARALLEL UNSAFE')
emit('AS $BODY$')
emit('BEGIN')
ident_check = branch_populated_expr("Identification", 'public."AccountIdentification4Choice"')
proxy_check = branch_populated_expr("Proxy", 'public."ProxyAccountIdentification1"')
emit(f'    RETURN ({ident_check})')
emit(f'        OR ({proxy_check});')
emit('END;')
emit('$BODY$;')
emit('ALTER FUNCTION public.validate_cash_account40(public."CashAccount40")')
emit('    OWNER TO postgres;')
emit('COMMENT ON FUNCTION public.validate_cash_account40(public."CashAccount40") IS')
emit(sqlstr('Checks the IdentificationOrProxyPresenceRule: at least one of Identification/Proxy is '
            'populated (inclusive-or). Uses num_nonnulls-based checks since both are optional-field '
            'composite types, not plain scalars.') + ';\n')
TYPE_FIELDS["CashAccount40"] = ["Identification", "Type", "Currency", "Name", "Proxy"]

with open('/home/claude/sql_10_1_file3.sql', 'w') as f:
    f.writelines(out)
print("Part 1 complete")

# ---------------------------------------------------------------------
# PART 2 -- 10.1.7 Financial Institution Identification
# ---------------------------------------------------------------------
emit('-- ---------------------------------------------------------------------')
emit('-- PART 2 -- 10.1.7 Financial Institution Identification')
emit('-- ---------------------------------------------------------------------\n')

# ClearingSystemMemberIdentification2 (10.1.7.1) -- reuses File 1's ClearingSystemIdentification2Choice
simple_type("ClearingSystemMemberIdentification2", [
    ("ClearingSystemIdentification", 'public."ClearingSystemIdentification2Choice"',
     'Specification of a pre-agreed offering between clearing agents or the channel through which the payment instruction is processed.'),
    ("MemberIdentification", 'public."Max35Text"', 'Identification of a member of a clearing system.'),
], "10.1.7.1", "Unique identification, as assigned by a clearing system, to unambiguously identify a member of the clearing system.",
   required=["MemberIdentification"])

# FinancialIdentificationSchemeName1Choice (inline, GenericFinancialIdentification1.SchemeName)
choice_type("FinancialIdentificationSchemeName1Choice", [
    ("Code", 'public."ExternalFinancialInstitutionIdentification1Code"', 'Name of the identification scheme, in a coded form as published in an external list.'),
    ("Proprietary", 'public."Max35Text"', 'Name of the identification scheme, in a free text form.'),
], "inline, 10.1.7.2.2", "Name of the identification scheme.")

# GenericFinancialIdentification1 (10.1.7.2)
simple_type("GenericFinancialIdentification1", [
    ("Identification", 'public."Max35Text"', 'Unique and unambiguous identification of a person.'),
    ("SchemeName", 'public."FinancialIdentificationSchemeName1Choice"', 'Name of the identification scheme.'),
    ("Issuer", 'public."Max35Text"', 'Entity that assigns the identification.'),
], "10.1.7.2", "Information related to an identification of a financial institution.",
   required=["Identification"])

# FinancialInstitutionIdentification23 (inline, BranchAndFinancialInstitutionIdentification8.FinancialInstitutionIdentification)
emit('-- Type: FinancialInstitutionIdentification23 (inline, 10.1.7.3.1)')
emit('DROP TYPE IF EXISTS public."FinancialInstitutionIdentification23" CASCADE;')
emit('CREATE TYPE public."FinancialInstitutionIdentification23" AS (')
emit('    "BICFI" public."BICFIDec2014Identifier",')
emit('    "ClearingSystemMemberIdentification" public."ClearingSystemMemberIdentification2",')
emit('    "LEI" public."LEIIdentifier",')
emit('    "Name" public."Max140Text",')
emit('    "PostalAddress" public."PostalAddress27",')
emit('    "Other" public."GenericFinancialIdentification1"')
emit(');')
emit('ALTER TYPE public."FinancialInstitutionIdentification23" OWNER TO postgres;')
emit('COMMENT ON TYPE public."FinancialInstitutionIdentification23" IS')
emit(sqlstr('Definition: Unique and unambiguous identification of a financial institution, as assigned '
            'under an internationally recognised or proprietary identification scheme.\n\n'
            'BICFI: [0..1] Constraint C5 "BICFI" -- format already enforced by the BICFIDec2014Identifier domain.\n'
            'ClearingSystemMemberIdentification: [0..1] Reuses ClearingSystemMemberIdentification2.\n'
            'LEI: [0..1] Legal entity identifier of the financial institution.\n'
            'Name: [0..1] Name by which an agent is known.\n'
            'PostalAddress: [0..1] Reuses PostalAddress27 (File 2).\n'
            'Other: [0..1] Reuses GenericFinancialIdentification1 -- note: [0..1] here, NOT repeatable '
            '(unlike some other "Other" fields elsewhere in this library which are [0..*]).\n\n'
            'All fields optional -- no validate_ function needed at this level.') + ';\n')
TYPE_FIELDS["FinancialInstitutionIdentification23"] = ["BICFI", "ClearingSystemMemberIdentification", "LEI", "Name", "PostalAddress", "Other"]

# BranchData5 (inline, BranchAndFinancialInstitutionIdentification8.BranchIdentification)
emit('-- Type: BranchData5 (inline, 10.1.7.3.2)')
emit('DROP TYPE IF EXISTS public."BranchData5" CASCADE;')
emit('CREATE TYPE public."BranchData5" AS (')
emit('    "Identification" public."Max35Text",')
emit('    "LEI" public."LEIIdentifier",')
emit('    "Name" public."Max140Text",')
emit('    "PostalAddress" public."PostalAddress27"')
emit(');')
emit('ALTER TYPE public."BranchData5" OWNER TO postgres;')
emit('COMMENT ON TYPE public."BranchData5" IS')
emit(sqlstr('Definition: Identifies a specific branch of a financial institution.\n\n'
            'Usage: This component should be used in case the identification information in the financial '
            'institution component does not provide identification up to branch level.\n\n'
            'Identification: [0..1] Unique identification of a branch of a financial institution.\n'
            'LEI: [0..1] Legal entity identifier.\n'
            'Name: [0..1] Name of the branch.\n'
            'PostalAddress: [0..1] Reuses PostalAddress27 (File 2).\n\n'
            'All fields optional -- no validate_ function needed at this level.') + ';\n')
TYPE_FIELDS["BranchData5"] = ["Identification", "LEI", "Name", "PostalAddress"]

# BranchAndFinancialInstitutionIdentification8 (10.1.7.3) -- top-level component
simple_type("BranchAndFinancialInstitutionIdentification8", [
    ("FinancialInstitutionIdentification", 'public."FinancialInstitutionIdentification23"',
     'Unique and unambiguous identification of a financial institution.'),
    ("BranchIdentification", 'public."BranchData5"', 'Identifies a specific branch of a financial institution.'),
], "10.1.7.3", "Unique and unambiguous identification of a financial institution or a branch of a financial institution.",
   required=["FinancialInstitutionIdentification"])

with open('/home/claude/sql_10_1_file3.sql', 'w') as f:
    f.writelines(out)
save_registry(TYPE_FIELDS)
print("Part 2 complete -- FILE 3 GENERATION DONE")
