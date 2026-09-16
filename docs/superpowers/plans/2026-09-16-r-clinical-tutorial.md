# 《R 语言临床数据分析与制药实践》教程站 实现计划

**目标：** 在 `G:\test\learn_R` 构建中文交互式书籍式教程站（9 章 + 6 案例 + 首页），实跑 R 捕获案例输出，发布到 GitHub 公开仓库 `learn-r-clinical` 并启用 Pages。

**架构：** 零构建静态站：每章/每案例一个 HTML，共享 `assets/site.css`（视觉系统）与 `assets/site.js`（运行时 R 高亮单遍分词器 + 测验 + TOC + 暗色）。案例附可运行 `.R`，输出由本机 R 4.5.0 实跑捕获存 `docs/run-outputs/`。

**技术栈：** HTML/CSS/原生 JS（node 仅做校验）、R 4.5.0（`C:/Program Files/R/R-4.5.0/bin/Rscript.exe`，绝对路径调用）、CRAN 包（admiral/rtables/tern/mmrm/teal 等）、git + gh CLI。

**规格：** `docs/superpowers/specs/2026-09-16-r-clinical-tutorial-design.md`

---

## 全局约定（所有任务执行者必读）

- 仓库根 = 站点根 = `G:\test\learn_R`。开工第一步：`git checkout -b feature/tutorial-build`（main 上仅有 docs/）。
- R 调用一律：`"C:/Program Files/R/R-4.5.0/bin/Rscript.exe"`（不在 PATH）。
- **代码块标记**（内容作者只写原始源码，高亮由 site.js 运行时完成，禁止手写 span、禁止构建期替换）：
  ```html
  <pre class="code" style="white-space:pre"><code class="lang-r">原始R源码（< > & 保持原样，site.js 会转义）</code></pre>
  <pre class="out" style="white-space:pre">运行输出文本</pre>
  ```
- **测验标记**：
  ```html
  <div class="quiz" data-answer="B">
    <p class="quiz-q">题干</p>
    <button class="quiz-opt" data-opt="A">选项A</button>
    <button class="quiz-opt" data-opt="B">选项B</button>
    <button class="quiz-opt" data-opt="C">选项C</button>
    <div class="quiz-exp">解析文本</div>
  </div>
  ```
- **_callout_**：`<div class="pitfall"><strong>SAS 误区：</strong>…</div>`、`<div class="note">…</div>`。
- **章内块顺序**：概念引入 → 示例(易→难) → 逐行解读(`<div class="walk">` 有序列表) → 运行输出 → SAS 误区 → 测验；章末：`<section class="res">` 资源列表（条目格式：名称 — 理由 — 链接 — 难度标签）+ 练习 + 下章预告。
- **页面骨架**（每页 head/nav/aside 结构一致，仅 main 内容不同）：
  ```html
  <!DOCTYPE html><html lang="zh-CN"><head><meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>章标题 · R 临床数据分析教程</title>
  <link rel="stylesheet" href="assets/site.css"><link rel="icon" href="assets/logo.svg"></head>
  <body><div class="progress"></div>
  <header class="top"><a class="brand" href="index.html"><img src="assets/logo.svg" alt=""> <span>R 临床实战<em>In Depth</em></span></a>
  <nav class="topnav"><a href="index.html#toc">全书目录</a><a href="ch8-community.html">社区与职业</a>
  <button id="theme-toggle" aria-label="切换暗色">◐</button></nav></header>
  <div class="layout">
    <aside class="sidenav"><!-- 9 章 + 6 案例链接，当前章 .on --></aside>
    <main><article class="chap">
      <div class="crumb"><a href="index.html">全书目录</a> / 第 N 章</div>
      <div class="chapnum">0N</div><h1>章标题</h1><p class="lede">章导语</p>
      <!-- 知识块 -->
    </article></main>
    <aside class="toc"><!-- 章内 h2 列表 --></aside>
  </div>
  <script src="assets/site.js"></script></body></html>
  ```
- commit 风格：`feat:` / `docs:` / `test:` / `chore:`。
- 所有外部链接写入页面时必须来自本计划列出的 URL（已验证）；章末资源条目带难度标签（入门/进阶/参考）。

---

### 任务 1：共享资产与高亮器测试

**文件：** 创建 `assets/site.js`、`assets/site.css`、`assets/logo.svg`、`tools/hl_test.mjs`

