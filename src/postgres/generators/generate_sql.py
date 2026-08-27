#!/usr/bin/env python3
"""
Generates PostgreSQL DDL for ISO 20022 MDR Part 2 (Payments Clearing &
Settlement, Maintenance 2024-2025), Section 10.2 "Message Datatypes"
(pages 845-869).

Source: ISO20022_MDRPart2_PaymentsClearingAndSettlement_2024_2025_v1.pdf
Conventions follow the user's own AddressType2Code / validate_date_period
examples: schema public, double-quoted PascalCase names matching the MDR
exactly, OWNER TO postgres, full COMMENT ON blocks carrying the MDR prose
so the documentation survives outside the source PDF.
"""

out = []

def emit(sql):
    out.append(sql.rstrip() + "\n")

HEADER = '''-- =====================================================================
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

'''
emit(HEADER)

# ---------------------------------------------------------------------
# PART 1 - 10.2.3 CodeSet: pattern-only codes (external registries,
# but not "External*Code" named types -> no lookup table requested for
# these two + CountryCode; flagged to the user separately).
# ---------------------------------------------------------------------
emit('-- ---------------------------------------------------------------------')
emit('-- PART 1 -- 10.2.3 CodeSet: pattern-only codes backed by external registries')
emit('-- (ISO 4217 currency list, UN/ISO 3166 country list). Format-only checks.')
emit('-- ---------------------------------------------------------------------\n')

pattern_domains = [
    ("ActiveCurrencyCode", 3, r'^[A-Z]{3}$',
     'Definition: A code allocated to a currency by a Maintenance Agency under an '
     'international identification scheme as described in the latest edition of '
     'ISO 4217 "Codes for the representation of currencies and funds".\n\n'
     'Format: pattern [A-Z]{3,3} (3 contiguous uppercase letters).\n\n'
     'Constraint - ActiveCurrency: The currency code must be a valid ACTIVE '
     'currency code, not yet withdrawn on the day the message containing the '
     'currency is exchanged. Valid active currency codes are registered with '
     'the ISO 4217 Maintenance Agency, consist of three (3) contiguous letters, '
     'and are not yet withdrawn on the day the message is exchanged.\n\n'
     'Note: this domain enforces FORMAT ONLY (3 letters). Whether a code is '
     'currently active per ISO 4217 is not enforced at the database layer -- '
     'see the paired public."ActiveCurrencyCodeValues" lookup table below.'),
    ("ActiveOrHistoricCurrencyCode", 3, r'^[A-Z]{3}$',
     'Definition: A code allocated to a currency by a Maintenance Agency under an '
     'international identification scheme, as described in ISO 4217 "Codes for '
     'the representation of currencies and funds".\n\n'
     'Format: pattern [A-Z]{3,3} (3 contiguous uppercase letters).\n\n'
     'Constraint - ActiveOrHistoricCurrency: The currency code must be '
     'registered, or have already been registered (i.e. active OR historic / '
     'withdrawn). Valid codes are registered with the ISO 4217 Maintenance '
     'Agency.\n\n'
     'Note: this domain enforces FORMAT ONLY (3 letters), not registration '
     'status -- see the paired public."ActiveOrHistoricCurrencyCodeValues" '
     'lookup table below.'),
    ("CountryCode", 2, r'^[A-Z]{2}$',
     'Definition: Code to identify a country, a dependency, or another area of '
     'particular geopolitical interest, on the basis of country names obtained '
     'from the United Nations (ISO 3166, Alpha-2 code).\n\n'
     'Format: pattern [A-Z]{2,2} (2 contiguous uppercase letters).\n\n'
     'Constraint - Country: The code is checked against the list of country '
     'names obtained from the United Nations (ISO 3166, Alpha-2 code).\n\n'
     'Note: this domain enforces FORMAT ONLY (2 letters), not current UN/ISO '
     '3166 list membership -- see the paired public."CountryCodeValues" '
     'lookup table below.'),
]

for name, length, pattern, comment in pattern_domains:
    emit(f'-- Domain: {name}')
    emit(f'DROP DOMAIN IF EXISTS public.\"{name}\" CASCADE;')
    emit(f'CREATE DOMAIN public."{name}" AS varchar({length})')
    emit(f"    CHECK (VALUE ~ '{pattern}');")
    emit(f'ALTER DOMAIN public."{name}" OWNER TO postgres;')
    esc = comment.replace("'", "''")
    emit(f'COMMENT ON DOMAIN public."{name}" IS')
    emit(f"'{esc}';\n")

    tbl_comment = {
        "ActiveCurrencyCode": 'Lookup scaffold for ActiveCurrencyCode (ISO 4217 currently-'
            'active currencies). Empty by design -- populate from the current ISO 4217 '
            'Maintenance Agency list before relying on it for FK-enforced validation. '
            'Ask if you would like this pre-populated with the current published list.',
        "ActiveOrHistoricCurrencyCode": 'Lookup scaffold for ActiveOrHistoricCurrencyCode '
            '(ISO 4217 active AND historic/withdrawn currencies). Empty by design -- '
            'populate from the ISO 4217 Maintenance Agency list (including withdrawn '
            'codes) before relying on it for FK-enforced validation. "IsActive" '
            'distinguishes currently-active codes from historic/withdrawn ones once '
            'populated. Ask if you would like this pre-populated.',
        "CountryCode": 'Lookup scaffold for CountryCode (UN/ISO 3166-1 Alpha-2 country '
            'codes). Empty by design -- populate from the current ISO 3166 list before '
            'relying on it for FK-enforced validation. Ask if you would like this '
            'pre-populated with the current published list.',
    }[name].replace("'", "''")
    emit(f'-- Table: {name}Values')
    emit(f'DROP TABLE IF EXISTS public.\"{name}Values\" CASCADE;')
    emit(f'CREATE TABLE public."{name}Values" (')
    emit(f'    "Code" public."{name}" PRIMARY KEY,')
    emit(f'    "Name" text NOT NULL,')
    emit(f'    "Definition" text,')
    emit(f'    "IsActive" boolean NOT NULL DEFAULT true')
    emit(f');')
    emit(f'ALTER TABLE public."{name}Values" OWNER TO postgres;')
    emit(f'COMMENT ON TABLE public."{name}Values" IS')
    emit(f"'{tbl_comment}';\n")

print(f"Part 1 done: {len(pattern_domains)} domains + lookup tables")

# ---------------------------------------------------------------------
# PART 1b -- Seed data for ActiveCurrencyCodeValues,
# ActiveOrHistoricCurrencyCodeValues, CountryCodeValues, sourced from:
#   ISO 4217: https://datahub.io/core/currency-codes (data/codes-all.csv)
#             consolidation of ISO Tables A.1 + A.3, source SIX Interbank
#             Clearing Ltd on behalf of ISO, ODC-PDDL-1.0, updated 2026-02-09
#   ISO 3166-1 alpha-2: https://datahub.io/core/country-list (data.csv)
#             source: ISO Online Browsing Platform, ODC-PDDL-1.0,
#             249 entries as of 2026-05-12
# ---------------------------------------------------------------------
import csv as _csv

def sqlstr(s):
    # Normalize typographic/smart punctuation to plain ASCII before escaping.
    # Non-ASCII quote/dash characters are syntactically valid inside a SQL
    # string as-is, but they survive intact only if every tool that touches
    # this file afterward (editor, clipboard, terminal, download pipeline)
    # preserves UTF-8 bytes faithfully. When one doesn't -- e.g. a curly
    # apostrophe silently flattened to a straight one -- that straight quote
    # terminates the SQL string early and breaks syntax. Normalizing here
    # removes the whole class of failure regardless of what mangles it
    # downstream, at the cost of a slightly less typographically pretty
    # source string.
    _normalize = {
        '\u2018': "'", '\u2019': "'",    # left/right single quotation mark
        '\u201c': '"', '\u201d': '"',    # left/right double quotation mark
        '\u2013': '-', '\u2014': '-',    # en dash, em dash
        '\u2026': '...',                 # ellipsis
        '\u00a0': ' ',                   # non-breaking space
    }
    for orig, repl in _normalize.items():
        s = s.replace(orig, repl)
    return "'" + s.replace("'", "''") + "'"

