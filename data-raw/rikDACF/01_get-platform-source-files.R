library(platforms)
library(tidyverse)
library(stringr)

# zip archives were obtained directly from affymetrix support (via e-mail request).
srcdir <- "~/googledrive/makereach"

# get cdf file from archive -----------------------------------------------
zippath <- file.path(srcdir, "rikDACF.zip")
cdf <- list_zip(zippath) %>%
  str_subset("\\.cdf$") %>%
  extract_from_zip(zippath = zippath)

# get probeseq file from archive ------------------------------------------
zippath <- file.path(srcdir, "rikDACF_probeSeq.zip")
probeseq <- list_zip(zippath) %>%
  str_subset("probeSequences\\.txt") %>%
  extract_from_zip(zippath)
