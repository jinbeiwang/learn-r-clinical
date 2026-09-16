# 设计规格：《R 语言临床数据分析与制药实践》交互式教程站

- 日期：2026-09-16
- 状态：已获主人批准（方案 A + 安装 R 实跑）
- 交付目录：`G:\test\learn_R`（git 仓库根 = 站点根）
- 发布：GitHub 公开仓库 `learn-r-clinical`（账号 jinbeiwang）+ GitHub Pages

## 1. 目标与受众

受众：临床 SAS Programmer，R 仅会基本语法、无实战经验。
目标：一套循序渐进的中文交互式教程 + 六个可公开获取数据的实战案例，覆盖
R 基础 → CDISC/ADaM → 统计分析 → TLF 报告 → 进阶工程 → 包开发 → Shiny → 社区职业，
最终发布到 GitHub 供长期学习。

成功标准：
1. 站点可在 GitHub Pages 直接阅读，视觉风格对齐主人提供的两张参考图（书籍式编辑排版）。
2. 每个知识点含：概念→示例（易/难，临床背景）→逐行解读→运行输出→SAS 思维误区→带解析测验。
3. 六个案例全部附可运行 `.R` 与数据获取脚本；核心案例输出为 R 实跑捕获的真实输出。
4. README 说明教程结构、资料筛选标准、公开临床数据来源与对应练习。

## 2. 信息架构（文件 = 页面）

```
learn_R/
├── index.html            首页：大标题开篇 + SVG 概念图 + 全书目录卡片 + 90 天路径
├── ch0-environment.html  起步与环境
├── ch1-r-basics.html     R 语言基础（SAS 用户视角）
├── ch2-cdisc.html        数据管理与 CDISC
├── ch3-stats.html        统计分析
├── ch4-tfl.html          临床报告 TLFs
├── ch5-advanced.html     进阶 R 与工程化
├── ch6-pkgdev.html       R 包开发
├── ch7-shiny.html        Shiny 与交互应用
├── ch8-community.html    社区与职业
├── cases/
│   ├── c1-sdtm-adam-t1.html   + c1_sdtm_adam_t1.R
│   ├── c2-survival.html       + c2_survival.R
│   ├── c3-faers-signal.html   + c3_faers_signal.R + fetch_faers.R
│   ├── c4-nhanes.html         + c4_nhanes.R
│   ├── c5-trials-landscape.html + c5_trials_landscape.R
│   ├── c6-teal-explorer.html  + c6_teal_explorer.R
├── assets/
│   ├── site.css          视觉系统（含暗色模式 CSS 变量）
│   ├── site.js           R 高亮单遍分词器 + 测验交互 + TOC scrollspy + 复制按钮
│   └── logo.svg          站点标识
├── README.md             结构 / 筛选标准 / 数据来源 / 使用方法
└── docs/superpowers/     设计与实现文档（specs/、plans/）
```

## 3. 章节知识点清单

