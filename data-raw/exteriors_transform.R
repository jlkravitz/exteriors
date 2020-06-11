#!/usr/bin/env Rscript

'Transforms processed exterior survey data from old to new format.

The legacy `make_data.R` script created a dataframe which included the original
responses (i.e., unprocessed) and did not include demographic questions. This
script allows us to publish old data, but in this new format. It will likely
not have much use after a while.

Assumes script is being run from `data-raw` directory and that
`data-raw/surveys-processed` exists.

Usage:
  exteriors_transform.R <input> <output>
  exteriors_transform.R (-h | --help)

Options:
  -h --help       Show this screen.
  <input>         Name of RDS file containing old data.
  <output>        Name of RDS file to write transformed data.

' -> doc

library(tidyverse)
library(fs)
library(docopt)

transform_data <- function(input, output, surveys) {
  data_in <- read_rds(input)

  data_all <-
    dir_ls(path = "surveys-processed") %>%
    map_dfr(read_rds)

  data_out <-
    data_in %>%
    left_join(data_all, by = c("arm", "pre_q", "post_q")) %>%
    select(-ends_with("original"))

  stopifnot(
    "some responses matched more than once" = nrow(data_in) == nrow(data_out),
    "some responses did not match" = nrow(filter(data_out, is.na(housing_involved))) == 0
  )

  data_out %>%
    write_rds(output)
}

# Only runs if executed as script.
if (sys.nframe() == 0) {
  args <- docopt(doc)
  transform_data(args$input, args$output, args$survey)
}
