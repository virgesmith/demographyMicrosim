# Microsimulation for Demography Example

[![Build Status](https://travis-ci.org/virgesmith/demographyMicrosim.png?branch=master)](https://travis-ci.org/virgesmith/demographyMicrosim)
[![License](http://img.shields.io/badge/license-GPL%20%28%3E=%202%29-brightgreen.svg?style=flat)](http://www.gnu.org/licenses/gpl-3.0.html) 

## Prerequisites

The code is contained in an R package. We recommend the use of the most recent version of RStudio and users will need sufficient admin privileges to install packages. 

The code is also dependent on another github package `humanleague` which should be installed first. The following commands will install everything you need:
```
> devtools::install_github("virgesmith/humanleague")
> devtools::install_github("virgesmith/demographyMicrosim")
```
## Package Detail

### Microsynthesis 

* `microsynthesise()` - takes the input data (population aggregates) and synthesises an individual "base" population. See [microsynthesis.R](R/microsynthesis.R) 

### Microsimulation
* `microsimulate(basePopulation, years)` - takes the microsynthesised data from above, then uses more input data (fertility/mortality rates) to project the population. See [microsimulation.R](R/microsimulation.R).  

### Common Functionality
* `pyramid()` - graphic visualisations of data derived from the microsyntheses. See [graph.R](R/graph.R) for details.
* `map()` - geographic visualisations of data derived from the microsyntheses. See [map.R](R/map.R) for details. 
* `diversity(pop), growth(pop0, pop1)` - helper functions for calculating a growth and diversity coefficients. See [utils.R](R/utils.R) for details. 

In this example we microsynthesise a base human population for Tower Hamlets from 2011 census data, then microsimulate the evoluation of the population given detailed fertility and mortality data.

## Input data
The input data consists of three distinct datasets, which are used for the microsynthesis, the microsimulation, and visualisation. They are described in more detail in the following sections.
 
### Aggregate Population Data

This data is used to generate a synthetic population.

Population aggregate data is sourced from UK census 2011, for the London Borough of Tower Hamlets at middle-layer super output area (MSOA) resolution. MSOA corresponds to a subregion containing approximately 8,000 people. Tower Hamlets is split into 32 MSOAs and its total population is recorded as just over 250,000.

For the purposes of this worked example we have preprocessed the census data into the following csv files:

* [sexAgeEth.csv](data/sexAgeEth.csv) - count of persons by MSOA by sex by age band by ethnicity
* [sexAgeYear.csv](data/sexAgeYear.csv) - count of persons by MSOA by sex by single year of age by ethnicity

#### Categories:
- MSOA: ONS code for the 32 MSOAs within Tower Hamlets
- Sex: M/F
- Age Band: 0-4, 5-7, 8-9, 10-14, 15, 16-17, 18-19, 20-24, 25-29, 30-34, 35-39, 40-44, 45-49, 50-54, 55-59, 60-64, 65-69, 70-74, 75-79, 80-84, 85+
- Age: individual years up to 84, then a single 85+
- Ethnicity: BAN (Bangladeshi), BLA (Black African), BLC (Black Caribbean), CHI (Chinese), IND (Indian), MIX (Mixed), OAS (Other Asian), OBL (Other Black), OTH (Other), PAK (Pakistani), WBI (White British), WHO (White Other)

NB The categories for Ethnicity have been reduced slightly from the original census categories in order to be consistent with the fertility/mortality data.

### Fertility/mortality rate data

- fertility and mortality rate by ethnicity data, specific to Tower Hamlets. This is used to project the population forward in time by microsimulation.

Fertility and mortality rate data is taken from the Ethpop database @Nik can you provide more background/detail?, and gives rates by ethnicity and single year of age, for the entire borough, but does not differentiate on any smaller geographical scale. 

There is significant variation in the rates for different ethnicities, and it is important that our microsimulation captures this.

### Geographical Data

This data consists of shapefiles of MSOAs within Tower Hamlets, and is purely for geographic visualisation of the microsimulation results.

## Methodology

### Step 1 - Static microsynthesis

Load the package and call the `microsynthesise` function to generate a base population:
```
> library(demographicMisrosim)
> basePopulation = microsynthesise()
Population:  254096 
Starting microsynthesis...done
Checking consistency of microsynthesised population...done
```
This will take around 1 minute, depending on the hardware used. We can save this population for later use:
```
> write.csv(basePopulation, "basePopulation.csv", row.names=FALSE)
```
(The final argument stops R from inserting an index column into the saved data, which we do not require.) 


In this example, microsynthesis is necessary due to the fact that we have fertility/mortality rates for a single year of age, but census data does not give us ethnicity by single year of age. Using microsynthesis, we can generate a synthetic population that enumerates both ethnicity and single year of age for every individual. Moreover, this population is entirely consistent with the input data: it matches both the ethnicity total (by age band) and the population total (by single year of age) for each geographical area and gender. 

[shameless plug] For the microsynthesis we use the humanleague R package that generates a population using quasirandom sampling of the marginal data.

The code can be split into three functional parts:
1. load the input data and compute various data that will be required later (such as the categories, .and a mapping between age band and age)
2. perform microsyntheses for each geographical area and insert into the the population
3. perform checks on the synthesised population to ensure it is consistent with the input data

### Step 2 - Microsimulation (Projection)

Assuming you have already carried out the microsynthesis step above, we can project the population 6 years forward to 2017 using the following:
```
> population3 = microsimulate(basePopulation, 3)
base population: 254096 
Projecting: T+1...done
T+1 population 258274
Total simulation time(s):  339.806096315384 
Projecting: T+2...done
T+2 population 262393
Total simulation time(s):  680.060456752777 
Projecting: T+3...done
T+3 population 266528
Total simulation time(s):  1029.03516221046 
```
In this example we project the base population from 2011 to 2021, using a Monte-Carlo simulation to assign births and deaths to the population, using the age- and ethnicity-specific fertility and mortality rates, to generate population foreacsts for ten years. (Whilst there are more efficient ways of projection for this simple example, the aim here is to illustrate the process.) The following assumptions are made:
* only single births occur (assume that twins etc are factored into the fertility rate)
* newborn genders are equally probable
* the ethnicity and MSOA of the newborn is the same as their mother's
* births occur before deaths - thus a newborn will survive if a parent dies
* no migration occurs (which is clearly wrong - we leave this as an exercise for the reader)

The code can be split into functional parts:
1. load the synthetic population from the previous step, as well as the fertility and mortality rates
2. assign births and deaths to members of the population where the random draws are not greater than the appropriate fertility/mortality rates
3. age the population by one year
4. insert newborns (aged zero) and remove dead people 
5. save the population for later use
6. repeat from step 2 

The population for each year is saved as `./projection/data/synpop20YY.csv`

#### Visualisation
The package provides convenient functions for generating graphs. For example, to view the projected 2021 Bangladeshi population as a pyramid plot:
```
> pyramid("BAN", synpop2021, "Bangladeshi - 2021 Projection")
```
![](examples/BAN2021pyramid.png)

_2021 Projected Bangladeshi population pyramid._

The second file provides functionality for geographical visualisation file and requires MSOA shapefiles (provided).

There is some example code that computes a diversity measure and overall population growth by MSOA for the 2011 and 2021 (projected) populations. This can be run:
```
> div = diversity(population2021)
```
And visualised by calling the function
```
> genMap(growth)
```
![](examples/growth2011_2021.png)  

_Map of projected population growth 2011-2021 (lower growth is blue and higher orange)._
###### Map tiles by Carto, under CC BY 3.0. Data by OpenStreetMap, under ODbL  


It should be noted that the microsimulation is essential to arrive at a result like this - given only fertility and mortality data for the whole borough, we have been able to model growth at a higher geographical resolution thanks to the finer detail provided by census data, namely populations by ethnicity within each MSOA. 

### Taking it further
This projection omits crucial factors (most notably migration) in order to keep the worked example fairly simple, and the results presented here should not be considered realistic.

Readers are encouraged to clone the code and adapt it for their own use, or improve it. Pull requests are welcomed!


