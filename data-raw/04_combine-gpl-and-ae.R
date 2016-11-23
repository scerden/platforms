library(tidyverse)
library(httr)
library(rvest)
library(stringr)

# load data ---------------------------------------------------------------

## from GEO
metagpl <- read_csv("data-raw/2016-11-13_scer_GEOmetadb-gpl.csv.gz")
gpl_tbl <- metagpl %>%
  transmute(uid = ID,
            gpl_accession = gpl,
            gpl_title = title,
            gpl_acc = stringr::str_extract(gpl_accession, "\\d+$"))

## ArrayExpress data
metaae <- read_csv("data-raw/2016-11-23_scer_AE-arrays.csv.gz")
ae_tbl <- metaae %>%
  transmute(ae_accession = accession,
            ae_title = name,
            ae_acc = stringr::str_extract(ae_accession, "\\d+$"))


# map geo to ae accessions ------------------------------------------------

## map gpl <-> ae, only those with matching ids and title
index <- c("gpl_title" = "ae_title", "gpl_acc" = "ae_acc")
maptbl <- left_join(gpl_tbl, ae_tbl, by = index) %>%
  rename(title = gpl_title) %>%
  select(uid, title, gpl_accession, ae_accession)

## leftover platforms that did not match to a GPL.
ae_only <- ae_tbl %>%
  filter(!ae_accession %in% maptbl$ae_accession) %>%
  rename(title = ae_title) %>%
  select(title, ae_accession)
## for some reason there is an empty line at the bottom from parsing
tail(ae_only)
ae_only <- head(ae_only, -1)
tail(ae_only)

# Manual recoding unmatched ae --------------------------------------------

# for those arrays that did not nicely match to a GPL accession manually
# add a matching accession if it exists. I work through this in sections
# according to the array accessin subtype
ae_subtypes <- ae_only$ae_accession %>%
  str_split_fixed('-', 3) %>%
  .[,2] %>%
  unique()
map(ae_subtypes, ~ filter(ae_only, str_detect(ae_accession, .x)))

# if there is matching gpl accession add it, if sure there is not a matching accession in GEO then put NA_character_
ae_recode <- tribble(
  ~ae_accession, ~gpl_accession,
  ## AFFY
  "A-AFFY-27", "GPL90",      # title is same just out of order
  "A-AFFY-47", "GPL2529",    # title is same just out of order
  "A-AFFY-116", "GPL18871",  # Both have "Steinmetz"/"custom tiling"
  "A-AFFY-120", "GPL163",    # "Ye6100SubA", "Yeast 6100 Set - Chip A"
  "A-AFFY-121", "GPL164",    # "Ye6100SubB", "Yeast 6100 Set - Chip B"
  "A-AFFY-122", "GPL165",    # "Ye6100SubC", "Yeast 6100 Set - Chip C"
  "A-AFFY-123", "GPL166",    # "Ye6100SubD", "Yeast 6100 Set - Chip D"
  "A-AFFY-153", "GPL10373",  # both have "genechip" "tag3" "array"
  "A-AFFY-42", NA_character_, # !TODO
  ## AGIL
  "A-AGIL-29", "GPL3737",
  ## EMBL
  "A-EMBL-10", NA_character_,
  ## GEOD
  "A-GEOD-5991", "GPL5991",  # all just different titles..
  "A-GEOD-7542", "GPL7542",
  "A-GEOD-7550", "GPL7550",
  "A-GEOD-8435", "GPL8435",
  "A-GEOD-9825", "GPL9825",
  "A-GEOD-10930", "GPL10930",
  "A-GEOD-13492", "GPL13492",
  "A-GEOD-13972", "GPL13972",
  "A-GEOD-15289", "GPL15289",
  "A-GEOD-15290", "GPL15290",
  "A-GEOD-19506", "GPL19506",
  ## MAXD
  "A-MAXD-5", NA_character_  # closest i could find was GPL422
  ## MEXP
  ## MTAB
  ## SMDB
  ## UMCU
  ## WMIT
)

# these acceessions are the wrong organism or have been deleted
not_scer_platform_ae <- c("A-GEOD-4786", "A-GEOD-7476", "A-GEOD-8638", "A-GEOD-8761", "A-GEOD-17249",  "A-GEOD-17250")

ae_affy <- ae_only %>%
  filter(!ae_accession %in% not_scer_platform_ae) %>%
  left_join(ae_recode)


# now can combine things back together
x <- maptbl %>%
  transmute(geometa_uid = uid,
            gpl = gpl_accession,
            ae = ae_accession,
            gpl_title = title
            )
y <- ae_affy %>%
  transmute(gpl = gpl_accession,
            ae = ae_accession,
            ae_title = title)

combined_tbl <- full_join(x,y, by = c("gpl")) %>%
  unite(acc, gpl,ae.x,ae.y, sep = ';') %>%
  unite(title, gpl_title, ae_title, sep = ';') %>%
  mutate(scer_uid = row_number()) %>%
  separate_rows(acc, sep = ';', convert = T) %>%
  filter(!is.na(acc)) %>%
  group_by(scer_uid) %>%
  summarise(acc = paste0(acc, collapse = ';'),
            title = unique(title),
            geometa_uid = unique(geometa_uid)) %>%
  separate_rows(title, sep = ';', convert = T) %>%
  filter(!is.na(title)) %>%
  group_by(scer_uid, acc, geometa_uid) %>%
  summarise(title = paste0(title, collapse = ';')) %>%
  separate_rows(acc, sep =';', convert = T) %>%
  ungroup() %>%
  mutate(srcdb = if_else(str_detect(acc, "GPL"), "geo", "ae")) %>%
  group_by(scer_uid, geometa_uid, title, srcdb) %>%
  summarise(acc = paste0(acc, collapse = ';')) %>%
  spread(srcdb, acc)

# now add back in other vars from metagpl
combined_tbl <- metagpl %>%
  # remove redundant variables
  select(-ID, -title) %>%
  left_join(combined_tbl, ., by = c("geo" = "gpl"))


write_csv(combined_tbl, "data-raw/scer-platforms-geo-and-ae.csv")