- ch0：R/RStudio/Positron 安装与镜像；renv 项目化；目录结构约定；GxP/CSV 验证心智（对照 SAS 验证）；SAS↔R 概念映射表（DATA step↔dplyr、PROC↔函数族、libname↔包/读入、ODS↔Quarto/flextable、macro↔function、PUT log↔message/logging）；本站用法与复现指南。
- ch1：向量/因子/NA 语义；索引与回收规则；data.frame vs SAS dataset；base/tidyverse/data.table 三范式对照；函数与 pipe（|> 与 %>%）；日期（lubridate）与字符串（stringr）；SAS 用户十大陷阱（1-based 相同但 NA 传播、factor 层级、字符串比较、= vs ==、分号可选、无隐式输出等）。
- ch2：SDTM/ADaM 概念速览（假设读者懂 CDISC，聚焦 R 实现）；数据源 pharmaversesdtm / scda / synadam；admiral 推导 ADSL/ADAE/ADTTE（derive_vars_* 族）；metadata 驱动（metatools/metacore 概念）；双编程与比对（diffdf、arsenal、base::all.equal）；CDISC CORE 规则校验概念；define.xml 生态提及。
- ch3：ggplot2 图形语法分层讲解；生存分析：survfit/KM、survdiff log-rank、coxph、survminer 出图；纵向：mmrm（MMRM 主分析）、lme4 混合模型；分类：chisq/CMH（含 Mantel-Haenszel 手算对照）；森林图 forestploter；期中分析 gsDesign 概念；多重性提及。
- ch4：rtables/tern 表格语法（split/analyze 树）；gtsummary/tableone 快速 Table 1；flextable/officer 出 Word、openxlsx 出 Excel、RTF 路径；Quarto 参数化报告自动化；可追溯性（spec→code→output 链接、renv.lock、sessionInfo）。
- ch5：Advanced R 精选（函数式编程、环境与作用域、S3 简述）；性能 profvis 与向量化；错误处理 tryCatch/withCallingHandlers、logger；testthat 单元测试；GitHub Actions CI；GxP 包验证：valtools、CSV/GAMP5 映射、引用 PharmaSUG 2026 ET-140（R 包验证框架）与 ET-279（R 的 CDISC 全流程）；代码评审清单。
- ch6：R Packages 工作流（usethis→devtools→roxygen2→testthat→vignette）；依赖与版本策略；内部仓库（Posit Package Manager / drat / r-universe 概念）；实战：把 ch2 的一个 derive 函数包化成包并写测试与 vignette。
- ch7：Shiny reactive 心智模型（对照 SAS 无状态脚本）；module 化；DT/plotly 交互；teal 模块体系与 teal.slice；部署（shinyapps.io / Connect）；GxP 下 Shiny 验证要点（Part 11、审计轨迹概念）。
- ch8：社区地图（R/Pharma、China PharmaRUG、pharmaverse Slack、R Consortium SWG）；精读清单：PharmaSUG 2026 ET-279/ET-179/ET-140/AI-305、PhUSE 相关、R/Pharma Summit 2024/2025 圆桌、J&J 混合递交案例、FDA 2025-08 eCTD 格式更新；**链接主人本地 `G:\test\PharmaSUG2026-Analysis`、`G:\test\PharmaR` 精读资产**；90 天学习计划表；团队级 SAS→R 迁移策略（混合：ADaM 用 SAS、TFL 用 R 的 J&J 模式）。

## 4. 案例规格（数据全部可公开获取）

| 案例 | 数据源（获取方式） | 核心包 | 练习分级 |
|---|---|---|---|
| C1 SDTM→ADaM→Table 1 | pharmaversesdtm（CRAN 内置合成 SDTM）；扩展：scda/synadam | admiral, rtables, tern, diffdf | 易:改 ADSL 衍生；中:加 ADAE 表；难:双编程比对脚本 |
| C2 肿瘤生存分析 | survival::lung（NCCTG 试验，包内置）；hbiostat.org 数据；扩展:Project Data Sphere（注册） | survival, survminer, flexsurv | 易:KM 分层；中:Cox 多变量；难:MMRM/竞争风险扩展 |
| C3 FAERS 安全信号 | openFDA API（免注册）+ FAERS 季度 zip（FDA 官网） | jsonlite, httr2, base | 易:AE 频数表；中:ROR/PRR 2×2；难:时间趋势/亚组 |
| C4 NHANES 调查分析 | nhanesA（CRAN 直连 CDC） | survey, tidyverse | 易:加权均值；中:逻辑回归加权；难:合并周期 |
| C5 试验景观扫描 | ClinicalTrials.gov API v2（ctrdata 或 httr2 直连） | ctrdata, ggplot2 | 易:适应症 Top10；中:赞助方×相位；难:招募趋势地图 |
| C6 teal 数据探索器 | 复用 C1 的 ADaM 产物 | shiny, teal, teal.data | 易:换模块；中:加自定义图；难:部署 shinyapps.io |

扩展数据源（需注册/申请，仅列清单与适用场景，不做主案例）：Project Data Sphere、Vivli、YODA、DCRI SOAR、PhysioNet/MIMIC-IV、UK Biobank、ImmPort（免注册开放，可作 C3 类扩展）。

## 5. 页面模板与交互规格

