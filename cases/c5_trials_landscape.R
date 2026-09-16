# C5：ClinicalTrials.gov 试验景观扫描（API v2 直连；离线回退 cases/cache/）
# 运行：Rscript cases/c5_trials_landscape.R
suppressPackageStartupMessages({ library(httr2); library(jsonlite); library(dplyr) })

cachedir <- file.path(if (grepl("cases$", getwd())) ".." else ".", "cases", "cache")
dir.create(cachedir, showWarnings = FALSE, recursive = TRUE)
cf <- file.path(cachedir, "ctgov_diabetes.rds")

fields <- paste(c("NCTId", "protocolSection.conditionsModule.conditions",
                  "protocolSection.sponsorCollaboratorsModule.leadSponsor.name",
                  "protocolSection.designModule.phases",
                  "protocolSection.statusModule.overallStatus"), collapse = ",")
fetch <- function() {
  js <- request("https://clinicaltrials.gov/api/v2/studies") %>%
    req_url_query(query.cond = "diabetes", pageSize = 100, format = "json",
                  fields = fields) %>%
    req_timeout(90) %>%
    req_perform() %>%
    resp_body_json()
  js$studies
}
st <- tryCatch({ s <- fetch(); saveRDS(s, cf); s },
               error = function(e) {
                 cat("[cache] 网络失败:", conditionMessage(e), "\n读取:", cf, "\n")
                 readRDS(cf)
               })

flat <- data.frame(
  nct = sapply(st, function(x) x$protocolSection$identificationModule$nctId),
  cond = sapply(st, function(x) paste(unlist(x$protocolSection$conditionsModule$conditions), collapse = "; ")),
  sponsor = sapply(st, function(x) x$protocolSection$sponsorCollaboratorsModule$leadSponsor$name),
  phase = sapply(st, function(x) paste(unlist(x$protocolSection$designModule$phases), collapse = "/")),
  status = sapply(st, function(x) x$protocolSection$statusModule$overallStatus),
  stringsAsFactors = FALSE
)
flat$phase[flat$phase == ""] <- "NA/EARLY1"

cat("== 步骤 1：抓取概况 ==\n")
cat("研究数:", nrow(flat), "（API v2, query.cond=diabetes, pageSize=100）\n")

cat("\n== 步骤 2：状态分布 ==\n")
print(flat %>% count(status, sort = TRUE))

cat("\n== 步骤 3：相位 × 状态 ==\n")
print(table(phase = flat$phase, status = flat$status))

cat("\n== 步骤 4：牵头赞助方 Top10 ==\n")
print(flat %>% count(sponsor, sort = TRUE) %>% slice_head(n = 10), row.names = FALSE)

cat("\n== 步骤 5：条件词 Top10（条形图数据）==\n")
cond_long <- flat %>%
  mutate(c1 = sub(";.*$", "", cond)) %>%
  count(c1, sort = TRUE) %>% slice_head(n = 10)
print(cond_long, row.names = FALSE)
cat("== C5 完成 ==\n")
