# 反向修复：pre.code 块补回 </code>；pre.out 块确保无 </code>
import re, glob
code_pat = re.compile(r'(<pre class="code"[^>]*>)([\s\S]*?)(</pre>)')
out_pat = re.compile(r'(<pre class="out"[^>]*>)([\s\S]*?)(</pre>)')
for f in sorted(glob.glob('*.html') + glob.glob('cases/*.html')):
    s = open(f, encoding='utf-8').read()
    orig = s
    def fix_code(m):
        body = m.group(2)
        if '</code>' not in body:
            return m.group(1) + body + '</code>' + m.group(3)
        return m.group(0)
    s = code_pat.sub(fix_code, s)
    def fix_out(m):
        body = m.group(2).replace('</code>', '')
        return m.group(1) + body + m.group(3)
    s = out_pat.sub(fix_out, s)
    if s != orig:
        open(f, 'w', encoding='utf-8').write(s)
        print('repaired', f)
print('done')
