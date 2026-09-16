# C4：NHANES 调查加权分析（haven 直读 CDC XPT + survey；离线回退 cases/cache/）
# 运行：Rscript cases/c4_nhanes.R
suppressPackageStartupMessages({ library(haven); library(survey); library(dplyr) })

cachedir <- file.path(if (grepl("cases$", getwd())) ".." else ".", "cases", "cache")
dir.create(cachedir, showWarnings = FALSE, recursive = TRUE)
cf <- file.path(cachedir, "nhanes_2017_2018.rds")

xpt <- function(table) {
  url <- paste0("https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2017/DataFiles/", table, ".xpt")
  haven::read_xpt(url)
}
load_nhanes <- function() {
  list(demo = xpt("DEMO_J"), bpx = xpt("BPX_J"), bpq = xpt("BPQ_J"))
}
raw <- tryCatch({ d <- load_nhanes(); saveRDS(d, cf); d },
                error = function(e) { cat("[cache] 网络不可用，读取:", cf, "\n"); readRDS(cf) })

cat("== 步骤 1：合并与清洗 ==\n")
dat <- raw$demo %>%
  select(SEQN, RIDAGEYR, RIAGENDR, SDMVPSU, SDMVSTRA, WTMEC2YR) %>%
  inner_join(raw$bpx %>% select(SEQN, BPXSY1, BPXDI1), by = "SEQN") %>%
  inner_join(raw$bpq %>% select(SEQN, BPQ020), by = "SEQN") %>%
  filter(RIDAGEYR >= 20, !is.na(WTMEC2YR), WTMEC2YR > 0, BPQ020 %in% c(1, 2)) %>%
  mutate(sex = factor(RIAGENDR, labels = c("Male", "Female")),
         htn = factor(BPQ020, labels = c("Yes", "No")))
cat("分析样本 n =", nrow(dat), "\n")

cat("\n== 步骤 2：复杂抽样设计 ==\n")
des <- svydesign(ids = ~SDMVPSU, strata = ~SDMVSTRA, weights = ~WTMEC2YR,
                 data = dat, nest = TRUE)
print(des)

cat("\n== 步骤 3：加权均值（收缩压，总体与按性别）==\n")
print(svymean(~BPXSY1, des))
print(by_sex <- svyby(~BPXSY1, ~sex, des, svymean))

cat("\n== 步骤 4：加权逻辑回归（自报高血压 ~ 年龄 + 性别）==\n")
m <- svyglm(htn ~ RIDAGEYR + sex, family = quasibinomial(), design = des)
print(summary(m)$coefficients)
cat("OR(年龄+1岁) =", round(exp(coef(m)["RIDAGEYR"]), 3), "\n")
cat("== C4 完成 ==\n")
