# disp2.R population projection using a precomputed synthetic population of Tower Hamlets from 2011 census data

# visualisations for the projection microsimulation

# Tower Hamlets = E09000030

# load dependencies
library(data.table)
library(sf)

# TODO move to more appropriate file
diversityCoeff=function(pop) {
 # using 1-var(pop/sum(pop))) 
 # if pop all equal, returns 1 (max diversity)
 # if pop all one ethnicity, return 0
 return(1-var(pop/sum(pop))*length(pop))  
}

# MSOA shapefiles
source("../Mistral/src/Geography.R")

#allmsoas=getMSOABoundaries()
#msoas=allmsoas[grepl("Tower Hamlets", allmsoas$name),]
#st_write(msoas,"./common/data/msoa.shp")
# Load MSOA shapefile for Tower Hamlets
msoaBounds=st_read("./common/data/msoa.shp",stringsAsFactors = F)

# Ensure your working directory is the project root so that the data files can be found, e.g.
#setwd("~/dev/usim_demog/")

# Load the base population
synpop = as.data.table(read.csv("./projection/data/synpop.csv", stringsAsFactors = F))
synpop2021 = as.data.table(read.csv("./projection/data/synpop2021.csv", stringsAsFactors = F))

msoas = unique(synpop$MSOA)
ethnicities = unique(synpop$Ethnicity)

div11 = rep(-1, length(msoas))
div21 = rep(-1, length(msoas))

# calc diversity
for (i in 1:length(msoas)) {
  pops11 = rep(-1, length(ethnicities)) 
  pops21 = rep(-1, length(ethnicities)) 
  for (j in 1:length(ethnicities)) {
    pops11[j] = nrow(synpop[MSOA==msoas[i] & Ethnicity==ethnicities[j]])
    pops21[j] = nrow(synpop2021[MSOA==msoas[i] & Ethnicity==ethnicities[j]])
  }
  div11[i] = diversityCoeff(pops11)
  div21[i] = diversityCoeff(pops21)
}

# calc growth 
growth = rep(-1.0, length(msoas))

for (i in 1:length(msoas)) {
  growth[i] = nrow(synpop2021[MSOA==msoas[i]])/nrow(synpop[MSOA==msoas[i]]) - 1.0
}
#growth = nrow(synpop2021[MSOA==msoas])/nrow(synpop[MSOA==msoas]) - 1.0

library(leaflet)

#https://tiles.wmflabs.org/bw-mapnik/$%7Bz%7D/$%7Bx%7D/$%7By%7D.png
#http://a.tile.stamen.com/toner/$%7Bz%7D/$%7Bx%7D/$%7By%7D.png
#http://a.basemaps.cartocdn.com/light_all/$%7Bz%7D/$%7Bx%7D/$%7By%7D.png
div11map = leaflet() %>% addTiles(urlTemplate = "//a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png")#, options=tileOptions(opacity=0.5))
div21map = leaflet() %>% addTiles(urlTemplate = "//a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png")#, options=tileOptions(opacity=0.5))
divdeltamap = leaflet() %>% addTiles(urlTemplate = "//a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png")#, options=tileOptions(opacity=0.5))
growthmap = leaflet() %>% addTiles(urlTemplate = "//a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png")#, options=tileOptions(opacity=0.5))
# Use of these tiles requires an acknowledgement
print("Map tiles by Carto, under CC BY 3.0. Data by OpenStreetMap, under ODbL")

divpal=colorNumeric(c("#0080FF","#FF8000"),c(min(div11,div21),max(div11,div21)))
divdeltapal=colorNumeric(c("#0080FF","#FF8000"),c(min(div21-div11),max(div21-div11)))
growthpal=colorNumeric(c("#808080","#80FF80"),c(0,max(growth)))
for (i in 1:length(msoas)) {
  div11map = div11map %>% addPolygons(data = msoaBounds[msoaBounds$code==msoas[i],], fillColor = divpal(div11[i]), fillOpacity=.2, weight=1, color = "black")
  div21map = div21map %>% addPolygons(data = msoaBounds[msoaBounds$code==msoas[i],], fillColor = divpal(div21[i]), fillOpacity=.2, weight=1, color = "black")
  divdeltamap = divdeltamap %>% addPolygons(data = msoaBounds[msoaBounds$code==msoas[i],], fillColor = divdeltapal(div21[i]-div11[i]), fillOpacity=.2, weight=1, color = "black")
  growthmap = growthmap %>% addPolygons(data = msoaBounds[msoaBounds$code==msoas[i],], fillColor = growthpal(growth[i]), fillOpacity=.2, weight=1, color = "black")
}

div11map
div21map
growthmap
