# build.R
# Zachary Lorico Hertz
#
# Assembles a single respondent-level file aggregating CCES/CES ideological
# placements from 2008-2025. Items placed and included in this file:
# respondent's self-placement, Democratic/Republican Parties, sitting president,
# presidential candidates, respondent's governor, respondent's Senator(s),
# candidates for Senate in respondent's state, candidates for House in
# respondent's district, incumbent House representative. Columns are joined to
# demographics and geography from the CES cumulative file.
#
# This script downloads data inputs from the Harvard Dataverse. Because CES 
# files sometimes use different variable names across years to refer to the
# same ideological placement item (ie 'yourself' is CC317a in 2008 and CC22_340a
# in 2022), variable_map.csv lists each year's variable name for every item. 
# This script reads the mapping from that .csv, so to add or edit items
# you should edit that file.

# Output: output/ces_placements.rds (see README.md for every column).

library(dataverse)
library(haven)
library(tidyverse)

dir.create("data/raw", recursive = TRUE, showWarnings = FALSE)
dir.create("output", showWarnings = FALSE)

# Yearly Common Content files ==================================================
# case_var is respondent ID that year, to match to case_id in the cumulative file.

years_info <- tribble(
  ~year, ~doi,                  ~filename,                                  ~case_var,
  2008,  "10.7910/DVN/YUYIVB", "cces_2008_common.tab",                     "V100",
  2009,  "10.7910/DVN/KKM9UK", "cces09_cmn_output_2.dta",                  "v100",
  2010,  "10.7910/DVN/VKKRWA", "cces_2010_common_validated.dta",           "V100",
  2011,  "10.7910/DVN/GLRXZ0", "CCES11_Common_OUTPUT.tab",                 "V100",
  2012,  "10.7910/DVN/HQEVPK", "CCES12_Common_VV.tab",                     "V101",
  2013,  "10.7910/DVN/KPP85M", "Common Content Data.tab",                  "caseid",
  2014,  "10.7910/DVN/XFXJVY", "CCES14_Common_Content_Validated.dta",      "V101",
  2015,  "10.7910/DVN/SWMWX8", "CCES15_Common_OUTPUT_Jan2016.tab",         "V101",
  2016,  "10.7910/DVN/GDF6Z0", "CCES16_Common_OUTPUT_Feb2018_VV.tab",      "V101",
  2017,  "10.7910/DVN/3STEZY", "Common Content Data.tab",                  "V101",
  2018,  "10.7910/DVN/ZSBZ7K", "CCES18_Common_OUTPUT_vv_topost.dta",       "caseid",
  2019,  "10.7910/DVN/WOT7O8", "CCES19_Common_OUTPUT.tab",                 "caseid",
  2020,  "10.7910/DVN/E9N6PH", "CES20_Common_OUTPUT_vv.dta",               "caseid",
  2021,  "10.7910/DVN/OPQOCU", "CES21_Common_OUTPUT.tab",                  "caseid",
  2022,  "10.7910/DVN/PR4L8P", "CCES22_Common_OUTPUT_vv_topost.dta",       "caseid",
  2023,  "10.7910/DVN/JQJTCC", "CCES23_Common_OUTPUT.tab",                 "caseid",
  2024,  "10.7910/DVN/X11EP6", "CCES24_Common_OUTPUT_vv_topost_final.dta", "caseid",
  2025,  "10.7910/DVN/DFUGJR", "CES25_Common.tab",                         "caseid"
)

variable_map <- read_csv("variable_map.csv", col_types = cols(.default = "c")) |>
  mutate(year = as.integer(year))

# Download each year and pull its placement items ==============================
# IDs are written with sprintf("%.0f") because as.character(100000) is "1e+05".
# Each year's extract is cached in data/raw/, so a rerun only downloads years
# that are missing. Delete data/raw/ to force a fresh download.

all_years <- list()
code8_labels <- list()

