library(tidyverse)
library(stringr)
library(lubridate)
library(forcats)

# Load data ---------------------------------------------------------------

db <- src_sqlite(destfile)
#' assign tbls to variables in .GlobalEnv
#' This is a shortcut to `tblname <- tbl(db, "tblname")`
#' handles multiple tables at once.
#'
#' @param db a dplyr "src" object
#' @param tbl chracter vector of tbls to assign. defaults to all tbls in db.
assign_tbls <- function(db, tbl = dplyr::src_tbls(db)) {
  stopifnot(inherits(db, "src"))
  tbl %>%
    purrr::walk(~ assign(.x, dplyr::tbl(db, .x), envir = .GlobalEnv))
}
### assign all tbls to object in .GlobalEnv
assign_tbls(db)

### how old is this version of database
creation_date <- metaInfo %>%
  filter(name == "creation timestamp") %>%
  select(value) %>%
  collect() %>%
  unlist() %>%
  unname() %>%
  lubridate::as_datetime()
today_date <- lubridate::now() %>% lubridate::as_datetime()
diff <- today_date - creation_date
cat("db is", diff, units(diff), "days old")
tbl_date <- lubridate::as_date(creation_date)
rm(creation_date, today_date, diff, metaInfo)

# Filter db for S. cerevisiae ---------------------------------------------

# gpl, gsm and gds tables have organism level variables, use gpl
geodb_column_desc %>%
  collect() %>%
  filter(stringr::str_detect(FieldName, "organism"))

count(gpl); dim(gpl) # not too big, safe to collect
# platform can cover more than one organism (eg. org1;\torg2)
filt_gpl <- gpl %>%
  collect() %>%
  filter(str_detect(organism, "Saccharomyces cerevisiae"))
destfile <- paste0(tbl_date, "_scer_GEOmetadb-gpl.csv")
write_csv(filt_gpl, file.path("data-raw", destfile))
# now get all the linked accessions
# `copy = T` copies filter tbl into db to do join; tbl is small so ok.
filt_geoConvert <- geoConvert %>%
  semi_join(filt_gpl %>% select(gpl),
            by = c("from_acc" = "gpl"), copy = T)
rm(filt_gpl)
# GDS
filt_gds <- filt_geoConvert %>%
  filter(to_type == "gds") %>%
  select(to_acc) %>%
  rename(gds = to_acc) %>%
  left_join(gds) %>%
  collect()
destfile <- paste0(tbl_date, "_scer_GEOmetadb-gds.csv")
write_csv(filt_gds, file.path("data-raw", destfile))
rm(filt_gds)
# GDS subset
filt_gds_subset <- filt_geoConvert %>%
  filter(to_type == "gds") %>%
  select(to_acc) %>%
  rename(gds = to_acc) %>%
  left_join(gds_subset) %>%
  collect()
destfile <- paste0(tbl_date, "_scer_GEOmetadb-gds-subset.csv")
write_csv(filt_gds_subset, file.path("data-raw", destfile))
rm(filt_gds_subset)
# GSE
filt_gse <- filt_geoConvert %>%
  filter(to_type == "gse") %>%
  select(to_acc) %>%
  rename(gse = to_acc) %>%
  left_join(gse) %>%
  collect()
destfile <- paste0(tbl_date, "_scer_GEOmetadb-gse.csv")
write_csv(filt_gse, file.path("data-raw", destfile))
rm(filt_gse)
# GSM
filt_gsm <- filt_geoConvert %>%
  filter(to_type == "gsm") %>%
  select(to_acc) %>%
  rename(gsm = to_acc) %>%
  left_join(gsm) %>%
  collect()
destfile <- paste0(tbl_date, "_scer_GEOmetadb-gsm.csv")
write_csv(filt_gsm, file.path("data-raw", destfile))
rm(filt_gsm)

system('gzip data-raw/*.csv')
system('rm -rf data-raw/tmp')
