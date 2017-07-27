
# usim.R

# Static household microsimulation

# pull in dependencies
source("./common/utils.R")
library(data.table)

# Load the input data

# Households by tenure, central heating and dwelling type
tenureChType = as.data.table(read.csv("./households/data/tenureChType.csv",stringsAsFactors = F))

# Household tenures by people by bedrooms
tenurePeopleBeds = as.data.table(read.csv("./households/data/tenurePeopleBeds.csv",stringsAsFactors = F))

# Household tenures by people by rooms
tenurePeopleRooms = as.data.table(read.csv("./households/data/tenurePeopleRooms.csv",stringsAsFactors = F))

# Household with no permanent occupant on census reference date
unoccupied = as.data.table(read.csv("./households/data/unoccupied.csv",stringsAsFactors = F))

# Population by residence type: household (1), or communal (2)
communal = as.data.table(read.csv("./households/data/communal.csv",stringsAsFactors = F))

# Communal population (only) by communal residence type
communalDetail = as.data.table(read.csv("./households/data/communalDetail.csv",stringsAsFactors = F))

# Define some lookups that map census codes to meaningful names
tenureLookup = data.table(Name=c("Owned", "Mortgaged/shared", "Rented social", "Rented private"), Value=c(2,3,5,6))

# TODO append communal residence type/index to this lookup (since we reuse column)

typeLookup = data.table(Name=c("Detached", "Semi", "Terrace", "Flat/mobile", "Communal"), Value = c(2,3,4,5,6))

# Compute some aggreagate stats
totalPopulation = sum(communal$Count)
totalDwellings = sum(unoccupied$Count)
totalOccDwellings = sum(tenureChType$Count)
totalCommunal = sum(communalDetail$Count)
occPopLBound = sum(tenurePeopleRooms$People*tenurePeopleRooms$Count)
householdPopulation = sum(communal[communal$Communal == F,]$Count)
communalPopulation = sum(communal[communal$Communal == T,]$Count)

print(paste0("Dwellings: ", totalDwellings))
print(paste0("Occupied households: ", totalOccDwellings))
print(paste0("Unoccupied dwellings: ", totalDwellings- totalOccDwellings))
print(paste0("Communal residences: ", totalCommunal))

print(paste0("Total population: ", totalPopulation))
print(paste0("Population in occupied households: ", householdPopulation))
print(paste0("Population in communal residences: ", communalPopulation))
print(paste0("Population lower bound from occupied households: ", occPopLBound))
print(paste0("Occupied household population underestimate: ", householdPopulation - occPopLBound))

tableLimit = totalDwellings + totalCommunal
library(data.table)
synhomes=data.table(MSOA=rep("n/a", tableLimit),
                    Type=rep(-1L, tableLimit), 
                    TypeName=rep("", tableLimit), 
                    Tenure=rep(-1L, tableLimit),
                    TenureName=rep("", tableLimit),
                    Rooms=rep(-1L, tableLimit),
                    People=rep(-1L, tableLimit),
                    Bedrooms=rep(-1L, tableLimit),
                    CentralHeating=rep(NA, tableLimit)
)

# constraint matrix: rooms(1-6) >= beds(1-4)
permittedStates = matrix(rep(1,24), nrow=6)
permittedStates[1,2] = 0
permittedStates[1,3] = 0
permittedStates[1,4] = 0
permittedStates[2,3] = 0
permittedStates[2,4] = 0
permittedStates[3,4] = 0

msoas=unique(communal$MSOA)
tenures=tenureLookup$Value

mainIndex = 1L
startTime = Sys.time()

