
# graph.R

# Graphical Visualisation of dynamic microsimulation results

# load dependencies
library(plotrix)
library(data.table)

# Ensure your working directory is the project root so that the data files can be found, e.g.
#setwd("~/dev/usim_demog/")
 
# produce a pyramid plot
pyramid = function(eth, population, title) {

  # mapping from age bands to age ranges
  ageLookup=data.table(Band=c("0-4","5-9","10-14","15-19","20-24","25-29","30-34","35-39","40-44","45-49","50-54","55-59","60-64","65-69","70-74","75-79","80-84","85+"),
                       LBound=c(0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85),
                       UBound=c(4,9,14,19,24,29,34,39,44,49,54,59,64,69,74,79,84,999))

  m=rep(0,length(ageLookup$Band))
  f=rep(0,length(ageLookup$Band))
  
  for (i in 1:length(ageLookup$Band)) {
    m[i] = nrow(population[Sex=="M" & Age>=ageLookup$LBound[i] & Age<=ageLookup$UBound[i] & Ethnicity==eth])/1000
    f[i] = nrow(population[Sex=="F" & Age>=ageLookup$LBound[i] & Age<=ageLookup$UBound[i] & Ethnicity==eth])/1000
  }
  
  mcol<-color.gradient(c(0,0,0.5,1),c(0,0,0.5,1),c(1,1,0.5,1),length(ageLookup$Band))
  fcol<-color.gradient(c(1,1,0.5,1),c(0.5,0.5,0.5,1),c(0.5,0.5,0.5,1),length(ageLookup$Band))
  par(mar=pyramid.plot(m,f,labels=ageLookup$Band,
                       main=paste(title),lxcol=mcol,rxcol=fcol,
                       gap=1,space=0.5,unit="('000s)",show.values=F))
}


# line graph of population growth for different ethnicities, 2011-2021
# TODO use a better plot package
growthByEthnicity = function() {

  # population change by ethnicity over 10 years
  
  # create a table containing time (y axis) and Ethnicity (x axis)
  ethnicities=c("BAN", "BLA", "BLC", "CHI", "IND", "MIX", "OAS", "OBL","OTH", "PAK", "WBI", "WHO")
  changeByYear=data.table(Year=2011:2021)
  changeByYear[,ethnicities] = as.numeric(NA)
  
  for (e in ethnicities) {
    changeByYear[1,e] = 1
    changeByYear[2,e] = nrow(synpop2012[Ethnicity==e])/nrow(synpop2011[Ethnicity==e])
    changeByYear[3,e] = nrow(synpop2013[Ethnicity==e])/nrow(synpop2011[Ethnicity==e])
    changeByYear[4,e] = nrow(synpop2014[Ethnicity==e])/nrow(synpop2011[Ethnicity==e])
    changeByYear[5,e] = nrow(synpop2015[Ethnicity==e])/nrow(synpop2011[Ethnicity==e])
    changeByYear[6,e] = nrow(synpop2016[Ethnicity==e])/nrow(synpop2011[Ethnicity==e])
    changeByYear[7,e] = nrow(synpop2017[Ethnicity==e])/nrow(synpop2011[Ethnicity==e])
    changeByYear[8,e] = nrow(synpop2018[Ethnicity==e])/nrow(synpop2011[Ethnicity==e])
    changeByYear[9,e] = nrow(synpop2019[Ethnicity==e])/nrow(synpop2011[Ethnicity==e])
    changeByYear[10,e] = nrow(synpop2020[Ethnicity==e])/nrow(synpop2011[Ethnicity==e])
    changeByYear[11,e] = nrow(synpop2021[Ethnicity==e])/nrow(synpop2011[Ethnicity==e])
  }
  
  # take out year column as we dont want it plotted
  xLabels = changeByYear$Year
  changeByYear$Year=NULL
  
  # plot the remaining data
  matplot(changeByYear, type="l")
  
  # add legend (TODO fix color coding)
  legend("topleft", legend=ethnicities, col=1:12, lty=1:12, lwd=1)
}

# Load the base population and the saved projections
synpop2011 = as.data.table(read.csv("./projection/data/synpop.csv", stringsAsFactors = F))
synpop2012 = as.data.table(read.csv("./projection/data/synpop2012.csv", stringsAsFactors = F))
synpop2013 = as.data.table(read.csv("./projection/data/synpop2013.csv", stringsAsFactors = F))
synpop2014 = as.data.table(read.csv("./projection/data/synpop2014.csv", stringsAsFactors = F))
synpop2015 = as.data.table(read.csv("./projection/data/synpop2015.csv", stringsAsFactors = F))
synpop2016 = as.data.table(read.csv("./projection/data/synpop2016.csv", stringsAsFactors = F))
synpop2017 = as.data.table(read.csv("./projection/data/synpop2017.csv", stringsAsFactors = F))
synpop2018 = as.data.table(read.csv("./projection/data/synpop2018.csv", stringsAsFactors = F))
synpop2019 = as.data.table(read.csv("./projection/data/synpop2019.csv", stringsAsFactors = F))
synpop2020 = as.data.table(read.csv("./projection/data/synpop2020.csv", stringsAsFactors = F))
synpop2021 = as.data.table(read.csv("./projection/data/synpop2021.csv", stringsAsFactors = F))

# Example - pyramid plots of white British population in 2011 and 2021
eth="WBI"
pyramid("WBI", synpop2011, "White British Population 2011 (Tower Hamlets)")
pyramid("WBI", synpop2021, "White British Population 2021 (Tower Hamlets)")

# Example - line graph of population growth by Ethnicity, 2011-2021
growthByEthnicity()
