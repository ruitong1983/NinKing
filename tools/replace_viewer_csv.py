#!/usr/bin/env python3
"""Replace embedded CSV data in ninja-test-viewer.html (both sections)"""
import csv
import os

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Read new CSV
rows = []
csv_path = os.path.join(BASE, 'docs/ninking/testing/ninja-test-full.csv')
with open(csv_path, 'r', encoding='utf-8-sig') as f:
    reader = csv.reader(f)
    header = next(reader)
    rows = list(reader)

# Read viewer HTML
html_path = os.path.join(BASE, 'docs/ninking/testing/ninja-test-viewer.html')
with open(html_path, 'r', encoding='utf-8') as f:
    html = f.read()

# Find embed markers — replace ALL occurrences
start_marker = '// Embedded CSV data (ninja-test-full.csv, UTF-8 BOM removed for JS)'
# End marker: backtick+semicolon (closing template literal)
end_marker = '`;'

replace_count = 0
search_start = 0
while True:
    start_pos = html.find(start_marker, search_start)
    if start_pos == -1:
        break

    # Find the backtick+semicolon after the data
    # We need to find the first `; after start_pos (after the marker and header)
    end_marker_pos = html.find(end_marker, start_pos + len(start_marker))
    if end_marker_pos == -1:
        print('ERROR: end marker (`;) not found')
        exit(1)
    end_pos = end_marker_pos + 2  # include `;

    # Build new embed content
    lines = [start_marker]
    for row in rows:
        csv_line = ','.join(row)
        lines.append('\t' + csv_line)

    new_embed = '\n'.join(lines) + '\n\t`;'

    html = html[:start_pos] + new_embed + html[end_pos:]
    replace_count += 1
    search_start = start_pos + len(new_embed)  # continue after this replacement

with open(html_path, 'w', encoding='utf-8') as f:
    f.write(html)

print(f'Replaced {replace_count} section(s) with {len(rows)} rows each')
