
#' pyramid
#'
#' Produces a pyramid plot for a particular ethnicity
#' @param eth a three-letter string identifying the ethnicity
#' @param population the overall population
#' @param title and optional title for the graph
#' @export
#' @examples
#' p = microsynthesise()
#' pyramid("BAN", p, "Tower Hamlets Bangladeshi population 2011")
pyramid = function(eth, population, title = "") {

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

  mcol<-"blue"
  fcol<-"red"
  par(mar=pyramid.plot(m,f,labels=ageLookup$Band,
                       main=paste(title),lxcol=mcol,rxcol=fcol,
                       gap=1,space=0.5,unit="('000s)",show.values=F))
}

