#' Download the family.soft.gz file for a given geo platform accession.
#'
#' @param acc GPL accession in the format "GPL<n>" where <n> is the number.
#' @param expath path to download to
#'
#' @export
softfile_dl <- function(acc, expath = '.') {
  url <- softfile_url(acc)
  outfile <- file.path(expath, basename(url))
  if(!file.exists(outfile)) {
    download.file(url, outfile)
  }else{
    cat("File already exists.\n")
  }
}


#' make url for family.soft file for a given GEO platform accession
#'
#' @param acc character vector of of geo accession
#' @return character vector of softfile url
#' @export
softfile_url <- function(acc) {
  stopifnot(grepl("^GPL\\d+$", acc)) # ensure valid GPL accession
  stub <- gsub("\\d{1,3}$", "nnn", acc)
  platform_ftp <- "ftp://ftp.ncbi.nlm.nih.gov/geo/platforms"
  filename <- paste0(acc, "_family.soft.gz")
  paste(platform_ftp, stub, acc, "soft", filename, sep = '/')
}
