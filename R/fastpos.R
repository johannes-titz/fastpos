#' @useDynLib fastpos
#' @importFrom Rcpp sourceCpp
NULL

#' @details
#' In most cases you will just need the function \code{\link{fastpos}}which will
#' you give you the points of stability for your specific parameters. If you are
#' interested in more complicated analysis you might want to look at the
#' functions that fastpos builds upon:
#'
#' \code{\link{get_one_n}} and \code{\link{get_several_n}} are the workhorse of
#' the package. They call C++ functions to calculate correlations sequentially
#' and they do it pretty fast, thus fastpos.
#'
#' \code{\link{find_pos}} calls \code{\link{get_several_n}} and then calculates
#' the quantiles for the specified confidence levels. It returns an informative
#' summary and the individual critical sample sizes. If you are interested in
#' working with the distribution of critical sample sizes (instead of just the
#' point of stability) you could use this function.
#'
#' \code{\link{create_pop}} creates the population matrix by using mvrnorm. This
#' is a much simpler way compared to Schönbrodt and Perugini's used functions,
#' but the results do not seem to be different. If you are interested in how
#' population parameters (e.g. skewness) affect the point of stability, you
#' should rather refer to the functions in Schönbrodt and Perugini's work.
#'
#' \code{\link{run_one_simulation}} does what it says, it runs one simulation
#' for a specific population correlation. It first creates a population
#' (\code{\link{create_pop}}), then calculates the limits of the corridor and
#' then calls \code{\link{find_pos}}.
#'
#' \code{\link{fastpos}} simply calls run_one_simulation several times if you
#' specify several population correlations. One could also call it
#' run_several_simulations, but the main function of a package is conveniently
#' called the same as the package.
#'
#' @references Schönbrodt, F. D. & Perugini, M. (2013). At what sample size do
#' correlations stabilize? \emph{Journal of Research in Personality, 47},
#' 609-612. \url{https://doi.org/10.1016/j.jrp.2013.05.009}
#'
#' Schönbrodt, F. D. & Perugini, M. (2018) Corrigendum to “At what sample size
#' do correlations stabilize?” [J. Res. Pers. 47 (2013) 609–612.
#' https://doi.org/10.1016/j.jrp.2013.05.009]. \emph{Journal of Research in
#' Personality, 74}, 194. \url{https://doi.org/10.1016/j.jrp.2018.02.010}
#' @keywords internal
"_PACKAGE"

#' Creates a population with a specified correlation.
#'
#' @param rho Population correlation.
#' @param size Population size.
#' @return Two-dimensional population matrix with a specific correlation.
#' @examples
#' pop <- create_pop(0.5, 100000)
#' cor(pop)
#' @export
create_pop <- function(rho, size){
  mu <- c(1, 2)
  s1 <- 2
  s2 <- 8
  sigma <- matrix(c(s1^2, s1 * s2 * rho, s1 * s2 * rho, s2^2), 2)
  pop <- MASS::mvrnorm(n = size, mu = mu, Sigma = sigma)
  pop
}

#' Conducts several simulation studies to find point of stability.
#'
#' @param pop Ttwo-dimensional population matrix.
#' @param n_studies How many studies to conduct.
#' @param sample_size_max How many participants to draw initially.
#' @param lower_limit Lower limit of corridor of stability.
#' @param upper_limit Upper limit of corridor of stability.
#' @param sample_size_min Minimum sample size to start in corridor of stability.
#' @param confidence_levels Confidence levels for points of stability. This
#'   corresponds to the quantile of the distribution of all found critical
#'   sample sizes. Defaults to c(.8, .9, .95).
#' @return A list with two elements, (1) a data frame called "summary"
#'   containing all the above information as well as the critical sample sizes
#'   (points of stability) for the confidence-levels specified and (2) vector
#'   "n" with the sample size from each study (e.g. for plotting the
#'   distribution).
#' @examples
#' pop <- fastpos::create_pop(rho = .5, size = 100000)
#' res <- find_pos(pop, 100, 20, 1000, .4, .6)
#' res$summary
#' hist(res$n)
#' @export
find_pos <- function(pop, n_studies, sample_size_min, sample_size_max,
                     lower_limit, upper_limit,
                     confidence_levels = c(.8, .9, .95)){
  x <- pop[,1]
  y <- pop[,2]
  rho_pop <- stats::cor(x, y)
  res <- get_several_n(x, y, n_studies, sample_size_min, sample_size_max, T,
                       lower_limit, upper_limit)
  names(res) <- unlist(paste("study ", 1:length(res)))
  # TODO: exception handling
  if (sample_size_max %in% res) {
    cat("\nAt least one study did not reach the corridor of stability at a ",
        "sample size of ", sample_size_max,
        ".\nIncrease sample_size_max to solve the problem.", sep = "")
  }
  thequantiles <- stats::quantile(res, confidence_levels)
  return(list(summary = c(rho_pop = rho_pop, thequantiles,
                          sample_size_min = sample_size_min,
                          sample_size_max = sample_size_max,
                          lower_limit=lower_limit,
                          upper_limit=upper_limit,
                          n_studies = n_studies), n = res))
}

