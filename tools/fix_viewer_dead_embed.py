#!/usr/bin/env python3
"""Remove the first dead CSV embed (old format) from ninja-test-viewer.html"""
import os

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
path = os.path.join(BASE, 'docs/ninking/testing/ninja-test-viewer.html')

with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Remove from "// ===== CSV PARSING =====" to the first closing "`;" after the raw CSV
start_marker = '// ===== CSV PARSING ====='
end_marker = '\t`;'

start_pos = content.find(start_marker)
end_pos = content.find(end_marker, start_pos)

if start_pos == -1 or end_pos == -1:
    print(f'ERROR: markers not found (start={start_pos}, end={end_pos})')
    exit(1)

# Include the end marker
end_pos += len(end_marker)

old_len = len(content)
content = content[:start_pos] + content[end_pos:]
removed = old_len - len(content)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print(f'Removed {removed} bytes ({removed} chars) of dead CSV embed')
print(f'From position {start_pos} to {end_pos}')
