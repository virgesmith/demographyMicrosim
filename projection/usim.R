# usim.R 
# This file synthesises a population in: MSOA, Sex, Age(single year), Ethnicity
# The input data are two tables containing:
# Aggregates of Persons per MSOA, Sex, Age(band) and Ethnicity
# Aggregates of Persons per MSOA, Sex, Age(single year)

# source this file to run the microsynthesis that is used as tbe basis for the projection microsimulation
# Running this code is optional, a synthetic population is provided in projection/data/synpop.csv

# load dependencies
library(data.table)

# Ensure your working directory is the project root so that the data files can be found, e.g.
#setwd("~/dev/usim_demog/")

# load in the aggregates derived from census data# population by sex, age band, ethnicity
sexAgeEth=as.data.table(read.csv("./projection/data/sexAgeEth.csv", stringsAsFactors = F))
# population by single year of age
sexAgeYear=as.data.table(read.csv("./projection/data/sexAgeYear.csv", stringsAsFactors = F))

msoa=aggregate(sexAgeEth$Persons, by=list(sexAgeEth$MSOA), FUN=sum)
sex=aggregate(sexAgeEth$Persons, by=list(sexAgeEth$Sex), FUN=sum)
age=aggregate(sexAgeEth$Persons, by=list(sexAgeEth$Age), FUN=sum)
eth=aggregate(sexAgeEth$Persons, by=list(sexAgeEth$Ethnicity), FUN=sum)

# mapping from age bands to age ranges
ageLookup=data.table(Band=c("0-4","5-7","8-9","10-14","15","16-17","18-19","20-24","25-29","30-34","35-39","40-44","45-49","50-54","55-59","60-64","65-69","70-74","75-79","80-84","85+"),
                     LBound=c(0,5,8,10,15,16,18,20,25,30,35,40,45,50,55,60,65,70,75,80,85),
                     UBound=c(4,7,9,14,15,17,19,24,29,34,39,44,49,54,59,64,69,74,79,84,999))

# overall population
n = sum(sexAgeYear$Persons)

synpop=data.table(MSOA=rep("",n), Sex=rep("",n), Age=rep(-1,n), Ethnicity=rep("",n))

index = 1L

# microsim to get sex-age-eth expanded to single year of age, preserving marginal totals in area, sex, age band and ethnicity
for (a in msoa$Group.1) {
  for (s in sex$Group.1) {
    for (b in age$Group.1) {
      # marginal labels
      l1 = sexAgeEth[MSOA==a & Sex==s & Age==b]$Ethnicity
      l2 = sexAgeYear[MSOA==a & Sex==s & Age >= ageLookup[Band==b]$LBound & Age <= ageLookup[Band==b]$UBound]$Age
      # marginal frequencies
      m1 = sexAgeEth[MSOA==a & Sex==s & Age==b]$Persons
      m2 = sexAgeYear[MSOA==a & Sex==s & Age >= ageLookup[Band==b]$LBound & Age <= ageLookup[Band==b]$UBound]$Persons
      # microsynthesis
      if (sum(m1)>0) {
        res = humanleague::synthPop(list(m1,m2))
        for (i in 1:nrow(res$pop)) {
          set(synpop,index,"MSOA", a)
          set(synpop,index,"Sex", s)
          set(synpop,index,"Age", l2[res$pop$C1[i]+1])
          set(synpop,index,"Ethnicity", l1[res$pop$C0[i]+1])
          index = index + 1L
        }
      }
    }
  }
}

# do some spot-checks on the population to ensure it's consistent
# ensure all rows populated
stopifnot(nrow(synpop[Age==-1]) == 0)
# check sex totals match
stopifnot(nrow(synpop[Sex=="M"]) == sum(sexAgeYear[Sex=="M"]$Persons))
stopifnot(nrow(synpop[Sex=="F"]) == sum(sexAgeYear[Sex=="F"]$Persons))
# check some age totals match
stopifnot(nrow(synpop[Age==8]) == sum(sexAgeYear[Age==8]$Persons))
stopifnot(nrow(synpop[Age==48]) == sum(sexAgeYear[Age==48]$Persons))
# check some ethnicity totals match
stopifnot(nrow(synpop[Ethnicity=="OTH"]) == sum(sexAgeEth[Ethnicity=="OTH"]$Persons))
stopifnot(nrow(synpop[Ethnicity=="BLC"]) == sum(sexAgeEth[Ethnicity=="BLC"]$Persons))
stopifnot(nrow(synpop[Ethnicity=="BAN"]) == sum(sexAgeEth[Ethnicity=="BAN"]$Persons))
# check some MSOA totals match
stopifnot(nrow(synpop[MSOA=="E02000864"]) == sum(sexAgeEth[MSOA=="E02000864"]$Persons))
stopifnot(nrow(synpop[MSOA=="E02000888"]) == sum(sexAgeEth[MSOA=="E02000888"]$Persons))
stopifnot(nrow(synpop[MSOA=="E02006854"]) == sum(sexAgeEth[MSOA=="E02006854"]$Persons))


# save data
write.csv(synpop,"./projection/data/synpop.csv", row.names = F)