#' Run simulation for one specific correlation.
#'
#' @param rho Population correlation.
#' @param pop_size Population size.
#' @param sample_size_max Number of participants for each study.
#' @param n_studies Number of studies to run.
#' @param precision Precision around the correlation which is acceptable
#' @param precision_rel Whether the precision is absolute (rho+-precision or
#'   relative rho+-rho*precision).
#' @param sample_size_min Minimum sample size to start in corridor of stability.
#' @param confidence_levels Confidence levels for point of stability. This
#'   corresponds to the quantile of the distribution of all found critical
#'   sample sizes. Defaults to c(.8, .9, .95).
#' @return A list with two elements, (1) a data frame called "summary"
#'   containing all the above information as well as the critical sample sizes
#'   (points of stability) for the confidence-levels specified and (2) vector
#'   "n" with the sample size from each study (e.g. for plotting the
#'   distribution)
#' @examples
#' run_one_simulation(rho = 0.5)
#' @export
run_one_simulation <- function(rho, sample_size_min = 20,
                               sample_size_max = 1000, n_studies = 1000,
                               pop_size = 1e6, precision = .1,
                               precision_rel = T,
                               confidence_levels = c(.8, .9, .95)){
  if (precision_rel) {
    limits <- rho * (1 + c(-1, 1) * precision)
  } else {
    limits <- rho + c(-1, 1) * precision
  }
  pop <- create_pop(rho, pop_size)
  find_pos(pop, n_studies, sample_size_min, sample_size_max, limits[1],
           limits[2], confidence_levels)
}

#' Run simulations for one or several population correlations.
#'
#' @param rhos Vector of population correlations (can also be a single
#'   correlation).
#' @param sample_size_max Number of participants for each study.
#' @param n_studies Number of studies to run for each rho.
#' @param precision Precision around the correlation which is acceptable.
#' @param precision_rel Whether the precision is absolute (rho+-precision or
#'   relative rho+-rho*precision).
#' @param sample_size_min Minimum sample size to start in corridor of stability.
#' @param confidence_levels Confidence levels for point of stability. This
#'   corresponds to the quantile of the distribution of all found critical
#'   sample sizes. Defaults to c(.8, .9, .95).
#' @return A data frame containing all the above information, as well as the
#'   points of stability.
#' @examples
#' fastpos(rho = 0.5)
#' fastpos(rho = c(0.4, 0.5))
#' @export
fastpos <- function(rhos, sample_size_min = 20, sample_size_max = 1000,
                            n_studies = 10000,
                            precision = 0.1, precision_rel = F,
                            confidence_levels = c(.8, .9, .95)) {
  result <- lapply(rhos, run_one_simulation,
                   sample_size_min = sample_size_min,
                   sample_size_max = sample_size_max,
                   n_studies = n_studies,
                   precision = precision,
                   precision_rel = precision_rel,
                   confidence_levels = confidence_levels)

  summary <- lapply(result, function(x) x[[1]])
  summary <- plyr::ldply(summary)
  summary <- cbind(summary, precision, precision_rel)
  summary
}

# should this go in zzz.R? see wickham
.onAttach <- function(libname, pkgname) {
  packageStartupMessage("Welcome to fastpos")
}

.onUnload <- function (libpath) {
  library.dynam.unload("fastpos", libpath)
}