/* 
This do file uses both the mens and womens Kenya DHS datasets to create a single 
dataset with which to estimate the likely covariance matrix for the error terms 
in our final specification.  As most users of m4RH are likely from urban areas,
I only include respondents from urban areas in the final dataset
*/

do "C:\Code\m4RH_missing_data_sim\set_paths.do"

********* WOMEN'S DATASET ***********
use "$dhs\KEIR52FL.dta", clear
gen sex = 0
* keep if the respondent is from an urban area
keep if v025 == 1
* drop unnecessary variables
keep v005 v106 v012 v130 v304_01-v304_20 sex
tempfile temp
save `temp'

********* MEN'S DATASET ***********
use "$dhs\KEMR52FL.dta", clear
gen sex = 1
* keep if the respondent is from an urban area
keep if mv025 == 1
* drop unnecessary variables
keep mv005 mv106 mv012 mv130 mv304_01-mv304_20 sex
rename m* *
append using `temp'


******* LABEL VARIABLES ***********
label define sex 0 "female" 1 "male"
label values sex sex 
* Note: It is difficult to determine which methods each question
* refers to as they are not labeled and don't appear to follow the
* same order as in the questionnaire.
rename v012 age
rename v106 education
generate religion = 0
replace religion = 1 if v130 == 1 | v130 == 2
replace religion = 2 if v130 == 3
replace religion = 3 if v130 > 3

generate christian = (religion == 1)
generate muslim = (religion == 2)
generate primary = (education == 1)
generate secondary = (education == 2)
generate higher = (education == 3)

* there are a few respondents which didn't answer these questions.  
* drop if respondent failed to answer any of the questions
local outcome_vars "v304_02 v304_06 v304_07 v304_08 v304_09 v304_13 v304_16"
egen to_drop = anymatch(`outcome_vars'), values(9)
drop if to_drop


save "$temp\DHS data for estimating covariance.dta", replace
