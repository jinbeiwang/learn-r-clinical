# C7: Minimum Reproducible Submission Bundle
# Run from the repo root:  Rscript cases/c7_submission_bundle.R
# Required : admiral, pharmaversesdtm, dplyr, diffdf, renv
# Optional : xportr, datasetjson, pkglite, logrx  (graceful fallback if absent)
# C7_R_LIBS: optional path to a private R library (used for the real-run capture).
# All submitted artifacts are written as single-byte ASCII text; see CH9 9.1 / 9.4.

old_wd <- getwd()
root <- normalizePath(if (grepl("cases$", getwd())) ".." else ".", mustWork = TRUE)
if (nzchar(Sys.getenv("C7_R_LIBS")))
  .libPaths(c(Sys.getenv("C7_R_LIBS"), .libPaths()))
old_lib <- .libPaths()
has <- function(p) requireNamespace(p, quietly = TRUE)

bundle <- file.path(root, "cases", "out", "c7_bundle")
adam   <- file.path(bundle, "m5", "datasets", "c7demo", "analysis", "adam")
datasets <- file.path(adam, "datasets")
programs <- file.path(adam, "programs")
docu     <- file.path(adam, "documentation")
logs     <- file.path(bundle, "logs")
reviewer <- file.path(bundle, "reviewer_env")
unlink(bundle, recursive = TRUE)
inputs <- file.path(bundle, "inputs")
for (d in c(datasets, programs, docu, logs, reviewer, inputs))
  dir.create(d, recursive = TRUE, showWarnings = FALSE)

cat("== C7 Minimum Reproducible Submission Bundle ==\n")
cat("[0] R", as.character(getRversion()), "|", R.version$platform, "| bundle cases/out/c7_bundle\n")

## ---- Step 1: analysis dataset (reuse the site's shared derivation) ----
suppressPackageStartupMessages({ library(dplyr); library(diffdf) })
source(file.path(root, "cases", "common.R"))
adsl <- suppressWarnings(derive_adsl())
cat("\n-- Step 1 analysis dataset --\n")
cat("ADSL", nrow(adsl), "x", ncol(adsl), "| ITTFL=Y", sum(adsl$ITTFL == "Y"), "\n")
qc <- diffdf(adsl, suppressWarnings(derive_adsl()), keys = "USUBJID")
cat("[QC] diffdf issues:", diffdf_has_issues(qc), "\n")

## ---- Step 2: the seven-layer evidence chain ----
cat("\n-- Step 2 environment evidence (L1-L7) --\n")
sha <- tryCatch(system2("git", c("-C", shQuote(normalizePath(root)), "rev-parse", "--short", "HEAD"),
                        stdout = TRUE, stderr = FALSE)[1], error = function(e) NA_character_)
if (is.na(sha) || !nzchar(sha)) sha <- "NA (not a git checkout)"
cat("L1 git SHA          :", sha, "\n")

# L2: rebuild the lockfile in a REVIEWER-side project, not copied from the sponsor
tryCatch({
  invisible(capture.output(suppressMessages({
    renv::init(project = reviewer, bare = TRUE, restart = FALSE)
    renv::snapshot(project = reviewer, prompt = FALSE)
  })))
}, error = function(e) cat("renv:", conditionMessage(e), "\n"))
setwd(old_wd)                            # renv::init switches wd; restore
.libPaths(old_lib)                       # ...and library paths; restore
lock <- file.path(reviewer, "renv.lock")
cat("L2 renv.lock        :", if (file.exists(lock)) "rebuilt in reviewer_env/" else "NOT CREATED", "\n")
if (file.exists(lock)) {
  lk <- paste(readLines(lock, warn = FALSE), collapse = " ")
  cat("   contains R/renv  :", grepl('"R"', lk), "/", grepl("renv", lk), "\n")
}

# L3/L4: session info + exact versions of the packages actually used
writeLines(capture.output(sessionInfo()), file.path(logs, "session.txt"))
used <- c("admiral", "pharmaversesdtm", "dplyr", "diffdf", "renv",
          "xportr", "datasetjson", "pkglite", "logrx")
vers <- vapply(used, function(p)
  if (has(p)) as.character(packageVersion(p)) else "not installed", character(1))
writeLines(paste0("package\tversion\n", paste(used, vers, sep = "\t", collapse = "\n")),
           file.path(logs, "package_versions.tsv"))
cat("L3 sessionInfo      : logs/session.txt\n")
cat("L4 package versions :", sum(vers != "not installed"), "of", length(used),
    "available -> logs/package_versions.tsv\n")