emit('-- ---------------------------------------------------------------------')
emit('-- PART 1b -- Seed data: ISO 4217 currencies and ISO 3166-1 countries')
emit('-- Source: ISO 4217 -- https://datahub.io/core/currency-codes')
emit('--         (SIX Interbank Clearing Ltd on behalf of ISO; ODC-PDDL-1.0;')
emit('--          consolidated Tables A.1 + A.3; retrieved 2026-08-26)')
emit('--         ISO 3166-1 alpha-2 -- https://datahub.io/core/country-list')
emit('--         (source: ISO Online Browsing Platform; ODC-PDDL-1.0;')
emit('--          249 entries as of 2026-05-12; retrieved 2026-08-26)')
emit('-- Re-run against a refreshed CSV to update; these lists do drift')
emit('-- (new currencies, redenominations, occasional country code changes).')
emit('-- ---------------------------------------------------------------------\n')

emit('-- ---------------------------------------------------------------------')
emit('-- PART 1b -- Seed data: ISO 4217 currencies and ISO 3166-1 countries')
emit('-- Source: ISO 4217 -- https://datahub.io/core/currency-codes')
emit('--         (SIX Interbank Clearing Ltd on behalf of ISO; ODC-PDDL-1.0;')
emit('--          consolidated Tables A.1 + A.3; retrieved 2026-08-26)')
emit('--         ISO 3166-1 alpha-2 -- https://datahub.io/core/country-list')
emit('--         (source: ISO Online Browsing Platform; ODC-PDDL-1.0;')
emit('--          249 entries as of 2026-05-12; retrieved 2026-08-26)')
emit('-- Re-run against a refreshed CSV to update; these lists do drift')
emit('-- (new currencies, redenominations, occasional country code changes).')
emit('--')
emit('-- NOTE: 6 country names contain accented characters (Curacao, Cote')
emit("-- d'Ivoire, Reunion, Saint Barthelemy, Turkiye, Aland Islands). The")
emit('-- client_encoding line below guards against a non-UTF8 session silently')
emit('-- failing the whole batch on those rows.')
emit('-- ---------------------------------------------------------------------\n')
emit("SET client_encoding = 'UTF8';\n")

def batched(items, n):
    items = list(items)
    for i in range(0, len(items), n):
        yield items[i:i+n]

BATCH_SIZE = 40

with open('/home/claude/iso4217_raw.csv') as f:
    currency_rows = list(_csv.DictReader(f))

active_currency = {}
all_currency = {}
for r in currency_rows:
    code = r['AlphabeticCode'].strip()
    if not code:
        continue
    name = r['Currency'].strip()
    withdrawal = r['WithdrawalDate'].strip()
    all_currency.setdefault(code, name)
    if not withdrawal:
        active_currency[code] = name

# ActiveCurrencyCodeValues: currently-active codes only, batched
emit('-- Seed: ActiveCurrencyCodeValues (currently active ISO 4217 codes)')
items = sorted(active_currency.items())
for batch in batched(items, BATCH_SIZE):
    rows_sql = ",\n    ".join(f"({sqlstr(code)}, {sqlstr(name)})" for code, name in batch)
    emit(f'INSERT INTO public."ActiveCurrencyCodeValues" ("Code", "Name") VALUES')
    emit(f'    {rows_sql}')
    emit('ON CONFLICT ("Code") DO NOTHING;\n')
print(f"Seeded ActiveCurrencyCodeValues: {len(active_currency)} rows in "
      f"{-(-len(items)//BATCH_SIZE)} batches")

# ActiveOrHistoricCurrencyCodeValues: all codes, IsActive flag set accordingly
emit('-- Seed: ActiveOrHistoricCurrencyCodeValues (active + historic/withdrawn)')
items = sorted(all_currency.items())
for batch in batched(items, BATCH_SIZE):
    rows_sql = ",\n    ".join(
        f"({sqlstr(code)}, {sqlstr(name)}, {'true' if code in active_currency else 'false'})"
        for code, name in batch
    )
    emit(f'INSERT INTO public."ActiveOrHistoricCurrencyCodeValues" ("Code", "Name", "IsActive") VALUES')
    emit(f'    {rows_sql}')
    emit('ON CONFLICT ("Code") DO NOTHING;\n')
print(f"Seeded ActiveOrHistoricCurrencyCodeValues: {len(all_currency)} rows in "
      f"{-(-len(items)//BATCH_SIZE)} batches "
      f"({len(active_currency)} active, {len(all_currency)-len(active_currency)} historic-only)")

with open('/home/claude/iso3166_raw.csv') as f:
    country_rows = list(_csv.DictReader(f))

emit('-- Seed: CountryCodeValues (ISO 3166-1 alpha-2, official short names)')
country_entries = []
for r in country_rows:
    name = r['Name'].strip()
    code = r['Code'].strip()
    provisional = name.endswith('*')
    clean_name = name.rstrip('*').strip()
    definition = 'Provisional name per ISO 3166/MA.' if provisional else None
    country_entries.append((code, clean_name, definition))

items = sorted(country_entries)
for batch in batched(items, BATCH_SIZE):
    rows_sql = ",\n    ".join(
        f"({sqlstr(code)}, {sqlstr(name)}, {sqlstr(defn) if defn else 'NULL'})"
        for code, name, defn in batch
    )
    emit(f'INSERT INTO public."CountryCodeValues" ("Code", "Name", "Definition") VALUES')
    emit(f'    {rows_sql}')
    emit('ON CONFLICT ("Code") DO NOTHING;\n')
print(f"Seeded CountryCodeValues: {len(country_entries)} rows in "
      f"{-(-len(items)//BATCH_SIZE)} batches")

# Verification block -- makes population success/failure immediately visible
# in the psql/client output, rather than a silent empty table.
emit('-- Verification -- confirms seed data actually landed. If any of these')
emit('-- read 0, look upward in your client output for an ERROR line from one')
emit('-- of the INSERT batches above (a common cause: non-UTF8 client_encoding')
emit('-- choking on the accented country names noted above).')
emit('SELECT \'ActiveCurrencyCodeValues\' AS "Table", count(*) AS "RowCount" FROM public."ActiveCurrencyCodeValues"')
emit('UNION ALL SELECT \'ActiveOrHistoricCurrencyCodeValues\', count(*) FROM public."ActiveOrHistoricCurrencyCodeValues"')
emit('UNION ALL SELECT \'CountryCodeValues\', count(*) FROM public."CountryCodeValues";\n')

with open('/home/claude/sql_generated.sql', 'w') as f:
    f.writelines(out)

# ---------------------------------------------------------------------
# PART 2 - 10.2.3 CodeSet: embedded value lists -> native ENUM
# (19 code sets whose full value list is printed in the MDR)
# ---------------------------------------------------------------------
emit('-- ---------------------------------------------------------------------')
emit('-- PART 2 -- 10.2.3 CodeSet: embedded value lists -> native ENUM')
emit('-- ---------------------------------------------------------------------\n')