for (i in seq_len(nrow(years_info))) {
  info <- years_info[i, ]
  cache_file <- paste0("data/raw/extract_", info$year, ".csv")

  if (file.exists(cache_file)) {
    all_years[[i]] <- read_csv(cache_file, col_types = cols(.default = "c"))
    next
  }

  cat("Downloading", info$year, "...\n")
  dat <- get_dataframe_by_name(
    filename = info$filename,
    dataset  = info$doi,
    original = TRUE,
    # 2009's strings are latin1; the default read will fail without this fix
    .f       = function(x) haven::read_dta(x, encoding = if (info$year == 2009) "latin1" else NULL),
    server   = "dataverse.harvard.edu"
  )
  names(dat) <- tolower(names(dat))

  year_map <- variable_map |> filter(year == info$year)

  sub <- tibble(year = info$year,
                case_id = sprintf("%.0f", as.numeric(dat[[tolower(info$case_var)]])))

  for (j in seq_len(nrow(year_map))) {
    row <- year_map[j, ]

    # Placement as stored (8 = "Not sure" in most years; 2008 is 0-100)
    sub[[paste0("place_", row$item, "_raw")]] <- as.character(as.numeric(dat[[tolower(row$place_var)]]))

    # Record what code 8 means in this file, to check it is "Not sure"
    value_labels <- attr(dat[[tolower(row$place_var)]], "labels")
    code8_labels[[paste(info$year, row$item)]] <- tibble(
      year = info$year, item = row$item,
      code8_label = if (8 %in% value_labels) names(value_labels)[value_labels == 8] else NA_character_
    )

    # Name and party of the person rated, as text
    if (!is.na(row$name_var)) {
      sub[[paste0("name_", row$item)]] <- na_if(as.character(as_factor(dat[[tolower(row$name_var)]])), "")
    }
    if (!is.na(row$party_var)) {
      sub[[paste0("party_", row$item)]] <- na_if(as.character(as_factor(dat[[tolower(row$party_var)]])), "")
    }
    # 2008 and 2010 have no party field for candidates; the slot itself is
    # the Democratic or Republican candidate
    if (!is.na(row$party_fixed)) {
      sub[[paste0("party_", row$item)]] <- row$party_fixed
    }
  }

  write_csv(sub, cache_file)
  write_csv(bind_rows(code8_labels), paste0("data/raw/code8_", info$year, ".csv"))
  code8_labels <- list()
  all_years[[i]] <- sub
  rm(dat); gc()
}

# Check what code 8 means, item by item and year by year
bind_rows(map(list.files("data/raw", pattern = "^code8_", full.names = TRUE),
              ~ read_csv(.x, col_types = "icc"))) |>
  write_csv("output/code8_labels.csv")

placements <- bind_rows(all_years) |>
  mutate(year = as.integer(year))

# Recode placements ============================================================
# 1 = Very liberal ... 7 = Very conservative, 8 = Not sure. Blank = not asked or skipped.
# 2009: no "Not sure" option; code 8 is "Skipped" (2009 codebook), so left blank.
# 2008: the guide lists 997 = Not sure, 998 = Skipped, 999 = Not asked, but the
# Dataverse file stores all three as plain missing values, so 2008 has no 8s.
# The 997 line below is kept in case a future release restores the codes.
# 2008: cut the 0-100 slider into seven equal bins and keep the continuous 
# measure as place_<item>_slider, which is blank in every other year.

raw_cols <- names(placements)[str_detect(names(placements), "^place_.*_raw$")]

for (col in raw_cols) {
  raw <- as.numeric(placements[[col]])
  placements[[str_remove(col, "_raw$")]] <- case_when(
    placements$year == 2008 & between(raw, 0, 100) ~ pmin(floor(raw / (100 / 7)) + 1, 7),
    placements$year == 2008 & raw == 997 ~ 8,
    placements$year == 2009 & raw %in% 1:7 ~ raw,
    !placements$year %in% c(2008, 2009) & raw %in% 1:8 ~ raw
  )
  placements[[str_replace(col, "_raw$", "_slider")]] <- if_else(placements$year == 2008 & between(raw, 0, 100), raw, NA_real_)
}

