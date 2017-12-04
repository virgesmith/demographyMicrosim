# proj.R population projection using a precomputed synthetic population of Tower Hamlets from 2011 census data

# uses fertility and mortality data by local authority, age and ethnicity


#' microsimulate
#'
#' This function projects an (synthetic) population from aggregate census data. Members of the population are
#' categorised by age, sex, ethnicity and geographical location.
#' - births are a single child only (assumed that twins etc are accounted for in the fertility rate)
#' - newborns are equally likely to be male or female (this may be incorrect esp. for certain ethnicities)
#' - ethnicity of newborn is the same as mother (in the absence of other information)
#' - the death rate for age zero is the average of the rate of stillbirths and deaths under one year
#' - births supersede deaths: thus a person who gives birth and dies in a single year will have a surviving child
#' @param synpop a dataframe containing the base population to be projected
#' @param years a number of years to run the simulation
#' @return a data.table containing the projected population
#' @export
#' @examples
#' \dontrun{
#' synpop = microsynthesise()
#' projpop = microsimulate(synpop, 10)
#' }
microsimulate = function(synpop, years) {

  # years must be strictly positive
  stopifnot(years>0)

  # makes use of the following lazy-loaded package data: TowerHamletsFertility, TowerHamletsMortality
  # to make vectorisation easier, we include males in fertility table (obviously with zero rate)
  ftable = xtabs(Rate~Sex+Age+Ethnicity, TowerHamletsFertility)
  mtable = xtabs(Rate~Sex+Age+Ethnicity, TowerHamletsMortality)
  # two status columns will be added to the population to flag birth and death events

  # perform the microsimulation
  cat(paste("base population:", nrow(synpop), "\n"))
  startTime = Sys.time()
  for (y in 1:years) {
    cat(paste0("Projecting: T+", y, "..."))
    n = nrow(synpop)
    # add/reset status
    synpop$B = rep(0,n)
    synpop$D = rep(0,n)

    # fertility and mortality are independent so need different draws
    xf = runif(n) # fertility: n uniform random variates in (0,1)
    xm = runif(n) # mortality: n uniform random variates in (0,1)
    fr=ftable[cbind(synpop$Sex, synpop$Age, synpop$Ethnicity)]
    mr=mtable[cbind(synpop$Sex, synpop$Age, synpop$Ethnicity)]

    # births/deaths occur when the random variate is lower than the fertility/mortality rate
    synpop$B = ifelse(fr >= xf, 1, 0)
    synpop$D = ifelse(mr >= xm, 1, 0)

    # age the population (capping at 85+) before we add newborns
    synpop$Age = synpop$Age + 1
    synpop[Age>85]$Age=85

    # add newborns
    # clone mothers
    newborns = synpop[B == 1]
    # then set baby age to zero
    newborns$Age = 0
    # randomise baby gender
    newborns$Sex=ifelse(runif(nrow(newborns))<=0.5,"M","F")
    # add to the main population
    synpop = rbind(synpop, newborns)

    # remove the deceased
    synpop = synpop[D != 1]

    cat("done\n")
    cat(paste0("T+", y, " population ", nrow(synpop), "\n"))
    cat(paste("Overall simulation time(s): ", difftime(Sys.time(), startTime, units="secs"), "\n"))
  }
  return(synpop)
}