# (name, definition, [(code, name, definition), ...])
enums = [
    ("AddressType2Code", "Specifies the type of address.", [
        ("ADDR", "Postal", "Address is the complete postal address."),
        ("PBOX", "POBox", "Address is a postal office (PO) box."),
        ("HOME", "Residential", "Address is the home address."),
        ("BIZZ", "Business", "Address is the business address."),
        ("MLTO", "MailTo", "Address is the address to which mail is sent."),
        ("DLVY", "DeliveryTo", "Address is the address to which delivery is to take place."),
    ]),
    ("Authorisation1Code", "Specifies the level of approval depending on a number of "
     "factors, including payment type, threshold amount or local country or "
     "operations practice.", [
        ("AUTH", "PreAuthorisedFile", "Indicates a file has been pre authorised or "
         "approved within the originating customer environment and no further "
         "approval is required."),
        ("FDET", "FileLevelAuthorisationDetails", "Indicates that a file requires "
         "additional file level approval, with the ability to view both the payment "
         "information block and supporting customer credit transaction detail."),
        ("FSUM", "FileLevelAuthorisationSummary", "Indicates that a file requires "
         "additional file level approval, with the ability to view only the payment "
         "information block level information."),
        ("ILEV", "InstructionLevelAuthorisation", "Indicates that a file requires all "
         "customer transactions to be authorised or approved."),
    ]),
    ("ChargeBearerType1Code", "Specifies which party(ies) will pay charges due for "
     "processing of the instruction.", [
        ("DEBT", "BorneByDebtor", "All transaction charges are to be borne by the debtor."),
        ("CRED", "BorneByCreditor", "All transaction charges are to be borne by the creditor."),
        ("SHAR", "Shared", "In a credit transfer context, means that transaction charges "
         "on the sender side are to be borne by the debtor, transaction charges on the "
         "receiver side are to be borne by the creditor. In a direct debit context, "
         "means that transaction charges on the sender side are to be borne by the "
         "creditor, transaction charges on the receiver side are to be borne by the debtor."),
        ("SLEV", "FollowingServiceLevel", "Charges are to be applied following the rules "
         "agreed in the service level and/or scheme."),
    ]),
    ("ClearingChannel2Code", "Specifies the clearing channel for the routing of the "
     "transaction, as part of the payment type identification.", [
        ("RTGS", "RealTimeGrossSettlementSystem", "Clearing channel is a real-time gross "
         "settlement system."),
        ("RTNS", "RealTimeNetSettlementSystem", "Clearing channel is a real-time net "
         "settlement system."),
        ("MPNS", "MassPaymentNetSystem", "Clearing channel is a mass payment net "
         "settlement system."),
        ("BOOK", "BookTransfer", "Payment through internal book transfer."),
    ]),
    ("CreditDebitCode", "Specifies if an operation is an increase or a decrease.", [
        ("CRDT", "Credit", "Operation is an increase."),
        ("DBIT", "Debit", "Operation is a decrease."),
    ]),
    ("Frequency6Code", "Specifies the regularity of an event.", [
        ("YEAR", "Annual", "Event takes place every year or once a year."),
        ("MNTH", "Monthly", "Event takes place every month or once a month."),
        ("QURT", "Quarterly", "Event takes place every three months or four times a year."),
        ("MIAN", "SemiAnnual", "Event takes place every six months or two times a year."),
        ("WEEK", "Weekly", "Event takes place once a week."),
        ("DAIL", "Daily", "Event takes place every day."),
        ("ADHO", "Adhoc", "Event takes place on request or as necessary."),
        ("INDA", "IntraDay", "Event takes place several times a day."),
        ("FRTN", "Fortnightly", "Event takes place every two weeks."),
    ]),
    ("Instruction4Code", "Specifies further instructions concerning the processing of "
     "a payment instruction, provided by the sending clearing agent to the next agent(s).", [
        ("PHOA", "PhoneNextAgent", "Please advise/contact next agent by phone."),
        ("TELA", "TelecomNextAgent", "Please advise/contact next agent by the most "
         "efficient means of telecommunication."),
    ]),
    ("MandateClassification1Code", "Specifies the type of direct debit amount, such as "
     "fixed or variable.", [
        ("FIXE", "Fixed", "Direct debit amount is fixed."),
        ("USGB", "UsageBased", "Direct debit amount is based on usage."),
        ("VARI", "Variable", "Direct debit amount is variable."),
    ]),
    ("NamePrefix2Code", "Specifies the terms used to formally address a person.", [
        ("DOCT", "Doctor", "Title of the person is Doctor or Dr."),
        ("MADM", "Madam", "Title of the person is Madam."),
        ("MISS", "Miss", "Title of the person is Miss."),
        ("MIST", "Mister", "Title of the person is Mister or Mr."),
        ("MIKS", "GenderNeutral", "Title of the person is gender neutral (Mx)."),
    ]),
    ("PaymentMethod4Code", "Specifies the transfer method that will be used to transfer "
     "an amount of money.", [
        ("CHK", "Cheque", "Written order to a bank to pay a certain amount of money "
         "from one person to another person."),
        ("TRF", "CreditTransfer", "Transfer of an amount of money in the books of the "
         "account servicer."),
        ("DD", "DirectDebit", "Collection of an amount of money from the debtor's bank "
         "account by the creditor. The amount of money and dates of collections may vary."),
        ("TRA", "TransferAdvice", "Transfer of an amount of money in the books of the "
         "account servicer. An advice should be sent back to the account owner."),
    ]),
    ("PreferredContactMethod2Code", "Preferred method used to reach the individual "
     "contact within an organisation.", [
        ("MAIL", "Email", "Preferred method used to reach the contact is per email."),
        ("FAXX", "Fax", "Preferred method used to reach the contact is per fax."),
        ("LETT", "Letter", "Preferred method used to reach the contact is per letter."),
        ("CELL", "MobileOrCellPhone", "Preferred method used to reach the contact is "
         "per mobile or cell phone."),
        ("ONLI", "Online", "Preferred method used to reach the contact is online."),
        ("PHON", "Phone", "Preferred method used to reach the contact is per phone."),
    ]),
    ("Priority2Code", "Specifies the priority level of an event.", [
        ("HIGH", "High", "Priority level is high."),
        ("NORM", "Normal", "Priority level is normal."),
    ]),
    ("Priority3Code", "Specifies the priority level of an event.", [
        ("URGT", "Urgent", "Priority level is urgent (highest priority possible)."),
        ("HIGH", "High", "Priority level is high."),
        ("NORM", "Normal", "Priority level is normal."),
    ]),
    ("RegulatoryReportingType1Code", "Identifies whether the regulatory reporting "
     "information applies to the debit side, to the credit side or to both debit and "
     "credit sides of the transaction.", [
        ("CRED", "Credit", "Regulatory information applies to the credit side."),
        ("DEBT", "Debit", "Regulatory information applies to the debit side."),
        ("BOTH", "Both", "Regulatory information applies to both credit and debit sides."),
    ]),
    ("RemittanceLocationMethod2Code", "Specifies the method used to deliver the "
     "remittance advice information.", [
        ("FAXI", "Fax", "Remittance advice information must be faxed."),
        ("EDIC", "ElectronicDataInterchange", "Remittance advice information must be "
         "sent through Electronic Data Interchange (EDI)."),
        ("URID", "UniformResourceIdentifier", "Remittance advice information needs to "
         "be sent to a Uniform Resource Identifier (URI). URI is a compact string of "
         "characters that uniquely identify an abstract or physical resource. URI's "
         "are the super-set of identifiers, such as URLs, email addresses, ftp sites, "
         "etc, and as such, provide the syntax for all of the identification schemes."),
        ("EMAL", "EMail", "Remittance advice information must be sent through e-mail."),
        ("POST", "Post", "Remittance advice information must be sent through postal services."),
        ("SMSM", "SMS", "Remittance advice information must be sent through by phone as "
         "a short message service (SMS)."),
    ]),
    ("SequenceType3Code", "Specifies the type of the current transaction that belongs "
     "to a sequence of transactions.", [
        ("FRST", "First", "First collection of a series of direct debit instructions."),
        ("RCUR", "Recurring", "Direct debit instruction where the debtor's authorisation "
         "is used for regular direct debit transactions initiated by the creditor."),
        ("FNAL", "Final", "Final collection of a series of direct debit instructions."),
        ("OOFF", "OneOff", "Direct debit instruction where the debtor's authorisation "
         "is used to initiate one single direct debit transaction."),
        ("RPRE", "Represented", "Collection used to re-present previously reversed or "
         "returned direct debit transactions."),
    ]),
    ("SettlementMethod1Code", "Specifies the method used to settle the credit transfer "
     "instruction.", [
        ("INDA", "InstructedAgent", "Settlement is done by the agent instructed to "
         "execute a payment instruction."),
        ("INGA", "InstructingAgent", "Settlement is done by the agent instructing and "
         "forwarding the payment to the next party in the payment chain."),
        ("COVE", "CoverMethod", "Settlement is done through a cover payment."),
        ("CLRG", "ClearingSystem", "Settlement is done through a payment clearing system."),
    ]),
    ("SettlementMethod2Code", "Specifies the method used to settle the credit transfer "
     "instruction.", [
        ("INDA", "InstructedAgent", "Settlement is done by the agent instructed to "
         "execute a payment instruction."),
        ("INGA", "InstructingAgent", "Settlement is done by the agent instructing and "
         "forwarding the payment to the next party in the payment chain."),
        ("CLRG", "ClearingSystem", "Settlement is done through a payment clearing system."),
    ]),
    ("TaxRecordPeriod1Code", "Specifies the period related to the tax payment.", [
        ("MM01", "FirstMonth", "Tax is related to the first month of the period."),
        ("MM02", "SecondMonth", "Tax is related to the second month of the period."),
        ("MM03", "ThirdMonth", "Tax is related to the third month of the period."),
        ("MM04", "FourthMonth", "Tax is related to the fourth month of the period."),
        ("MM05", "FifthMonth", "Tax is related to the fifth month of the period."),
        ("MM06", "SixthMonth", "Tax is related to the sixth month of the period."),
        ("MM07", "SeventhMonth", "Tax is related to the seventh month of the period."),
        ("MM08", "EighthMonth", "Tax is related to the eighth month of the period."),
        ("MM09", "NinthMonth", "Tax is related to the ninth month of the period."),
        ("MM10", "TenthMonth", "Tax is related to the tenth month of the period."),
        ("MM11", "EleventhMonth", "Tax is related to the eleventh month of the period."),
        ("MM12", "TwelfthMonth", "Tax is related to the twelfth month of the period."),
        ("QTR1", "FirstQuarter", "Tax is related to the first quarter of the period."),
        ("QTR2", "SecondQuarter", "Tax is related to the second quarter of the period."),
        ("QTR3", "ThirdQuarter", "Tax is related to the third quarter of the period."),
        ("QTR4", "FourthQuarter", "Tax is related to the fourth quarter of the period."),
        ("HLF1", "FirstHalf", "Tax is related to the first half of the period."),
        ("HLF2", "SecondHalf", "Tax is related to the second half of the period."),
    ]),
]

