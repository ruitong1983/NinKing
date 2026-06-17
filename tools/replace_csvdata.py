#!/usr/bin/env python3
"""Replace const CSV_DATA content in ninja-test-viewer.html with generated CSV"""
import csv
import os

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Read generated CSV
rows = []
csv_path = os.path.join(BASE, 'docs/ninking/testing/ninja-test-full.csv')
with open(csv_path, 'r', encoding='utf-8-sig') as f:
    reader = csv.reader(f)
    header = next(reader)
    rows = list(reader)

# Read viewer HTML
html_path = os.path.join(BASE, 'docs/ninking/testing/ninja-test-viewer.html')
with open(html_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Find const CSV_DATA boundaries
start_marker = 'const CSV_DATA = `'
end_marker = '`;'

start_pos = content.find(start_marker)
if start_pos == -1:
    print('ERROR: const CSV_DATA not found')
    exit(1)

# Find opening backtick
bt_start = content.find('`', start_pos)
# Find closing backtick + semicolon (after the header line)
bt_end = content.rfind('`;')
if bt_end <= bt_start:
    print('ERROR: backtick boundaries wrong')
    exit(1)

# Build new CSV_DATA content
csv_lines = []
csv_lines.append('const CSV_DATA = `' + ','.join(header))
for row in rows:
    csv_lines.append(','.join(row))
csv_data_section = '\n'.join(csv_lines) + '\n`;'

# Replace
old_len = len(content)
content = content[:start_pos] + csv_data_section + content[bt_end+2:]

with open(html_path, 'w', encoding='utf-8') as f:
    f.write(content)

new_len = len(content)
print(f'Replaced CSV_DATA: {len(rows)} rows, {old_len - new_len} bytes change')
