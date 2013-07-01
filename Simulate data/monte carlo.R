# SIMULATE DATA TO TEST WHETHER MULTIPLE IMPUTATION RECOVERS 
# TRUE 



# set paths and other housekeeping
remove(list = ls())
temp <- "H:/IHA/SHOPS/M+E/SHOPS M&E/2 Country and study-level/Studies/M4RH/Prior Usage Data/Temp"
setwd(temp)
library(foreign)
library(mvtnorm)
library(mi)
library(Amelia)
library(Zelig)


# Read in data and output from multivariate probit model fit in Stata
mvp_corr <- as.matrix(read.table("mv probit correlation matrix.txt"))
df <- read.dta("DHS data for estimating covariance.dta")
mvp_beta <- as.matrix(read.table("mvp beta.txt"))
n <- nrow(df)
# MV probit correlation matrix has zeroes in top half.  fix this.
mvp_corr <- mvp_corr + t(mvp_corr) - diag(7)


# Create matrix of covariates.  Note that the order of the covariates should match the 
# order of the covariates used when estimating the model in Stata so that the covariates
# match up with the appropriate betas. This means that the constant term in X should be the last 
# column of the matrix
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
  delta <- rnorm(7, mean = .1, sd = .05)
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
                      impact_mcar = numeric(num_iter), std_err_mcar = numeric(num_iter),
                      impact_mnar = numeric(num_iter), std_err_mnar = numeric(num_iter))

remove_mcar <- function(y) {
  # randomly select p% of y values and replace with NA
  p <- .3
  remove <- matrix(rbinom(n*7, 1, p),n,7)
  y[remove == 1] <- NA
  y
}

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
  threshold <- quantile(missing_star, probs = .7)
  y[missing_star > threshold] <- NA
  y
}


for (iter in 1:num_iter) {
  sim_data <- gen_data()
  # y <- remove_mnar(sim_data$y)
  # sum(is.na(y)) / length(y)
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
  
  # multiply impute MCAR data using amelia package with defaults
  nominal_variables <- names(df_mcar)[!names(df_mcar)=="age"]
  df_mcar_mi <- amelia(df_mcar, m = 5, noms = nominal_variables)
  df_mcar_mi <- transform(df_mcar_mi, y_total = v304_02+v304_06+v304_07+v304_08+v304_09+v304_13+v304_16) 
  fit_mcar <- zelig(y_total ~ age + primary + secondary + higher + christian + muslim + treat,
                    data = df_mcar_mi, model = "ls")
  results[iter, 4] <- coef(summary(fit_mcar))["treat", 1]
  results[iter, 5] <- coef(summary(fit_mcar))["treat", 2]
  
  # remove some data randomly (MNAR)
  mnar_y <- remove_mnar(sim_data$y)
  df_mnar <- data.frame(mnar_y, covars)

  # multiply impute MNAR data using amelia package with defaults
  df_mnar_mi <- amelia(df_mnar, m = 5, noms = nominal_variables)
  df_mnar_mi <- transform(df_mnar_mi, y_total = v304_02+v304_06+v304_07+v304_08+v304_09+v304_13+v304_16) 
  fit_mnar <- zelig(y_total ~ age + primary + secondary + higher + christian + muslim + treat,
                    data = df_mnar_mi, model = "ls")
  results[iter, 6] <- coef(summary(fit_mnar))["treat", 1]
  results[iter, 7] <- coef(summary(fit_mnar))["treat", 2]
}






