* test stata MI features

*** SET PATHS AND OTHER SETTINGS **** 
set more off
do "C:\Code\m4RH_missing_data_sim\set_paths.do"


use "$sim_data\\mcar_1.dta", clear
local vars "treat age primary secondary higher christian muslim sex"

tempfile temp
ice v304_02 v304_06 v304_07 v304_08 v304_09 v304_13 v304_16 age primary secondary higher christian muslim sex treat, saving(`temp') m(5)
use `temp'
mi import ice, imputed(v304_02 v304_06 v304_07 v304_08 v304_09 v304_13 v304_16)
mi passive: egen y_total = rowtotal(v304*)
mi estimate, vartable: reg y_total `vars'
matrix coeffs = e(b_mi)
local impact = coeffs[1,1]
matrix var = e(V_mi)
local impact_se = var[1,1]^.5

/*
mi set wide
mi register imputed v304_02 v304_06 v304_07 v304_08 v304_09 v304_13 v304_16
mi register regular age primary secondary higher christian muslim sex treat
mi impute mvn v304_02 v304_06 v304_07 v304_08 v304_09 v304_13 v304_16 = age primary secondary higher christian muslim sex treat, add(5)

