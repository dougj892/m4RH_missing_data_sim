# This script performs Monte Carlo simulations to estimate the performance of multiple imputation and full information
# maximum likelihood on data of the sort we are likely to receive as part of the m4RH study.
# 
# The script first imports a dataset of covariates from a sample of DHS respondents along with estimated coefficients
# and a erro correlation matrix from a multivariate probit model fit to this data.  (For more details, see the Stata do
# file "fit model.do").  Then the following steps are performed:
#   1. Generate random outcome data
#   2. Estimate the impact of the treatment using this complete dataset
#   3. Remove some of the instances of the outcome variables according to a missing completely at random pattern
#   4. Fill in the missing data using multiple imputation and refit the model
#   5. Fit this dataset with missing data using FIML
#   6. Take the complete dataset and remove some of the instances of the outcome variables according to a missing not at random pattern
#   7. Fill in the missing data using multiple imputation and refit the model
#   8. Fit this dataset with missing data using FIML
#   
# Steps 1 through 8 are repeated several times and the estimates of impact and standard errors from each iteration are stored
# in the dataframe "results".  For each iteration, the complete data and the MCAR and MNAR datasets are exported as Stata datasets.
# This is so that we can also use Stata to perform MI on the same datasets. 
# 
# This script does not attempt to remove some data according to a missing at random pattern.  The reason for this is that generating 
# a missing at random missingness pattern which is non-trivial and the true data are unlikely to exhibit this pattern. 
# 
# Currently the FIML model is taking a humongous amount of time to run so I haven't actually checked the output from this model.
# In addition, I am unable to get the MI package to converge.  Unclear what is going wrong here.
# 
# Package dependencies: mvtnorm, mi, Amelia, Zelig, rjags
# 
# To run this on AWS do the following:
# 1. Upload the DHS data used as a basis for the Monte Carlo simulations
# 2. Create a folder to output the Stata datasets to
# 3. Change the paths below as appropriate
# 4. Load all packages



# set paths and other housekeeping
remove(list = ls())
set.seed(8675209)
# the two lines below must be modified to work on a different system
df_dir <- "H:/IHA/SHOPS/M+E/SHOPS M&E/2 Country and study-level/Studies/M4RH/Data for Monte Carlo Simulations"
stata_output <- "H:/IHA/SHOPS/M+E/SHOPS M&E/2 Country and study-level/Studies/M4RH/Data for Monte Carlo Simulations/Simulated data"
setwd(df_dir)

# load packages
library(foreign)
library(mvtnorm)
# library(mi)
library(Amelia)
library(Zelig)
# library(rjags)

# Read in data and output from multivariate probit model fit in Stata
mvp_corr <- as.matrix(read.table("prob_corr_mat.txt"))
df <- read.dta("dhs_data.dta")
mvp_beta <- as.matrix(read.table("mvp beta.txt"))
n <- nrow(df)
# MV probit correlation matrix has zeroes in top half.  fix this.
mvp_corr <- mvp_corr + t(mvp_corr) - diag(7)


# Split out the covariates from the rest of the dataset and create a separate dataframe of just covariates.  
# Note that the order of the covariates should match the 
# order of the covariates used when estimating the model in Stata so that the covariates
# match up with the appropriate betas. This means that the constant term in X should be the last 
# column of the matrix
covars <- subset(df, select = c("age", "primary", "secondary", "higher", "christian", "muslim"))
# recode "sex" from a string variable to a binary variable
covars$sex <- ifelse(df$sex=="male", 1, 0)
X <- cbind(as.matrix(covars),rep(1, n))


