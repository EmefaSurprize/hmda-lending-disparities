# hmda-lending-disparities

![Approval rate by race](output/approval_rate_by_race.png)

# Disparate Access to Credit: North Carolina's Residential Mortgage Market, 2018–2021

Analysis code for a white paper from the Research, Policy, and Impact Center (RPIC)
by Emefa Surprize Buaka and Stephen J. Sills, PhD.

## Research question
Do mortgage approval rates in North Carolina differ by applicant race, ethnicity, and sex once loan, income, and neighborhood characteristics are taken into account?
And do these patterns differ across the state's major metro areas?

## Data
Home Mortgage Disclosure Act (HMDA) public loan-level data for North Carolina, 2018–2021, from the FFIEC HMDA Data Browser (https://ffiec.cfpb.gov/data-browser/).
The raw files hold about 2.9 million loan application records.

Analyses are run statewide and for seven metro areas:

| Metro area | MSA/MD code |
| Raleigh | 39580 |
| Durham–Chapel Hill | 20500 |
| Greensboro–High Point | 24660 |
| Winston-Salem | 49180 |
| Charlotte | 16740 |
| Asheville | 11700 |
| Wilmington | 47260 |

Raw data is not included in this repository because of file size. To reproduce, download the North Carolina files for 2018, 2019, 2020, and 2021 from the Data Browser and save them as `state_NC_2018.csv` through `state_NC_2021.csv`.

## Methods
- **Outcome:** loan approved (originated, or approved but not accepted) vs. not approved.
  Purchased loans are excluded because the reporting lender did not make the decision.
- **Descriptive analysis:** loan, applicant, and census tract characteristics by year; approval and denial reasons by race/ethnicity, sex, loan type, and loan-to-income ratio; chi-square and ANOVA tests of group differences.
- **Logistic regression (three models):**
  1. Minority vs. Non-Hispanic White applicants
  2. Hispanic, Asian, African American, and other race groups vs. Non-Hispanic White
  3. Model 2 with the log loan-to-income ratio in place of loan amount and income
- **Controls:** loan type, purpose, occupancy, manufactured housing, loan amount, income, tract population, tract minority share, tract income relative to the metro median, owner-occupied units, and applicant sex.
- Models are run statewide and separately for each metro area.

## Key findings
*Descriptive results from the original report (2018–2021, about 2.9 million applications).

- **White applicants had the highest approval rate:** 69.7% over the period,
  compared with 65.7% for Asian, 55.0% for Black or African American, 55.0% for
  Native Hawaiian or Other Pacific Islander, 48.1% for applicants of two or more
  minority races, and 47.5% for American Indian or Alaska Native applicants.
- **Gaps narrowed but persisted:** approval rates rose for every group between 2018
  and 2021. Black applicants' rate rose from 49.9% to 58.0%, but it was still
  13 points below White applicants (71.1%) in 2021.
- **Joint applicants did best:** joint applications were approved 71.0% of the time,
  compared with 64.4% for male and 63.4% for female primary applicants.
- **Debt-to-income ratio and credit history drove denials:** together they accounted
  for 54% of denials with a stated reason.
- **Rural loan programs had the highest approval rates:** FSA/RHS loans were approved 81.5% of the time, compared with 67–70% for conventional, FHA, and VA loans.

Across 2.5 million North Carolina mortgage applications (2018–2021), Hispanic, African American, and Asian applicants had 44%, 38%, and 32% lower odds of approval than Non-Hispanic White applicants, after controlling for loan type, loan amount, income, and neighborhood characteristics. These gaps appeared in all seven metro areas studied, and loan characteristics such as manufactured housing (73% lower odds) and refinancing (41% lower odds) were also strong predictors of denial.

## Repository contents
- `code/hmda_analysis.do`: full analysis in Stata (data import, recoding, descriptives, and regression models)

## How to reproduce
1. Download the HMDA files listed above.
2. Install the table package in Stata: `ssc install estout`
3. Open `code/hmda_analysis.do`, set the data folder path at the top, and run the file.

## Software
Stata 17 or later

## Authors
Emefa Surprize Buaka, PhD candidate in Applied Economics, University of North Carolina at Greensboro
Stephen J. Sills, PhD, Research, Policy, and Impact Center
