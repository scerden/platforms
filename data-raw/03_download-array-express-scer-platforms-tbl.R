library(tidyverse)
library(httr)
library(rvest)


# scrape arrays table for scer --------------------------------------------

keywords <- "Saccharomyces+cerevisiae"
# request params
url <- "http://www.ebi.ac.uk/arrayexpress/arrays/browse.html"
query <- list(keywords = keywords, page = "1", pagesize = "100000")
h <- GET(url, query = query)
d <- content(h) %>%
  html_nodes("#ae-browse table") %>%
  .[[2]] %>%
  html_table(fill = T) %>%
  as_tibble()
names(d) <- c("accession", "name", "organism", "files")

request_date <- lubridate::as_date(h$date)
destfile <- paste0(request_date, "_scer_AE-arrays.csv")
write_csv(d, file.path("data-raw", destfile))
system('gzip data-raw/*.csv')