- [ ] 步骤 1：写 `tools/hl_test.mjs`（先测试）：导入 site.js 的 hl（site.js 末尾 `if (typeof module!=='undefined') module.exports={hl};` 兼容 node），样本断言：
  ```js
  import { readFileSync } from 'node:fs';
  const src = readFileSync(new URL('../assets/site.js', import.meta.url), 'utf8');
  const hl = new Function(src + '; return hl;')();
  const strip = h => h.replace(/<span class="tok-[a-z]+">/g, '').replace(/<\/span>/g, '');
  const cases = [
    'x <- c(1, NA) # 注释含 "引号" 和 <-',
    'adsl |> dplyr::filter(ARM == "Placebo") |> nrow()',
    'f <- function(a, b = TRUE) { a + b }  # 尾注释',
    'mmrm::mmrm(FEV1 ~ ARM + AVISIT | USUBJID, data = d)',
    's <- "a # b <- c"; n <- 3.14e-2'
  ];
  let fail = 0;
  for (const c of cases) {
    const h = hl(c);
    if (strip(h) !== c.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;')) { console.log('ROUNDTRIP FAIL:', c); fail++; }
    if (/tok-[a-z]+="|<span<span|undefined/.test(h)) { console.log('LEAK FAIL:', c); fail++; }
  }
  const h1 = hl('x <- 1 # c');
  for (const cls of ['tok-com','tok-num','tok-kwop']) if (!h1.includes(cls) && cls!=='tok-kwop') {}
  if (!/tok-com/.test(h1) || !/tok-num/.test(h1)) { console.log('CLASS FAIL'); fail++; }
  console.log(fail ? `FAIL ${fail}` : 'HL TEST PASS');
  process.exit(fail ? 1 : 0);
  ```
- [ ] 步骤 2：运行 `node tools/hl_test.mjs`，预期 FAIL（site.js 不存在）。
- [ ] 步骤 3：写 `assets/site.js`（单遍分词器 + 交互）：
  ```js
  /* R 运行时高亮：先转义后单遍分词，禁止多遍 replace */
  function hl(src){
    function esc(s){return s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');}
    try{
      var TOKEN=/(#[^\n]*)|("(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*')|(<-|->>|->|\|>|%[^%\n]*%)|(\b(?:function|if|else|for|while|repeat|return|next|break|library|require|local|tryCatch|withCallingHandlers|in|NULL|NaN|Inf|TRUE|FALSE|NA|NA_integer_|NA_real_|NA_character_)\b)|(\b[A-Za-z][A-Za-z0-9._]*::)|(\b[A-Za-z._][A-Za-z0-9._]*(?=\s*\())|(\b\d+(?:\.\d+)?(?:[eE][+-]?\d+)?\b)/g;
      var out='',last=0,m;
      while((m=TOKEN.exec(src))!==null){
        if(m[0].length===0){TOKEN.lastIndex++;continue;}
        out+=esc(src.slice(last,m.index));
        var t=esc(m[0]);
        if(m[1])out+='<span class="tok-com">'+t+'</span>';
        else if(m[2])out+='<span class="tok-str">'+t+'</span>';
        else if(m[3])out+='<span class="tok-op">'+t+'</span>';
        else if(m[4])out+='<span class="tok-kw">'+t+'</span>';
        else if(m[5])out+='<span class="tok-ns">'+t+'</span>';
        else if(m[6])out+='<span class="tok-fn">'+t+'</span>';
        else if(m[7])out+='<span class="tok-num">'+t+'</span>';
        last=m.index+m[0].length;
      }
      out+=esc(src.slice(last));
      return out;
    }catch(e){return esc(src);}
  }
  document.addEventListener('DOMContentLoaded',function(){
    document.querySelectorAll('code.lang-r').forEach(function(c){c.innerHTML=hl(c.textContent);});
    document.querySelectorAll('pre.code, pre.out').forEach(function(p){p.style.whiteSpace='pre';});
    /* 复制按钮 */
    document.querySelectorAll('pre.code').forEach(function(p){
      var b=document.createElement('button');b.className='copy';b.textContent='复制';
      b.onclick=function(){navigator.clipboard.writeText(p.textContent);b.textContent='已复制';setTimeout(function(){b.textContent='复制';},1500);};
      p.appendChild(b);
    });
    /* 测验 */
    document.querySelectorAll('.quiz').forEach(function(q){
      var ans=q.getAttribute('data-answer');
      q.querySelectorAll('.quiz-opt').forEach(function(btn){
        btn.onclick=function(){
          q.querySelectorAll('.quiz-opt').forEach(function(x){x.classList.remove('right','wrong');});
          btn.classList.add(btn.getAttribute('data-opt')===ans?'right':'wrong');
          q.classList.add('revealed');
        };
      });
    });
    /* TOC scrollspy */
    var links=[].slice.call(document.querySelectorAll('.toc a'));
    if(links.length&&'IntersectionObserver' in window){
      var io=new IntersectionObserver(function(es){es.forEach(function(e){
        if(e.isIntersecting){links.forEach(function(l){l.classList.toggle('on',l.getAttribute('href')==='#'+e.target.id);});}
      });},{rootMargin:'-10% 0px -80% 0px'});
      document.querySelectorAll('article h2[id]').forEach(function(h){io.observe(h);});
    }
    /* 暗色 */
    var tt=document.getElementById('theme-toggle');
    if(tt)tt.onclick=function(){document.body.classList.toggle('dark');};
    /* 进度条 */
    var pb=document.querySelector('.progress');
    if(pb)addEventListener('scroll',function(){
      var h=document.documentElement;pb.style.width=(h.scrollTop/(h.scrollHeight-h.clientHeight)*100)+'%';
    });
  });
  if (typeof module!=='undefined') module.exports={hl};
  ```
