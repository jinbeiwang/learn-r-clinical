# 从 SAS 到 R：临床数据分析与制药实践（交互式教程）

一套面向**临床 SAS Programmer** 的中文交互式教程站：9 章主线 + 6 个可公开获取数据的实战案例。
在线阅读：<https://jinbeiwang.github.io/learn-r-clinical/>（GitHub Pages）；本地阅读：浏览器打开 `index.html`。

> 教学用途，不构成监管递交依据。所有"实跑捕获"输出来自 R 4.5.0（Windows x86_64）。

## 目录结构

```
├── index.html               首页：概念图、全书目录、90 天路径
├── ch0-environment.html     起步与环境：R 进入监管递交的事实、renv、SAS↔R 映射、GxP 心智
├── ch1-r-basics.html        R 语言基础：向量/factor/NA、三范式对照、十大陷阱
├── ch2-cdisc.html           数据管理与 CDISC：pharmaversesdtm/scda、admiral 推导、双编程比对
├── ch3-stats.html           统计分析：ggplot2、KM/Cox、MMRM(mmrm)、混合模型、CMH、森林图
├── ch4-tfl.html             临床报告 TLFs：rtables/tern、tableone/gtsummary、Word/Excel/RTF、Quarto
├── ch5-advanced.html        进阶 R 与工程化：函数式/环境/S3、testthat、CI、valtools 验证
├── ch6-pkgdev.html          R 包开发：usethis/roxygen2/vignette、迷你包实战
├── ch7-shiny.html           Shiny 与交互：reactive、modules、DT/plotly、teal、GxP 考量
├── ch8-community.html       社区与职业：R/Pharma、China PharmaRUG、精读清单、90 天计划
├── cases/                   六个实战案例（页面 + 可运行 .R + 离线缓存）
│   ├── c1_sdtm_adam_t1.R    SDTM→ADaM→Table 1 全链路
│   ├── c2_survival.R        公开肿瘤试验生存分析（survival::lung）
│   ├── c3_faers_signal.R    FAERS/openFDA 安全信号（ROR/PRR）
│   ├── c4_nhanes.R          NHANES 调查加权分析（survey）
│   ├── c5_trials_landscape.R ClinicalTrials.gov 试验景观（API v2）
│   ├── c6_teal_explorer.R   teal 临床数据探索器（Shiny）
│   └── cache/               网络数据缓存（断网可复现）
├── assets/                  site.css / site.js（运行时 R 高亮、测验、TOC）/ logo.svg
├── docs/run-outputs/        案例与章节的实跑输出捕获
├── docs/superpowers/        设计规格与实现计划
└── tools/                   校验脚本（verify.mjs / verify_html.py / 高亮器测试）
```

## 教程结构：章 → 知识点 → 案例

| 章 | 核心知识点 | 对应案例 |
|---|---|---|
| 0 | 监管递交现状、renv、SAS↔R 映射、GxP 心智 | — |
| 1 | 向量/factor/NA、索引回收、base/tidyverse/data.table、函数与管道 | — |
| 2 | SDTM/ADaM 的 R 实现、admiral、metadata、diffdf 双编程 | C1 |
| 3 | 生存分析、MMRM、混合模型、CMH、森林图、期中分析 | C2 |
| 4 | rtables/tern、Table 1、三格式导出、Quarto、追溯性 | C1 |
| 5 | 函数式、环境、S3、性能、testthat、CI、包验证 | — |
| 6 | 包工作流、roxygen、vignette、内部分发 | C1 延伸 |
| 7 | reactive、modules、DT/plotly、teal、部署与 GxP | C6 |
| 8 | 社区地图、论文精读、90 天计划、迁移策略 | 全部 |

## 资料筛选标准

1. **一手来源优先**：CRAN / 官方 GitHub org / 书籍官网（如 r4ds.hadley.nz、adv-r.hadley.nz、r-pkgs.org、mastering-shiny.org）。
2. **制药垂直相关**：pharmaverse 生态、R/Pharma、R Consortium Submissions WG、PharmaSUG/PhUSE 论文。
3. **时效**：2024–2026 为主，外链发布前抽样校验（见 `tools/` 与 docs/superpowers/plans）。
4. **可动手**：优先带可运行代码或可获取数据者；纯观点文章仅作背景引用。
5. **与本地精读互补**：第 8 章显式衔接 `../PharmaSUG2026-Analysis/`（250 篇分 track 导读）与 `../PharmaR/`（近 2 年生态精读）。
6. **许可注明**：案例数据源在页面"数据源卡"中标注获取方式与许可/使用条款。

## 公开临床数据来源与对应练习

| 数据源 | 获取方式 | 许可/条款 | 对应案例与练习 |
|---|---|---|---|
| pharmaversesdtm（合成 SDTM） | CRAN 包内置 | 包内许可（合成数据） | C1：改 ADSL 衍生 / 加 ADAE 表 / 双编程脚本 |
| scda（合成 SDTM+ADaM 年度归档） | GitHub insightsengineering/scda | 合成数据，见仓库许可 | C1 扩展：换年度归档重跑 |
| survival::lung（NCCTG 肺癌试验） | R 包内置 | 包内公开试验数据 | C2：KM 分层 / Cox 交互 / 竞争风险 |
| hbiostat 数据集 | hbiostat.org/data 直下 | 教学公开 | C2 扩展：换队列复现 |
| FAERS / openFDA | openFDA API 免注册；季度文件 FDA 官网 | 美国政府公共数据 | C3：AE 频数 / ROR·PRR / 时间趋势 |
| NHANES | CDC 官网 XPT 直读（haven::read_xpt） | 公共数据 | C4：加权均值 / 加权回归 / 合并周期 |
| ClinicalTrials.gov | API v2 免注册 | 公共数据 | C5：适应症 Top / 相位×状态 / 趋势 |
| ImmPort | 官网免注册下载 | 开放使用协议 | C3 类扩展：免疫学 AE 背景率 |
| Project Data Sphere / Vivli / YODA / DCRI SOAR / PhysioNet | 注册或申请 | 各自 DUA | 进阶扩展：真实个体级数据复现 C2 全流程 |

## 使用方法

```bash
# 本地阅读
start index.html            # Windows；或任意静态服务器

# 复现案例（需 R ≥ 4.3 与 cases 所列包）
Rscript cases/c1_sdtm_adam_t1.R
# 网络案例首次运行写 cases/cache/，之后断网可复现

# 站点自检
node tools/hl_test.mjs && node tools/verify.mjs && python tools/verify_html.py
```

## 许可与免责

教程文本与代码：MIT（教学自由使用）。案例输出为教学演示；信号检测、统计结论不构成监管或临床建议。