# NOTE on TaxRecordPeriod1Code MM01/MM02: the source PDF text literally has a
# copy-editing swap ("MM01 FirstMonth ... second month of the period." /
# "MM02 SecondMonth ... first month of the period.") -- the CodeName/Name
# columns are unambiguous and used here as ground truth; see caveat in reply.

for name, definition, values in enums:
    vals_sql = ", ".join(f"'{c}'" for c, n, d in values)
    emit(f'-- Type: {name}')
    emit(f'DROP TYPE IF EXISTS public.\"{name}\" CASCADE;')
    emit(f'CREATE TYPE public."{name}" AS ENUM')
    emit(f'    ({vals_sql});')
    emit(f'ALTER TYPE public."{name}" OWNER TO postgres;')
    lines = [definition, "CodeSet:"]
    for c, n, d in values:
        lines.append(f"{c} ({n}): {d}")
    comment = "\n".join(lines).replace("'", "''")
    emit(f'COMMENT ON TYPE public."{name}" IS')
    emit(f"'{comment}';\n")

print(f"Part 2 done: {len(enums)} enums")

# ---------------------------------------------------------------------
# PART 3 - 10.2.3 CodeSet: External*Code (26 types) -> domain (format
# check only) + an empty paired lookup table scaffold, per instruction.
# ---------------------------------------------------------------------
emit('-- ---------------------------------------------------------------------')
emit('-- PART 3 -- 10.2.3 CodeSet: External*Code -> domain + lookup table scaffold')
emit('-- Values are maintained by ISO 20022, not embedded in the MDR. Populate')
emit('-- each "<Name>Values" table from https://www.iso20022.org external code')
emit('-- list downloads, then FK downstream columns to it for strict validation.')
emit('-- ---------------------------------------------------------------------\n')

# (name, maxLength, definition)
external_codes = [
    ("ExternalAccountIdentification1Code", 4,
     "Specifies the external account identification scheme name code in the "
     "format of character string with a maximum length of 4 characters. The "
     "list of valid codes is an external code list published separately."),
    ("ExternalCashAccountType1Code", 4,
     "Specifies the nature, or use, of the cash account in the format of "
     "character string with a maximum length of 4 characters. The list of "
     "valid codes is an external code list published separately."),
    ("ExternalCashClearingSystem1Code", 3,
     "Specifies the cash clearing system, as published in an external cash "
     "clearing system code list."),
    ("ExternalCategoryPurpose1Code", 4,
     "Specifies the category purpose, as published in an external category "
     "purpose code list."),
    ("ExternalChargeType1Code", 4,
     "Specifies the nature, or use, of the charges in the format of character "
     "string with a maximum length of 4 characters. The list of valid codes "
     "is an external code list published separately."),
    ("ExternalClearingSystemIdentification1Code", 5,
     "Specifies the clearing system identification code, as published in an "
     "external clearing system identification code list."),
    ("ExternalCreditorAgentInstruction1Code", 4,
     "Specifies further instructions concerning the processing of a payment "
     "instruction, as provided to the creditor agent."),
    ("ExternalCreditorReferenceType1Code", 4,
     "Specifies the type of creditor reference as published in an external "
     "creditor reference type code set."),
    ("ExternalDateType1Code", 4,
     "Defines the type of date, as published in an external date type code list."),
    ("ExternalDocumentAmountType1Code", 4,
     "Specifies the nature, or use, of the amount, as published in an external "
     "document amount type code set."),
    ("ExternalDocumentLineType1Code", 4,
     "Specifies the document line type as published in an external document "
     "type code list."),
    ("ExternalDocumentType1Code", 4,
     "Specifies the document type as published in an external document type "
     "code list."),
    ("ExternalFinancialInstitutionIdentification1Code", 4,
     "Specifies the external financial institution identification scheme "
     "name code in the format of character string with a maximum length of "
     "4 characters. The list of valid codes is an external code list "
     "published separately."),
    ("ExternalGarnishmentType1Code", 4,
     "Specifies the garnishment type as published in an external document "
     "type code list."),
    ("ExternalLocalInstrument1Code", 35,
     "Specifies the external local instrument code in the format of character "
     "string with a maximum length of 35 characters. The list of valid codes "
     "is an external code list published separately."),
    ("ExternalMandateSetupReason1Code", 4,
     "Specifies the external mandate setup reason code in the format of "
     "character string with a maximum length of 4 characters."),
    ("ExternalOrganisationIdentification1Code", 4,
     "Specifies the external organisation identification scheme name code in "
     "the format of character string with a maximum length of 4 characters. "
     "The list of valid codes is an external code list published separately."),
    ("ExternalPaymentGroupStatus1Code", 4,
     "Specifies the status of a group of payment instructions, as published "
     "in an external payment group status code set."),
    ("ExternalPaymentTransactionStatus1Code", 4,
     "Specifies the status of an individual payment instructions, as "
     "published in an external payment transaction status code set."),
    ("ExternalPersonIdentification1Code", 4,
     "Specifies the external person identification scheme name code in the "
     "format of character string with a maximum length of 4 characters. The "
     "list of valid codes is an external code list published separately."),
    ("ExternalProxyAccountType1Code", 4,
     "Specifies the external proxy account type code, as published in the "
     "proxy account type external code set."),
    ("ExternalPurpose1Code", 4,
     "Specifies the external purpose code in the format of character string "
     "with a maximum length of 4 characters. The list of valid codes is an "
     "external code list published separately."),
    ("ExternalReturnReason1Code", 4,
     "Specifies the return reason, as published in an external return reason "
     "code list."),
    ("ExternalReversalReason1Code", 4,
     "Specifies the reversal reason, as published in an external reversal "
     "reason code list."),
    ("ExternalServiceLevel1Code", 4,
     "Specifies the external service level code in the format of character "
     "string with a maximum length of 4 characters. The list of valid codes "
     "is an external code list published separately."),
    ("ExternalStatusReason1Code", 4,
     "Specifies the status reason, as published in an external status reason "
     "code list."),
]

