#' Exteriors survey responses for 500 individuals, including all treatment arms.
#'
#' A dataset containing exteriors survey responses of almost 500 individuals,
#' with almost 100 responses per treatment arm. This dataset contains responses
#' for the following treatment arms:
#'     * strong architecture
#'     * weak architecture
#'     * graphical architecture
#'     * curb appeal
#'     * control
#'
#' @format A data frame with 470 rows and 5 variables:
#' \describe{
#'   \item{arm}{treatment arm, as factor}
#'   \item{pre_q}{pre-intervention response, lower-cased and lemmatized}
#'   \item{post_q}{post-intervention response, lower-cased and lemmatized}
#'   \item{housing_involved}{indicates whether respondent is involved in housing sales and development, as logical}
#'   \item{housing_purchased}{indicates whether respondent has tried to purchase a house in past ten years, as logical}
#' }
"exteriors_study_large"

#' Exteriors survey responses for 125 individuals, including all treatment arms.
#'
#' A dataset containing exteriors survey responses of 125 individuals, with
#' 25 responses per treatment arm. This dataset contains responses for the
#' following treatment arms:
#'     * strong architecture
#'     * weak architecture
#'     * graphical architecture
#'     * curb appeal
#'     * control
#'
#' @format A data frame with 125 rows and 5 variables:
#' \describe{
#'   \item{arm}{treatment arm, as factor}
#'   \item{pre_q}{pre-intervention response, lower-cased and lemmatized}
#'   \item{post_q}{post-intervention response, lower-cased and lemmatized}
#'   \item{housing_involved}{indicates whether respondent is involved in housing sales and development, as logical}
#'   \item{housing_purchased}{indicates whether respondent has tried to purchase a house in past ten years, as logical}
#' }
"exteriors_study_small"

#' Exteriors survey responses for 360 individuals, for evaluating new curb appeal words.
#'
#' A dataset containing exteriors survey responses of 357 individuals, with
#' 89 responses per treatment arm. This dataset contains responses for the
#' following treatment arms:
#'     * strong architecture
#'     * curb appeal
#'     * control
#'
#' @format A data frame with 125 rows and 5 variables:
#' \describe{
#'   \item{arm}{treatment arm, as factor}
#'   \item{pre_q}{pre-intervention response, lower-cased and lemmatized}
#'   \item{post_q}{post-intervention response, lower-cased and lemmatized}
#'   \item{housing_involved}{indicates whether respondent is involved in housing sales and development, as logical}
#'   \item{housing_purchased}{indicates whether respondent has tried to purchase a house in past ten years, as logical}
#' }
"exteriors_study_curb_appeal"
