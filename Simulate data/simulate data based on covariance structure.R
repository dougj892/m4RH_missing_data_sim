# SIMULATE DATA TO TEST WHETHER MULTIPLE IMPUTATION RECOVERS 
# TRUE 



# set paths and other housekeeping
remove(list = ls())
temp <- "H:/IHA/SHOPS/M+E/SHOPS M&E/2 Country and study-level/Studies/M4RH/Data/Temp"
setwd(temp)
library(foreign)
library(mvtnorm)
library(mi)

# Read in data and output from multivariate probit model fit in Stata
mvp_corr <- as.matrix(read.table("mv probit correlation matrix.txt"))
df <- read.dta("DHS data for estimating covariance.dta")
mvp_beta <- as.matrix(read.table("mvp beta.txt"))
n <- nrow(df)
# MV probit correlation matrix has zeroes in top half.  fix this.
mvp_corr <- mvp_corr + t(mvp_corr) - diag(7)


# Create matrix of covariates.  Note that the order of the covariates should match the 
# order of the covariates used when estimating the model in Stata so that the covariates
# match up with the appropriate betas. This means that constant term in X should be at the 
# end of the matrix
covars <- subset(df, select = c("age", "primary", "secondary", "higher", "christian", "muslim"))
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
  alpha <- rnorm(n, sd = .02)
  delta <- rnorm(7, mean = .1, sd = .01)
  delta
  treat_effect <- matrix(rep(alpha,7),n,7) + t(matrix(rep(delta, n),7,n))
  treat_mat <- matrix(rep(treat, 7),n,7)
  treat_effect <- treat_effect * treat_mat

  # generate random errors based on covariance matrix from mv provit fit in Stata
  errors <- rmvnorm(n, mean = rep(0,7), mvp_corr)
  
  # generate latent ys
  y_star <- X %*% t(mvp_beta) + treat_effect + errors
  y <- y_star >= 0
  # convert y from boolean to zeros and ones
  y <- y * 1 
  z <- list(y = y, treat = treat)
  z
}

num_iter <- 1
results <- data.frame(iter = seq(1, num_iter), 
                      impact_true = numeric(num_iter), std_err_true = numeric(num_iter),
                      impact_mcar = numeric(num_iter), std_err_mcar = numeric(num_iter))

remove_mcar <- function(y) {
  # randomly select p% of y values and replace with NA
  p <- .3
  remove <- matrix(rbinom(n*7, 1, p),n,7)
  y[remove == 1] <- NA
  y
}


for (iter in 1:num_iter) {
  sim_data <- gen_data()
  
  # generate results of simple regression of total answers correct on X and treat  
  y_total <- apply(sim_data$y, 1, sum)
  treat <- sim_data$treat
  model_df <- cbind(y_total, covars, treat)
  fit1 <- lm(y_total ~ age + primary + secondary + higher + christian + muslim + treat, data = model_df)
  results[iter, 2] <- coef(summary(fit1))["treat", 1]
  results[iter, 3] <- coef(summary(fit1))["treat", 2]
  
  # remove some data randomly (MCAR)
  mcar_y <- remove_mcar(sim_data$y)
  df_mcar <- data.frame(mcar_y, covars)
  
  # multiply impute the data using mi package with defaults
  # mi_settings <- mi.info(df_mcar)
  # mi_settings$include[15] <- FALSE
  df_mcar_mi <- mi(df_mcar)
  fit_mcar_mi <- lm.mi(y_total ~ age + primary + secondary + higher + christian + muslim + treat, mi.object = df_mcar_mi)
  results[iter, 4] <- coef(summary(fit1))["treat", 1]
  results[iter, 5] <- coef(summary(fit1))["treat", 2]
}






