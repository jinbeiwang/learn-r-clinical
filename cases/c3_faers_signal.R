# C3：FAERS 安全信号检测（openFDA API 双查询；离线回退 cases/cache/）
# 运行：Rscript cases/c3_faers_signal.R
suppressPackageStartupMessages({ library(httr2); library(jsonlite); library(dplyr) })

cachedir <- file.path(if (grepl("cases$", getwd())) ".." else ".", "cases", "cache")
dir.create(cachedir, showWarnings = FALSE, recursive = TRUE)

count_pt <- function(search = NULL, cache_name) {
  cf <- file.path(cachedir, cache_name)
  get_it <- function() {
    pages <- list()
    for (sk in seq(0, 400, by = 100)) {
      q <- list(limit = 100, skip = sk)
      if (!is.null(search)) q$search <- search
      r <- request("https://api.fda.gov/drug/event.json") %>%
        req_url_query(!!!q) %>%
        req_timeout(120)
      js <- resp_body_json(req_perform(r))
      pages[[length(pages) + 1]] <- js$results
    }
    results <- unlist(pages, recursive = FALSE)
    pts <- unlist(lapply(results, function(x)
      unlist(lapply(x$patient$reaction, function(r) r$reactionmeddrapt))))
    stopifnot(length(pts) > 0)
    tb <- sort(table(pts), decreasing = TRUE)
    data.frame(PT = names(tb), N = as.integer(tb), stringsAsFactors = FALSE)
  }
  tryCatch({
    d <- get_it()
    saveRDS(d, cf); d
  }, error = function(e) {
    cat("[cache] 网络失败:", conditionMessage(e), "\n读取:", cf, "\n"); readRDS(cf)
  })
}

cat("== 步骤 1：分页拉取报告级 AE（5 页 x 100 报告/组，免 API key；R 内聚合 PT）==\n")
drug <- count_pt('patient.drug.openfda.generic_name:"imatinib"', "faers_imatinib.rds")
bg   <- count_pt(NULL, "faers_background.rds")
cat("imatinib 组 PT 提及合计:", sum(drug$N), "（来自 500 份报告）；背景组:", sum(bg$N), "\n")

cat("\n== 步骤 2：imatinib AE 频数 Top10 ==\n")
print(drug %>% arrange(desc(N)) %>% slice_head(n = 10), row.names = FALSE)

cat("\n== 步骤 3：2x2 不成比例分析（目标 PT = Oedema peripheral）==\n")
target <- "Oedema peripheral"
if (!target %in% drug$PT) target <- drug$PT[1]
cat("目标 PT:", target, "\n")
n_of <- function(d, pt) { v <- d$N[d$PT == pt]; if (length(v)) v else 0L }
a <- n_of(drug, target)          # 药 + 目标AE
b <- sum(drug$N) - a             # 药 + 其他AE（Top1000 近似）
c <- n_of(bg, target)            # 背景 + 目标AE
d <- sum(bg$N) - c               # 背景 + 其他AE
tab <- matrix(c(a, b, c, d), nrow = 2, byrow = TRUE,
              dimnames = list(Group = c("imatinib", "background"),
                              AE = c(target, "other PTs")))
print(tab)
ror <- (a * d) / (b * c)
se <- sqrt(1/a + 1/b + 1/c + 1/d)
prr <- (a / (a + b)) / (c / (c + d))
cat(sprintf("ROR = %.2f (95%%CI %.2f - %.2f)；PRR = %.2f\n",
            ror, exp(log(ror) - 1.96 * se), exp(log(ror) + 1.96 * se), prr))
if (a >= 3 && exp(log(ror) - 1.96 * se) > 1) {
  cat("判读：ROR 95%CI 下限 > 1 且 a >= 3 → 不成比例信号（教学口径）。\n")
} else {
  cat("判读：本截断样本未检出不成比例信号。注意免 key 分页背景组不代表全库暴露结构，\n",
      "    ROR 可能低估/高估；监管级信号检测需用全量 FAERS 季度文件与规范对照。\n")
}
cat("== C3 完成 ==\n")
