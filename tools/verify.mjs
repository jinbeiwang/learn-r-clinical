/* 全站校验：node tools/verify.mjs */
import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
const ROOT = new URL('..', import.meta.url).pathname.replace(/^\/([A-Z]:)/, '$1');
/* 枚举根目录下全部 html（含 index 与非 chN 命名的工具页），避免新增页面漏检 */
const files = [...readdirSync(ROOT).filter(f => f.endsWith('.html')),
  ...readdirSync(join(ROOT, 'cases')).filter(f => f.endsWith('.html')).map(f => 'cases/' + f)];
let fail = 0;
const bad = (f, msg) => { console.log(`FAIL ${f}: ${msg}`); fail++; };
for (const rel of files) {
  const p = join(ROOT, rel);
  if (!existsSync(p)) continue;
  const html = readFileSync(p, 'utf8');
  /* 1. 所有 pre 必须带 white-space:pre 内联样式 */
  for (const m of html.matchAll(/<pre\b([^>]*)>/g)) if (!/white-space:\s*pre/.test(m[1])) bad(rel, 'pre 缺内联 white-space:pre -> ' + m[0].slice(0, 60));
  /* 2. out 块内不得出现 </code> */
  for (const m of html.matchAll(/<pre class="out"[^>]*>([\s\S]*?)<\/pre>/g)) if (m[1].includes('</code>')) bad(rel, 'out 块含游离 </code>');
  /* 3. code 块必须闭合在 pre 内：统计 */
  const openCode = (html.match(/<code\b/g) || []).length, closeCode = (html.match(/<\/code>/g) || []).length;
  if (openCode !== closeCode) bad(rel, `code 开闭不等 ${openCode}/${closeCode}`);
  /* 4. quiz 答案存在于选项 */
  for (const m of html.matchAll(/<div class="quiz" data-answer="([^"]+)">([\s\S]*?)<\/div>\s*(?=<div class="quiz"|<h2|<section|<p class="lede"|<\/article)/g)) {
    const opts = [...m[2].matchAll(/data-opt="([^"]+)"/g)].map(x => x[1]);
    if (!opts.includes(m[1])) bad(rel, `quiz 答案 ${m[1]} 不在选项 ${opts}`);
    if (opts.length < 2) bad(rel, 'quiz 选项少于 2');
  }
  /* 5. 内部链接存在性 */
  for (const m of html.matchAll(/href="([^"#][^"]*)"/g)) {
    const h = m[1];
    if (/^(https?:|mailto:)/.test(h)) continue;
    const target = h.split('#')[0];
    if (!target) continue;
    if (!existsSync(join(dirname(p), target))) bad(rel, '内部链接不存在: ' + h);
  }
  /* 6. lang-r 代码块括号配平（单遍扫描剥离字符串与注释） */
  for (const m of html.matchAll(/<code class="lang-r">([\s\S]*?)<\/code>/g)) {
    const raw = m[1].replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&amp;/g, '&');
    let kept = '', q = null;
    for (let i = 0; i < raw.length; i++) {
      const c = raw[i];
      if (q) { if (c === '\\') { i++; continue; } if (c === q) q = null; continue; }
      if (c === '"' || c === "'") { q = c; continue; }
      if (c === '#') { while (i < raw.length && raw[i] !== '\n') i++; kept += '\n'; continue; }
      kept += c;
    }
    const cnt = c => (kept.match(new RegExp('\\' + c, 'g')) || []).length;
    if (cnt('(') !== cnt(')')) bad(rel, '代码块圆括号不配平: ' + m[1].split('\n')[0].slice(0, 50));
    if (cnt('[') !== cnt(']')) bad(rel, '代码块方括号不配平: ' + m[1].split('\n')[0].slice(0, 50));
  }
  /* 7. 骨架要件 */
  for (const need of ['assets/site.css', 'assets/site.js', 'class="sidenav"', 'class="toc"', 'id="theme-toggle"'])
    if (!html.includes(need) && rel !== 'index.html') bad(rel, '缺骨架要件 ' + need);
}
console.log(fail ? `VERIFY FAIL ${fail}` : 'VERIFY PASS (' + files.length + ' files)');
process.exit(fail ? 1 : 0);
