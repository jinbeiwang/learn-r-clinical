# C2：公开肿瘤试验生存分析（survival::lung，NCCTG 肺癌试验）
# 运行：Rscript cases/c2_survival.R
suppressPackageStartupMessages({
  library(survival); library(survminer); library(ggplot2)
})

cat("== 步骤 1：数据与清洗 ==\n")
dat <- lung
dat$status <- dat$status - 1   # survival::lung 的 status 为 1=删失 2=死亡 → 转 0/1
cat("n =", nrow(dat), "；事件数 =", sum(dat$status), "；删失 =", sum(dat$status == 0), "\n")

cat("\n== 步骤 2：KM 按性别分层 ==\n")
fit <- survfit(Surv(time, status) ~ sex, data = dat)
print(fit)

cat("\n== 步骤 3：log-rank 检验 ==\n")
print(survdiff(Surv(time, status) ~ sex, data = dat))

cat("\n== 步骤 4：Cox 多变量模型 ==\n")
cox <- coxph(Surv(time, status) ~ age + sex + ph.ecog, data = dat)
print(summary(cox)$coefficients)
cat("HR(sex=男 vs 女) =", round(exp(coef(cox)["sex"]), 3), "\n")

cat("\n== 步骤 5：KM 图落盘 ==\n")
out_png <- file.path(if (grepl("cases$", getwd())) ".." else ".",
                     "docs", "run-outputs", "c2_km.png")
p <- ggsurvplot(fit, data = dat, pval = TRUE, conf.int = FALSE,
                risk.table = TRUE, palette = c("#7d8f4e", "#b0413e"),
                xlab = "Days", ylab = "Survival probability")
ggsave(out_png, print(p), width = 8, height = 6, dpi = 150)
cat("KM 图已保存:", out_png, "；文件大小 =", file.size(out_png), "bytes\n")
cat("== C2 完成 ==\n")
