#!/usr/bin/env python3
"""Replace embedded CSV data in ninja-test-viewer.html"""
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

# Find embed markers
start_marker = '// Embedded CSV data (ninja-test-full.csv, UTF-8 BOM removed for JS)'
end_marker = '\t`;'

start_pos = html.find(start_marker)
end_pos = html.find(end_marker, start_pos) + 3  # include \t`;

if start_pos == -1:
    print('ERROR: start marker not found')
    exit(1)
if end_pos == -1:
    print('ERROR: end marker not found')
    exit(1)

# Build new embed content
lines = [start_marker]
for row in rows:
    csv_line = ','.join(row)
    lines.append('\t' + csv_line)

new_embed = '\n'.join(lines) + '\n\t`;'

html_new = html[:start_pos] + new_embed + html[end_pos:]

with open(html_path, 'w', encoding='utf-8') as f:
    f.write(html_new)

print(f'Replaced {len(rows)} rows of embedded CSV data')
