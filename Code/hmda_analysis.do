/*==============================================================================
  Disparate Access to Credit: North Carolina Residential Mortgage Market,
  2018-2021 (HMDA)
  Emefa Surprize Buaka
  Requires: estout (ssc install estout)
==============================================================================*/

clear all
set more off

*------------------------------------------------------------------------------
* Settings
*------------------------------------------------------------------------------
global raw  "S:\HDMA project"     // folder with state_NC_YYYY.csv files
global work "."                   // folder for .dta files

local drop_purchased 1            // 1 = drop purchased loans (action 6)


*------------------------------------------------------------------------------
* 1. Import and append 2018-2021
*------------------------------------------------------------------------------
foreach y in 2018 2019 2020 2021 {
    import delimited "$raw/state_NC_`y'.csv", clear
    capture tostring income, replace     // keep income the same type every year
    save "$work/data_`y'.dta", replace
}

use "$work/data_2018.dta", clear
foreach y in 2019 2020 2021 {
    append using "$work/data_`y'.dta"
}
save "$work/combined_data.dta", replace


*------------------------------------------------------------------------------
* 2. Prepare analysis variables (once, for all analyses)
*------------------------------------------------------------------------------

* Income (HMDA reports income in thousands)
replace income = "" if inlist(strtrim(income), "NA", "Exempt")
destring income, replace
replace income = . if income < 0

* Loan approval
if `drop_purchased' == 1 {
    drop if action_taken == 6
}
generate loan_approved = inlist(action_taken, 1, 2, 6)
label variable loan_approved "Loan approved (originated or approved not accepted)"

* Race/ethnicity recode
generate str40 race_ethnicity = ""
generate _race = strtrim(derived_race)
generate _eth  = strtrim(derived_ethnicity)

replace race_ethnicity = "Non-Hispanic White"               if _race == "White"
replace race_ethnicity = "African American"                 if _race == "Black or African American"
replace race_ethnicity = "Asian"                            if _race == "Asian"
replace race_ethnicity = "American Indian or Alaska Native" if _race == "American Indian or Alaska Native"
replace race_ethnicity = "Pacific Islander"                 if _race == "Native Hawaiian or Other Pacific Islander"
replace race_ethnicity = "Multiracial Non-White"            if _race == "2 or more minority races"
replace race_ethnicity = "Multiracial White"                if _race == "Joint"
* Hispanic overrides race (any race), as described in the report
replace race_ethnicity = "Hispanic"                         if inlist(_eth, "Hispanic or Latino", "Joint")
* Everything left: race not available / free-form text only
replace race_ethnicity = "Other/Not reported"               if race_ethnicity == ""
drop _race _eth
label variable race_ethnicity "Race/Ethnicity"

* Minority status
generate str20 minority_status = "Not reported"
replace minority_status = "Non-Hispanic White" if inlist(race_ethnicity, "Non-Hispanic White", "Multiracial White")
replace minority_status = "Non-White" if inlist(race_ethnicity, "African American", "Asian", ///
    "American Indian or Alaska Native", "Pacific Islander", "Hispanic", "Multiracial Non-White")

* Applicant dummies
generate female_dummy     = derived_sex == "Female"
generate minority_dummy   = minority_status == "Non-White"
generate race_na          = race_ethnicity == "Other/Not reported"
generate hispanic         = race_ethnicity == "Hispanic"
generate asian            = race_ethnicity == "Asian"
generate african_american = race_ethnicity == "African American"
generate other_race       = inlist(race_ethnicity, "American Indian or Alaska Native", ///
    "Pacific Islander", "Multiracial White", "Multiracial Non-White")

* Loan dummies
generate nonconventional    = loan_type != 1
generate home_improvement   = inlist(loan_purpose, 2, 31, 32)
generate not_owner_occupied = occupancy_type == 3
generate manufactured       = inlist(derived_dwelling_category, ///
    "Single Family (1-4 Units):Manufactured", "Multifamily:Manufactured")
generate single_family_units = inlist(derived_dwelling_category, ///
    "Single Family (1-4 Units):Manufactured", "Single Family (1-4 Units):Site-Built")

* Continuous measures
generate loan_amount_1000     = loan_amount / 1000
generate lnloan_amount        = ln(loan_amount_1000)
generate lnincome             = ln(income)
generate income1000           = income * 1000
generate loan_to_income_ratio = loan_amount / income1000
generate lnratio              = ln(loan_to_income_ratio)

save "$work/analysis_data.dta", replace


*------------------------------------------------------------------------------
* 3. Variable lists
*------------------------------------------------------------------------------
global loanvars home_improvement not_owner_occupied manufactured nonconventional
global commvars tract_population tract_minority_population ///
    tract_to_msa_income_percentage tract_owner_occupied_units single_family_units
global racevars hispanic asian african_american other_race race_na


*------------------------------------------------------------------------------
* 4. Program: descriptives + three logit models for any subsample
*------------------------------------------------------------------------------
capture program drop run_analysis
program define run_analysis
    syntax [if], label(string)
    marksample touse, novarlist

    display as result _n(2) "==================== `label' ===================="

    * Loan characteristics
    tabulate activity_year loan_type                 if `touse', row
    tabulate activity_year derived_dwelling_category if `touse', row
    tabulate activity_year loan_purpose              if `touse', row
    tabulate activity_year occupancy_type            if `touse', row

    summarize loan_amount if `touse', detail
    forvalues y = 2018/2021 {
        summarize loan_amount if `touse' & activity_year == `y', detail
    }
    foreach p in 1 2 4 5 31 32 {
        summarize loan_amount if `touse' & loan_purpose == `p'
    }

    * Pre-approval and loan action
    tabulate activity_year preapproval   if `touse', row
    tabulate activity_year action_taken  if `touse', row
    tabulate activity_year loan_approved if `touse', row
    tabulate activity_year loan_approved if `touse' & preapproval == 1, row
    tabulate activity_year loan_approved if `touse' & preapproval == 2, row

    * Applicant information
    tabulate activity_year derived_sex       if `touse', row
    tabulate activity_year coapplicant_sex   if `touse', row
    tabulate activity_year derived_ethnicity if `touse', row
    tabulate activity_year derived_race      if `touse', row
    tabulate activity_year race_ethnicity    if `touse', row
    summarize income if `touse', detail

    * Community measures
    summarize $commvars if `touse'
    forvalues y = 2018/2021 {
        summarize $commvars if `touse' & activity_year == `y'
    }

    * Reasons for denial (10 = not applicable)
    tabulate activity_year denial_reason1 if `touse' & denial_reason1 != 10, row

    * Approval by loan type
    tabulate activity_year loan_type if `touse' & loan_approved == 1, row
    forvalues t = 1/4 {
        tabulate activity_year loan_approved if `touse' & loan_type == `t', row
    }

    * Approval by sex
    foreach s in Male Female Joint {
        tabulate activity_year loan_approved if `touse' & derived_sex == "`s'", row
    }

    * Logistic regressions
    * Model 1: minority vs. Non-Hispanic White
    logit loan_approved $loanvars lnloan_amount $commvars ///
        female_dummy minority_dummy race_na lnincome if `touse'
    estimates store M1_`label'

    * Model 2: distinct race/ethnic groups vs. Non-Hispanic White
    logit loan_approved $loanvars lnloan_amount $commvars ///
        female_dummy $racevars lnincome if `touse'
    estimates store M2_`label'

    * Model 3: Model 2 with log loan-to-income ratio
    logit loan_approved $loanvars $commvars ///
        female_dummy $racevars lnratio if `touse'
    estimates store M3_`label'

    esttab M1_`label' M2_`label' M3_`label', ///
        starlevels(* 0.10 ** 0.05 *** 0.01) pr2 ///
        mtitles("Model 1" "Model 2" "Model 3") ///
        title("Logistic Regression: `label'")