for (a in msoas) {
  for (t in tenures) {
    # 1. unconstrained usim of type and central heating 
    # first get aggregates for the MSOA and tenure
    thdata = tenureChType[tenureChType$MSOA == a 
                        & tenureChType$Tenure == t
                        & tenureChType$Count != 0,]
    # expand out the aggregates of central heating and type
    thdata = data.table(type=rep(thdata$Type,thdata$Count),
                          ch=rep(thdata$CentHeat, thdata$Count))
    # then randomise the order to avoid bias w.r.t no. People occupying property
    thdata = thdata[sample(nrow(thdata)),]
    
    # append to main population
    # use a copy of main index as we need to populate other columns in the next step
    outerIndex = mainIndex
    if (nrow(thdata)) { # otherwise loop gets messed up when 0 rows 1:0 = 1 0
      for(i in 1L:nrow(thdata)) {
        set(synhomes,outerIndex,"Type", thdata[i,"type"])
        set(synhomes,outerIndex,"CentralHeating", thdata[i,"ch"])
        outerIndex = outerIndex + 1L
      }
    }
    
    # 2. constrained usim of rooms and bedrooms by People
    for (p in 1:4) {
      rmarginal = tenurePeopleRooms[tenurePeopleRooms$MSOA == a
                                  & tenurePeopleRooms$Tenure == t
                                  & tenurePeopleRooms$People == p,]$Count
      bmarginal = tenurePeopleBeds[tenurePeopleBeds$MSOA == a
                                 & tenurePeopleBeds$Tenure == t
                                 & tenurePeopleBeds$People == p,]$Count
      # This microsynthesis function won't populate states that aren't permitted (and still preserve marginals)
      usim = humanleague::synthPopG(list(rmarginal, bmarginal), permittedStates)
      stopifnot(usim$conv)
      # this gives us the indices of the nonzero elements in the population table
      idx=which(usim$x.hat>0,arr.ind=T)
      
      stopifnot(sum(rmarginal) == sum(bmarginal))
      #stopifnot(sum(usim$x.hat) == sum(bmarginal))
      
      # skip if we have zero population for this state
      if (sum(rmarginal) != 0) {
        # loop over nonzero indices
        for (i in 1:nrow(idx)) {
          # index of household
          ir = idx[i,1]
          # index of bedrooms
          ib = idx[i,2]
          n = usim$x.hat[ir, ib]
          for (k in 1:n) {
            set(synhomes,mainIndex,"MSOA", a)
            set(synhomes,mainIndex,"Tenure", t)
            set(synhomes,mainIndex,"Rooms", ir)
            set(synhomes,mainIndex,"People", p)
            set(synhomes,mainIndex,"Bedrooms", ib)
            mainIndex = mainIndex + 1L
          }
        }
      }
    }
  }
  # 3. communal residences
  # assumptions:
  # - people spread evenly (rounded) across similar establishments within OA
  # - nBeds = nRooms = nOccupants
  # - tenure is unknown, field is used to denote communal residence type
  # - all communal residences have central heating
  msoaCommunal = communalDetail[MSOA == a,]
  
  if (nrow(msoaCommunal) > 0) {
    for (i in 1:nrow(msoaCommunal)) {
      # average occupants per establishment - integerised (special case when zero occupants)
      occs = rep(0L, msoaCommunal[i,]$Count)
      if ( msoaCommunal[i,]$Occupants > 0) {
        occs = humanleague::prob2IntFreq(rep(1/msoaCommunal[i,]$Count, msoaCommunal[i,]$Count), msoaCommunal[i,]$Occupants)$freq
      }
      for (j in 1:msoaCommunal[i,]$Count) {
        stopifnot(!is.na(occs[j]))
        set(synhomes,mainIndex,"MSOA", a)
        set(synhomes,mainIndex,"Type", 6)
        set(synhomes,mainIndex,"Tenure", 100+msoaCommunal[i,"TypeCode"])
        set(synhomes,mainIndex,"Rooms", occs[j])
        set(synhomes,mainIndex,"Bedrooms", occs[j])
        set(synhomes,mainIndex,"People", occs[j])
        set(synhomes,mainIndex,"CentralHeating", TRUE)
        mainIndex = mainIndex + 1L
      }
    }
  }
  
  # 4. unoccupied is sampled usim of occupied dwellings (type/tenure/central heating)
  nUnocc = unoccupied[MSOA == a & Unoccupied == TRUE]$Count
  if (nUnocc > 0) {
    # type marginal
    tymarginal = aggregate(Count ~ Type, tenureChType[MSOA == a], sum)$Count
    # tenure marginal
    tnmarginal = aggregate(Count ~ Tenure, tenureChType[MSOA == a], sum)$Count
    # central heating marginal
    chmarginal = aggregate(Count ~ CentHeat, tenureChType[MSOA == a], sum)$Count
    
    uusim = humanleague::synthPop(list(tymarginal, tnmarginal, chmarginal))
    stopifnot(uusim$conv)
    
    idx = which(uusim$x.hat>0,arr.ind=T)
    # R alert! the type of variable index depends on the number of samples (this code fails when nUnocc=1 so we oversample) 
    idx = idx[sample(nrow(idx),nUnocc+1,replace = T),]
    
    for (i in 1:nUnocc) {
      set(synhomes,mainIndex,"MSOA", a)
      set(synhomes,mainIndex,"Type", typeLookup[idx[i,1],"Value"])
      set(synhomes,mainIndex,"Tenure", tenureLookup[idx[i,2],"Value"])
      set(synhomes,mainIndex,"People", 0)
      # Rooms/beds are done at the end (so we can sample population)
      set(synhomes,mainIndex,"CentralHeating", idx[i,3]==2)
      mainIndex = mainIndex + 1L
    }
  }
}
   
# add rooms and bedrooms to unoccupied properties (which have -1 rooms)
for (i in 1L:nrow(synhomes)) {
  if (synhomes$Room[i] < 0 ) {
    # (omitting tenure and central heating to avoid not finding similar properties)
    subset = synhomes[MSOA == synhomes$MSOA[i] & Type == synhomes$Type[i] & Rooms > 0 & Bedrooms > 0]
    stopifnot(nrow(subset) > 0)
    sampleIndex = sample(nrow(subset),1)
    set(synhomes, i, "Rooms", subset$Rooms[sampleIndex])
    set(synhomes, i, "Bedrooms", subset$Bedrooms[sampleIndex])
  }
}


print(paste("assembly time (s): ", difftime(Sys.time(), startTime, units="secs"))) 

# Consistency checks
stopifnot(nrow(synhomes[MSOA=="n/a"]) == 0)
stopifnot(nrow(synhomes[Type==-1]) == 0)
stopifnot(nrow(synhomes[Tenure==-1]) == 0)
stopifnot(nrow(synhomes[Rooms==-1]) == 0)
stopifnot(nrow(synhomes[Bedrooms==-1]) == 0)
stopifnot(nrow(synhomes[People==-1]) == 0)
stopifnot(nrow(synhomes[is.na(CentralHeating)]) == 0)

for (a in msoas) {
  stopifnot(nrow(synhomes[MSOA==a]) == sum(tenureChType[MSOA==a]$Count) + sum(communalDetail[MSOA==a]$Count) + sum(unoccupied[MSOA==a & Unoccupied==TRUE]$Count))
}

# Populate named columns from category values
# TODO surely loop can be avoided? this is extremely slow
for (i in 1L:nrow(synhomes)) {
  set(synhomes, i, "TypeName", typeLookup[Value==synhomes[i]$Type]$Name)
  #set(synhomes, i, "TenureName", tenureLookup[Value==synhomes[i]$Tenure]$Name)
}

# save synthetic population
write.csv(synhomes, "./households/data/synhomes.csv", row.names = F)


