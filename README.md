# CES ideological placements, 2008–2025

Zachary Lorico Hertz

The [Cooperative Election Study](https://dataverse.harvard.edu/dataverse/cces) (aka CES, fka CCES) has asked respondents to place politicians and themselves on a liberal-conservative scale every year since 2008. Annoyingly, these variables are not harmonized across years, making analysis across years difficult. This repository contains code to clean and harmonize those data across all surveys since 2008 into a single respondent-level file, while joining in relevant demographic and geographic covariates from the [CES cumulative data](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/II2DB6) maintained by Shiro Kuriwaki. 

Data is saved as `output/ces_placements.rds`, where each row is a respondent-year observation. Open it in R with `readRDS()`. You can use `build.R` to rebuild the output using the original Dataverse files.

## What is in the repository

**Ideological placements.** In 2020, respondents were asked "How would you rate each of the following individuals and groups?" and given a grid, where the rows are a person or group, and the answer options are:

1. Very Liberal
2. Liberal
3. Somewhat Liberal
4. Middle of the Road
5. Somewhat Conservative
6. Conservative
7. Very Conservative
8. Not sure

Each row of the grid is an item, and each item gets these columns:
- `place_<item>`: the placement, coded 1 (Very liberal) to 7 (Very conservative), or 8 for "Not sure". This is blank if the item wasn't asked of that respondent in that year, or was skipped. **Make sure to drop not sure responses before creating averages.**
- `name_<item>` and `party_<item>`: the name and party of the person rated. These are filled in only for rows that vary by respondent (governor, senators, House member, candidates).
- `place_<item>_slider` (2008 only): the original 0–100 slider value.

The rated objects included here are:

| Item | Who is rated |
|---|---|
| `self` | The respondent |
| `dem_party`, `rep_party` | The Democratic and Republican parties |
| `bush`, `obama`, `mccain`, `romney`, `clinton`, `trump`, `biden`, `harris` | Presidents and presidential candidates, by name |
| `gov` | The respondent's sitting governor |
| `sen1`, `sen2` | The respondent's two sitting senators |
| `house_member` | The respondent's sitting House member |
| `sen_cand1`, `sen_cand2` | Candidates in the respondent's Senate race |
| `sen_cand1_r2`, `sen_cand2_r2` | Candidates in a second Senate race in the state that year when applicable (special elections) |
| `house_cand1`, `house_cand2` | Candidates in the respondent's House race |

`variable_map.csv` lists the source variable for every item in every year.

**Geographic and demographic covariates**, included from the CES cumulative file. Categorical variables are stored as numeric codes with value labels attached. See the cumulative file codebook for full definitions and information about how each variable is harmonized across years.

| Variable | What it is | Values |
|---|---|---|
| `weight` | Pre-election survey weight. Use this for the placements, which are asked before the election | Numeric, every year; sums to 1 within each year |
| `weight_cumulative` | Weight for pooling years; each year counts equally (see the cumulative codebook) | Numeric, every year; sums to 29,250 within each year |
| `weight_post` | Post-election survey weight, for respondents who took the post-election wave | Numeric; 2012, 2016, 2018, 2020 and 2022 only |
| `vvweight`, `vvweight_post` | Pre- and post-election weights for validated voters (respondents matched to a voter-file record) | Numeric; 2018, 2020, 2022 and 2024 only |
| `state`, `st` | State of residence (full name), and state of residence (two-letter abbreviation) | e.g. `North Carolina`, `NC` |
| `cd` | Congressional district | e.g. `NC-10` |
| `county_fips` | County, five-digit FIPS code | e.g. `37027` |
| `zipcode` | Five-digit ZIP code | e.g. `08030` |
| `age`, `birthyr` | Age and birth year | 18–109; 1900–2007 |
| `gender` | Gender | Male, Female |
| `race` | Race | White, Black, Hispanic, Asian, Native American, Mixed, Other, Middle Eastern |
| `hispanic` | Hispanic or Latino origin | Yes, No (blank for 13% of respondents) |
| `educ` | Highest level of education | No HS, High School Graduate, Some College, 2-Year, 4-Year, Post-Grad |
| `faminc` | Family income | Twelve brackets from Less than 10k to 150k+, plus Prefer not to say and Skipped |
| `pid3` | Three-point party identification | Democrat, Republican, Independent, Other, Not Sure |
| `pid3_leaner` | Party identification with leaners counted as partisans | Democrat, Republican, Independent, Not Sure |
| `pid7` | Seven-point party identification | Strong Democrat to Strong Republican, plus Not Sure and Don't Know |
| `ideo5` | Five-point ideological self-identification (a separate question from `place_self`) | Very Liberal, Liberal, Moderate, Conservative, Very Conservative, Not Sure |
| `relig_bornagain` | Identifies as born-again or evangelical Christian | Yes, No |
| `relig_church` | Frequency of attending religious services | More Than Once a Week to Never, plus Don't Know |

## Item coverage across years

| Item | Years asked |
|---|---|
| Self, both parties | Every year, 2008–2025 |
| Sitting president | Every year |
| Both major-party presidential nominees | 2008, 2012, 2016, 2020, 2024; also 2013 (Romney) and 2021–2023 (Trump) |
| Governor | 2009–2025 (not 2008) |
| Senators, House member | Every year (in 2008 House members are only asked about if they are retiring) |
| Senate candidates | Even years, 2008–2022 |
| House candidates | Even years, 2008–2022 |

The 2024 public release only includes placements for sitting House members and senators but not candidates. The 2014 release asked about Clinton (included as `clinton`) as well as three Republican candidates not included in this release. I do not include ratings of the Tea Party (asked from 2010–2014) or the Supreme Court (asked from 2011–2019 and 2022–2025).

## Important warnings and notes

**2008, as the first year, measures these items using a 0-100 slider.** I harmonized this by binning answers into seven equal-width bins centered around 50. You can view or use the original value in the `place_<item>_slider` columns.

For some reason, **2009 does not have a "Not sure" response option**.

**Candidate party affiliations.** Respondents rate the actual candidates in their given House and Senate races. The CES data stores these ratings as evaluations of "candidate 1" and "candidate 2". `party_<item>` records the party affiliation for each candidate. In 2012 onwards, the CES directly records the party affiliation for each respondent's candidates, so I copy this field directly. In 2008 and 2010, the codebooks say candidate 1 is always the Democrat and candidate 2 is always the Republican, so I fill those in directly.

**2009 and 2011 are missing partisan affiliations.** Both years record the names of which elected officials respondents rated, but not their partisan affiliation. As a result, `party_gov`, `party_sen1`, `party_sen2` and `party_house_member` are empty in those years.

**Incumbents running for reelection are rated once, as candidates.** There are only additional rows in the grid to rate sitting Senators or House representatives when the member isn't on the ballot in that year. As a result, `sen1`, `sen2` and `house_member` are blank for many respondents in election years, and the incumbent's placement that year is in `sen_cand*` or `house_cand*`.

**Joining this data to the cumulative CES data.** I match rows using `year` and `case_id` (each year's respondent ID). I include match rates, by year, in `output/match_rates.csv`.

## Rebuilding

Run `build.R`, which requires the `dataverse`, `haven` and `tidyverse` packages. The script downloads yearly files and the cumulative file from the Harvard Dataverse, which can run slow on slow Internet connections. Each year is cached in `data/raw/` as it progresses to guard against connection or download failures.

## Sources

Each year's CES Common Content, downloaded from the Harvard Dataverse (DOIs in `build.R`):

| Year | DOI | Year | DOI |
|---|---|---|---|
| 2008 | 10.7910/DVN/YUYIVB | 2017 | 10.7910/DVN/3STEZY |
| 2009 | 10.7910/DVN/KKM9UK | 2018 | 10.7910/DVN/ZSBZ7K |
| 2010 | 10.7910/DVN/VKKRWA | 2019 | 10.7910/DVN/WOT7O8 |
| 2011 | 10.7910/DVN/GLRXZ0 | 2020 | 10.7910/DVN/E9N6PH |
| 2012 | 10.7910/DVN/HQEVPK | 2021 | 10.7910/DVN/OPQOCU |
| 2013 | 10.7910/DVN/KPP85M | 2022 | 10.7910/DVN/PR4L8P |
| 2014 | 10.7910/DVN/XFXJVY | 2023 | 10.7910/DVN/JQJTCC |
| 2015 | 10.7910/DVN/SWMWX8 | 2024 | 10.7910/DVN/X11EP6 |
| 2016 | 10.7910/DVN/GDF6Z0 | 2025 | 10.7910/DVN/DFUGJR |

Shiro Kuriwaki, *Cumulative CES Common Content*, Harvard Dataverse,
doi:10.7910/DVN/II2DB6, version 12.0.

Please cite the CES releases and the cumulative file when using these data.
