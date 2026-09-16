# 全站 HTML 标签配对校验：python tools/verify_html.py
import re, sys, glob
from html.parser import HTMLParser

VOID = {'meta','link','img','br','hr','input','area','base','col','embed','source','track','wbr'}

class P(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.stack, self.errs = [], []
    def handle_starttag(self, tag, attrs):
        if tag not in VOID:
            self.stack.append((tag, self.getpos()))
    def handle_startendtag(self, tag, attrs):
        pass
    def handle_endtag(self, tag):
        if tag in VOID:
            return
        if not self.stack:
            self.errs.append(f'游离闭标签 </{tag}> at {self.getpos()}')
            return
        top, pos = self.stack.pop()
        if top != tag:
            self.errs.append(f'不配对: <{top}> at {pos} 被 </{tag}> at {self.getpos()} 关闭')

fail = 0
for f in sorted(glob.glob('*.html') + glob.glob('cases/*.html')):
    p = P()
    p.feed(open(f, encoding='utf-8').read())
    p.close()
    for t, pos in p.stack:
        p.errs.append(f'未闭合 <{t}> at {pos}')
    if p.errs:
        fail += len(p.errs)
        print(f'FAIL {f}:')
        for e in p.errs[:12]:
            print('   ', e)
print('HTML VERIFY FAIL %d' % fail if fail else 'HTML VERIFY PASS')
sys.exit(1 if fail else 0)