# L5: input data fingerprint
snapshot <- file.path(inputs, "dm_snapshot.csv")
write.csv(pharmaversesdtm::dm, snapshot, row.names = FALSE)
md5 <- substr(unname(tools::md5sum(snapshot)), 1, 12)
cat("L5 input md5        :", md5, "(inputs/dm_snapshot.csv)\n")

# L6: execution log (logrx when available, logger otherwise)
writeLines(c("# C7 analysis step, executed under logrx", "cat('C7 analysis step completed\\n')"),
           file.path(programs, "run.R"))
log_ok <- tryCatch({
  if (!has("logrx")) stop("logrx not installed")
  invisible(capture.output(logrx::axecute(
    file.path(programs, "run.R"), log_name = "run.log", log_path = logs,
    to_report = c("messages", "output", "result"), quit_on_error = FALSE)))
  TRUE
}, error = function(e) FALSE)
if (!log_ok) writeLines(c("C7 execution log (logger fallback)",
                          "Rscript cases/c7_submission_bundle.R", "status: completed"),
                        file.path(logs, "run.log"))
cat("L6 execution log    : logs/run.log (",
    if (log_ok) "logrx" else "plain-text fallback", ")\n", sep = "")

## ---- Step 3: data deliverables ----
cat("\n-- Step 3 data deliverables --\n")
xpt <- file.path(datasets, "adsl.xpt")
xpt_ok <- tryCatch({
  if (has("xportr")) {
    xportr::xportr_write(adsl, path = xpt, domain = "ADSL")
  } else {
    haven::write_xpt(adsl, path = xpt, version = 5)
  }
  TRUE
}, error = function(e) { cat("   XPT:", conditionMessage(e), "\n"); FALSE })
cat("XPT v5              :", if (xpt_ok) paste0(basename(xpt), " ", file.size(xpt), " bytes") else "FAILED", "\n")

# Dataset-JSON v1.1 needs explicit column-level metadata (itemOID/name/label/dataType)
mk_cols <- function(df, domain = "ADSL") {
  dt <- vapply(df, function(x) {
    if (inherits(x, "Date")) "date" else if (is.integer(x)) "integer" else
    if (is.numeric(x)) "float" else if (is.logical(x)) "boolean" else "string"
  }, character(1))
  data.frame(itemOID = paste0("IT.", domain, ".", names(df)), name = names(df),
             label = names(df), dataType = unname(dt), length = NA_integer_,
             keySequence = ifelse(names(df) == "USUBJID", 1L, NA_integer_),
             targetDataType = NA_character_, displayFormat = NA_character_,
             stringsAsFactors = FALSE)
}
js <- file.path(datasets, "adsl.json")
js_ok <- tryCatch({
  if (!has("datasetjson")) stop("datasetjson not installed")
  # Dataset-JSON v1.1: date columns must be ISO-8601 character, not Date objects
  adsl_json <- as.data.frame(lapply(adsl, function(x)
    if (inherits(x, "Date")) format(x, "%Y-%m-%d") else x), stringsAsFactors = FALSE)
  dj <- datasetjson::dataset_json(
    adsl_json, name = "ADSL", dataset_label = "Subject-Level Analysis Dataset",
    file_oid = "c7demo.adsl", study = "C7DEMO", metadata_version = "1.0",
    originator = "Sponsor", sys = "R", sys_version = as.character(getRversion()),
    columns = mk_cols(adsl), version = "1.1.0")
  datasetjson::write_dataset_json(dj, file = js, pretty = TRUE)
  TRUE
}, error = function(e) { cat("   Dataset-JSON:", conditionMessage(e), "\n"); FALSE })
cat("Dataset-JSON 1.1.0  :", if (js_ok) paste0(basename(js), " ", file.size(js), " bytes") else "FAILED", "\n")
cat("Note                : keep XPT too - v1.1 not yet in Pinnacle 21 (Pilot 5)\n")

## ---- Step 4: readable ASCII programs + package bundle ----
cat("\n-- Step 4 program bundle --\n")
prog <- file.path(programs, "adam_adsl.txt")
writeLines(c(
  "# Program: adam_adsl.txt - derive ADSL (single-byte ASCII, SDTCG 4.1.2.10)",
  "source('cases/common.R')",
  "adsl <- derive_adsl()",
  "stopifnot(nrow(adsl) > 0, !anyDuplicated(adsl$USUBJID))",
  "write.csv(adsl, 'outputs/adsl.csv', row.names = FALSE)"
), prog)
ascii_ok <- if (has("pkglite")) tryCatch(pkglite::verify_ascii(prog, quiet = TRUE),
                                         error = function(e) NA) else NA