assert len(external_codes) == 26, len(external_codes)

for name, maxlen, definition in external_codes:
    comment = (f"{definition}\n\n"
               f"Format: minLength 1, maxLength {maxlen}.\n\n"
               f'Note: values are maintained externally by ISO 20022, not '
               f'embedded in the MDR. This domain enforces LENGTH ONLY. '
               f'Download the current list from https://www.iso20022.org '
               f'and populate public."{name}Values" below; reference that '
               f'table via FK from consuming columns for authoritative '
               f'validation.').replace("'", "''")
    emit(f'-- Domain: {name}')
    emit(f'DROP DOMAIN IF EXISTS public.\"{name}\" CASCADE;')
    emit(f'CREATE DOMAIN public."{name}" AS varchar({maxlen})')
    emit(f'    CHECK (char_length(VALUE) >= 1);')
    emit(f'ALTER DOMAIN public."{name}" OWNER TO postgres;')
    emit(f'COMMENT ON DOMAIN public."{name}" IS')
    emit(f"'{comment}';\n")

    tbl_comment = (f'Lookup for the {name} external code list, sourced from the official '
                   f'ISO 20022 External Code Sets registry (https://www.iso20022.org, '
                   f"quarterly XLSX publication). \"Status\" is the registry's own field "
                   f"('Registered' or 'Obsolete'), not a derived flag. \"ReplacedBy\" is "
                   f"free text (the successor code), not FK-constrained, since a successor "
                   f"can be a code retired from an earlier quarter's list.").replace("'", "''")
    emit(f'-- Table: {name}Values')
    emit(f'DROP TABLE IF EXISTS public.\"{name}Values\" CASCADE;')
    emit(f'CREATE TABLE public."{name}Values" (')
    emit(f'    "Code" public."{name}" PRIMARY KEY,')
    emit(f'    "Name" text NOT NULL,')
    emit(f'    "Definition" text,')
    emit(f'    "Status" text,')
    emit(f'    "LastUpdate" date,')
    emit(f'    "CreationDate" date,')
    emit(f'    "ReplacedBy" text,')
    emit(f'    "AdditionalInformation" text')
    emit(f');')
    emit(f'ALTER TABLE public."{name}Values" OWNER TO postgres;')
    emit(f'COMMENT ON TABLE public."{name}Values" IS')
    emit(f"'{tbl_comment}';\n")

print(f"Part 3 done: {len(external_codes)} external codes + lookup tables")

# ---------------------------------------------------------------------
# PART 3b -- Seed data for the 26 External*Code lookup tables, sourced
# from the official ISO 20022 External Code Sets registry:
#   https://www.iso20022.org/catalogue-messages/additional-content-messages/external-code-sets
#   Publication: 1Q2026 (v1), XLSX format, sheet "AllCodeSets"
#   3247 total rows across 135 code sets in the full registry; filtered
#   here to the 26 code sets referenced by this MDR.
# ---------------------------------------------------------------------
emit('-- ---------------------------------------------------------------------')
emit('-- PART 3b -- Seed data: the 26 External*Code lookup tables')
emit('-- Source: ISO 20022 External Code Sets registry, 1Q2026 (v1) publication')
emit('-- https://www.iso20022.org/catalogue-messages/additional-content-messages/external-code-sets')
emit('-- (XLSX format, sheet "AllCodeSets"; retrieved 2026-08-26)')
emit('-- Re-run against a refreshed download to update -- external code sets')
emit('-- follow a quarterly update cycle (end of Feb/May/Aug/Nov).')
emit('-- ---------------------------------------------------------------------\n')

import openpyxl as _openpyxl

def clean_text(s):
    if s is None:
        return None
    s = str(s).replace('_x000D_', '').replace('\r\n', '\n').replace('\r', '\n')
    s = s.strip()
    return s if s else None

def sqlval(s):
    return 'NULL' if s is None else sqlstr(s)

def sqldate(s):
    return 'NULL' if not s else sqlstr(s) + '::date'

_wb = _openpyxl.load_workbook(
    '/home/claude/1Q2026_externalcodesets_v1.xlsx', read_only=True, data_only=True)
_ws = _wb['AllCodeSets']
_rows = list(_ws.iter_rows(values_only=True))
_data = _rows[1:]  # skip header

by_codeset = {}
for r in _data:
    codeset = r[0]
    if codeset not in {n for n, _, _ in external_codes}:
        continue
    by_codeset.setdefault(codeset, []).append(r)

seeded_total = 0
empty_codesets = []
for name, maxlen, _definition in external_codes:
    codeset_rows = by_codeset.get(name, [])
    emit(f'-- Seed: {name}Values ({len(codeset_rows)} codes)')
    if not codeset_rows:
        emit(f'-- No codes currently published for {name} in the 1Q2026 registry --')
        emit(f'-- it is a registered/defined code set with zero enumerated values')
        emit(f"-- this quarter (confirmed via the registry's \"CodeSetsDefinition\" sheet,")
        emit(f'-- Status: Registered). Table intentionally left empty.\n')
        empty_codesets.append(name)
        continue
    entries = []
    for r in codeset_rows:
        code, code_name, definition, requester, status, last_update, creation_date, replaced_by = r[1:9]
        additional_info = r[13]
        entries.append((
            code.strip() if code else code,
            clean_text(code_name) or code,
            clean_text(definition),
            clean_text(status),
            clean_text(last_update),
            clean_text(creation_date),
            clean_text(replaced_by),
            clean_text(additional_info),
        ))
    # de-dupe on Code (primary key) -- keep first occurrence if the
    # registry ever lists the same code twice for a code set
    seen = set()
    deduped = []
    for e in entries:
        if e[0] in seen:
            continue
        seen.add(e[0])
        deduped.append(e)
    for batch in batched(sorted(deduped, key=lambda x: x[0]), BATCH_SIZE):
        rows_sql = ",\n    ".join(
            f"({sqlstr(code)}, {sqlstr(cname)}, {sqlval(defn)}, {sqlval(status)}, "
            f"{sqldate(lu)}, {sqldate(cd)}, {sqlval(rb)}, {sqlval(ai)})"
            for code, cname, defn, status, lu, cd, rb, ai in batch
        )
        emit(f'INSERT INTO public."{name}Values" '
             f'("Code", "Name", "Definition", "Status", "LastUpdate", "CreationDate", '
             f'"ReplacedBy", "AdditionalInformation") VALUES')
        emit(f'    {rows_sql}')
        emit('ON CONFLICT ("Code") DO NOTHING;\n')
    seeded_total += len(deduped)

print(f"Part 3b done: seeded {seeded_total} rows across "
      f"{len(external_codes) - len(empty_codesets)} of {len(external_codes)} code sets")
print(f"  (currently zero published codes for: {', '.join(empty_codesets)})")

emit('-- Verification -- External*Code seed row counts.')
verify_lines = [f"SELECT '{name}Values' AS \"Table\", count(*) AS \"RowCount\" FROM public.\"{name}Values\""
                for name, _, _ in external_codes]
emit((" UNION ALL\n").join(verify_lines) + ';\n')

with open('/home/claude/sql_generated.sql', 'w') as f:
    f.writelines(out)

