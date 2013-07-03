# Test approaches to missing data in m4RH
The code in this repository attempts to test the effectiveness of two different methods for dealing with missing data in the m4RH randomized evaluation: multiple imputation and full information maximum likelihood.

## What each file does
1. Create DHS data for estimating covariance matrix -- This do file takes the Kenya DHS dataset and creates a small dataset with just urban Kenyans and a few variables
2. fit model -- This do file fits a multivariate probit model and a linear SUREG model to the dataset created in step one and then saves the error covariance matrices to separate files.
3. inspect matrices -- This script just transforms the SUREG error covariance matrix into a correlation matrix for easier comparison with the error covariance matrix from the multivariate probit model
4. monte carlo -- This is the main script in the repository.  It takes the data and parameter estimates output by the do files and performs monte carlo simulations to test the performance of multiple imputation and FIML.


## Notes on analysis
- Having trouble achieving convergence with package mi in R.  In addition, it is unclear how to specify that the treatment status variable should not be included in the imputation model.

## To do on FIML
- Add code to generate the predicted value of y_total under treatment and y_total under control for each iteration.  Then add code to derive confidence intervals from estimated full distribution