cat("ASCII program       : adam_adsl.txt (verify_ascii =", ascii_ok, ")\n")

pkgdir <- file.path(programs, "c7pkg")
dir.create(file.path(pkgdir, "R"), recursive = TRUE, showWarnings = FALSE)
writeLines(c("Package: c7pkg", "Version: 0.0.1", "Title: C7 Demo Package",
             "Description: Minimal closed-source package for text-bundle demo.",
             "Author: Sponsor", "Maintainer: Sponsor <sponsor@example.org>",
             "License: MIT", "Encoding: UTF-8"), file.path(pkgdir, "DESCRIPTION"))
writeLines(c("# ASCII helper", "derive_adsl_flags <- function(x) {",
             "  x$ITTFL <- ifelse(is.na(x$TRTSDT), 'N', 'Y')", "  x", "}"),
           file.path(pkgdir, "R", "derive.R"))
txtbundle <- file.path(programs, "r0pkg.txt")
pk_ok <- tryCatch({
  if (!has("pkglite")) stop("pkglite not installed")
  invisible(capture.output(
    pkglite::collate(pkg = pkgdir, pkglite::file_ectd(), pkglite::file_auto("R")) %>%
      pkglite::pack(output = txtbundle)))
  TRUE
}, error = function(e) { cat("   pkglite:", conditionMessage(e), "\n"); FALSE })
cat("pkglite text bundle :", if (pk_ok) paste0("r0pkg.txt ", file.size(txtbundle), " bytes") else "FAILED", "\n")
zip_ok <- tryCatch({
  suppressWarnings(utils::zip(file.path(programs, "c7pkg.zip"), files = pkgdir, flags = "-r9X"))
  file.exists(file.path(programs, "c7pkg.zip")) && file.size(file.path(programs, "c7pkg.zip")) > 0
}, error = function(e) FALSE)
cat(".zip package        :", if (isTRUE(zip_ok)) "created" else "skipped (no external zip tool); .txt bundle used", "\n")

## ---- Step 5: ADRG skeleton ----
cat("\n-- Step 5 ADRG skeleton --\n")
adrg <- c(
  "ANALYSIS DATA REVIEWER'S GUIDE (ADRG) - C7 DEMO / TEACHING SKELETON",
  "",
  "7. SUBMISSION OF PROGRAMS",
  "   All programs for analysis datasets and displays were created on a",
  paste0("   Windows platform using R ", as.character(getRversion()), "."),
  "   Source programs are submitted as single-byte ASCII text (.txt).",
  "   Package versions and sources are listed in package_versions.tsv.",
  "   Closed-source package c7pkg is supplied as r0pkg.txt (pkglite)",
  "   and may alternatively be supplied as a .zip (eCTD file formats v9.3).",
  "",
  "9.1 APPENDIX 1 - RECREATING THE R ENVIRONMENT",
  "   1. Install R 4.5.0 (or the version agreed with the reviewer in advance).",
  "   2. Install Rtools matching the R version.",
  "   3. Run 00_install_packages.R to install the exact package versions from",
  "      CRAN / the internal repository. Do NOT copy the sponsor's lockfile:",
  "      it was produced on a different OS and is not portable.",
  "   4. Run renv::init(bare = TRUE); renv::snapshot() to create a LOCAL lockfile.",
  "   5. Run adam_adsl.txt; compare outputs against adsl.xpt.",
  "   6. Record sessionInfo() and the execution log in logs/.",
  "",
  "NOTE: teaching skeleton only - not a submission-ready ADRG."
)
writeLines(adrg, file.path(docu, "adrg.txt"))
cat("ADRG sections       : 7 Submission of Programs / 9.1 Environment Recreation\n")

## ---- Step 6: manifest + final QC ----
cat("\n-- Step 6 manifest / QC --\n")
files <- list.files(bundle, recursive = TRUE, full.names = TRUE)
files <- files[!dir.exists(files)]
files <- files[!grepl("renv/library", files)]
md5s <- tools::md5sum(files)
writeLines(c("file\tmd5\tbytes",
             paste(basename(files), substr(unname(md5s), 1, 12), file.size(files), sep = "\t")),
           file.path(bundle, "manifest.tsv"))
cat("artifacts           :", length(files), "| all non-empty:", all(file.size(files) > 0), "\n")
cat("manifest            : manifest.tsv (file + md5 + bytes)\n")
cat("== C7 complete ==\n")
