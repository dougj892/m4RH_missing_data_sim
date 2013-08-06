* 

*** SET PATHS AND OTHER SETTINGS **** 
set more off
do "C:\Code\m4RH_missing_data_sim\set_paths.do"


local vars "treat age primary secondary higher christian muslim sex"
local num_data 50
local num_impute 10

*** RUN A BASIC REGRESSION ON COMPLETE DATA TO VERIFY 
matrix define comp = (0,0)
forvalues i = 1(1)`num_data' {
	disp as error "Running results for comp_`i'"
	use "$sim_data\\comp_`i'.dta", clear
	egen y_total = rowtotal(v304*)
	quietly reg y_total `vars'
	local impact = _b[treat]
	local impact_se = _se[treat]
	matrix comp = (comp \ `impact', `impact_se')
}
mat2txt, matrix(comp) saving("$temp\comp.txt") replace

*** MCAR WITH ICE
matrix define mcar_ice = (0,0)
forvalues i = 1(1)`num_data' {
	disp as error "Running results for mcar_`i' with ice"
	use "$sim_data\\mcar_`i'.dta", clear
	
	tempfile temp
	ice v304_02 v304_06 v304_07 v304_08 v304_09 v304_13 v304_16 age primary secondary higher christian muslim sex treat, saving(`temp') m(`num_impute')
	use `temp'
	mi import ice, imputed(v304_02 v304_06 v304_07 v304_08 v304_09 v304_13 v304_16)
	mi passive: egen y_total = rowtotal(v304*)
	mi estimate: reg y_total `vars'
	matrix coeffs = e(b_mi)
	local impact = coeffs[1,1]
	matrix var = e(V_mi)
	local impact_se = var[1,1]^.5
	matrix mcar_ice = (mcar_ice \ `impact', `impact_se')
}
mat2txt, matrix(mcar_ice) saving("$temp\mcar_ice.txt") replace


*** MCAR WITH MULTIVARIATE NORMAL IMPUTATION
matrix define mcar_mvn = (0,0)
forvalues i = 1(1)`num_data' {
	disp as error "Running results for mcar_`i' with multivariate normal"
	use "$sim_data\\mcar_`i'.dta", clear
	
	mi set wide
	mi register imputed v304_02 v304_06 v304_07 v304_08 v304_09 v304_13 v304_16
	mi register regular age primary secondary higher christian muslim sex treat
	mi impute mvn v304_02 v304_06 v304_07 v304_08 v304_09 v304_13 v304_16 = age primary secondary higher christian muslim sex treat, add(`num_impute')

	mi passive: egen y_total = rowtotal(v304*)
	mi estimate: reg y_total `vars'
	matrix coeffs = e(b_mi)
	local impact = coeffs[1,1]
	matrix var = e(V_mi)
	local impact_se = var[1,1]^.5
	matrix mcar_mvn = (mcar_mvn \ `impact', `impact_se')
}
mat2txt, matrix(mcar_mvn) saving("$temp\mcar_mvn.txt") replace


*** MNAR WITH ICE
matrix define mnar_ice = (0,0)
forvalues i = 1(1)`num_data' {
	disp as error "Running results for mnar_`i' with ice"
	use "$sim_data\\mnar_`i'.dta", clear
	
	tempfile temp
	ice v304_02 v304_06 v304_07 v304_08 v304_09 v304_13 v304_16 age primary secondary higher christian muslim sex treat, saving(`temp') m(`num_impute')
	use `temp'
	mi import ice, imputed(v304_02 v304_06 v304_07 v304_08 v304_09 v304_13 v304_16)
	mi passive: egen y_total = rowtotal(v304*)
	mi estimate: reg y_total `vars'
	matrix coeffs = e(b_mi)
	local impact = coeffs[1,1]
	matrix var = e(V_mi)
	local impact_se = var[1,1]^.5
	matrix mnar_ice = (mnar_ice \ `impact', `impact_se')
}
mat2txt, matrix(mnar_ice) saving("$temp\mnar_ice.txt") replace


*** MNAR WITH MULTIVARIATE NORMAL IMPUTATION
matrix define mnar_mvn = (0,0)
forvalues i = 1(1)`num_data' {
	disp as error "Running results for mnar_`i' with multivariate normal"
	use "$sim_data\\mnar_`i'.dta", clear
	
	mi set wide
	mi register imputed v304_02 v304_06 v304_07 v304_08 v304_09 v304_13 v304_16
	mi register regular age primary secondary higher christian muslim sex treat
	mi impute mvn v304_02 v304_06 v304_07 v304_08 v304_09 v304_13 v304_16 = age primary secondary higher christian muslim sex treat, add(`num_impute')

	mi passive: egen y_total = rowtotal(v304*)
	mi estimate: reg y_total `vars'
	matrix coeffs = e(b_mi)
	local impact = coeffs[1,1]
	matrix var = e(V_mi)
	local impact_se = var[1,1]^.5
	matrix mnar_mvn = (mnar_mvn \ `impact', `impact_se')
}
mat2txt, matrix(mnar_mvn) saving("$temp\mnar_mvn.txt") replace


