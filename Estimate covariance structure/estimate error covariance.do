/* 
Estimate covariance structure of error terms in final specification
Note: The ado program "mat2txt" must be installed in order to save the matrices as text files.
*/

do "C:\Code\m4RH_missing_data_sim\set_paths.do"

use "$dhs\DHS data for estimating covariance.dta", clear

* Note: I have no idea which methods these variables refer to
* but knowledge of them seems to be close to 50% which is what we
* expect for our own outcome variables
local outcome_vars "v304_02 v304_06 v304_07 v304_08 v304_09 v304_13 v304_16"
local covariates "age primary secondary higher christian muslim sex"


* estimate error term covariance structure using mvprobit
mvprobit (v304_02 `covariates') ///
	(v304_06 `covariates') ///
	(v304_07 `covariates') ///
	(v304_08 `covariates') ///
	(v304_09 `covariates') ///
	(v304_13 `covariates') ///
	(v304_16 `covariates')
estimates store mvp_ests


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
	
* estimate error term covariance structure using sureg
sureg (v304_02 `covariates') ///
	(v304_06 `covariates') ///
	(v304_07 `covariates') ///
	(v304_08 `covariates') ///
	(v304_09 `covariates') ///
	(v304_13 `covariates') ///
	(v304_16 `covariates')
estimates store sureg_ests
matrix define sureg_sig = e(Sigma)

mat2txt, matrix(mvp_sig) saving("$temp\mv probit correlation matrix.txt")
mat2txt, matrix(mvp_sig_se) saving("$temp\mv probit correlation matrix se estimates.txt")
mat2txt, matrix(sureg_sig) saving("$temp\SUREG covariance matrix.txt")


