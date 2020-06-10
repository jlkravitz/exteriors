#!/usr/bin/env Rscript

library(tidyverse)
library(fs)

  # Parameters
# Factor levels for study arms. We use this to ensure that arms have the
# have the same factor levels, regardless of the subset of arms a particular
# dataset contains.
arm_levels <- c(
  "arch_strong", "arch_weak", "arch_graphic", "curb_appeal", "control"
)

# Mapping from qualtric treatment arm identifier to standard treatment arm names
# for data analysis. In the Qualtrics survey, there is a timer column prefixed
# with `prompt_<arm>`, where arm is the qualtric treatment arm identifier.
#
# NOTE: We could just change the qualtric identifiers, but we would need to
#   special-case some old data, for which we no longer have access to the qualtrics
#   survey. We'd rather solve this issue programmatically than by manually changing
#   column names in the raw data.
recoded_qualtric_arms <- list(
  "arch" = "arch_strong",
  "a1" = "arch_graphic",
  "weak" = "arch_weak"
)

# MTurk survey codes that were from "accepted" HITs but that we don't want
# to include in any analyses. The most common use for this list is for HITs
# that were automatically accepted (e.g., because we were too slow to reject
# them).
mturk_code_blacklist <- c(
  "2756254845",
  "2083738408",
  "6065091942",
  "3398814299",
  "1179329520",
  "6985391932",
  "200269073",
  "1678176932",
  "8930646367",
  "8797725080",
  "233035711",
  "5174946575",
  "8054283410",
  "3836992750",
  "6165895690",
  "2168976604"
)

make_data <- function(survey_path) {
  data_file <- dir_ls(survey_path, regexp = "*.csv")[1]  # Assumes only 1

  message(data_file)

  # There are 3 messy lines at the start, so we read the columns in separately. This makes
  # it easier to get correct typing in the columns, without needing to specify types manually.
  col_names <-
    data_file %>%
    read_csv(n_max = 0) %>%
    names()

  # We only know which arm of the study a participant is sent to based on the timing data
  # available. We use this to simplify the dataframe.
  data_file %>%
    read_csv(
      skip = 3,
      col_names = col_names,
      col_types = cols(
        MTurkCode = col_character()
      )
    ) %>%
    # Exactly one arm will have click data for each observation. Adding `na.rm`
    # filters out the click data of the other arms.
    # gather(
    #   key = "timer_name",
    #   value = "timer_time",
    #   matches("^prompt.*First Click$"),
    #   na.rm = TRUE
    # ) %>%
    pivot_longer(
      matches("^prompt.*First Click$"),
      names_to = "timer_name",
      values_to = "timer_time",
      values_drop_na = TRUE
    ) %>%
    mutate(
      arm =
        timer_name %>%
        str_match("prompt_(.+)_t(imer)?_First Click") %>%
        .[,2] %>%
        recode(!!!recoded_qualtric_arms) %>%
        factor(levels = arm_levels)
    ) %>%
    semi_join(
      accepted_mturk_codes(survey_path),
      by = "MTurkCode"
    ) %>%
    filter(!MTurkCode %in% mturk_code_blacklist) %>%
    rename(pre_q = main_pre_prompt_q) %>%
    mutate_at(
      vars(pre_q, post_q),
      list(processed = process_text)
    ) %>%
    # For backwards compatibility, `pre_q` and `post_q` need to be the processed
    # responses.
    select(
      arm,
      pre_q_original = pre_q,
      post_q_original = post_q,
      pre_q = pre_q_processed,
      post_q = post_q_processed
    ) %>%
    write_rds(path_ext_set(path_file(survey_path), "rds"))
}

# Given a path to a survey's data directory, returns a dataframe with all
# survey codes associated with accepted MTurk HITS.
accepted_mturk_codes <- function(survey_path) {
  read_batch_file <- function(batch_file) {
    col_names <-
      batch_file %>%
      read_csv(n_max = 0) %>%
      names() %>%
      head(-2)

    batch_file %>%
      read_csv(
        skip = 1,
        col_names = col_names,
        col_types = cols_only(
          ApprovalTime = col_character(),
          Answer.surveycode = col_character()
        )
      ) %>%
      filter(!is.na(ApprovalTime)) %>%
      transmute(MTurkCode = Answer.surveycode)
  }

  path_join(c(survey_path, "mturk_batch_files")) %>%
    dir_ls() %>%
    map_dfr(read_batch_file)
}

process_text <- compose(
  str_squish,
  textstem::lemmatize_strings,
  str_to_lower
)

# If no survey name provided, tidy all survey data.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) > 0) {
  make_data(args[1])
} else {
  dir_ls(path = "surveys") %>%
    walk(make_data)
}
