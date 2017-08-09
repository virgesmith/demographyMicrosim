# proj.R population projection using a precomputed synthetic population of Tower Hamlets from 2011 census data

# uses fertility and mortality data by local authority, age and ethnicity


#' Population projection microsimulation
#'
#' This function projects an (synthetic) population from aggregate census data. Members of the population are 
#' categorised by age, sex, ethnicity and geographical location.
#' - births are a single child only (assumed that twins etc are accounted for in the fertility rate)
#' - newborns are equally likely to be male or female (this may be incorrect esp. for certain ethnicities)
#' - ethnicity of newborn is the same as mother (in the absence of other information)
#' - the death rate for age zero is the average of the rate of stillbirths and deaths under one year
#' - births supersede deaths: thus a person who gives birth and dies in a single year will have a surviving child
#' @export
#' @examples
#' synpop = microsynthesise()
#' synpop10 = microsimulate(synPop, 10)
microsimulate = function(synPop, years) {

  # Load fertility rates
  fertility=as.data.table(read.csv("./data/TowerHamletsFertility.csv", stringsAsFactors = F))
  
  # Load mortality rates for Tower Hamlets
  mortality=as.data.table(read.csv("./data/TowerHamletsMortality.csv", stringsAsFactors = F))
  
  # two status columns will be added to the population to flag birth and death events
  
  # perform the microsimulation
  print(paste("2011 population",nrow(synpop)))
  startTime = Sys.time()
  for (y in 2012:2021) {
    n = nrow(synpop)
    # add/reset status
    synpop$B = rep(0,n)
    synpop$D = rep(0,n)
    
    # fetility and mortality are independent so need different draws
    xf = runif(n) # fertility: n uniform random variates in (0,1)
    xm = runif(n) # mortality: n uniform random variates in (0,1)
    fr=rep(-1,n)
    mr=rep(-1,n)
    for (i in 1:n) {
      # births
      if (synpop[i,]$Sex == "F") {
        # pick correct fertility rate for age and ethnicity
        fr[i] = fertility[Age==synpop[i,]$Age & Ethnicity==synpop[i,]$Ethnicity]$Rate
      }
  
      # deaths
      # pick correct mortality rate for sex, age and ethnicity
      mr[i] = mortality[Sex==synpop[i,]$Sex & Age==synpop[i,]$Age & Ethnicity==synpop[i,]$Ethnicity]$Rate
      # death occurs when the random variate is lower than the fertility rate
  
      # migration
      # TODO...
      
    }
    # births/deaths occur when the random variate is lower than the fertility/mortality rate
    synpop$B = ifelse(fr >= xf, 1, 0)
    synpop$D = ifelse(mr >= xm, 1, 0)
    
    # age the population (capping at 85+) before we add newborns
    synpop$Age = synpop$Age + 1
    synpop[Age>85]$Age=85
    
    # add newborns
    # clone mothers
    newborns = synpop[B == 1]
    # set age to zero
    newborns$Age = 0
    # randomise gender
    newborns$Sex=ifelse(runif(nrow(newborns))<=0.5,"M","F")
    # add to the main population
    synpop = rbind(synpop, newborns)
    
    # remove the deceased
    synpop = synpop[D != 1]
    
    print(paste(y,"population",nrow(synpop)))
    print(paste("simulation time(s): ", difftime(Sys.time(), startTime, units="secs")))
    
    write.csv(synpop, paste0("./projection/data/synpop", y, ".csv"), row.names = F)
  }

}