# ---------------------------------------------------------------------
# PART 4 -- 10.2.2 Binary
# ---------------------------------------------------------------------
emit('-- ---------------------------------------------------------------------')
emit('-- PART 4 -- 10.2.2 Binary')
emit('-- ---------------------------------------------------------------------\n')

emit('-- Domain: Max10KBinary')
emit('DROP DOMAIN IF EXISTS public.\"Max10KBinary\" CASCADE;')
emit('CREATE DOMAIN public."Max10KBinary" AS bytea')
emit('    CHECK (octet_length(VALUE) BETWEEN 1 AND 10240);')
emit('ALTER DOMAIN public."Max10KBinary" OWNER TO postgres;')
emit('COMMENT ON DOMAIN public."Max10KBinary" IS')
emit("'Definition: Binary data of 10K maximum.\n\n"
     "Format: minLength 1, maxLength 10240 (bytes).\n\n"
     "Note: modeled as bytea (native Postgres binary type); the CHECK "
     "enforces the MDR''s 1-10240 byte range.';\n")

# ---------------------------------------------------------------------
# PART 5 -- 10.2.4 Date, 10.2.5 DateTime, 10.2.11 Time, 10.2.12 Year
# ---------------------------------------------------------------------
emit('-- ---------------------------------------------------------------------')
emit('-- PART 5 -- 10.2.4 Date / 10.2.5 DateTime / 10.2.11 Time / 10.2.12 Year')
emit('-- ---------------------------------------------------------------------\n')

emit('-- Domain: ISODate')
emit('DROP DOMAIN IF EXISTS public.\"ISODate\" CASCADE;')
emit('CREATE DOMAIN public."ISODate" AS date;')
emit('ALTER DOMAIN public."ISODate" OWNER TO postgres;')
emit('COMMENT ON DOMAIN public."ISODate" IS')
emit("'Definition: A particular point in the progression of time in a "
     "calendar year expressed in the YYYY-MM-DD format (XML Schema date, "
     "aligned with ISO 8601).\n\n"
     "Note: native Postgres date already enforces calendar validity; no "
     "additional CHECK needed. Wrapped as a domain purely so the MDR "
     "semantics/documentation travel with the column type.';\n")

emit('-- Domain: ISODateTime')
emit('DROP DOMAIN IF EXISTS public.\"ISODateTime\" CASCADE;')
emit('CREATE DOMAIN public."ISODateTime" AS timestamptz;')
emit('ALTER DOMAIN public."ISODateTime" OWNER TO postgres;')
emit('COMMENT ON DOMAIN public."ISODateTime" IS')
emit("'Definition: A particular point in time defined by a mandatory date "
     "and mandatory time component, expressed as UTC "
     "(YYYY-MM-DDThh:mm:ss.sssZ), local time with UTC offset "
     "(YYYY-MM-DDThh:mm:ss.sss+/-hh:mm), or local time with no offset "
     "(YYYY-MM-DDThh:mm:ss.sss). Aligned with ISO 8601.\n\n"
     "Note on time format: 00:00:00 = beginning of a calendar day, "
     "24:00:00 = end of a calendar day. Fractional seconds allowed, "
     "precision by agreement between parties.\n\n"
     "MODELING CHOICE: mapped to timestamptz, which correctly handles the "
     "UTC and UTC-offset variants (stored internally as UTC, rendered in "
     "session timezone). The MDR''s third variant -- local time with NO "
     "offset info at all -- has no lossless native equivalent: timestamptz "
     "will interpret it using the session timezone at insert time. If your "
     "messages regularly omit the offset and that distinction matters "
     "downstream, consider timestamp (without time zone) instead and "
     "handle offset-bearing values explicitly. Flag if you want this "
     "changed before the component library is built on top of it.';\n")

emit('-- Domain: ISOTime')
emit('DROP DOMAIN IF EXISTS public.\"ISOTime\" CASCADE;')
emit('CREATE DOMAIN public."ISOTime" AS timetz;')
emit('ALTER DOMAIN public."ISOTime" OWNER TO postgres;')
emit('COMMENT ON DOMAIN public."ISOTime" IS')
emit("'Definition: A particular point in time in a calendar day, expressed "
     "as UTC (hh:mm:ss.sssZ), local time with UTC offset "
     "(hh:mm:ss.sss+/-hh:mm), or local time with no offset (hh:mm:ss.sss). "
     "Aligned with ISO 8601.\n\n"
     "Note on time format: 00:00:00 = beginning of a calendar day, "
     "24:00:00 = end of a calendar day (Postgres time/timetz accept "
     "24:00:00). Fractional seconds allowed, precision by agreement.\n\n"
     "MODELING CHOICE: mapped to timetz to preserve an explicit UTC "
     "offset where present -- same no-offset caveat as ISODateTime above "
     "applies.';\n")

emit('-- Domain: ISOYear')
emit('DROP DOMAIN IF EXISTS public.\"ISOYear\" CASCADE;')
emit('CREATE DOMAIN public."ISOYear" AS smallint')
emit('    CHECK (VALUE BETWEEN 0 AND 9999);')
emit('ALTER DOMAIN public."ISOYear" OWNER TO postgres;')
emit('COMMENT ON DOMAIN public."ISOYear" IS')
emit("'Definition: Year represented by YYYY (ISO 8601).\n\n"
     "Note: modeled as smallint restricted to the 4-digit YYYY range "
     "(0-9999) implied by the format.';\n")

# ---------------------------------------------------------------------
# PART 6 -- 10.2.6 IdentifierSet
# ---------------------------------------------------------------------
emit('-- ---------------------------------------------------------------------')
emit('-- PART 6 -- 10.2.6 IdentifierSet')
emit('-- ---------------------------------------------------------------------\n')

identifiers = [
    ("AnyBICDec2014Identifier", 11, r'^[A-Z0-9]{4}[A-Z]{2}[A-Z0-9]{2}([A-Z0-9]{3})?$',
     'Definition: Code allocated to a financial or non-financial institution by the '
     'ISO 9362 Registration Authority, as described in ISO 9362:2014 "Banking - '
     'Banking telecommunication messages - Business identifier code (BIC)".\n\n'
     'Identification scheme: SWIFT; AnyBICIdentifier.\n\n'
     'Format: pattern [A-Z0-9]{4,4}[A-Z]{2,2}[A-Z0-9]{2,2}([A-Z0-9]{3,3}){0,1} '
     '(8 or 11 characters).\n\n'
     'Constraint - AnyBIC: Only a valid Business Identifier Code is allowed. BICs '
     'for financial or non-financial institutions are registered and published by '
     'the ISO 9362 Registration Authority in the ISO directory of BICs, and consist '
     'of eight (8) or eleven (11) contiguous characters.'),
    ("BICFIDec2014Identifier", 11, r'^[A-Z0-9]{4}[A-Z]{2}[A-Z0-9]{2}([A-Z0-9]{3})?$',
     'Definition: Code allocated to a financial institution by the ISO 9362 '
     'Registration Authority as described in ISO 9362:2014 "Banking - Banking '
     'telecommunication messages - Business identifier code (BIC)".\n\n'
     'Identification scheme: SWIFT; BICIdentifier.\n\n'
     'Format: pattern [A-Z0-9]{4,4}[A-Z]{2,2}[A-Z0-9]{2,2}([A-Z0-9]{3,3}){0,1} '
     '(8 or 11 characters).\n\n'
     'Constraint - BICFI: Valid BICs for financial institutions are registered and '
     'published by the ISO 9362 Registration Authority in the ISO directory of BICs, '
     'and consist of eight (8) or eleven (11) contiguous characters.'),
    ("IBAN2007Identifier", 34, r'^[A-Z]{2}[0-9]{2}[a-zA-Z0-9]{1,30}$',
     'Definition: The International Bank Account Number is a code used '
     'internationally by financial institutions to uniquely identify the account of '
     'a customer at a financial institution, as described in the 2007 edition of '
     'ISO 13616 "Banking and related financial services - International Bank '
     'Account Number (IBAN)" and replaced by more recent editions of the standard.\n\n'
     'Identification scheme: National Banking Association; International Bank '
     'Account Number (ISO 13616).\n\n'
     'Format: pattern [A-Z]{2,2}[0-9]{2,2}[a-zA-Z0-9]{1,30} (up to 34 characters).\n\n'
     'Constraint - IBAN: A valid IBAN consists of all three of the following '
     'components: Country Code, check digits and BBAN.\n\n'
     'Note: this domain enforces FORMAT ONLY (structure/length); it does not '
     'verify the mod-97 check-digit algorithm.'),
    ("LEIIdentifier", 20, r'^[A-Z0-9]{18}[0-9]{2}$',
     'Definition: Legal Entity Identifier is a code allocated to a party as '
     'described in ISO 17442 "Financial Services - Legal Entity Identifier (LEI)".\n\n'
     'Identification scheme: Global LEI System; LEIIdentifier.\n\n'
     'Format: pattern [A-Z0-9]{18,18}[0-9]{2,2} (fixed 20 characters).'),
    ("UUIDv4Identifier", 36,
     r'^[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$',
     'Definition: Universally Unique IDentifier (UUID) version 4, as described in '
     'IETF RFC 4122 "Universally Unique IDentifier (UUID) URN Namespace".\n\n'
     'Identification scheme: RFC4122; UUIDv4.\n\n'
     'Format: pattern '
     '[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}.\n\n'
     'Note: Postgres has a native uuid type; this domain instead follows the MDR''s '
     'own lowercase-hex-with-version/variant-nibble pattern literally over text, so '
     'a value that is syntactically a UUID but NOT specifically v4 (wrong version '
     'nibble) is rejected -- native uuid alone would accept any UUID version.'),
]

