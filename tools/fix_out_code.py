# 修复 out 块内游离 </code>：python tools/fix_out_code.py
import re, glob
pat = re.compile(r'(<pre class="out"[^>]*>)([\s\S]*?)</code>\s*</pre>')
for f in sorted(glob.glob('*.html') + glob.glob('cases/*.html')):
    s = open(f, encoding='utf-8').read()
    n = len(pat.findall(s))
    if n:
        s = pat.sub(lambda m: m.group(1) + m.group(2) + '</pre>', s)
        open(f, 'w', encoding='utf-8').write(s)
        print(f, 'fixed', n)
print('done')