end


*------------------------------------------------------------------------------
* 5. North Carolina (statewide)
*------------------------------------------------------------------------------
use "$work/analysis_data.dta", clear

run_analysis, label(NC)

* Mean income by race and year
preserve
collapse (mean) income, by(derived_race activity_year)
forvalues y = 2018/2021 {
    list derived_race income if activity_year == `y'
}
restore

* Correlations with income and loan amount
foreach v of global commvars {
    pwcorr income      `v', sig star(.05) obs
    pwcorr loan_amount `v', sig star(.05) obs
}

* Approval by sex: significance test (male vs. female)
tabulate derived_sex loan_approved if inlist(derived_sex, "Male", "Female"), chi2

* Approval rates by race
levelsof derived_race, local(races)
foreach r of local races {
    tabulate activity_year loan_approved if derived_race == "`r'", row
}

* Approval by race/ethnicity recode: significance test
tabulate loan_approved race_ethnicity, chi2

* Denial reasons by minority status, sex, and race/ethnicity
tabulate activity_year denial_reason1 if denial_reason1 != 10 & minority_status == "Non-Hispanic White", row
tabulate activity_year denial_reason1 if denial_reason1 != 10 & minority_status == "Non-White", row
tabulate activity_year denial_reason1 if denial_reason1 != 10 & derived_sex == "Female", row
tabulate activity_year denial_reason1 if denial_reason1 != 10 & derived_sex == "Male", row
tabulate race_ethnicity denial_reason1 if denial_reason1 != 10, row

* Loan-to-income ratio and approval
correlate income1000 loan_amount
regress income1000 loan_amount

summarize loan_to_income_ratio
generate z_lti = (loan_to_income_ratio - r(mean)) / r(sd)

generate str40 lti_category = ""
replace lti_category = "1+ SD below mean"       if z_lti <= -1
replace lti_category = "Within 1 SD of mean"    if z_lti > -1 & z_lti <= 1
replace lti_category = "+1 to +5 SD"            if z_lti > 1  & z_lti <= 5
replace lti_category = "+5 to +20 SD"           if z_lti > 5  & z_lti <= 20
replace lti_category = "More than +20 SD"       if z_lti > 20 & !missing(z_lti)

tabulate loan_approved lti_category, row
tabulate loan_approved lti_category, chi2

* Approval by community measures
tabstat $commvars, by(loan_approved) statistics(N mean sd sem) columns(statistics)
foreach v of global commvars {
    oneway `v' loan_approved
}

* Correlation among model predictors
correlate $loanvars loan_amount_1000 $commvars female_dummy minority_dummy ///
    income loan_to_income_ratio


*------------------------------------------------------------------------------
* 6. Seven metro areas
*------------------------------------------------------------------------------
local msa_codes 39580 20500 24660 49180 16740 11700 47260
local msa_names Raleigh Durham Greensboro_HighPoint Winston_Salem Charlotte Asheville Wilmington

forvalues i = 1/7 {
    local code : word `i' of `msa_codes'
    local name : word `i' of `msa_names'
    run_analysis if derived_msamd == `code', label(`name')
}

* Model comparison across metros
esttab M1_*, starlevels(* 0.10 ** 0.05 *** 0.01) pr2 title("Model 1 by area")
esttab M2_*, starlevels(* 0.10 ** 0.05 *** 0.01) pr2 title("Model 2 by area")
esttab M3_*, starlevels(* 0.10 ** 0.05 *** 0.01) pr2 title("Model 3 by area")
