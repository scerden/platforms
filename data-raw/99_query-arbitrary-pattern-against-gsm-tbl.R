library(tidyverse)
library(stringr)

# read in scer geo samples
file <- list.files("data-raw/", pattern = "gsm\\.csv\\.gz$", full.names = T)
gsms <- read_csv(file)




# query platforms tbl for any matches -------------------------------------

pattern <- "top[o|\\d]"
# which row indices have a case-insensitive match in at least 1 col.
match_index <- gsms %>%
  map(~which(str_detect(tolower(.x), pattern))) %>%
  unlist(use.names = F) %>%
  unique()

matched <- gsms[match_index,]
nrow(matched) # n samples matching pattern

# which platforms have at least 1 matched sample
matched_gpls <- unique(matched$gpl)
write_lines(matched_gpls, "data-raw/matched-gpls.txt")
# which geo series include at least 1 match
# a sample can be represented in more than one series (csv row)
matched_gses <- str_split(matched$series_id, ',') %>% unlist() %>% unique()
matched_gses
write_lines(matched_gses, "data-raw/matched-gses.txt")
write_lines(matched_gses)
