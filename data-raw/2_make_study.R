#!/usr/bin/env Rscript

'Builds study dataset from processed exteriors survey data.

Assumes script is being run from the `data-raw` directory and that
`data-raw/surveys-processed` contains processed survey data (see `exteriors.R`).

Usage:
  exteriors_study.R [--N=<val>] [--output=<file>] [<input>...]
  exteriors_study.R (-h | --help)
  exteriors_study.R --version

Options:
  -h --help                 Show this screen.
  -N <val>, --N=<val>       Maximum number of observations to include per arm  [default: Inf].
  <input>                   Survey directory.
  -o <file> --output=<file> Output file.

' -> doc

library(fs)
library(tidyverse)

set.seed(156)

make_study_data <- function(files_in, file_out = NULL, N_max = Inf) {
  df_all <-
    files_in %>%
    map_dfr(read_rds)

  # Compute how many observations we want per arm: the smallest number of
  # observations in any arm or `N_max`, whichever is smaller.
  N <-
    df_all %>%
    count(arm) %>%
    pull(n) %>%
    min()
  N <- min(N, N_max)

  file_out <-
    if (!is.null(file_out)) {
      file_out
    } else {
      str_glue("study-data/study_data_", N, ".rds")
    }

  # Sample `N` observations from each arm and write out the file!
  df_study <-
    df_all %>%
    group_by(arm) %>%
    sample_n(N) %>%
    ungroup() %>%
    write_rds(file_out)
}

# Only runs if executed as script.
if (sys.nframe() == 0L) {
  library(docopt)
  args <- docopt(doc)
  N_max <- as.numeric(args$N)

  files_in <-
    if (length(args$input) > 0) {
      path("surveys-processed", args$input, ext = "rds")
    } else {
      dir_ls(path = "surveys-processed")
    }

  make_study_data(files_in, args$output, N_max = N_max)
}