- [ ] 步骤 4：运行 `node tools/hl_test.mjs` 预期 `HL TEST PASS`；`node --check assets/site.js` 预期无输出。
- [ ] 步骤 5：写 `assets/site.css`（视觉系统，CSS 变量 + 组件）：
  ```css
  :root{--bg:#f7f6f2;--ink:#1a1a1a;--mut:#6b6b64;--acc:#7d8f4e;--num:#d7e05a;--card:#fffef9;--line:#e3e1d8;--code:#f2f1ea;--out:#efeee7;}
  body.dark{--bg:#191a17;--ink:#e8e6dd;--mut:#9a988e;--acc:#a8b878;--num:#b9c437;--card:#20211c;--line:#33342c;--code:#20211c;--out:#1d1e19;}
  *{box-sizing:border-box}html{scroll-behavior:smooth}
  body{margin:0;background:var(--bg);color:var(--ink);font:17px/1.9 "Noto Serif SC","Source Han Serif SC",serif;}
  .progress{position:fixed;top:0;left:0;height:3px;background:var(--acc);width:0;z-index:9}
  .top{position:sticky;top:0;display:flex;justify-content:space-between;align-items:center;padding:14px 28px;background:var(--bg);border-bottom:1px solid var(--line);z-index:8}
  .brand{display:flex;gap:10px;align-items:center;text-decoration:none;color:var(--ink);font-weight:700}
  .brand em{display:block;font-style:normal;font-size:12px;color:var(--mut)}
  .topnav a{margin:0 12px;color:var(--ink);text-decoration:none}
  #theme-toggle{background:none;border:1px solid var(--line);border-radius:50%;width:36px;height:36px;cursor:pointer;color:var(--ink)}
  .layout{display:grid;grid-template-columns:230px minmax(0,780px) 210px;gap:36px;justify-content:center;padding:40px 24px}
  .sidenav,.toc{position:sticky;top:80px;align-self:start;font-size:14px;max-height:calc(100vh - 100px);overflow:auto}
  .sidenav a{display:block;padding:7px 12px;color:var(--mut);text-decoration:none;border-left:2px solid transparent}
  .sidenav a.on{color:var(--ink);background:var(--card);border-left-color:var(--acc);font-weight:700}
  .toc a{display:block;padding:4px 0;color:var(--mut);text-decoration:none}
  .toc a.on{color:var(--acc);font-weight:700}
  .crumb{font-size:13px;color:var(--mut)}
  .chapnum{display:inline-block;background:var(--num);color:#1a1a1a;font:700 14px/1 monospace;padding:6px 9px;margin:18px 0 10px}
  h1{font-size:44px;line-height:1.25;margin:0 0 8px;font-weight:900}
  .lede{color:var(--mut);font-size:18px}
  h2{font-size:26px;margin:52px 0 12px;padding-top:8px;border-top:1px solid var(--line)}
  h3{font-size:20px;margin:30px 0 8px}
  p{margin:12px 0}
  pre.code,pre.out{position:relative;background:var(--code);border:1px solid var(--line);border-radius:8px;padding:16px 18px;font:13.5px/1.7 Consolas,"Cascadia Mono",monospace;overflow:auto;white-space:pre!important}
  pre.out{background:var(--out);border-style:dashed}
  pre .copy{position:absolute;top:8px;right:8px;font:12px/1 sans-serif;border:1px solid var(--line);background:var(--card);color:var(--mut);border-radius:5px;padding:4px 8px;cursor:pointer}
  .tok-com{color:#8a8a80;font-style:italic}.tok-str{color:#8a6d3b}.tok-op{color:#b0413e}.tok-kw{color:#7d4fb0;font-weight:700}.tok-ns{color:#3a7ca5}.tok-fn{color:#2a6f77}.tok-num{color:#b0413e}
  body.dark .tok-com{color:#7c7c72}body.dark .tok-str{color:#c9a86a}body.dark .tok-kw{color:#b794d6}body.dark .tok-fn{color:#7fd1c0}body.dark .tok-num{color:#e08585}
  .walk{background:var(--card);border:1px solid var(--line);border-radius:8px;padding:6px 22px}
  .pitfall{border-left:4px solid #b0413e;background:var(--card);padding:12px 16px;border-radius:0 8px 8px 0;margin:16px 0}
  .note{border-left:4px solid var(--acc);background:var(--card);padding:12px 16px;border-radius:0 8px 8px 0;margin:16px 0}
  .quiz{background:var(--card);border:1px solid var(--line);border-radius:10px;padding:16px 20px;margin:22px 0}
  .quiz-q{font-weight:700;margin:0 0 10px}
  .quiz-opt{display:block;width:100%;text-align:left;margin:6px 0;padding:9px 14px;border:1px solid var(--line);border-radius:7px;background:var(--bg);color:var(--ink);cursor:pointer;font:15px/1.6 inherit}
  .quiz-opt.right{border-color:var(--acc);background:#eef2df}
  .quiz-opt.wrong{border-color:#b0413e;background:#f6e7e5}
  .quiz-exp{display:none;margin-top:10px;color:var(--mut);font-size:15px;border-top:1px dashed var(--line);padding-top:8px}
  .quiz.revealed .quiz-exp{display:block}
  body.dark .quiz-opt.right{background:#2c3320}body.dark .quiz-opt.wrong{background:#3a2422}
  table{border-collapse:collapse;width:100%;font-size:15px;margin:16px 0}
  th,td{border:1px solid var(--line);padding:8px 10px;text-align:left;vertical-align:top}
  th{background:var(--card)}
  .res a{color:var(--acc)}
  .cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:18px;margin:26px 0}
  .card{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:18px 20px;text-decoration:none;color:var(--ink)}
  .card b{display:block;font-size:18px;margin-bottom:6px}
  .card span{color:var(--mut);font-size:14px}
  .hero{padding:70px 0 30px}
  .hero h1{font-size:76px;line-height:1.12}
  .hero h1 i{font-style:italic;font-weight:400}
  .btn{display:inline-block;background:#1a1a1a;color:#f7f6f2;padding:13px 26px;border-radius:4px;text-decoration:none;font-weight:700}
  body.dark .btn{background:#e8e6dd;color:#1a1a1a}
  @media(max-width:1100px){.layout{grid-template-columns:1fr}.sidenav,.toc{display:none}.hero h1{font-size:48px}}
  ```
