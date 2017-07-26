
# utils.R - utility functions

# calculate a single value diversity coefficient in [0,1] from a vector of populations for each ethnicity
diversityCoeff=function(pop) {
  # uses a value based on the normalised variance of the population
  # if pop all equal, returns 1 (max diversity)
  # if pop all one ethnicity, return 0
  # This is essentially 1- SAMPLE variance * n 
  # Or 1 - POPULATION variance * n * n / (n-1)
  p = pop/sum(pop)
  n = length(p)
  return((1 - p %*% p)*n/(n-1))
}


