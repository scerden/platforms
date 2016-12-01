context("extract-from-zip")

test_that("handles inputs and outputs properly", {
  path <- "~/googledrive/makereach/rikDACF.zip"
  expect_length(list_zip(path), 32L)
  expect_type(list_zip(path), "character")
  expect_error(list_zip(NULL))
  expect_error(list_zip(NA_character_))

})