# generate random data
gen_data <- function() {
  # for each person, flip a coin to determine if they are in treatment or not
  # note: would be slightly better to randomly select exactly 1/2 of the sample but
  # i'm lazy and that is more difficult
  treat <- rbinom(n,1,.5)
  
  # generate a random treatment effect for each of the treated units
  # equal to a random term for each individual and a random effect for each question
  # In other words, the treatment effect for question j for individual i, delta_ij = alpha_i + beta_j 
  # where alpha ~N(0, .02^2) and beta ~ N(.1, .05^2)
#   alpha <- rnorm(n, sd = .02)
#   delta <- rnorm(7, mean = .1, sd = .05)
#   delta
#   treat_effect <- matrix(rep(alpha,7),n,7) + t(matrix(rep(delta, n),7,n))
#   treat_mat <- matrix(rep(treat, 7),n,7)
#   treat_effect <- treat_effect * treat_mat

  
  # generate a random treatment effect equal to the following
  # tao_i = Covars_const_i * beta + epsilon_i + alpha_i
  # where tao_i is 1 x J, Covars_constant is 1 x (K+1), beta is (K+1) x (J), 
  # epsilon is 1 x J and alpha_i  is 1 x J.  J is the number of outcome vars and K is the number 
  # of covariates.  Covars_constant is the covariates plus a vector of 1s.  Alpha_i is included because
  # I don't have enough intuition to guarantee that drawing epsilon from a multivariate normal distribution
  # will ensure that there is enough correlation between outcome vars
  covars_const <- cbind(covars, rep(1,n))
  k <- length(covars_const)
  beta <- matrix(rnorm(k*7, mean = .1, sd = .3), k , 7)
  # make the beta corresponding to age smaller than the others since it can take on larger values
  temp <- diag(k)
  temp[1,1] <- .1
  beta  <- temp %*% beta
  epsilon <- matrix(rnorm(n*7),n,7)
  alpha <- rnorm(n, sd = .02)
  treat_effect <- as.matrix(covars_const) %*% beta + alpha
  treat_mat <- matrix(rep(treat, 7),n,7)
  treat_effect <- treat_effect * treat_mat
  
  # generate random errors based on covariance matrix from mv probit fit in Stata
  errors <- rmvnorm(n, mean = rep(0,7), mvp_corr)
  
  # generate latent ys
  y_star <- X %*% t(mvp_beta) + treat_effect + errors
  y <- y_star >= 0
  # convert y from boolean to zeros and ones
  y <- y * 1 
  z <- list(y = y, treat = treat)
  z
}

# This function takes a matrix of outcome variables and randomly removes p% of these values
remove_mcar <- function(y) {
  # randomly select p% of y values and replace with NA
  p <- .3
  remove <- matrix(rbinom(n*7, 1, p),n,7)
  y[remove == 1] <- NA
  y
}

# This function takes a matrix of outcome variables and removes p% of these values according a MNAR pattern
# The model for the missingness pattern is pretty similar to the model for the treatment effect. 

remove_mnar <- function(y) {
  df3 <- data.frame(y, covars)
  k <- length(df3)
  beta <- matrix(rnorm(k*7), k , 7)
  # make the beta corresponding to age smaller than the others since it can take on larger values
  temp <- diag(14)
  temp[8,8] <- .1
  beta  <- temp %*% beta
  epsilon <- matrix(rnorm(n*7),n,7)
  missing_star <- as.matrix(df3) %*% beta + epsilon
  thresholds <- apply(missing_star, 2, function(x) quantile(x, probs = .7))
  threshmat <- t(matrix(rep(thresholds,3688),7,3688))
  y[missing_star > threshmat] <- NA
  dummy <- apply(y, 2, function(x) sum(is.na(x)))
  y
}

# this function performs FIML on the data.  Safe to ignore for now.
test_fiml <- function(df) {
  # generate constants 
  N <- nrow(df)
  # J is the number of outcome variables
  J <- 7
  # K is the number of coviarates
  K <- 7
  ID <- diag(J)
  
  # setting ID matrix to be smaller.  hopefully by assigning a strong prior on Tau
  # we can speed convergence
  ID <- ID / 10
  degrees <- J + 1
  # throw the y variables into a matrix
  y_var_names <- grep("v304*", names(df), value = TRUE)
  y <- as.matrix(subset(df, select = y_var_names))
    
  # compile data into a list to pass to jags.model
  attach(df)
  data4jags2 <- list("age" = age, "primary" = primary, "secondary" = secondary, 
                     "higher" = higher, "christian" = christian,  "muslim" = muslim,
                     "treat" = treat, "sex" = sex, 'y' = y, 'N' = N, 'J' = J, 'ID' = ID, 'degrees' = degrees)
  
  # We set initial values of Z to be y - .5 (i.e. Z is -.5 if y is 0 and .5 if y is 1)
  # for the purposes of setting the initial values of Z we need to first replace all missing values in y
  y_filled_in <- y
  y_filled_in[is.na(y_filled_in)] <- 0
  
  # create function to randomly pick initial values for parameters
  jags_inits <- function() {
    list(a = rnorm(J), b = rnorm(J), c = rnorm(J), d = rnorm(J), e = rnorm(J), 
         f = rnorm(J), g = rnorm(J), h = rnorm(J), k = rnorm(J), Z = (y_filled_in-.5))
  }
  
  # fit the model using JAGS and perform burnin
  dir <- "C:/Code/m4RH_missing_data_sim/Simulate data"
  setwd(dir)
  fitted_model <- jags.model('m4rh_mvprobit.bug', data = data4jags2, inits = jags_inits, n.chains = 4, n.adapt = 1000)
  
  # run MCMC and save output
  out <- coda.samples(model = fitted_model, variable.names = c("e", "diff_total"), n.iter = 1000, thin = 5)
}

