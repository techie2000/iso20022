#!/usr/bin/env python3
"""
Converts ISO 20022 MDR PDF pages into clean, diffable Markdown.

Purpose: this Markdown is the *source-of-truth surface* that drove the
SQL build in this project. When ISO publishes a new MDR version, run this
same script against the new PDF (same page range, same section), then
diff the new Markdown against the version checked in here. The diff tells
you exactly what changed in the spec -- new/removed/modified datatypes,
elements, constraints -- which is what actually needs auditing in the SQL
generators, rather than re-reading the whole PDF from scratch.

Usage:
    python3 pdf_to_markdown.py <spec.pdf> <first_page> <last_page> <output.md> <title>

Example (reproduces this project's two Markdown files):
    python3 pdf_to_markdown.py spec.pdf 845 869 10.2_message_datatypes_spec.md \\
        "ISO 20022 MDR Part 2 -- Section 10.2 Message Datatypes"
    python3 pdf_to_markdown.py spec.pdf 743 844 10.1_message_components_spec.md \\
        "ISO 20022 MDR Part 2 -- Section 10.1 Message Components"

Design choices (see this directory's README.md "Spec extraction" section
for the full rationale, checked-in file locations, and known limitations):
  - Page header/footer boilerplate is stripped (it repeats on every page
    and would otherwise pollute every future diff with pure noise).
  - Section numbering (10, 10.1, 10.1.1, ...) becomes Markdown ATX
    headers, capped at h6 (Markdown's limit) for anything nested deeper.
  - The columnar "Or / MessageElement<XML Tag> / Mult. / Type / Constr.
    No. / Page" element tables are preserved verbatim inside fenced code
    blocks, NOT reformatted into Markdown tables. This is deliberate:
    forcing fixed-width source columns into a reflowable Markdown table
    risks realigning cells in ways that make future diffs harder to read
    (a single changed value could cascade into a whole-table diff via
    column-width recalculation). A verbatim code block diffs line-by-line,
    which is what you actually want when comparing two spec versions.
  - Everything else (Definition/Format/Presence/Usage/Datatype/Constraints
    prose) is left as plain text, since it already reads fine and prose
    changes are exactly what you want a normal line-level diff to show.
"""
import re
import subprocess
import sys


HEADING_RE = re.compile(r'^(\d+(?:\.\d+)*)\s+(\S.*)$')

# Page footer/header boilerplate, repeated once per page. Matches the
# 3-line block: "Payments Clearing ... February 2025" / "2025" /
# (form feed) "Approved by the Payments SEG ... Message Items Types".
# Also handles the case where the form feed and header appear without a
# preceding footer (can happen at odd page boundaries).
BOILERPLATE_RE = re.compile(
    r'Payments Clearing and Settlement - Maintenance \d{4} -\s*\d*\s*February \d{4}\n'
    r'\d{4}\n'
    r'(?:\x0c?Approved by the Payments SEG on \d{2} \w+ \d{4}\s+Message Items Types\n?)?',
    re.MULTILINE
)
LONE_HEADER_RE = re.compile(
    r'\x0c?Approved by the Payments SEG on \d{2} \w+ \d{4}\s+Message Items Types\n?'
)
FORM_FEED_RE = re.compile(r'\x0c')


def extract_raw_text(pdf_path, first_page, last_page):
    """Run pdftotext -layout for the given page range."""
    result = subprocess.run(
        ['pdftotext', '-layout', '-f', str(first_page), '-l', str(last_page), pdf_path, '-'],
        capture_output=True, text=True, check=True
    )
    return result.stdout


def strip_boilerplate(text):
    text = BOILERPLATE_RE.sub('', text)
    text = LONE_HEADER_RE.sub('', text)
    text = FORM_FEED_RE.sub('', text)
    return text


def collapse_blank_lines(text):
    return re.sub(r'\n{3,}', '\n\n', text)


LABEL_RE = re.compile(
    r'^\s*(Definition|Format|Presence|Usage|Datatype|Constraints|'
    r'Impacted by|Identification scheme):\s*(.*)$')


def convert_to_markdown(text, title):
    lines = text.split('\n')
    out = [f'# {title}', '']
    out.append('<!-- markdownlint-disable -->')
    out.append('<!-- Verbatim spec extraction: fixed-width tables and inline XML tags '
                'are preserved on purpose for line-accurate diffing, not linted as prose. -->')
    out.append('')
    out.append('> Extracted from the source PDF with `pdf_to_markdown.py`. '
                'Element tables are preserved verbatim in fenced code blocks '
                'rather than reformatted, so future diffs stay line-accurate. '
                'See src/postgres/generators/README.md "Spec extraction" for methodology.')
    out.append('')

    in_table = False
    table_buffer = []

    def flush_table():
        nonlocal table_buffer, in_table
        # Trim trailing blank lines from the buffer before closing the fence
        while table_buffer and not table_buffer[-1].strip():
            table_buffer.pop()
        if table_buffer:
            out.append('```')
            out.extend(table_buffer)
            out.append('```')
            out.append('')
        table_buffer = []
        in_table = False

    for line in lines:
        stripped = line.rstrip()
        is_heading = bool(HEADING_RE.match(stripped)) and not stripped.startswith(' ')
        is_label = bool(LABEL_RE.match(stripped))
        is_constraints_marker = stripped.strip() == 'Constraints'
        is_bullet = stripped.strip().startswith('\u2022')  # "•"

        if in_table:
            if is_heading or is_label or is_constraints_marker or is_bullet:
                flush_table()
                # fall through to normal handling of this line below
            else:
                table_buffer.append(line.rstrip())
                continue

        if is_heading:
            number, title_text = HEADING_RE.match(stripped).groups()
            depth = min(number.count('.') + 1, 6)
            out.append(f'{"#" * depth} {number} {title_text}')
            out.append('')
            continue

        if 'MessageElement<XML Tag>' in line or ('CodeName' in line and 'Name' in line and 'Definition' in line):
            in_table = True
            table_buffer = [line.rstrip()]
            continue

        if not stripped:
            out.append('')
            continue

        if is_label:
            m = LABEL_RE.match(stripped)
            label, rest = m.group(1), m.group(2)
            out.append(f'**{label}:** {rest}')
        else:
            out.append(stripped.strip())

    flush_table()
    return '\n'.join(out) + '\n'


def main():
    if len(sys.argv) != 6:
        print(__doc__)
        sys.exit(1)
    pdf_path, first_page, last_page, output_path, title = sys.argv[1:]
    raw = extract_raw_text(pdf_path, int(first_page), int(last_page))
    cleaned = strip_boilerplate(raw)
    cleaned = collapse_blank_lines(cleaned)
    md = convert_to_markdown(cleaned, title)
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(md)
    print(f'Wrote {output_path} ({len(md.splitlines())} lines)')


if __name__ == '__main__':
    main()
