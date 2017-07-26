# usim_demog - Microsimulation for Demography Worked Examples

## Prerequisites

The code is written in R. We recommend the use of the most recent version of RStudio. Users will need sufficient admin priviledges to install packages.
The code is dependent on a number of standard (CRAN) packages, such as data.table, sf, leaflet, plotrix, devtools, Rcpp

The code is also dependent on the humanleague package which is currently available on github, and can be installed using the following command:
```
> devtools::install_github("CatchDat/humanleague")
```
## Static Microsynthesis

TODO...

## Dynamic Microsynthesis / Microsimulation

### Code
* [usim.R](projection/usim.R) - takes the input data (population aggregates) and synthesises an individual "base" population.  
* [proj.R](projection/proj.R) - takes the microsimulated data from above, then uses more input data (fertility/mortality rates) to project the population.  
* [graph.R](projection/graph.R) - graphic visualisations of the base and projected populations.  
* [map.R](projection/map.R) - geographic visualisations of the base and projected populations.  

### Input data
The input data consists of two distinct datasets: aggregate population data, and fertility/mortality rate data.

#### Aggregate Population Data
Population aggregate data is sourced from UK census 2011, for the London Borough of Tower Hamlets at middle-layer super output area (MSOA) resolution. MSOA corresponds to a subregion containing approximately 8000 people. Tower Hamlets is split into 32 MSOAs.

For the purposes of this worked example we have preprocessed the census data into the following csv files:

* [sexAgeEth.csv](projection/data/sexAgeEth.csv) - count of persons by MSOA by sex by age band by ethnicity
* [sexAgeYear.csv](projection/data/sexAgeYear.csv) - count of persons by MSOA by sex by age band by ethnicity

Categories
* MSOA: ONS code for the 32 MSOAs within Tower Hamlets
* Sex: M/F
* Age Band: 0-4, 5-7, 8-9, 10-14, 15, 16-17, 18-19, 20-24, 25-29, 30-34, 35-39, 40-44, 45-49, 50-54, 55-59, 60-64, 65-69, 70-74, 75-79, 80-84, 85+
* Age: individual years up to 84, then a single 85+
* Ethnicity: BAN (Bangladeshi), BLA (Black African), BLC (Black Caribbean), CHI (Chinese), IND (Indian), MIX (Mixed), OAS (Other Asian), OBL (Other Black), OTH (Other), PAK (Pakistani), WBI (White British), WHO (White Other)

NB The categories for Ethnicity have been reduced slightly from the original census categories in order to be consistent with the fertility/mortality data.

#### Fertility/mortality rate data

Fertility and mortality rate data is taken from the Ethpop database ?ref, and gives rates by ethnicity and single year of age, for the entire borough. (We thus assume that the rates do not vary by MSOA) 

### Methodology

#### Static microsynthesis (usim.R)

In this example, microsynthesis is necessary due to the fact that for we have fertility/mortality rates for a single year of age, but census data does not give us ethnicity by single year of age. Using microsynthesis, we can generate a synthetic population that matches both the ethnicity total (by age band) and the population total (by single year of age) for each geographical area and gender. 

For the microsynthesis we use the humanleague R package that generates a population using quasirandom sampling of the marginal data.

#### Projection

