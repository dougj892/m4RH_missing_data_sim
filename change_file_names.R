# change names of simulated data to make it easier 
# to deal with them in Stata

setwd("H:/IHA/SHOPS/M+E/SHOPS M&E/2 Country and study-level/Studies/M4RH/Data for Monte Carlo Simulations/Simulated data")

all <- list.files()
mnar <- grep("MNAR*", all, value = TRUE)


for (file in mnar) {
  print(file)
  iter <- unlist(strsplit(file, " "))[2]
  print(iter)
  new_name <- print(paste("mnar_",iter, ".dta", sep = ""))
  file.rename(file, new_name)
}

