* 

*** SET PATHS AND OTHER SETTINGS **** 
set more off
do "C:\Code\m4RH_missing_data_sim\set_paths.do"

*** CREATE LIST OF COMPLETE, MCAR, AND MNAR DATASETS ***
local complete: dir "$sim_data" files "comp*.dta"
local mcar: dir "$sim_data" files "mcar*.dta"
local mnar: dir "$sim_data" files "mnar*.dta"
local vars "treat age primary secondary higher christian muslim sex"

disp `complete'
*** replace complete with single file name for testing purposes ***
local first_file "comp_1.dta"
disp "`first_file'"


*** RUN A BASIC REGRESSION ON COMPLETE DATA TO VERIFY 
** R CODE:   fit1 <- lm(y_total ~ age + primary + secondary + higher + christian + muslim + treat + sex, data = model_df)
foreach file of local first_file {
	disp as error "Running results for `file'"
	use "$sim_data\\`file'", clear
	egen y_total = rowtotal(v304*)
	
	foreach var of local vars {
		egen `var'_std = std(`var')
	}
	reg y_total `vars'
	_b[treat]
}


