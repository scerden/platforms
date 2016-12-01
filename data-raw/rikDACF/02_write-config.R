library(scerden.geometadb)
library(tidyverse)
library(stringr)

inpdir <- "data-raw2/rikDACF"

# CDF file ----------------------------------------------------------------
config_cdf <- list.files(inpdir , pattern = "\\.cdf$")
stopifnot(length(config_cdf) == 1)


# Probe tab file ----------------------------------------------------------

config_probetab <- list.files(inpdir, pattern = "_probeSequences\\.txt$")
stopifnot(length(config_probetab) == 1)

# GPL accessions ----------------------------------------------------------
geo_platforms <- find_in_gpl("rikdacf")[[1]] %>% print()
config_gpl <- geo_platforms$gpl
stopifnot(length(config_gpl) > 0)

# eg cel file -------------------------------------------------------------

gsm_with_cels <- gsm %>%
  filter(gpl %in% config_gpl) %>%
  separate_rows(supplementary_file, sep = ";\t") %>%
  filter(str_detect(supplementary_file, ".+\\.[C|c][E|e][L|l]\\.gz$"))
stopifnot(length(gsm_with_cels) > 0)

eg_cel_url <- gsm_with_cels$supplementary_file[1]
destfile <- file.path(inpdir, basename(eg_cel_url))
download.file(url = eg_cel_url,
              destfile = destfile,
              method = "wget",
              mode = "wb",
              extra = "--continue --no-clobber",
              quiet = T)
R.utils::gunzip(destfile)

config_cel <- list.files(inpdir, ".+\\.[C|c][E|e][L|l]$")
stopifnot(length(config_cel) == 1)


# write config.yml --------------------------------------------------------

config <- list(default =list(cdf = config_cdf, probetab = config_probetab, cel = config_cel, gpl = config_gpl))
config_file <- file.path(inpdir, "config.yml")
yaml::as.yaml(config) %>% write_file(config_file)


# Check config can read it properly ---------------------------------------

config::get(file = config_file)
