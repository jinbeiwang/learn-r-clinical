# C6：teal 临床数据探索器（复用 C1 的 ADaM 推导；非交互模式打印结构）
# 运行：Rscript cases/c6_teal_explorer.R ；交互：R 会话内 source 后 shiny::runApp(app)
source(file.path(if (grepl("cases$", getwd())) ".." else ".", "cases", "common.R"))
suppressPackageStartupMessages({ library(teal); library(shiny) })

cat("== 步骤 1：构造 ADaM 输入 ==\n")
adsl <- derive_adsl() %>% filter(ITTFL == "Y")
adae <- derive_adae()
td <- teal_data(ADSL = adsl, ADAE = adae)
td <- within(td, {
  ADAE <- merge(ADAE, ADSL[c("USUBJID", "AGE", "SEX")], by = "USUBJID")
})
cat("datanames:", paste(datanames(td), collapse = ", "), "\n")

cat("\n== 步骤 2：组装 teal 应用 ==\n")
app <- init(
  data = td,
  modules = modules(
    example_module(label = "通用表格示例"),
    module(
      label = "ADSL 年龄直方图",
      server = function(id, data) {
        moduleServer(id, function(input, output, session) {
          output$plot <- renderPlot({
            d <- data()[["ADSL"]]
            hist(d$AGE, main = "AGE at trial start", col = "#7d8f4e", border = "white")
          })
          renderUI(tags$p("按 ARM 查看请配合 filter 面板使用。"))
        })
      },
      ui = function(id) {
        ns <- NS(id)
        tags$div(plotOutput(ns("plot")), uiOutput(ns("txt")))
      },
      datanames = "ADSL"
    )
  )
)
cat("app 类型:", class(app)[1], "\n")

cat("\n== 步骤 3：模块清单 ==\n")
lbls <- vapply(app$modules, function(m) m$label, character(1))
print(lbls)

if (interactive()) {
  cat("\n交互模式：启动应用……\n")
  shiny::runApp(app)
} else {
  cat("\n非交互模式：不启动服务器。交互运行请在 R 会话执行 shiny::runApp(app)。\n")
}
cat("== C6 完成 ==\n")
