# SIMULATE DATA TO TEST WHETHER MULTIPLE IMPUTATION RECOVERS 
# TRUE 




# set paths and other housekeeping
temp <- "H:/IHA/SHOPS/M+E/SHOPS M&E/2 Country and study-level/Studies/M4RH/Data/Temp"
setwd(temp)
library(foreign)
library(mvtnorm)

# Read in data and output from multivariate probit model fit in Stata
mvp_corr <- as.matrix(read.table("mv probit correlation matrix.txt"))
df <- read.dta("DHS data for estimating covariance.dta")
mvp_beta <- as.matrix(read.table("mvp beta.txt"))
n <- nrow(df)

covars <- subset(df, select = c("age", "primary", "secondary", "higher", "christian", "muslim"))
covars$sex <- ifelse(df$sex=="male", 1, 0)
X <- cbind(as.matrix(covars),rep(1, n))