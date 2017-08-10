
# map.R

# Geographical Visualisation of dynamic microsimulation results

# TODO lazy load MSOA shapefiles into global variable

#' map
#'
#' Displays a map outlining the MSOAs within Tower Hamlets, filling with a colour derived from the supplied data
#' @param data a data.table (or data.frame) containing a column "MSOA" containing the MSOA code and
#' a column "Value" containing numeric data to be plotted
#' @param minColour colour for the lowest value of the data
#' @param maxColour colour for the lowest value of the data
#' @examples
#' p = microsimulate()
#' d = diversity(p)
#' m = map(d)
#' @export
map = function(data, minColour = "#0080FF", maxColour= "#FF8000") {

  # TODO path/data issues
  map_msoaBounds=st_read("./data/msoa.shp",stringsAsFactors = F)

  map = leaflet() %>% addTiles(urlTemplate = "//a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png")#, options=tileOptions(opacity=0.5))
  # Use of these tiles requires an acknowledgement
  cat("Map tiles by Carto, under CC BY 3.0. Data by OpenStreetMap, under ODbL\n")

  pal=colorNumeric(c(minColour,maxColour),c(min(data$Value),max(data$Value)))

  map = map %>% addPolygons(data = map_msoaBounds[map_msoaBounds$code==data$MSOA,], fillColor = pal(data$Value), fillOpacity=.2, weight=1, color = "black")

  return(map)
}

