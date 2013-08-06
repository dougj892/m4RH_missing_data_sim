/* 
Estimate covariance structure of error terms in final specification
Note: The ado programs "mvprobit" and "mat2txt" must be installed to run this do file.
*/

do "C:\Code\m4RH_missing_data_sim\set_paths.do"

use "$input\DHS data for estimating covariance.dta", clear

* Note: I have no idea which methods these variables refer to
* but knowledge of them seems to be close to 50% which is what we
* expect for our own outcome variables
local outcome_vars "v304_02 v304_06 v304_07 v304_08 v304_09 v304_13 v304_16"
local covariates "age primary secondary higher christian muslim sex"


* Fit a multivariate probit model to the data
mvprobit (v304_02 `covariates') ///
	(v304_06 `covariates') ///
	(v304_07 `covariates') ///
	(v304_08 `covariates') ///
	(v304_09 `covariates') ///
	(v304_13 `covariates') ///
	(v304_16 `covariates')
estimates store mvp_ests

* Save the estimated error correlation matrix as a Stata matrix
* Note that I only populate the lower half of the matrix
matrix define mvp_sig = (1,0,0,0,0,0,0 ///
	\e(rho21),1,0,0,0,0,0 ///
	\e(rho31),e(rho32),1,0,0,0,0 ///
	\e(rho41),e(rho42),e(rho43),1,0,0,0  ///
	\e(rho51),e(rho52),e(rho53),e(rho54),1,0,0  ///
	\e(rho61),e(rho62),e(rho63),e(rho64),e(rho65),1,0  ///
	\e(rho71),e(rho72),e(rho73),e(rho74),e(rho75),e(rho76),1)

matrix define mvp_sig_se = (1,0,0,0,0,0,0 ///
	\e(serho21),1,0,0,0,0,0 ///
	\e(serho31),e(serho32),1,0,0,0,0 ///
	\e(serho41),e(serho42),e(serho43),1,0,0,0  ///
	\e(serho51),e(serho52),e(serho53),e(serho54),1,0,0  ///
	\e(serho61),e(serho62),e(serho63),e(serho64),e(serho65),1,0  ///
	\e(serho71),e(serho72),e(serho73),e(serho74),e(serho75),e(serho76),1)

* Save the estimated coefficients as a matrix
matrix define b = e(b)
matrix define mvp_beta = (b[1,1..8]\b[1,9..16]\b[1,17..24]\b[1,25..32]\b[1,33..40]\b[1,41..48]\b[1,49..56])
matrix rownames mvp_beta = v304_02 v304_06 v304_07 v304_08 v304_09 v304_13 v304_16
	
* Fit a SUREG model to the data and save the estimated error covariance matrix and coefficients as Stata matrices
sureg (v304_02 `covariates') ///
	(v304_06 `covariates') ///
	(v304_07 `covariates') ///
	(v304_08 `covariates') ///
	(v304_09 `covariates') ///
	(v304_13 `covariates') ///
	(v304_16 `covariates')
estimates store sureg_ests
matrix define sureg_sig = e(Sigma)
matrix define c = e(b)
matrix define sureg_beta = (c[1,1..8]\c[1,9..16]\c[1,17..24]\c[1,25..32]\c[1,33..40]\c[1,41..48]\c[1,49..56])
matrix rownames sureg_beta = v304_02 v304_06 v304_07 v304_08 v304_09 v304_13 v304_16

* Output the stored matrices as tab delimited files for use in the R programs
mat2txt, matrix(mvp_sig) saving("$temp\prob_corr_mat.txt") replace
mat2txt, matrix(mvp_sig_se) saving("$temp\mv probit correlation matrix se estimates.txt") replace
mat2txt, matrix(sureg_sig) saving("$temp\SUREG covariance matrix.txt") replace
mat2txt, matrix(mvp_beta) saving("$temp\mvp beta.txt") replace
mat2txt, matrix(sureg_beta) saving("$temp\sureg beta.txt") replace
