#' list contents of a zip archive
#'
#' @param path character vector of path to zip file
#' @return character vector of full paths in archive.
#' @export
list_zip <- function(path) {
  stopifnot(length(path) == 1)
  d <- unzip(path, list = T)
  d[["Name"]]
}


#' extract file from zip archive
#'
#' @param path path of file in zip archive
#' @param zippath path to zip archive
#' @param expath path to extract to
#' @return character vector of full path to extracted file
#' @export
extract_from_zip <- function(path, zippath, expath = '.') {
  stopifnot(length(path) == 1)
  unzip(zippath, files = path, junkpaths = T, exdir = expath)
}
