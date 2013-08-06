# compare covariance matrix from sureg with correlation matrix from mvprobit

# set paths
temp <- "H:/IHA/SHOPS/M+E/SHOPS M&E/2 Country and study-level/Studies/M4RH/Data/Temp"
setwd(temp)

# read in matrices
mvp_corr <- as.matrix(read.table("mv probit correlation matrix.txt"))
mvp_corr_se <- as.matrix(read.table("mv probit correlation matrix se estimates.txt"))
sureg_cov <- as.matrix(read.table("SUREG covariance matrix.txt"))

# create sureg correlation matrix based on covariance matrix
sureg_corr <- matrix(rep(0,49),nrow = 7, ncol =7)
for (i in 1:7) {
  for (j in 1:i) {
    sureg_corr[i,j] <- sureg_cov[i,j] / (sureg_cov[i,i]^.5 * sureg_cov[j,j]^.5) 
  }
}