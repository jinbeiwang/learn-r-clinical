# C1：SDTM → ADaM → Table 1 全链路（pharmaversesdtm + admiral + rtables + diffdf）
# 运行：Rscript cases/c1_sdtm_adam_t1.R
source(file.path(if (grepl("cases$", getwd())) ".." else ".", "cases", "common.R"))
suppressPackageStartupMessages({ library(rtables); library(diffdf) })

cat("== 步骤 1：SDTM 源数据 ==\n")
cat("dm:", nrow(pharmaversesdtm::dm), "行 /", ncol(pharmaversesdtm::dm), "列；ae:",
    nrow(pharmaversesdtm::ae), "行\n")

cat("\n== 步骤 2：admiral 推导 ADSL ==\n")
adsl <- derive_adsl()
print(adsl %>% count(ARM, ITTFL))
cat("ADSL 维度:", dim(adsl), "\n")

cat("\n== 步骤 3：admiral 推导 ADAE（含 AOCC01FL 首次发生标志）==\n")
adae <- derive_adae()
cat("AOCC01FL='Y' 行数:", sum(adae$AOCC01FL == "Y", na.rm = TRUE),
    "（应等于受试者数", n_distinct(adae$USUBJID), "中有 AE 者）\n")
print(adae %>% count(AEBODSYS) %>% slice_max(n, n = 5))

cat("\n== 步骤 4：rtables 出 Table 1（按 ARM 分层）==\n")
adsl_it <- adsl %>% filter(ITTFL == "Y")
tbl <- basic_table() %>%
  split_cols_by("ARM") %>%
  split_rows_by("SEX", split_fun = drop_split_levels) %>%
  analyze("AGE", afun = function(x) {
    in_rows(
      "n" = length(x),
      "Mean (SD)" = c(mean(x), sd(x)),
      .formats = c("n" = "xx", "Mean (SD)" = "xx.x (xx.xx)")
    )
  }) %>%
  build_table(adsl_it)
print(tbl)

cat("\n== 步骤 5：双编程自检（diffdf）==\n")
adsl_re <- derive_adsl()
res <- diffdf(adsl, adsl_re, keys = "USUBJID")
cat("diffdf 发现问题:", diffdf_has_issues(res), "\n")
cat("== C1 完成 ==\n")
