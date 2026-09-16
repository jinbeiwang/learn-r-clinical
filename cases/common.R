# cases/common.R — 案例共享函数：从 pharmaversesdtm 的 SDTM 推导 ADSL/ADAE
# 用法：source("cases/common.R")（在仓库根目录运行）
suppressPackageStartupMessages({
  library(dplyr)
  library(admiral)
  library(pharmaversesdtm)
})

derive_adsl <- function() {
  dm <- pharmaversesdtm::dm
  dm %>%
    derive_vars_dt(new_vars_prefix = "BRTH", dtc = BRTHDTC) %>%
    derive_vars_dt(new_vars_prefix = "TRTS", dtc = RFSTDTC) %>%
    derive_vars_dt(new_vars_prefix = "TRTE", dtc = RFENDTC) %>%
    derive_vars_duration(
      new_var = AGE, new_var_unit = AGEU,
      start_date = BRTHDT, end_date = TRTSDT,
      out_unit = "years", trunc_out = TRUE
    ) %>%
    derive_vars_dy(reference_date = TRTSDT, source_vars = exprs(TRTSDT, TRTEDT)) %>%
    mutate(
      ITTFL = if_else(!is.na(TRTSDT), "Y", "N"),
      SEX = as.character(SEX), ARM = as.character(ARM), RACE = as.character(RACE)
    ) %>%
    select(USUBJID, ARM, ARMCD, ACTARM, SEX, AGE, AGEU, RACE,
           TRTSDT, TRTEDT, TRTSDY, TRTEDY, DTHFL, ITTFL)
}

derive_adae <- function() {
  pharmaversesdtm::ae %>%
    derive_vars_dt(new_vars_prefix = "AST", dtc = AESTDTC) %>%
    derive_vars_dt(new_vars_prefix = "AEN", dtc = AEENDTC) %>%
    derive_var_extreme_flag(
      by_vars = exprs(USUBJID), new_var = AOCC01FL,
      order = exprs(ASTDT), mode = "first"
    ) %>%
    mutate(AEBODSYS = as.character(AEBODSYS)) %>%
    select(USUBJID, AEBODSYS, AEDECOD, ASTDT, AENDT, AOCC01FL)
}
