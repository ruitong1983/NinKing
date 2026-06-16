#!/usr/bin/env python3
import re
t = open('docs/ninking/ninja_card_viewer.html', encoding='utf-8').read()
m = re.search(r'<div id="recent-updates".*?</div>', t, re.DOTALL)
if m:
    sec = m.group()
    print('close span count:', sec.count('</span>'))
    for line in sec.split('\n')[:15]:
        if 'span' in line:
            print(repr(line))