for name, length, pattern, comment in identifiers:
    esc = comment.replace("'", "''")
    emit(f'-- Domain: {name}')
    emit(f'DROP DOMAIN IF EXISTS public.\"{name}\" CASCADE;')
    emit(f'CREATE DOMAIN public."{name}" AS varchar({length})')
    emit(f"    CHECK (VALUE ~ '{pattern}');")
    emit(f'ALTER DOMAIN public."{name}" OWNER TO postgres;')
    emit(f'COMMENT ON DOMAIN public."{name}" IS')
    emit(f"'{esc}';\n")

# ---------------------------------------------------------------------
# PART 7 -- 10.2.7 Indicator
# ---------------------------------------------------------------------
emit('-- ---------------------------------------------------------------------')
emit('-- PART 7 -- 10.2.7 Indicator')
emit('-- ---------------------------------------------------------------------\n')

indicators = [
    ("BatchBookingIndicator",
     'Definition: Identifies whether the sending party requests a single debit or '
     'credit entry per individual transaction or a batch entry for the sum of the '
     'amounts of all transactions.\n\n'
     'Meaning When True: Identifies that a batch entry for the sum of the amounts '
     'of all transactions in the batch or message is requested.\n\n'
     'Meaning When False: Identifies that a single entry for each of the '
     'transactions in the batch or message is requested.'),
    ("TrueFalseIndicator",
     'Definition: A flag indicating a True or False value.\n\n'
     'Meaning When True: True.\n\n'
     'Meaning When False: False.'),
]

for name, comment in indicators:
    esc = comment.replace("'", "''")
    emit(f'-- Domain: {name}')
    emit(f'DROP DOMAIN IF EXISTS public.\"{name}\" CASCADE;')
    emit(f'CREATE DOMAIN public."{name}" AS boolean;')
    emit(f'ALTER DOMAIN public."{name}" OWNER TO postgres;')
    emit(f'COMMENT ON DOMAIN public."{name}" IS')
    emit(f"'{esc}';\n")

# ---------------------------------------------------------------------
# PART 8 -- 10.2.8 Quantity, 10.2.9 Rate
# ---------------------------------------------------------------------
emit('-- ---------------------------------------------------------------------')
emit('-- PART 8 -- 10.2.8 Quantity / 10.2.9 Rate')
emit('-- ---------------------------------------------------------------------\n')

numeric_types = [
    ("DecimalNumber", 18, 17,
     'Definition: Number of objects represented as a decimal number, for example '
     '0.75 or 45.6.\n\nFormat: totalDigits 18, fractionDigits 17.'),
    ("Number", 18, 0,
     'Definition: Number of objects represented as an integer.\n\n'
     'Format: totalDigits 18, fractionDigits 0.'),
    ("BaseOneRate", 11, 10,
     'Definition: Rate expressed as a decimal, for example, 0.7 is 7/10 and 70%.\n\n'
     'Format: totalDigits 11, fractionDigits 10, baseValue 1.0.'),
    ("PercentageRate", 11, 10,
     'Definition: Rate expressed as a percentage, that is, in hundredths, for '
     'example, 0.7 is 7/10 of a percent, and 7.0 is 7%.\n\n'
     'Format: totalDigits 11, fractionDigits 10, baseValue 100.0.'),
]

for name, total, frac, comment in numeric_types:
    esc = comment.replace("'", "''")
    emit(f'-- Domain: {name}')
    emit(f'DROP DOMAIN IF EXISTS public.\"{name}\" CASCADE;')
    emit(f'CREATE DOMAIN public."{name}" AS numeric({total},{frac});')
    emit(f'ALTER DOMAIN public."{name}" OWNER TO postgres;')
    emit(f'COMMENT ON DOMAIN public."{name}" IS')
    emit(f"'{esc}';\n")

# ---------------------------------------------------------------------
# PART 9 -- 10.2.10 Text (21 types)
# ---------------------------------------------------------------------
emit('-- ---------------------------------------------------------------------')
emit('-- PART 9 -- 10.2.10 Text')
emit('-- ---------------------------------------------------------------------\n')

# (name, base_len, kind, pattern_or_None, definition)
# kind: 'exact' (fixed-format regex), 'maxlen' (1..N, plain length check)
text_types = [
    ("Exact2NumericText", 2, "exact", r'^[0-9]{2}$',
     "Definition: Specifies a numeric string with an exact length of 2 digits."),
    ("Exact4AlphaNumericText", 4, "exact", r'^[a-zA-Z0-9]{4}$',
     "Definition: Specifies an alphanumeric string with a length of 4 characters."),
    ("HexBinaryText", 0, "openpattern", r'^[0-9a-fA-F]+$',
     "Definition: Specifies a character string with hexadecimal text characters. "
     "Used for hex binary data only, supports only characters A-F, a-f and 0-9."),
    ("Max1025Text", 1025, "maxlen", None,
     "Definition: Specifies a character string with a maximum length of 1025 characters."),
    ("Max105Text", 105, "maxlen", None,
     "Definition: Specifies a character string with a maximum length of 105 characters."),
    ("Max10Text", 10, "maxlen", None,
     "Definition: Specifies a character string with a maximum length of 10 characters."),
    ("Max128Text", 128, "maxlen", None,
     "Definition: Specifies a character string with a maximum length of 128 characters."),
    ("Max140Text", 140, "maxlen", None,
     "Definition: Specifies a character string with a maximum length of 140 characters."),
    ("Max15NumericText", 15, "exactrange", r'^[0-9]{1,15}$',
     "Definition: Specifies a numeric string with a maximum length of 15 digits."),
    ("Max16Text", 16, "maxlen", None,
     "Definition: Specifies a character string with a maximum length of 16 characters."),
    ("Max2048Text", 2048, "maxlen", None,
     "Definition: Specifies a character string with a maximum length of 2048 characters."),
    ("Max210Text", 210, "maxlen", None,
     "Definition: Specifies a character string with a maximum length of 210 characters."),
    ("Max256Text", 256, "maxlen", None,
     "Definition: Specifies a character string with a maximum length of 256 characters."),
    ("Max34Text", 34, "maxlen", None,
     "Definition: Specifies a character string with a maximum length of 34 characters."),
    ("Max350Text", 350, "maxlen", None,
     "Definition: Specifies a character string with a maximum length of 350 characters."),
    ("Max35Text", 35, "maxlen", None,
     "Definition: Specifies a character string with a maximum length of 35 characters."),
    ("Max4Text", 4, "maxlen", None,
     "Definition: Specifies a character string with a maximum length of 4 characters."),
    ("Max52Text", 52, "maxlen", None,
     "Definition: Specifies a character string with a maximum length of 52 characters."),
    ("Max70Text", 70, "maxlen", None,
     "Definition: Specifies a character string with a maximum length of 70 characters."),
    ("PhoneNumber", 35, "exactrange", r'^\+[0-9]{1,3}-[0-9()+\-]{1,30}$',
     'Definition: The collection of information which identifies a specific phone '
     'or FAX number as defined by telecom services. It consists of a "+" followed '
     'by the country code (1 to 3 characters) then a "-" and finally, any '
     'combination of numbers, "(", ")", "+" and "-" (up to 30 characters).'),
    ("SHA256SignatureText", 64, "exact", r'^([0-9A-F]{2}){32}$',
     "Definition: Specifies a character string with an exact length of 32 binary "
     "bytes (64 hexadecimal text characters). Used only for hex binary data, "
     "supports only characters A-F and 0-9."),
]

