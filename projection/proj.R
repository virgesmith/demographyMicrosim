# proj.R population projection using a precomputed synthetic population of Tower Hamlets from 2011 census data

# uses fertility and mortality data by local authority, age and ethnicity

# note the following assumptions:
# - births are a single child only (assumed that twins etc are accounted for in the fertility rate)
# - ethnicity of newborn is the same as mother (in the absence of other information)
# - the death rate for age zero is the average of the rate of stillbirths and deaths under one year

# load dependencies
library(data.table)

# Ensure your working directory is the project root so that the data files can be found, e.g.
#setwd("~/dev/usim_demog/")

# Load the base population
synpop = as.data.table(read.csv("./projection/data/synpop.csv", stringsAsFactors = F))

# TODO fertility rates

# Load mortality rates for Tower Hamlets
mortality=as.data.table(read.csv("./projection/data/TowerHamletsMortality.csv", stringsAsFactors = F))

# a status column will be added to the population
# status codes (chosen so that summing will give new population):
# 1: no change
# 2: gave birth
# 0: died


# perform the microsimulation
print(paste("2011 population",nrow(synpop)))
for (year in 2012:2013) {
  n = nrow(synpop)
  # add/reset status
  synpop$Status = rep(1,n)
  # fetility and mortality are independent so need different draws
  xf = runif(n) # fertility: n uniform random variates in (0,1)
  xm = runif(n) # mortality: n uniform random variates in (0,1)
  r=rep(-1,n)
  for (i in 1:n) {
    # births
    # TODO
    
    # deaths
    # pick correct mortality rate for sex, age and ethnicity
    r = mortality[Sex==synpop[i,]$Sex & Age==synpop[i,]$Age & Ethnicity==synpop[i,]$Ethnicity]$Rate
    # death occurs when the random variate is lower than the fertility rate
    if (r >= xm[i]) {
      synpop[i,]$Status = 0
    }
  }
  # add newborns
  # TODO
  
  # remove the deceased
  synpop = synpop[Status != 0]
  print(paste(year,"population",nrow(synpop)))

  # age the population (capping at 85+)
  synpop$Age = synpop$Age + 1
  synpop[Age>85]$Age=85
}
