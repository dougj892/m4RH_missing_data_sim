# ???

# set paths and other housekeeping
temp <- "H:/IHA/SHOPS/M+E/SHOPS M&E/2 Country and study-level/Studies/M4RH/Data/Temp"
setwd(temp)
library(foreign)

# Read in data and output from multivariate probit model fit in Stata
mvp_corr <- as.matrix(read.table("mv probit correlation matrix.txt"))
df <- read.dta("DHS data for estimating covariance.dta")
mvp_beta <- as.matrix(read.table("mvp beta.txt"))

# the following function generates random data
generate_data <- function() {
  temp <- df
  temp$treat <- rbinom(nrow(temp),1,.5)
  
  
  
  temp
}

generate_date