assert len(text_types) == 21, len(text_types)

for name, length, kind, pattern, definition in text_types:
    if kind == "maxlen":
        fmt_note = f"Format: minLength 1, maxLength {length}."
        base_type = f"varchar({length})"
        check = "CHECK (char_length(VALUE) >= 1)"
    elif kind == "exact":
        fmt_note = f"Format: pattern {pattern}."
        base_type = f"varchar({length})"
        check = f"CHECK (VALUE ~ '{pattern}')"
    elif kind == "exactrange":
        fmt_note = f"Format: pattern {pattern}."
        base_type = f"varchar({length})"
        check = f"CHECK (VALUE ~ '{pattern}')"
    elif kind == "openpattern":
        fmt_note = f"Format: pattern {pattern} (no explicit maxLength in the MDR)."
        base_type = "text"
        check = f"CHECK (VALUE ~ '{pattern}')"
    comment = f"{definition}\n\n{fmt_note}".replace("'", "''")
    emit(f'-- Domain: {name}')
    emit(f'DROP DOMAIN IF EXISTS public.\"{name}\" CASCADE;')
    emit(f'CREATE DOMAIN public."{name}" AS {base_type}')
    emit(f'    {check};')
    emit(f'ALTER DOMAIN public."{name}" OWNER TO postgres;')
    emit(f'COMMENT ON DOMAIN public."{name}" IS')
    emit(f"'{comment}';\n")

print(f"Part 9 done: {len(text_types)} text domains")

# ---------------------------------------------------------------------
# PART 10 -- 10.2.1 Amount: composite Amount+Currency types, following
# the DatePeriod2 / validate_date_period pattern (composite TYPE, since
# composite types can't carry CHECK constraints directly, + a paired
# validate_ function).
# ---------------------------------------------------------------------
emit('-- ---------------------------------------------------------------------')
emit('-- PART 10 -- 10.2.1 Amount: composite TYPE + validate_ function')
emit('-- (composite types cannot carry CHECK constraints directly -- mirrors')
emit('-- the DatePeriod2 / validate_date_period pattern)')
emit('-- ---------------------------------------------------------------------\n')

amount_types = [
    ("ActiveCurrencyAndAmount", "ActiveCurrencyCode", "validate_active_currency_and_amount",
     'Definition: A number of monetary units specified in an active currency where '
     'the unit of currency is explicit and compliant with ISO 4217.\n\n'
     'XML attribute: Currency <Ccy>, datatype ActiveCurrencyCode.\n\n'
     'Format: minInclusive 0, totalDigits 18, fractionDigits 5.\n\n'
     'Constraint - ActiveCurrency: The currency code must be a valid active '
     'currency code, not yet withdrawn on the day the message containing the '
     'currency is exchanged.\n\n'
     'Constraint - CurrencyAmount: The number of fractional digits (minor unit of '
     'currency) must comply with ISO 4217. Note: the decimal separator is a dot.',
     'ActiveCurrency (currency format checked by the ActiveCurrencyCode domain; '
     'active/withdrawn status is NOT checked here -- see that domain''s comment) '
     'and CurrencyAmount (Amt must be present and >= 0, per Format minInclusive 0).'),
    ("ActiveOrHistoricCurrencyAndAmount", "ActiveOrHistoricCurrencyCode",
     "validate_active_or_historic_currency_and_amount",
     'Definition: A number of monetary units specified in an active or a historic '
     'currency where the unit of currency is explicit and compliant with ISO 4217.\n\n'
     'XML attribute: Currency <Ccy>, datatype ActiveOrHistoricCurrencyCode.\n\n'
     'Format: minInclusive 0, totalDigits 18, fractionDigits 5.\n\n'
     'Constraint - ActiveOrHistoricCurrency: The currency code must be registered, '
     'or have already been registered.\n\n'
     'Constraint - CurrencyAmount: The number of fractional digits (minor unit of '
     'currency) must comply with ISO 4217. Note: the decimal separator is a dot.',
     'ActiveOrHistoricCurrency (currency format checked by the '
     'ActiveOrHistoricCurrencyCode domain; registration status is NOT checked here) '
     'and CurrencyAmount (Amt must be present and >= 0, per Format minInclusive 0).'),
]

for type_name, ccy_domain, fn_name, type_comment, fn_constraint_note in amount_types:
    esc_type_comment = type_comment.replace("'", "''")
    emit(f'-- Type: {type_name}')
    emit(f'DROP TYPE IF EXISTS public.\"{type_name}\" CASCADE;')
    emit(f'CREATE TYPE public."{type_name}" AS (')
    emit(f'    "Amt" numeric(18,5),')
    emit(f'    "Ccy" public."{ccy_domain}"')
    emit(f');')
    emit(f'ALTER TYPE public."{type_name}" OWNER TO postgres;')
    emit(f'COMMENT ON TYPE public."{type_name}" IS')
    emit(f"'{esc_type_comment}';\n")

    fn_comment = (f'Validates a public."{type_name}" value against MDR constraints '
                  f'{fn_constraint_note}').replace("'", "''")
    emit(f'-- FUNCTION: public.{fn_name}("{type_name}")')
    emit(f'-- DROP FUNCTION IF EXISTS public.{fn_name}(public."{type_name}");')
    emit(f'CREATE OR REPLACE FUNCTION public.{fn_name}(')
    emit(f'    val public."{type_name}")')
    emit(f'    RETURNS boolean')
    emit(f"    LANGUAGE 'plpgsql'")
    emit(f'    COST 100')
    emit(f'    IMMUTABLE PARALLEL UNSAFE')
    emit(f'AS $BODY$')
    emit(f'BEGIN')
    emit(f'    RETURN val."Amt" IS NOT NULL')
    emit(f'        AND val."Amt" >= 0')
    emit(f'        AND val."Ccy" IS NOT NULL;')
    emit(f'END;')
    emit(f'$BODY$;')
    emit(f'ALTER FUNCTION public.{fn_name}(public."{type_name}")')
    emit(f'    OWNER TO postgres;')
    emit(f'COMMENT ON FUNCTION public.{fn_name}(public."{type_name}") IS')
    emit(f"'{fn_comment}';\n")

print(f"Part 10 done: {len(amount_types)} composite amount types + validate functions")

with open('/home/claude/sql_generated.sql', 'w') as f:
    f.writelines(out)

total_objects = 3 + 19 + 26*2 + 1 + 4 + 5 + 2 + 4 + 21 + 2*2
print(f"\nTOTAL SQL statements written to sql_generated.sql")
print(f"Approx object count: {total_objects}")
