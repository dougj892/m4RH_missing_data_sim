# ???

# set paths
temp <- "H:/IHA/SHOPS/M+E/SHOPS M&E/2 Country and study-level/Studies/M4RH/Data/Temp"
setwd(temp)

# read in correlation matrix from mvprobit estimates
mvp_corr <- as.matrix(read.table("mv probit correlation matrix.txt"))

simulate_