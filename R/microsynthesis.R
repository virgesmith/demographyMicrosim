

#' microsynthesise
#'
#' This function generates an individual population from aggregate census data. Members of the population are
#' categorised by age, sex, ethnicity and geographical location.
#' This file synthesises a population in: MSOA, Sex, Age(single year), Ethnicity
#' The input data are loaded automatically and derive from 2011 census tables containing:
#'   Aggregates of Persons per MSOA, Sex, Age(band) and Ethnicity
#'   Aggregates of Persons per MSOA, Sex, Age(single year)
#' @return a data.table containing the synthetic population
#' @export
#' @examples
#' synpop = microsynthesise()
microsynthesise = function() {

  # makes use of the following lazy-loaded package data: sexAgeEth, sexAgeYear

  cat(paste("Population: ", sum(sexAgeEth$Persons), "\n"))
  cat("Starting microsynthesis...")

  age=aggregate(sexAgeEth$Persons, by=list(sexAgeEth$AgeBand), FUN=sum)
  # mapping from age bands to age ranges
  ageLookup=data.table(Band=c("0-4","5-7","8-9","10-14","15","16-17","18-19","20-24","25-29","30-34","35-39","40-44","45-49","50-54","55-59","60-64","65-69","70-74","75-79","80-84","85+"),
                       LBound=c(0,5,8,10,15,16,18,20,25,30,35,40,45,50,55,60,65,70,75,80,85),
                       UBound=c(4,7,9,14,15,17,19,24,29,34,39,44,49,54,59,64,69,74,79,84,999))

  # overall population
  n = sum(sexAgeYear$Persons)

  # initialise population table
  #synpop=data.table(MSOA=rep("",n), Sex=rep("",n), Age=rep(-1,n), Ethnicity=rep("",n))
  synpop=data.table()

  # microsim to get sex-age-eth expanded to single year of age, preserving marginal totals in area, sex, age band and ethnicity

  # for expediency we do separate mcicrosyntheses for each age band. alternative would be to do a global seeded microsynthesis,
  # forbidding states where age is not within age band (e.g. 7 is only in "5-7". this approach would be far slower due to
  # requiring IPF to generate the sampling distribution.

  # loop over age bands
  for (b in age$Group.1) {
    # m1 is Geog by Sex by Ethnicity for a single age band
    m1 = xtabs(Persons~MSOA+Sex+Ethnicity, sexAgeEth[sexAgeEth$AgeBand==b,])
    # m2 is Geog by Sex by Age for ages within the band
    m2 = xtabs(Persons~MSOA+Sex+Age, sexAgeYear[sexAgeYear$Age >= ageLookup[Band==b]$LBound & sexAgeYear$Age <= ageLookup[Band==b]$UBound,])
    # labels
    geo_labels = dimnames(m1)$MSOA
    sex_labels = dimnames(m1)$Sex
    eth_labels = dimnames(m1)$Ethnicity
    age_labels = dimnames(m2)$Age

        # microsynthesis (if people exist in MSOA/sex/age combination)
    if (sum(m1)>0) {
      res = humanleague::qis(list(c(1,2,3),c(1,2,4)), list(m1,m2))
      stopifnot(res$conv)
      table = humanleague::flatten(res$result, c("MSOA", "Sex", "Ethnicity", "Age"))
      # give meaningful names to what are essentially array index values
      table$MSOA = geo_labels[table$MSOA]
      table$Sex = sex_labels[table$Sex]
      table$Age = age_labels[table$Age]
      table$Ethnicity = eth_labels[table$Ethnicity]
      synpop = rbind(synpop, table)
    }
  }

  cat("done\n")

  cat("Checking consistency of microsynthesised population...")
  # do some spot-checks on the population to ensure it's consistent
  # ensure all rows populated
  stopifnot(nrow(synpop[Age==-1]) == 0)
  # check sex totals match
  stopifnot(nrow(synpop[Sex=="M"]) == sum(sexAgeYear[sexAgeYear$Sex=="M",]$Persons))
  stopifnot(nrow(synpop[Sex=="F"]) == sum(sexAgeYear[sexAgeYear$Sex=="F",]$Persons))
  # check some age totals match
  stopifnot(nrow(synpop[Age==8]) == sum(sexAgeYear[sexAgeYear$Age==8,]$Persons))
  stopifnot(nrow(synpop[Age==48]) == sum(sexAgeYear[sexAgeYear$Age==48,]$Persons))
  # check some ethnicity totals match
  stopifnot(nrow(synpop[Ethnicity=="OTH"]) == sum(sexAgeEth[sexAgeEth$Ethnicity=="OTH",]$Persons))
  stopifnot(nrow(synpop[Ethnicity=="BLC"]) == sum(sexAgeEth[sexAgeEth$Ethnicity=="BLC",]$Persons))
  stopifnot(nrow(synpop[Ethnicity=="BAN"]) == sum(sexAgeEth[sexAgeEth$Ethnicity=="BAN",]$Persons))
  # check some MSOA totals match
  stopifnot(nrow(synpop[MSOA=="E02000864"]) == sum(sexAgeEth[sexAgeEth$MSOA=="E02000864",]$Persons))
  stopifnot(nrow(synpop[MSOA=="E02000888"]) == sum(sexAgeEth[sexAgeEth$MSOA=="E02000888",]$Persons))
  stopifnot(nrow(synpop[MSOA=="E02006854"]) == sum(sexAgeEth[sexAgeEth$MSOA=="E02006854",]$Persons))

  cat("done\n")

  # save data
  return(synpop)
}

