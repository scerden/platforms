
<!-- README.md is generated from README.Rmd. Please edit that file -->
1. extract files from zip archives
----------------------------------

``` r
srcdir <- "~/googledrive/makereach"
exdir <- "inst/extdata"
# get cdf file from archive -----------------------------------------------
zippath <- file.path(srcdir, "rikDACF.zip")
cdf <- list_zip(zippath) %>%
  str_subset("\\.cdf$") %>%
  extract_from_zip(zippath = zippath, exdir)


# get probeseq file from archive ------------------------------------------
zippath <- file.path(srcdir, "rikDACF_probeSeq.zip")
probeseq <- list_zip(zippath) %>%
  str_subset("probeSequences\\.txt") %>%
  extract_from_zip(zippath, exdir)
probeseq <- R.utils::gzip(probeseq, overwrite = T)
```

2. probe cdf files
------------------

``` r
# detach("package:tidyverse", unload=TRUE) # in case i need to detach something without restarting R
library(affyio)
check.cdf.type(cdf) # text version of cdf file not binary
cdf_l <- read.cdffile.list(cdf)
cdf_l %>% str(max.level = 1)
library(affxparser)
cdf_l2 <- readCdf(cdf) # different structure than cdf_l
cdf_d <- readCdfDataFrame(cdf) %>% as_tibble() # this is very convenient
cdf_d
```

3. probe sequence files
-----------------------

``` r
probeseq_d <- read_tsv(probeseq, col_types = "ciiicc")
names(probeseq_d) <- names(probeseq_d) %>%
  str_to_lower() %>% 
  str_replace_all("[^a-z0-9]", '_')
probeseq_d %>% glimpse()
```

4. platform accessions
----------------------

Find all platforms in geo that match this name.

``` r
library(scerden.geometadb)
geo_platforms <- find_in_gpl("rikdacf")[[1]] %>% print()
```

5. sample accessions
--------------------

``` r
geo_samples <- gsm %>% filter(gpl %in% geo_platforms$gpl) %>% print()
geo_samples %>% count(gpl)
```

6. sample supplementary files
-----------------------------

Download all the supplementary files for the geo samples.

``` r
library(GEOquery)
# as long as wget is installed on machine this will make it so that it doesn't clobber
# file if it is already there.
options(download.file.method = "wget", 
        download.file.method.GEOquery = "wget",
        download.file.extra = "--continue --no-clobber")

if(!dir.exists("data-raw")) dir.create("data-raw")
geo_samples$gsm %>% 
  walk(~getGEOSuppFiles(.x, makeDirectory = T, baseDir = "data-raw"))
```

Validate all the headers:

``` r
cels <- list.files("data-raw", full.names = T, recursive = T) %>% str_subset('\\.CEL\\.gz$')
cel_headers <- cels %>% map(~read.celfile.header(.x, info = "full"))
cel_headers <- cel_headers %>% 
  # .[1:5] %>% # debug
  map_df(~tibble(cdfname = .x$cdfName, 
              cols = .$`CEL dimensions`[1], 
              rows = .$`CEL dimensions`[2],
              scandate = .$ScanDate))
cel_headers %>% count(cdfname, cols, rows) # all the same good.
```

7. array quality metrics
------------------------

``` r
library(arrayQualityMetrics)

abatch <- affy::ReadAffy(filenames = cels[1:10])
arrayQualityMetrics(expressionset = abatch,
                    outdir = "Report_for_rikdacf",
                    force = T,
                    do.logtransform = T)
```
