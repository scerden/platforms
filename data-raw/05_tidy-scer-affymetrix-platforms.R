library(tidyverse)
library(stringr)

platforms <- read_csv("data-raw/scer-platforms-geo-and-ae.csv")

# query platforms tbl for any matches -------------------------------------

pattern <- "affy"
# which row indices have a case-insensitive match in at least 1 col.
match_index <- platforms %>%
  map(~which(str_detect(tolower(.x), pattern))) %>%
  unlist(use.names = F) %>%
  unique()

matched <- platforms[match_index,]
nrow(matched) # unique platforms




# All geo samples associated to matched platform --------------------------

file <- list.files("data-raw/", pattern = "gsm\\.csv\\.gz$", full.names = T)
matched_gsms <- read_csv(file) %>% filter(gpl %in% matched$geo)
# n samples per platform
matched_gsms %>% count(gpl, sort = T)




# download example raw data file for each platform ------------------------

# not all platforms necessarily have samples with supplementary files
eg_samples <- matched_gsms %>%
  # keep only samples with supplementary file links
  filter(!is.na(supplementary_file)) %>%
  group_by(gpl) %>%
  filter(row_number() == 1)
# a sample can have more than one suppl file. If this is the case only
# keep the first one, add basename col for later
eg_samples <- eg_samples %>%
  mutate(suppl_url = str_split_fixed(supplementary_file, ";\t", 2)[,1],
         suppl_basename = gsub(".gz$", "", basename(suppl_url)))

# download the files in parallel with xargs to data-raw/tmp
write_lines(eg_samples$suppl_url, "data-raw/affy-supp-file-urls.txt")
cmd <- paste("cat", "data-raw/affy-supp-file-urls.txt",
             "| xargs -n 1 -P 8 wget --continue --directory-prefix=data-raw/tmp --no-clobber")
system(cmd)
system("gunzip data-raw/tmp/*.gz") # unzip them




# affymetrix P/N 510636 ---------------------------------------------------

# there are 3 platforms that seem to all be the same "rikDacF" platform.
#   This is an oligo array that tiles chr VI at 300bp resolution.
# 16 25-nucleotide probes were selected evenly from each 300-bp locus on
# the basis of their uniqueness, to avoid cross hybridization and to
# make the uniform hybridization condition.
grp <- c(35, 156, 185) # by visual inspection
matched_curr <- matched %>% filter(scer_uid %in% grp)
matched_gsms_curr <- matched_gsms %>% filter(gpl %in% matched_curr$geo)
eg_samples_curr <- eg_samples %>% filter(gpl %in% matched_curr$geo)

# reading the header of each representative sample raw file shows that
# they have the same dimensions and chiptype
library(affxparser)
eg_files <- file.path("data-raw/tmp", eg_samples_curr$suppl_basename)
cel_headers <- eg_files %>%
  map(readCelHeader) %>%
# printing the actual celfile header shows all are rikDACF.1sq based
  cel_headers %>%
  map("header") %>%
  walk(cat)
# reading intensities confirms that each sample indeed has 33489 values
readCelIntensities(eg_files) %>% dim()

# have a look at all matched platform samples
# * 143/289 don't have suppl file
matched_gsms_curr %>% count(supplementary_file, sort = T)
# those that have suppl file(s) always have at least at cel file
matched_gsms_curr %>%
  filter(!is.na(supplementary_file)) %>%
  filter(!str_detect(tolower(supplementary_file), "[\\.cel\\.gz$|\\.cel\\.gz;]")) %>%
  .$supplementary_file

# weird thing is that they have different data rows as processed...
# different papers cite that the library files are available upon
# request from affymetrix themselves and so have emailed their
# technical support. asking for these:

# Chromosome VI S.cerevisiae: rikDACF, P/N# 510636
# Chromosome III,IV,V S.cerevisiae: SC3456a520015F, P/N# 520015

# also emailed this lab:
# kshirahi@iam.u-tokyo.ac.jp
# who's website is no longer up:
# http://chromosomedynamics.bio.titech.ac.jp

# stoping here for now.
