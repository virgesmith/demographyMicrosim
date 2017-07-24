
# utils.R - utility functions

# calculate a single value diversity coefficient in [0,1] from a vector of populations for each ethnicity
diversityCoeff=function(pop) {
  # uses a value based on the normalised variance of the population
  # if pop all equal, returns 1 (max diversity)
  # if pop all one ethnicity, return 0
  return(1-var(pop/sum(pop))*length(pop))  
}

