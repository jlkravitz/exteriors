#!/usr/bin/env Rscript

library(tidyverse)

exteriors_study_large <-
  read_rds("study-data/exteriors_study_large.rds")
usethis::use_data(exteriors_study_large, overwrite = TRUE)

exteriors_study_small <-
  read_rds("study-data/exteriors_study_small.rds")
usethis::use_data(exteriors_study_small, overwrite = TRUE)

exteriors_study_curb_appeal <-
  read_rds("study-data/exteriors_study_curb_appeal.rds")
usethis::use_data(exteriors_study_curb_appeal, overwrite = TRUE)
