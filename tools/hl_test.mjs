/* 高亮器往返与泄漏测试：node tools/hl_test.mjs */
import { readFileSync } from 'node:fs';
const src = readFileSync(new URL('../assets/site.js', import.meta.url), 'utf8');
const hl = new Function(src + '; return hl;')();
const esc = s => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
const strip = h => h.replace(/<span class="tok-[a-z]+">/g, '').replace(/<\/span>/g, '');
const cases = [
  'x <- c(1, NA) # 注释含 "引号" 和 <-',
  'adsl |> dplyr::filter(ARM == "Placebo") |> nrow()',
  'f <- function(a, b = TRUE) { a + b }  # 尾注释',
  'mmrm::mmrm(FEV1 ~ ARM + AVISIT | USUBJID, data = d)',
  's <- "a # b <- c"; n <- 3.14e-2',
  'if (x > 1 && !is.na(y)) z <- x %>% sum(na.rm = TRUE)'
];
let fail = 0;
for (const c of cases) {
  const h = hl(c);
  if (strip(h) !== esc(c)) { console.log('ROUNDTRIP FAIL:', c); fail++; }
  if (/tok-[a-z]+="|<span<span|undefined|NaN</.test(h)) { console.log('LEAK FAIL:', c); fail++; }
}
const h1 = hl('x <- 1 # c');
if (!/tok-com/.test(h1) || !/tok-num/.test(h1) || !/tok-op/.test(h1)) { console.log('CLASS FAIL h1:', h1); fail++; }
const h2 = hl('dplyr::filter(df, a == "s")');
if (!/tok-ns/.test(h2) || !/tok-str/.test(h2) || !/tok-fn/.test(h2)) { console.log('CLASS FAIL h2:', h2); fail++; }
const h3 = hl('for (i in 1:10) f(i)');
if (!/tok-kw/.test(h3)) { console.log('CLASS FAIL h3:', h3); fail++; }
console.log(fail ? `FAIL ${fail}` : 'HL TEST PASS');
process.exit(fail ? 1 : 0);
