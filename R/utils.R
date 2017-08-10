
# utils.R - utility functions

# calculate a single value diversity coefficient in [0,1] from a vector of populations for each ethnicity
diversityCoeff = function(pop) {
  # uses a value based on the normalised variance of the population
  # if pop all equal, returns 1 (max diversity)
  # if pop all one ethnicity, return 0
  # This is essentially 1- SAMPLE variance * n
  # Or 1 - POPULATION variance * n * n / (n-1)
  p = pop/sum(pop)
  n = length(p)
  return((1 - p %*% p)*n/(n-1))
}

#' diversity
#'
#' Calculates a diversity coefficient for a population, grouped by by MSOA
#' The coefficient is related to the normalised variance of the population
#' and will range from  0 (if only one ethnicity is present) to 1 (if equal
#' populations of each ethnicity).
#' @param population the synthesised or projected population
#' @return a two colum data table containing the MSOA and the diversity coefficient
#' @export
#' @examples
#' p = microsynthesise()
#' d = diversity(d)
diversity = function(synpop) {
  # get the MSOAs and ethnicities
  msoas = unique(synpop$MSOA)
  ethnicities = unique(synpop$Ethnicity)

  # preallocate the table
  div = data.table(MSOA=msoas, Value=rep(-1, length(msoas)))

  for (msoa in msoas) {
    pops = rep(-1, length(ethnicities))
    for (j in 1:length(ethnicities)) {
      pops[j] = nrow(synpop[MSOA==msoa & Ethnicity==ethnicities[j]])
    }
    div[MSOA==msoa]$Value = diversityCoeff(pops)
  }
  return(div)
}

#' growth
#'
#' Calculates growth rate by MSOA between a two synthetic populations
#' @param pop0 a data table containing the initial population
#' @param pop1 a data table containing the final population
#' @return a two column data table containing the MSOA and the diversity coefficient
#' @export
#' @examples
#' basepop = microsynthesise()
#' projpop = microsimulate(basepop,1)
#' g = growth(basePop, projpop)
growth = function(pop0, pop1) {
  # get the MSOAs
  msoas = unique(synpop$MSOA)

  # preallocate the table
  g = data.table(MSOA=msoas, Value=rep(-1, length(msoas)))
  for (msoa in msoas) {
    g[MSOA==msoa]$Value = nrow(pop0[MSOA==msoa]) / nrow(pop0[MSOA==msoa]) - 1.0
  }
  return(g)
}
