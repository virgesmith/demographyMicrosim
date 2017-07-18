# usim.R

# source this file to run the microsimulation

# load in the aggregates derived from census data

# load dependencies
library(data.table)

#
setwd("~/dev/usim_demog/projection/")

# read in data:
# population by sex, ageBand, ethnicity
sexAgeEth=as.data.table(read.csv("./data/sexAgeEth.csv", stringsAsFactors = F))
# population by single year of age
sexAgeYear=as.data.table(read.csv("./data/sexAgeYear.csv", stringsAsFactors = F))


# this is slightly pointless as the data is already there
msoa=aggregate(sexAgeEth$Persons, by=list(sexAgeEth$MSOA), FUN=sum)
sex=aggregate(sexAgeEth$Persons, by=list(sexAgeEth$Sex), FUN=sum)
age=aggregate(sexAgeEth$Persons, by=list(sexAgeEth$Age), FUN=sum)
eth=aggregate(sexAgeEth$Persons, by=list(sexAgeEth$Ethnicity), FUN=sum)

ageLookup=data.table(Band=c("0-4","5-7","8-9","10-14","15","16-17","18-19","20-24","25-29","30-34","35-39","40-44","45-49","50-54","55-59","60-64","65-69","70-74","75-79","80-84","85+"),
                     LBound=c(0,5,8,10,15,16,18,20,25,30,35,40,45,50,55,60,65,70,75,80,85),
                     UBound=c(4,7,9,14,15,17,19,24,29,34,39,44,49,54,59,64,69,74,79,84,999))

# microsim to get sex-age-eth? expanding single year
for (a in msoa$Group.1) {
  for (s in sex$Group.1) {
    for (b in age$Group.1) {
      l1 = sexAgeEth[MSOA==a & Sex==s & Age==b]$Ethnicity
      m1 = sexAgeEth[MSOA==a & Sex==s & Age==b]$Persons
      l2 = sexAgeYear[MSOA==a & Sex==s & Age >= ageLookup[Band==b]$LBound & Age <= ageLookup[Band==b]$UBound]$Age
      m2 = sexAgeYear[MSOA==a & Sex==s & Age >= 0 & Age < 5]$Persons
      res = humanleague::synthPop(list(m1,m2))
    }
  }
}


# mortality rates (TODO revert back to single year)
mortality=as.data.table(read.csv("./data/TowerHamletsMortality.csv", stringsAsFactors = F))

# this is slightly pointless as the data is already there
msoa=aggregate(sexAgeEth$Persons, by=list(sexAgeEth$MSOA), FUN=sum)
sex=aggregate(sexAgeEth$Persons, by=list(sexAgeEth$Sex), FUN=sum)
age=aggregate(sexAgeEth$Persons, by=list(sexAgeEth$Age), FUN=sum)
eth=aggregate(sexAgeEth$Persons, by=list(sexAgeEth$Ethnicity), FUN=sum)

# Pointless, but illustrates how we dont preserve totals for msoa-sex-age-eth combination
res=humanleague::synthPop(list(msoa$x,sex$x,age$x,eth$x))

# Make the categories more readable
# indices start at zero in the output so add one
res$pop$C0=msoa$Group.1[res$pop$C0+1]
res$pop$C1=sex$Group.1[res$pop$C1+1]
res$pop$C2=age$Group.1[res$pop$C2+1]
res$pop$C3=eth$Group.1[res$pop$C3+1]

pop=nrow(sexAgeEth)


