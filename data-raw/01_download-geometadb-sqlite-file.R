library(tidyverse)

# download geometadb ------------------------------------------------------

# urls to sqlite db from GEOmetadb::getSQLiteFile source code
urls <-   c("https://gbnci-abcc.ncifcrf.gov/geo/GEOmetadb.sqlite.gz",
            "https://dl.dropboxusercontent.com/u/51653511/GEOmetadb.sqlite.gz",
            "http://watson.nci.nih.gov/~zhujack/GEOmetadb.sqlite.gz")
destfile <- "data-raw/tmp/GEOmetadb.sqlite"

if(!file.exists(destfile)) {
  # download file with wget, if already there won't clobber.
  cmds <- paste("wget --continue --directory-prefix=data-raw/tmp --no-clobber",
                urls)
  walk(cmds, system)
  # ~300Mb -> ~5Gb
  system(paste0("gunzip ", destfile, ".gz"))
}