# set the number of times the whole cycle of generating and fitting data is repeated
num_iter <- 3
# create an empty dataframe to populate with results later
results <- data.frame(iter = seq(1, num_iter), 
                      impact_true = numeric(num_iter), std_err_true = numeric(num_iter),
                      impact_mcar = numeric(num_iter), std_err_mcar = numeric(num_iter),
                      impact_mnar = numeric(num_iter), std_err_mnar = numeric(num_iter))


# This the meat of the script.  It calls the functions defined above to 
# perform MI and model fitting on a complete randomly generated dataset, 
# the same dataset with observations MCAR, and the same dataset with observations MNAR 
# for num_iter number of times.
setwd(stata_output)
for (iter in 1:num_iter) {
  # generate simulated data
  sim_data <- gen_data()
  # generate results of simple regression of total answers correct on X and treat  
  y_total <- apply(sim_data$y, 1, sum)
  treat <- sim_data$treat
  model_df <- cbind(y_total, covars, treat)
  # export the full, complete generated to Stata for use later
  write.dta(cbind(sim_data$y,covars, treat), paste("comp_", iter, ".dta", sep =""))
  fit1 <- lm(y_total ~ age + primary + secondary + higher + christian + muslim + treat + sex, data = model_df)
  results[iter, 2] <- coef(summary(fit1))["treat", 1]
  results[iter, 3] <- coef(summary(fit1))["treat", 2]
  
  # remove some data randomly (MCAR)
  mcar_y <- remove_mcar(sim_data$y)
  df_mcar <- data.frame(mcar_y, covars, treat)
  write.dta(df_mcar, paste("mcar_", iter, ".dta", sep =""))
  
  # multiply impute MCAR data using amelia package with defaults
  nominal_variables <- names(df_mcar)[!names(df_mcar)=="age"]
  df_mcar_mi <- amelia(df_mcar, m = 10, noms = nominal_variables)
  df_mcar_mi <- transform(df_mcar_mi, y_total = v304_02+v304_06+v304_07+v304_08+v304_09+v304_13+v304_16) 
  fit_mcar <- zelig(y_total ~ age + primary + secondary + higher + christian + muslim + treat + sex,
                    data = df_mcar_mi, model = "ls")
  results[iter, 4] <- coef(summary(fit_mcar))["treat", 1]
  results[iter, 5] <- coef(summary(fit_mcar))["treat", 2]
  
  # Note: There is some slightly repetitive code below.  This is because Zelig cannot be called from within a function due to some weird error
  # remove some data randomly (MNAR)
  mnar_y <- remove_mnar(sim_data$y)
  df_mnar <- data.frame(mnar_y, covars, treat)
  write.dta(df_mnar, paste("mnar_", iter, ".dta", sep =""))

  # multiply impute MNAR data using amelia package with defaults
  df_mnar_mi <- amelia(df_mnar, m = 10, noms = nominal_variables)
  df_mnar_mi <- transform(df_mnar_mi, y_total = v304_02+v304_06+v304_07+v304_08+v304_09+v304_13+v304_16) 
  fit_mnar <- zelig(y_total ~ age + primary + secondary + higher + christian + muslim + treat + sex,
                    data = df_mnar_mi, model = "ls")
  results[iter, 6] <- coef(summary(fit_mnar))["treat", 1]
  results[iter, 7] <- coef(summary(fit_mnar))["treat", 2]
  
  
  # multiply impute the data using mi package with defaults
  #  Currently, this is failing to converge.  Unclear what the problem is.
#   mi_settings <- mi.info(df_mcar)
#   mi_settings$include[15] <- FALSE
#   df_mcar_mi_gelman <- mi(df_mcar)
#   fit_mcar_mi_gelman <- lm.mi(y_total ~ age + primary + secondary + higher + christian + muslim + treat, mi.object = df_mcar_mi_gelman)
  
  # warning: the line below runs MCMC on the full information maximum likelihood model which, currently, takes forever to run
  # output <- test_fiml(df_mcar)

}
# png("convergence_graphs.png")
# plot(output)
# dev.off()
write.csv(results, file = paste("results_", "Date", Sys.Date(), ".csv"))