知识点块顺序：`概念引入 → 示例(易→难) → 逐行解读 → 运行输出 → SAS 误区 → 测验`。
- 代码块：`<pre class="code"><code class="lang-r">原始源码</code></pre>`；site.js 运行时单遍分词高亮（先转义后逐 token 着色；token：注释#、字符串、关键字、<-/->/|>/%>%、函数调用名、数字、TRUE/FALSE/NA/NULL/Inf）；**禁止多遍 replace 占位符方案**（历史事故）。pre 内联 `style="white-space:pre"` + CSS `!important` 防查看器压扁。
- 输出块：`<pre class="out">` 灰底等宽，标注来源（实跑捕获 / 示例输出(节选)）。
- 测验：`<div class="quiz" data-answer="B">` 选项按钮，点击判定+展开解析；页尾汇总得分。
- 导航：左固定章导航、右章内 TOC（IntersectionObserver scrollspy）、顶部进度条、代码复制按钮、暗色模式切换（CSS 变量）。
- 视觉：背景 #f7f6f2、墨黑 #1a1a1a、橄榄绿 accent #7d8f4e、章号黄绿块 #d7e05a（参考图 2）；中文标题 Noto Serif SC/serif，正文 17px/1.9；代码区浅色卡片+细边框（参考图 2 系统提示词卡片风格）。

## 6. 输出真实性策略

1. 复用本机已有 R 4.5.0（`C:/Program Files/R/R-4.5.0/bin/Rscript.exe`，不在 shell PATH 中，一律绝对路径调用）；不重装 R；配置 CRAN 镜像后仅补装缺失包（候选清单：tidyverse, admiral, pharmaversesdtm, synadam, rtables, tern, formatters, mmrm, lme4, survminer, flexsurv, gtsummary, tableone, flextable, officer, openxlsx, survey, nhanesA, ctrdata, httr2, jsonlite, shiny, DT, plotly, teal, testthat, usethis, roxygen2, renv, profvis, logger, diffdf, arsenal, metatools, gsDesign, forestploter, knitr, rmarkdown；先探测已有/缺失再装）。
2. 案例 `.R` 实跑，输出落盘 `docs/run-outputs/*.txt`，截取嵌入页面（标注"实跑捕获"）。
3. 章节内小示例输出逐行推演核验；无法实跑的（网络受限等）标注"示例输出(节选)"。
4. 安装失败回退：全部输出改人工核验+标注，ch0 保留安装指南供用户自装。

## 7. 资料筛选标准（写入 README 与章末）

① 一手来源优先（CRAN/官方 GitHub org/书籍官网）；② 制药垂直相关（pharmaverse、R/Pharma、R Consortium SWG、PharmaSUG/PhUSE）；③ 时效 2024–2026 且链接逐一验证；④ 可动手（带代码或数据）；⑤ 与主人本地精读资产互补互链；⑥ 数据许可与使用条款注明。
章末资源条目格式：名称 — 一句话理由 — 链接 — 难度标签。

## 8. 验证计划

- `node --check assets/site.js`；node 脚本对 10+ 代码样本做高亮往返测试（无残骸 span 泄漏）。
- Python html.parser 全站标签配对校验；quiz 的 data-answer 与选项数对齐校验；内部链接存在性校验；外部链接抽样 HTTP 校验。
- R 实跑：`Rscript cases/*.R` 全绿（网络案例允许 skip 标注）。
- 视觉自查：关键页面结构对照参考图清单（大标题/章号块/双栏 TOC）。

## 9. Git 与发布

- `git init` 于 G:\test\learn_R；里程碑提交（spec → 骨架 → 章节 → 案例 → 验证 → README）。
- `gh repo create learn-r-clinical --public --source . --remote origin --push`。
- Pages：`gh api repos/jinbeiwang/learn-r-clinical/pages -f build_type=legacy -f source[branch]=main -f source[path]=/`（站点根=仓库根）。
- 推送后 curl 校验 Pages URL 可达。

## 10. 范围外（YAGNI）

不做：Quarto 构建链、书籍翻译、视频录制、登录/评论功能、i18n 英文版、teal 之外的第二套 Shiny 框架、注册制数据的代申请。

## 11. 风险与对策

- R/包安装失败或过慢 → 回退人工核验输出（§6.4），不阻塞站点交付。
- 外部链接漂移 → 发布前抽样校验 + README 注明检索式。
- Pages 缓存旧版 → 交付说明中提示 Ctrl+F5。
- 单文件过大 → 每章独立 HTML，共享 assets，符合"小而边界清晰"原则。
