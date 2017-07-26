
# map.R

# Geographical Visualisation of microsynthesis results

# Ensure your working directory is the project root so that the data files can be found, e.g.
#setwd("~/dev/usim_demog/")

# load dependencies
library(data.table)
library(sf)
library(leaflet)

# common functions
source("./common/map.R")
source("./common/utils.R")


# Load the household synthetic population
synhomes = as.data.table(read.csv("./households/data/synhomes.csv", stringsAsFactors = F))

msoas = unique(synpop$MSOA)

density = data.table(MSOA=msoas, Value=rep(-1, length(msoas)))

# calc housing density
for (msoa in msoas) {

  density[MSOA==msoa]$Value = mean(synhomes[MSOA==msoa & People>0]$People / synhomes[MSOA==msoa & People>0]$Rooms) 
}

genMap(growth)

