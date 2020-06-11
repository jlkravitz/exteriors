#!/usr/bin/env Rscript

'Processes and tidies exterior survey data, individually for each survey.

Assumes script is being run from `data-raw` directory and that
`data-raw/surveys-raw` contains unprocessed survey data, organized as follows:

  surveys-raw
  ├── original
  │   ├── Exteriors\ Survey_April\ 25,\ 2019_17.21.csv
  │   └── mturk_batch_files
  │       ├── Batch_3058260_batch_results.csv
  │       └── Batch_3060313_batch_results.csv
  └── <human_readable_survey_name>
      ├── <Qualtrics response file>
      └── mturk_batch_files
          ├── <MTurk batch file #1>
          ├── <MTurk batch file #2>
          └── ...

The Qualtrics response file can be downloaded with the default settings (CSV,
"Download all fields", "Use choice text").

The MTurk batch files can be downloaded by clicking "Download CSV" on the
"Results" page for a particular batch.

Usage:
  exteriors.R [<input>...]
  exteriors.R (-h | --help)

Options:
  -h --help       Show this screen.
  <input>         Survey directory.

' -> doc

library(tidyverse)
library(fs)
library(docopt)

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
# that were automatically accepted by the Mechanical Turk system (e.g., because
# we were too slow to reject them).
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
  file_in <- dir_ls(survey_path, regexp = "*.csv")[1]  # Assumes only 1
  file_out <- path("surveys-processed", path_file(survey_path), ext = "rds")

  message(str_glue("Processing {file_in}"))

  # The input file begins with 3 messy lines, so we read the column names
  # separately and skip these lines when reading in the full data set (see below).
  col_names <-
    file_in %>%
    read_csv(
      col_types = cols(.default = col_character()),
      n_max = 0
    ) %>%
    names()

  file_in %>%
    read_csv(
      col_names = col_names,
      col_types = cols(MTurkCode = col_character()),
      skip = 3,
    ) %>%

# Determine treatment -----------------------------------------------------
    # For each observation, exactly one arm will have click data. This is how we
    # determine the treatment for a particular observation.
    pivot_longer(
      matches("^prompt.*First Click"),
      names_to = "arm",
      names_pattern = "prompt_(.+)_t.*_First Click",
      values_to = "arm_timer_time",
      values_drop_na = TRUE
    ) %>%
    mutate(
      arm =
        arm %>%
        recode(!!!recoded_qualtric_arms) %>%
        factor(levels = arm_levels)
    ) %>%

# Filter responses --------------------------------------------------------
    semi_join(
      accepted_mturk_codes(survey_path),
      by = "MTurkCode"
    ) %>%
    filter(!MTurkCode %in% mturk_code_blacklist) %>%

# Select and process variables --------------------------------------------
    transmute(
      arm,
      pre_q = main_pre_prompt_q,
      post_q,
      housing_involved = Q30,
      housing_purchased = baseline_learning
    ) %>%
    mutate(
      across(starts_with("housing"), compose(as_factor, str_to_lower)),
      across(c(pre_q, post_q), process_text)
    ) %>%

    write_rds(file_out)

  message(str_glue("Writing {file_out}"))
  message()
}

# Given a path to a survey's data directory, returns a dataframe with all
# survey codes associated with accepted MTurk HITS.
accepted_mturk_codes <- function(survey_path) {
  read_batch_file <- function(batch_file) {
    # We read in columns separately because two empty "Approve" and "Reject"
    # columns at the end of the dataframe create parsing problems.
    col_names <-
      batch_file %>%
      read_csv(
        col_types = cols(.default = col_character()),
        n_max = 0
      ) %>%
      names() %>%
      head(-2)

    batch_file %>%
      read_csv(
        col_names = col_names,
        col_types = cols_only(
          ApprovalTime = col_character(),
          Answer.surveycode = col_character()
        ),
        skip = 1
      ) %>%
      filter(!is.na(ApprovalTime)) %>%
      transmute(MTurkCode = Answer.surveycode)
  }

  path_join(c(survey_path, "mturk_batch_files")) %>%
    dir_ls() %>%
    map_dfr(read_batch_file)
}

# Simple text pre-processing function.
process_text <- compose(
  str_squish,
  textstem::lemmatize_strings,
  str_to_lower
)

# If no survey name provided, tidy all survey data.
args <- docopt(doc)
surveys_in <-
  if (length(args$input) > 0) {
  path("surveys-raw", args$input)
  } else {
    dir_ls(path = "surveys-raw")
  }
surveys_in %>%
  walk(make_data)