- [ ] 步骤 6：写 `assets/logo.svg`：橄榄绿圆角方块 + 白色 "R+" 字样（24×24 viewBox，`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect width="32" height="32" rx="6" fill="#7d8f4e"/><text x="16" y="22" font-family="serif" font-size="18" font-weight="700" fill="#fff" text-anchor="middle">R</text></svg>`）。
- [ ] 步骤 7：commit `feat: shared assets with runtime R highlighter and quiz engine`。

### 任务 2：首页 index.html

**文件：** 创建 `index.html`

- [ ] 步骤 1：按骨架写首页（无 sidenav/toc 两栏，用 `.hero` 全宽）：hero 大标题「从 SAS 到 R。<i>临床数据实战。</i>」+ 定位语（写给临床 SAS Programmer 的 R 进阶之路）+ `.btn` 继续阅读→ch0 + SVG 概念图（横向四节点：SAS 经验 → R 工具链(tidyverse·pharmaverse) → CDISC(SDTM·ADaM) → TLF 与监管递交，箭头连接，橄榄绿描边）+「本书用法」三卡 + `#toc` 目录卡片区（9 章卡：章号/标题/一句话/约 N 分钟；6 案例卡：C1–C6 标题/数据源标签）+ 90 天路径表（周 1-2：ch0-ch1；周 3-6：ch2-ch4 + C1/C2；周 7-10：ch5-ch7 + C3-C5；周 11-12：ch8 + C6 + 复盘）+ 页脚（本地精读资产链接：`../PharmaSUG2026-Analysis/00-总览与导读.md` 相对路径说明）。
- [ ] 步骤 2：运行任务 15 的校验脚本（若已存在）或人工核对内部链接；commit `feat: homepage with concept map and TOC`。

### 任务 3：ch0 金标准章（确立内容范式）

**文件：** 创建 `ch0-environment.html`

