
# map.R

# Geographical Visualisation of dynamic microsimulation results

# Ensure your working directory is the project root so that the data files can be found, e.g.
#setwd("~/dev/usim_demog/")

# load dependencies
library(data.table)
library(sf)
library(leaflet)

# common functions
source("./common/map.R")
source("./common/utils.R")


# Load the base population
synpop = as.data.table(read.csv("./projection/data/synpop.csv", stringsAsFactors = F))
synpop2021 = as.data.table(read.csv("./projection/data/synpop2021.csv", stringsAsFactors = F))

msoas = unique(synpop$MSOA)
ethnicities = unique(synpop$Ethnicity)

div11 = data.table(MSOA=msoas, Value=rep(-1, length(msoas)))
div21 = data.table(MSOA=msoas, Value=rep(-1, length(msoas)))
growth = data.table(MSOA=msoas, Value=rep(-1, length(msoas)))

# calc diversity
for (msoa in msoas) {
  pops11 = rep(-1, length(ethnicities)) 
  pops21 = rep(-1, length(ethnicities)) 
  for (j in 1:length(ethnicities)) {
    pops11[j] = nrow(synpop[MSOA==msoa & Ethnicity==ethnicities[j]])
    pops21[j] = nrow(synpop2021[MSOA==msoa & Ethnicity==ethnicities[j]])
  }
  div11[MSOA==msoa]$Value = diversityCoeff(pops11)
  div21[MSOA==msoa]$Value = diversityCoeff(pops21)
  growth[MSOA==msoa]$Value = nrow(synpop2021[MSOA==msoa]) / nrow(synpop[MSOA==msoa]) - 1.0
}

genMap(growth)