place_labels <- c("Very liberal" = 1, "Liberal" = 2, "Somewhat liberal" = 3,
                  "Middle of the road" = 4, "Somewhat conservative" = 5,
                  "Conservative" = 6, "Very conservative" = 7, "Not sure" = 8)
for (col in str_remove(raw_cols, "_raw$")) {
  placements[[col]] <- labelled(placements[[col]], labels = place_labels)
}
placements <- placements |> select(-all_of(raw_cols))

# Items not asked in 2008 (Trump, the governor, ...) have an empty slider column
empty_sliders <- names(placements)[str_detect(names(placements), "_slider$") &
                                     map_lgl(placements, ~ all(is.na(.x)))]
placements <- placements |> select(-all_of(empty_sliders))

# Blank names mean nobody was in that slot (an unopposed race, no race that
# year); the fixed party label should not be filled in for them
for (col in names(placements)[str_detect(names(placements), "^party_")]) {
  name_col <- str_replace(col, "^party_", "name_")
  if (name_col %in% names(placements)) {
    placements[[col]] <- if_else(is.na(placements[[name_col]]) | placements[[name_col]] == "",
                                 NA_character_, placements[[col]])
  }
}

# Cumulative file: demographics and geography ==================================
# Kuriwaki CES cumulative file

cumulative_file <- "data/raw/cumulative_2006-2025.rds"
if (!file.exists(cumulative_file)) {
  cat("Downloading cumulative file ...\n")
  cumulative <- get_dataframe_by_name(
    filename = "cumulative_2006-2025.rds",
    dataset  = "10.7910/DVN/II2DB6",
    .f       = readRDS,
    server   = "dataverse.harvard.edu"
  )
  saveRDS(cumulative, cumulative_file)
}
cumulative <- readRDS(cumulative_file)

covariates <- cumulative |>
  filter(year >= 2008) |>
  transmute(
    year = as.integer(year),
    case_id = sprintf("%.0f", case_id),
    # Weights. weight: pre-election weight. weight_cumulative: use only if
    # pooling years. weight_post: 2012, 2016, 2018, 2020, 2022 only. 
    # vvweight and vvweight_post: validated-voter weights, 2018-2024 only.
    weight, weight_cumulative, weight_post, vvweight, vvweight_post,
    state, st, cd, county_fips, zipcode,
    age, birthyr,
    gender, race, hispanic, educ, faminc,
    pid3, pid3_leaner, pid7, ideo5,
    relig_bornagain, relig_church
  )

# Join =========================================================================

ces_placements <- placements |>
  left_join(covariates, by = c("year", "case_id"))

# Match rate by year: share of placement-file respondents found in the
# cumulative file. Printed and saved, since the README reports it.
match_rates <- ces_placements |>
  group_by(year) |>
  summarise(
    n = n(),
    matched = sum(!is.na(weight)),
    share = matched / n
  )
print(match_rates, n = Inf)
write_csv(match_rates, "output/match_rates.csv")

# Column order: IDs and weights, covariates, then placements item by item
item_order <- unique(variable_map$item)
place_cols <- unlist(map(item_order, ~ c(paste0("place_", .x), paste0("place_", .x, "_slider"),
                                         paste0("name_", .x), paste0("party_", .x))))
place_cols <- place_cols[place_cols %in% names(ces_placements)]

ces_placements <- ces_placements |>
  select(year, case_id, all_of(names(covariates)[-(1:2)]), all_of(place_cols))

saveRDS(ces_placements, "output/ces_placements.rds")
cat("Wrote", nrow(ces_placements), "rows and", ncol(ces_placements), "columns\n")