- [ ] 步骤 1：按全局约定写 7 个知识块：0.1 R 已进入监管递交（事实块：R Consortium SWG Pilot 1–5、FDA 2025-08 eCTD 接受 .rds/.rdata/.rda/.zip/.html、J&J 混合递交获批；链接 rconsortium.github.io/submissions-wg/pilot1.html、r-consortium.org J&J 帖、r-consortium.com 格式帖）+ 测验（Q：2025-08 FDA eCTD 指南新增接受哪些 R 相关格式？A 选项含 .rds/.rdata/.zip/.html 正确）；0.2 安装与验证（代码：`Rscript --version`、`Rscript -e 'sessionInfo()'`、镜像 `options(repos = c(CRAN = "https://cloud.r-project.org"))`；输出=本机实跑捕获）；0.3 renv 项目化（`renv::init()/snapshot()/restore()/dependencies()` 代码+输出）；0.4 目录结构约定（tree 文本块）；0.5 SAS↔R 映射表（10 行：DATA step/merge/retain+lag/PROC SORT/PROC MEANS/PROC FREQ/PROC TRANSPOSE/ODS RTF/macro/%put → dplyr 动词/left_join 等/mutate(.by=) 或 accumulate/order_by+arrange/summarise(.by=)/table+gtsummary/pivot_wider/Quarto+flextable/function()/logger::log_info()）；0.6 GxP/CSV 心智对照（callout：验证对象从"脚本+日志"变为"包+测试+环境锁"）；0.7 本站用法与复现指南（如何跑 cases/*.R、输出标注含义）。
- [ ] 步骤 2：章末资源：R for Data Science(https://r4ds.hadley.nz,入门)、Posit cheatsheets(https://posit.co/resources/cheatsheets/,参考)、PharmaSUG 2026 ET-279(https://pharmasug.org/proceedings/2026/ET/PharmaSUG-2026-ET-279.pdf,进阶)、R/Pharma(https://rinpharma.com,参考)、本地精读(相对链接,参考)。
- [ ] 步骤 3：commit `feat: ch0 environment and SAS-R mental mapping`。

### 任务 4–11：ch1–ch8（可并行，子 Agent 执行）

每章一个任务，文件 `chN-*.html`，结构遵全局约定。以下为各章**必须包含**的块、示例、测验与资源（执行者不得增删块级结构，可润色文字）：

**任务 4 ch1-r-basics.html**：块 1.1 向量与强制（示例 `c(1,"a")` typeof；测验 Q:`c(1, TRUE, "a")` 类型？A:character）；1.2 factor（`factor(c("b","a"), levels=c("a","b"))`、table()；误区：as.integer(factor) 陷阱、与 SAS char 变量对比）；1.3 NA 语义（`mean(c(1,NA))` vs `na.rm=TRUE`；对照 SAS `.` 与 MISSING()；测验 Q: `c(1,NA)+1` 结果？A:`c(1,NA)`）；1.4 索引与回收（`x[2:4]`、逻辑索引、`1:3 + 1:2` 警告）；1.5 data.frame/tibble（str/glimpse 输出对照 SAS PROC CONTENTS）；1.6 三范式同任务（筛选 ARM=="Placebo" 并按 SITEID 求 AGE 均值：base aggregate / dplyr / data.table 三段代码+相同输出）；1.7 函数与管道（定义 derive_age(brth, ref) 用 lubridate；`|>` 链；误区：macro 全局 vs function 词法作用域）；1.8 日期字符串（ymd/dyears；stringr str_detect 与 SAS PRX 差异表）；1.9 十大陷阱汇总表。资源：R4DS、Advanced R(https://adv-r.hadley.nz)、r4stats(http://r4stats.com)、SAS and R 博客(http://sas-and-r.blogspot.com)、cheatsheets。commit `feat: ch1 R basics for SAS users`。

**任务 5 ch2-cdisc.html**：块 2.1 数据三源（`library(pharmaversesdtm); pharmaversesdtm::adsl` head 输出；scda GitHub https://github.com/insightsengineering/scda；synadam CRAN https://cran.r-project.org/package=synadam）；2.2 SDTM 在 R 中的样子（glimpse(dm)、关键变量 USUBJID/ARM/RFXSTDTC 讲解）；2.3 admiral 推 ADSL（代码：`derive_vars_duration(new_var = AGE, new_var_unit = AGEU, start_date = BRTHDT, end_date = TRTSDT, out_unit = "years")`、`derive_vars_dy(new_var = TRTSDY, reference_date = TRTSDT)`；逐行解读）；2.4 ADAE（`derive_vars_dt(new_var = ASTDT, dtc = AESTDTC)`、`derive_var_extreme_flag(by_vars=exprs(USUBJID), new_var=AOCC01FL, order=exprs(ASTDT), mode="first")`）；2.5 ADTTE（`derive_param_tte(dataset_adsl, event_source=..., censor_source=...)` 概念+骨架代码）；2.6 metadata 驱动（metatools https://pharmaverse.github.io/metatools/ 概念块）；2.7 双编程比对（diffdf::diffdf(base, compare, keys="USUBJID") 代码+输出；arsenal::compare；误区：SAS PROC COMPARE 的 criterion vs diffdf 的 tolerance）；2.8 CDISC CORE（https://github.com/CDISC-org/CORE 规则引擎概念）。测验：Q: admiral 中推导研究天数用哪个函数族？A: derive_vars_dy。资源：admiral docs(https://pharmaverse.github.io/admiral/)、pharmaverse examples(https://pharmaverse.github.io/examples/)、ET-279 PDF、scda、本地 `../PharmaSUG2026-Analysis/03-DS-SS-SI-数据标准与递交.md`。commit `feat: ch2 CDISC with admiral`。

**任务 6 ch3-stats.html**：块 3.1 ggplot2 语法（AE 计数条形：ggplot(adae_small, aes(x=AEBODSYS, fill=ARM))+geom_bar(position="dodge")+theme(axis.text.x=element_text(angle=45))；分层讲解 mapping/geom/scale/facet/theme）；3.2 Surv 结构（`Surv(time, event)` 代码+输出）；3.3 KM+log-rank（survival::lung：`fit <- survfit(Surv(time, status) ~ sex, data=lung)`、survdiff、survminer::ggsurvplot；输出实跑）；3.4 Cox（coxph 代码、summary 的 HR/exp(coef) 解读、ties 说明）；3.5 MMRM（set.seed(42) 模拟 80 人 3 访视数据 → `mmrm(FEV1 ~ ARM + AVISIT + ARM:AVISIT + BASE | USUBJID, data=dat)`；输出实跑；对照 SAS PROC MIXED REPEATED）；3.6 lme4 对照（lmer 同数据随机截距）；3.7 分类与 CMH（chisq.test、mantelhaen.test 分层 OR）；3.8 森林图（forestploter 三亚组示例）；3.9 期中分析（gsDesign::gsDesign(k=2) 边界输出+概念；多重性一句带过）。测验：Q: mmrm 公式中 `| USUBJID` 的作用？A: 指定重复测量个体（within-subject 协方差）。资源：mmrm CRAN、survminer(https://rpkgs.datanovia.com/survminer/)、flexsurv CRAN、gsDesign(https://keaven.github.io/gsDesign/)、Harrell RMS(https://hbiostat.org/rms/)、本地 `../mmrm`、`../lmm`。commit `feat: ch3 statistics survival mmrm`。

**任务 7 ch4-tfl.html**：块 4.1 TLF 流水线（spec→program→output→QC 列表+追溯要求）；4.2 rtables 基础（`basic_table() %>% split_rows_by("ARM") %>% analyze(c("SEX","AGE"))` 于 adsl 子集；输出实跑；讲解 split/analyze 树）；4.3 tern（`summarize_vars(c("SEX","AGE"))` 示例）；4.4 tableone（`CreateTableOne(vars=c("age","sex"), strata="arm", data=d)` 输出）；4.5 gtsummary（`tbl_summary(d, by=arm) %>% add_p()`）；4.6 导出三件套（flextable `save_as_docx(ft, path="t1.docx")`、openxlsx `write.xlsx(d, "t1.xlsx")`、rtables `export_as_txt(tb, file="t1.txt")` 并说明 RTF 路径）；4.7 Quarto 参数化（qmd YAML+参数块代码、`quarto render report.qmd -P arm:Placebo` 命令；标注需另装 Quarto CLI）；4.8 追溯清单（renv.lock、sessionInfo()、spec 链接、日志留存 callout）。测验：Q: 把 rtables 表格导出为文本/RTF 用哪个函数？A: export_as_txt。资源：rtables(https://pharmaverse.github.io/rtables/)、tern(https://pharmaverse.github.io/tern/)、gtsummary(https://www.danieldsjoberg.com/gtsummary/)、flextable(https://davidgohel.github.io/flextable/)、Quarto(https://quarto.org)、本地 `../tfl-review-tool`。commit `feat: ch4 TLF reporting`。

**任务 8 ch5-advanced.html**：块 5.1 函数式（purrr::map 族、`\(x) x*2`；对照 SAS macro 循环）；5.2 环境与作用域（词法作用域示例：计数器 make_counter()；误区：macro 变量全局污染）；5.3 S3 十分钟（class(x)<-"adsl"、print.adsl 方法示例）；5.4 性能（循环 vs 向量化 system.time 对比实跑；profvis 概念）；5.5 错误与日志（tryCatch vs withCallingHandlers 对照代码；logger::log_info）；5.6 testthat（test_that("derive_age works", {expect_equal(derive_age(...), 42)}) 实跑输出含 [ FAIL 0 ]）；5.7 CI（GitHub Actions yaml 块：on push → R setup → r-lib/actions/check-r-package@v2）；5.8 GxP 验证（valtools https://pharmaverse.github.io/valtools/ 工作流、CSV/GAMP5 映射表、PharmaSUG 2026 ET-140 https://pharmasug.org/proceedings/2026/ET/PharmaSUG-2026-ET-140.pdf 摘要块）；5.9 评审清单（10 条 list）。测验：Q: tryCatch 与 withCallingHandlers 的关键区别？A: 前者退出调用栈后者留在现场。资源：Advanced R、testthat(https://testthat.r-lib.org)、valtools、ET-140、logger CRAN。commit `feat: ch5 advanced R and GxP engineering`。

**任务 9 ch6-pkgdev.html**：块 6.1 包=复用与验证单元（pharma 视角 callout）；6.2 工作流全链（usethis::create_package("clinderive") → DESCRIPTION 字段 → R/derive_age.R → roxygen 注释 → devtools::document()/load_all()/test()/install() 代码序列+输出）；6.3 roxygen 标签表（@param/@return/@export/@examples/@importFrom）；6.4 测试布局（tests/testthat/test-derive_age.R 全文）；6.5 vignette（vignettes/ads.Rmd 骨架）；6.6 依赖与分发（Imports vs Suggests 表；renv vs 包管理；Posit Package Manager/drat/r-universe https://pharmaverse.r-universe.dev/packages）；6.7 实战迷你包（完整文件树 + 4 个文件全文：DESCRIPTION/NAMESPACE/derive_age.R/test）。测验：Q: devtools::load_all() 与 library() 的区别？A: 加载源码不安装、含未导出函数。资源：R Packages(https://r-pkgs.org)、usethis(https://usethis.r-lib.org)、devtools(https://devtools.r-lib.org)、roxygen2(https://roxygen2.r-lib.org)、r-universe。commit `feat: ch6 package development`。

**任务 10 ch7-shiny.html**：块 7.1 心智模型（reactive 图 vs SAS 批处理：list 对照）；7.2 最小 app（ui/server 全文代码+运行说明 `shiny::runApp()`）；7.3 三件套对照表（reactive/reactiveVal/observeEvent 返回值与副作用）；7.4 modules（ns() 模块示例代码）；7.5 DT 与 plotly（renderDataTable/renderPlotly 代码）；7.6 teal（`teal::init(data=teal::teal_data(adsl=adsl), modules=modules(teal.modules.general? 用 teal 内置 example_module()))` 骨架+teal.slice 说明；扩展提 teal.modules.clinical）；7.7 部署（shinyapps.io 四步 list + Connect 一句）；7.8 GxP（Part 11 考量、验证策略：输入边界/审计轨迹/版本锁定 callout）。测验：Q: reactive() 与 observeEvent() 的核心区别？A: 前者返回值供下游、后者做副作用。资源：Mastering Shiny(https://mastering-shiny.org)、shiny(https://shiny.posit.co)、teal(https://pharmaverse.github.io/teal/)、DT(https://rstudio.github.io/DT/)、本地 `../clinical-viz-improved`。commit `feat: ch7 shiny and teal`。

**任务 11 ch8-community.html**：块 8.1 社区地图（R/Pharma https://rinpharma.com、China PharmaRUG https://pharmarug.github.io、pharmaverse blog https://pharmaverse.github.io/blog/、R Consortium SWG、useR!）；8.2 精读清单表（ET-279/ET-179 https://pharmasug.org/proceedings/2026/ET/PharmaSUG-2026-ET-179.pdf/ET-140/TT-156 https://pharmasug.org/proceedings/2026/TT/PharmaSUG-2026-TT-156.pdf/AI-305 https://pharmasug.org/proceedings/2026/AI/PharmaSUG-2026-AI-305.pdf + R/Pharma Summit 2024 https://rinpharma.com/docs/summit/posts/2024-ai.html /2025 https://rinpharma.com/docs/summit/posts/2025-ai.html + J&J 帖；每条一句理由）；8.3 本地资产衔接（`../PharmaSUG2026-Analysis/00-总览与导读.md`、`../PharmaR/Pharma开源社区近2年文章精读与AI影响分析.md` 相对链接+用法说明：章→track 映射表）；8.4 90 天计划表（12 周×目标×产出×对应章/案例）；8.5 团队迁移策略（J&J 混合模式、试点选择三原则、验证资产复用）；8.6 职业（角色演进三阶段、面试知识点 12 条 list）。测验：Q: 想跟踪中国制药 R 社区活动应关注？A: China PharmaRUG。资源：上述社区链接汇总。commit `feat: ch8 community and career`。

### 任务 12：案例脚本 cases/*.R

**文件：** 创建 `cases/c1_sdtm_adam_t1.R`、`c2_survival.R`、`c3_faers_signal.R`、`c4_nhanes.R`、`c5_trials_landscape.R`、`c6_teal_explorer.R`、`cases/cache/README.md`

- [ ] 步骤 1：c1：`library(pharmaversesdtm); dm <- pharmaversesdtm::dm; adsl <- admiral 推导链（TRTSDT/AGE/SEX/ARM/ITTFL）→ adae 由 pharmaversesdtm::ae 推 ASTDT/AOCC01FL → rtables Table 1（ARM 分层 n(%) / mean(sd)）→ diffdf 自检（与重跑结果比对）`；每步 `cat("\n== 步骤 N ==\n")` 分隔；输出纯 stdout。
- [ ] 步骤 2：c2：`data(lung, package="survival")` → 清洗（status 2→1）→ survfit KM by sex → survdiff → coxph(age+sex+ph.ecog) → survminer ggsurvplot 存 `docs/run-outputs/c2_km.png`(ggsave) → 打印 median CI 表。
- [ ] 步骤 3：c3：openFDA API `https://api.fda.gov/drug/event.json?search=patient.drug.openfda.generic_name:"imatinib"&limit=100` httr2 请求；tryCatch 失败则 `readRDS("cases/cache/faers_imatinib.rds")`；AE 频数 Top10 表 + 手工 2×2 ROR/PRR（以"水肿"为目标 AE、其余为对照）打印含 95%CI。
- [ ] 步骤 4：c4：nhanesA::nhanes("2017-2018","DEMO_J") + BPX + 权重变量；survey::svydesign(ids=~SDMVPSU, strata=~SDMVSTRA, weights=~WTMEC2YR)；加权均值 BMI 按性别 + svyglm 逻辑回归（高血压~年龄+性别）；tryCatch 缓存 `cases/cache/nhanes_demo.rds`。
- [ ] 步骤 5：c5：ctrdata::rfc_active? 用 `ctrdata::ctr_register?` 实际：`ctrdata::rfc_active()`? 计划指定：`ctrdata::ctr_load? ` —— 执行者以 ctrdata README 为准：`library(ctrdata); rfc <- ctr_register? ` **确定写法**：`ctrdata::rfc_active()` 不存在；正确链：`ctrdata::ctr_load(query=..., register="CTR", collection="tmp")` 需 mongo/duckdb——过重。**改用 httr2 直连 API v2**：`https://clinicaltrials.gov/api/v2/studies?query.cond=diabetes&pageSize=100&format=json` 解析 fields（protocolSection.conditionsModule, sponsorCollaborators, phases）；Top10 条件条形数据 + 相位×状态表；缓存 `cases/cache/ctgov_diabetes.rds`。
- [ ] 步骤 6：c6：复用 c1 的 adsl（source 共享函数文件 `cases/common.R`：derive_adsl()）→ teal::init(teal_data(adsl=...), modules=modules(teal::example_module()))；脚本以 `if (interactive()) shiny::runApp(app)` 结尾并打印 app 结构摘要（非交互实跑只打印模块清单）。
- [ ] 步骤 7：commit `feat: six runnable case scripts with cache fallback`。

### 任务 13：实跑捕获输出

- [ ] 步骤 1：`mkdir -p docs/run-outputs`；逐案运行 `"C:/Program Files/R/R-4.5.0/bin/Rscript.exe" cases/cN_*.R > docs/run-outputs/cN.txt 2>&1`；失败则修脚本/补包重跑至 6 案全绿（网络案允许走 cache 路径，txt 首行标注 `[cache]`）。
- [ ] 步骤 2：c2 的 KM png 确认生成；c6 确认非交互模式打印摘要不阻塞。
- [ ] 步骤 3：commit `feat: real-run outputs for all six cases`。

### 任务 14：案例页面 cases/c1–c6.html（可 2 子 Agent 并行，各 3 页）

- [ ] 每页结构：背景与学习目标 → 数据源卡（名称/获取方式/许可说明：pharmaversesdtm=CC0? 标注"合成数据,包内许可"；openFDA/FAERS=public domain；NHANES=public；ClinicalTrials.gov=public；survival::lung=包内公开试验数据）→ 分段代码（与 .R 一致，段标题对应）→ **实跑输出块**（自 `docs/run-outputs/cN.txt` 截取，保留 `== 步骤 ==` 分隔，块首注释"实跑捕获 R 4.5.0"）→ 解读要点 3-5 条 → 练习三级（易/中/难，与规格 §4 表一致）→ 扩展（注册制数据源链接：Project Data Sphere https://data.projectdatasphere.org、Vivli https://vivli.org、YODA https://yoda.yale.edu、SOAR https://dcri.org/solutions/analytics-and-data-science/data-sharing/soar-data/、ImmPort https://www.immport.org，按案例相关性选 1-2）。
- [ ] commit 每页：`feat: case page cN`。

### 任务 15：校验套件

**文件：** 创建 `tools/verify.mjs`、`tools/verify_html.py`

- [ ] 步骤 1：verify.mjs：遍历全部 html → 抽取 `<code class="lang-r">` 块做括号/引号配平启发式（圆括号、方括号、花括号、双引号偶数）；校验每个 `.quiz` 的 data-answer 存在于其 data-opt 集合；校验内部 href（*.html#锚点除外）文件存在；校验所有 `<pre` 含 `style="white-space:pre"`；输出 FAIL 列表，exit 1/0。
- [ ] 步骤 2：verify_html.py：html.parser 子类统计开闭标签配对（忽略 void 元素），全站逐文件报告不配对标签。
- [ ] 步骤 3：运行两脚本 + `node --check assets/site.js` + `node tools/hl_test.mjs`；修复所有 FAIL（修内容文件而非放宽校验）。
- [ ] 步骤 4：外部链接抽样：对计划中列出的 URL 用 `curl -s -o /dev/null -w "%{http_code}"` 抽 15 条，非 200/302 记录并在 README 注明检索式。
- [ ] 步骤 5：commit `test: site-wide verification suite green`。

### 任务 16：README.md

- [ ] 内容：项目一句话；目录结构树；**教程结构表**（章→知识点→对应案例）；**资料筛选标准**六条（规格 §7 原文）；**公开临床数据来源表**（源/获取方式/许可/对应案例/练习入口，含注册制扩展源）；使用方法（浏览器打开 index.html 或 Pages URL；跑案例：Rscript 命令；复现输出）；本地精读资产衔接说明；许可与免责（教学用途，非监管递交依据）。
- [ ] commit `docs: README with structure, criteria, data sources`。

### 任务 17：合并、推送、Pages

- [ ] 步骤 1：`git checkout main && git merge feature/tutorial-build`（无冲突预期）。
- [ ] 步骤 2：`gh repo create learn-r-clinical --public --source=. --remote=origin --push`（在 G:\test\learn_R 执行）。
- [ ] 步骤 3：`gh api repos/jinbeiwang/learn-r-clinical/pages -f build_type=legacy -f "source[branch]=main" -f "source[path]=/"`。
- [ ] 步骤 4：等待 30s 后 `curl -s -o /dev/null -w "%{http_code}" https://jinbeiwang.github.io/learn-r-clinical/` 预期 200（首次可能 404，重试 ≤3 次间隔 30s）。
- [ ] 步骤 5：记录 Pages URL 到 README 顶部并 commit `docs: add pages url`。

### 任务 18：交付与记忆

- [ ] 步骤 1：向主人交付：Pages URL + 本地路径 + 结构/筛选标准/数据来源摘要（对话内）。
- [ ] 步骤 2：memory 写入：仓库与 Pages URL、R 4.5.0 绝对路径约定、教程站结构一句话。

---

## 自审记录

- 规格覆盖：§2 文件↔T1-T14 全覆盖（logo T1、run-outputs T13、cache T12）；§5 模板↔全局约定；§6 输出策略↔T13；§7 标准↔T16+各章资源；§8 验证↔T1+T15；§9 发布↔T17；§11 风险↔T12 cache 回退+T13 标注。
- 占位符：T12 步骤 5 曾写 ctrdata 不确定链，已改为 httr2 直连 API v2 确定写法；其余无 TBD。
- 一致性：class 名（code/out/quiz/pitfall/note/walk/chapnum/res/cards/hero/btn/copy/tok-*）在 T1 CSS/JS 与全局约定、T3-T14 间一致；data-answer/data-opt 与 verify.mjs 校验逻辑一致。
