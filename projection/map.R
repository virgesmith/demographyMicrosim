
# map.R

# Geographical Visualisation of dynamic microsimulation results

# Ensure your working directory is the project root so that the data files can be found, e.g.
#setwd("~/dev/usim_demog/")

# load dependencies
library(data.table)
library(sf)
library(leaflet)

# utility functions
source("./common/utils.R")

# load MSOA shapefiles into global variable
msoaBounds=st_read("./common/data/msoa.shp",stringsAsFactors = F)

# function that maps data supplied
# data should be a data.table (or data.frame) with:
# - a column "MSOA" containing the MSOA code
# - a column "Value" containing numeric data to be plotted
genMap = function(data, minColour = "#0080FF", maxColour= "#FF8000") {
  map = leaflet() %>% addTiles(urlTemplate = "//a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png")#, options=tileOptions(opacity=0.5))
  # Use of these tiles requires an acknowledgement
  print("Map tiles by Carto, under CC BY 3.0. Data by OpenStreetMap, under ODbL")
  
  pal=colorNumeric(c(minColour,maxColour),c(min(data$Value),max(data$Value)))
  
  map = map %>% addPolygons(data = msoaBounds[msoaBounds$code==data$MSOA,], fillColor = pal(data$Value), fillOpacity=.2, weight=1, color = "black")
  
  return(map)
}


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

