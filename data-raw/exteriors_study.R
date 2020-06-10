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
  -o <file> --output=<file> Output file

' -> doc

library(docopt)
library(fs)
library(tidyverse)

set.seed(156)

args <- docopt(doc)
N_max <- as.numeric(args$N)

files_in <-
  if (length(args$input) > 0) {
    path("surveys-processed", args$input, ext = "rds")
  } else {
    dir_ls(path = "surveys-processed")
  }

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
  if (!is.null(args$output)) {
    args$output
  } else {
    str_glue("study_data_", N, ".rds")
  }

# Sample `N` observations from each arm and write out the file!
df_study <-
  df_all %>%
  group_by(arm) %>%
  sample_n(N) %>%
  ungroup() %>%
  write_rds(file_out)
