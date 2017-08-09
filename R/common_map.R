#
# # map.R
#
# # Geographical Visualisation of dynamic microsimulation results
#
# # Ensure your working directory is the project root so that the data files can be found, e.g.
# #setwd("~/dev/usim_demog/")
#
# # load dependencies
# library(sf)
# library(leaflet)
#
# # load MSOA shapefiles into global variable
#
# function that maps data supplied
# data should be a data.table (or data.frame) with:
# - a column "MSOA" containing the MSOA code
# - a column "Value" containing numeric data to be plotted
genMap = function(data, minColour = "#0080FF", maxColour= "#FF8000") {

  # TODO path/data issues
  map_msoaBounds=st_read("./data/msoa.shp",stringsAsFactors = F)

  map = leaflet() %>% addTiles(urlTemplate = "//a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png")#, options=tileOptions(opacity=0.5))
  # Use of these tiles requires an acknowledgement
  cat("Map tiles by Carto, under CC BY 3.0. Data by OpenStreetMap, under ODbL\n")

  pal=colorNumeric(c(minColour,maxColour),c(min(data$Value),max(data$Value)))

  map = map %>% addPolygons(data = map_msoaBounds[map_msoaBounds$code==data$MSOA,], fillColor = pal(data$Value), fillOpacity=.2, weight=1, color = "black")

  return(map)
}


