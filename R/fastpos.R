#' @useDynLib fastpos
#' @importFrom Rcpp sourceCpp
NULL

#' Stops execution without giving error
#'
#' This is useful to have a consistent behavior when the user interrupts
#' function execution but this interruption is not catched by C++. If this
#' happens nothing is returned. But if C++ catches the interrupt, we need to
#' stop execution ourselves (and also return nothing).
#' @noRd
stop_quietly <- function() {
  blank_msg <- sprintf("\r%s\r", paste(rep("", getOption("width") - 1L),
                                      collapse =  " "))
  stop(simpleError(blank_msg))
}

#' Creates a population with a specified correlation.
#'
#' @param rho Population correlation.
#' @param size Population size.
#' @return Two-dimensional population matrix with a specific correlation.
#' @examples
#' pop <- create_pop(0.5, 1e5)
#' cor(pop)
#' @noRd
#' @importFrom MASS mvrnorm
create_pop_inexact <- function(rho, size) {
  mu <- c(1, 2)
  s1 <- 2
  s2 <- 8
  sigma <- matrix(c(s1^2, s1 * s2 * rho, s1 * s2 * rho, s2^2), 2)
  pop <- MASS::mvrnorm(n = size, mu = mu, Sigma = sigma)
  pop
}

#' Creates a population with a specified correlation.
#'
#' The correlation will be exactly the one specified. The used method is
#' described here:
#' https://stats.stackexchange.com/questions/15011/generate-a-random-variable-with-a-defined-correlation-to-an-existing-variables/15040#15040
#'
#' @param rho Population correlation.
#' @param size Population size.
#' @return Two-dimensional population matrix with a specific correlation.
#' @examples
#' pop <- create_pop(rho = 0.5, size = 1e6)
#' cor(pop)
#' @export
#' @importFrom stats residuals sd rnorm lm.fit
create_pop <- function(rho, size) {
  y <- stats::rnorm(size)
  x <- stats::rnorm(size)
  y_perp <- stats::residuals(stats::lm.fit(cbind(1, y), x))
  x <- rho * stats::sd(y_perp) * y + y_perp * stats::sd(y) * sqrt(1 - rho^2)
  matrix(c(x, y), ncol = 2)
}

#' Run simulation for one specific correlation.
#'
#' @param rho Population correlation.
#' @param lower_limit Lower limit of corridor, overrides precision parameter
#' @param upper_limit Upper limit of corridor, overrides precision parameter
#' @inheritParams find_critical_pos
#' @return A list with two elements, (1) a data frame called "summary"
#'   containing all the above information as well as the critical sample sizes
#'   (points of stability) for the confidence-levels specified and (2) vector
#'   "n" with the sample size from each study (e.g. for plotting the
#'   distribution)
#' @examples
#' find_one_critical_pos(rho = 0.5)
#' @noRd
#' @importFrom stats cor quantile
#' @importFrom future future value
#' @importFrom tibble lst
find_one_critical_pos <- function(rho, sample_size_min = 20,
                                  sample_size_max = 1e3,
                                  replace = TRUE, n_studies = 1e3,
                                  pop_size = 1e6,
                                  precision_absolute = .1,
                                  precision_relative = NA,
                                  confidence_levels = c(.8, .9, .95),
                                  n_cores = 1,
                                  lower_limit = NA,
                                  upper_limit = NA,
                                  progress = show_progress()) {

  # create corridor of stability
  corridor_function <- choose_corridor_function(
    !is.na(precision_absolute), !is.na(precision_relative),
    !is.na(lower_limit), !is.na(upper_limit)
  )
  corridor_values <- corridor_function(rho, precision_absolute,
                                       precision_relative,
                                       lower_limit, upper_limit)

  lower_limit <- corridor_values$lower_limit
  upper_limit <- corridor_values$upper_limit
  precision_absolute <- corridor_values$precision_absolute
  precision_relative <- corridor_values$precision_relative

  # create bivariate population distribution
  pop <- create_pop(rho, pop_size)

  x <- pop[, 1]
  y <- pop[, 2]
  rho_pop <- stats::cor(x, y)

  # create dist of pos

 # we will use 1 normal invocation and n_cores - 1 futures, this way we have
  # a progress bar
  if (n_cores > 1){
    f <- list()
    for (ii in seq(n_cores - 1)) { # -1 because we run one outside of multisession
      f[[ii]] <- future::future({
        simulate_pos(x, y, ceiling(n_studies/(n_cores)), sample_size_min,
                     sample_size_max, replace, lower_limit, upper_limit,
                     progress = FALSE)
      }, seed = TRUE)
    }
    res <- simulate_pos(x, y, ceiling(n_studies/n_cores), sample_size_min,
                        sample_size_max, replace, lower_limit, upper_limit,
                        progress = TRUE)
    v <- unlist(lapply(f, FUN = future::value))
    res <- c(res, v)
  } else {
    res <- simulate_pos(x, y, n_studies, sample_size_min, sample_size_max, T,
                        lower_limit, upper_limit,
                        progress = TRUE)
  }

  # on interruption, C++ will return -1 (if R interrupts by itself, nothing
  # will be returned, it just stops)
  if (length(res) == 1) {
    if (res == -1) stop_quietly()
  }
  names(res) <- unlist(paste("study ", 1:length(res)))
  n_not_breached <- sum(is.na(res))

  # calc critical pos
  # use max sample size for those studies where the corridor was not breached
  thequantiles <- stats::quantile(c(res, rep(sample_size_max, n_not_breached)),
                                    confidence_levels, na.rm = TRUE)
  return(list(summary = unlist(tibble::lst(
    rho_pop,
    pos = unlist(thequantiles),
    sample_size_min,
    sample_size_max,
    lower_limit,
    upper_limit,
    n_studies = length(res),
    n_not_breached,
    precision_absolute,
    precision_relative)),
    n = res
  ))
}

#' Find the critical point of stability
#'
#' Run simulations for one or several population correlations and return the
#' critical points of stability (POS). The critical point of stability is the
#' sample size at which a certain percentage of studies will fall into an a
#' priori specified interval and stay in this interval if the sample size is
#' increased further.
#'
#' @param rho Vector of population correlations (can also be a single correlation).
#' @param precision_absolute Precision around the correlation which is acceptable
#'   (defaults to 0.1). The precision will determine the corridor of stability which is
#'   just rho+-precision. Can be a single value or a vector (different values for
#'   different rhos).
#' @param confidence_levels Confidence levels for point of stability. This corresponds
#'   to the quantile of the distribution of all found critical sample sizes (defaults
#'   to c(.8, .9, .95)). A single value can also be used. Note that this value is fixed
#'   for all rhos! You cannot specify different levels for different rhos.
#' @param sample_size_min Minimum sample size for each study (defaults to 20). A vector
#'   can be used (different values for different rhos).
#' @param sample_size_max Maximum sample size for each study (defaults to 1e3). A
#'   vector can be used (different values for different rhos). If you get a warning
#'   that the corridor of stability was not reached, you should increase this value.
#'   But note that this will increase the time for the simulation.
#' @param n_studies Number of studies to run for each rho (defaults to 1e4). A vector
#'   can be used (different values for different rhos).
#' @param n_cores Number of cores to use for simulation. Defaults to 1.
#' @param pop_size Population size (defaults to 1e6). This is the size of the
#'   population from which value pairs for correlations are drawn. This value should
#'   usually not be decreased as it can lead to less accurate results.
#' @param replace Whether drawing samples is with replacement or not. Default is TRUE,
#'   which usually should not be changed. This parameter is mainly of interest for
#'   researchers studying the method in more detail. A vector can be used (different
#'   values for different rhos).
#' @param precision_relative Relative precision around the correlation
#'   (rho+-rho*precision), if set, it will overwrite precision_absolute. A vector can
#'   be used (different values for different rhos).
#' @param lower_limit Lower limit of corridor, overrides precision parameters. A vector
#'   can be used (different values for different rhos). If used, upper_limit must also
#'   be set.
#' @param upper_limit Upper limit of corridor, overrides precision parameters. A vector
#'   can be used (different values for different rhos). If used, lower_limit must also
#'   be set.
#' @param progress Should progress bar be displayed? Logical, default is to show
#'   progress when run in interactive mode.
#' @param precision `r lifecycle::badge("deprecated")`, use precision_absolute instead
#' @param precision_rel `r lifecycle::badge("deprecated")`, use precision_relative
#'   instead
#' @param rhos `r lifecycle::badge("deprecated")`, use rho instead
#' @return A data frame containing all the above information, as well as the critical
#'   points of stability.
#'
#' The critical points of stability follow directly after the first column (rho)
#' and are named pos.confidence-level, e.g. pos.80, pos.90, pos.95 for the
#' default confidence levels.
#'
#' @examples
#' find_critical_pos(rho = 0.5, n_studies = 1e3)
#' find_critical_pos(rho = c(0.4, 0.5), n_studies = 1e3)
#' @export
#' @importFrom lifecycle deprecated is_present deprecate_warn badge
#' @importFrom plyr ldply
find_critical_pos <- function(rho,
                              precision_absolute = 0.1,
                              confidence_levels = c(.8, .9, .95),
                              sample_size_min = 20,
                              sample_size_max = 1e3,
                              n_studies = 1e4,
                              n_cores = 1,
                              pop_size = 1e6,
                              replace = TRUE,
                              precision_relative = NA,
                              lower_limit = NA,
                              upper_limit = NA,
                              progress = show_progress(),
                              precision = lifecycle::deprecated(),
                              precision_rel = lifecycle::deprecated(),
                              rhos = lifecycle::deprecated()) {
  if (.Platform$OS.type == "windows" & n_cores > 1) {
    n_cores <- 1
    warnings("On Windows only one core can be used. Sorry.")
  }
  if (lifecycle::is_present(precision)) {
    lifecycle::deprecate_warn(
      when = "0.6.0",
      what = "find_critical_pos(precision)",
      details = "find_critical_pos(precision_absolute)"
    )
    precision_absolute <- precision
  }

  if (lifecycle::is_present(rhos)) {
    lifecycle::deprecate_warn(
      when = "0.6.0",
      what = "find_critical_pos(rhos)",
      details = "find_critical_pos(rho)"
    )
    rho <- rhos
  }

  if (lifecycle::is_present(precision_rel)) {
    lifecycle::deprecate_warn(
      when = "0.6.0",
      what = "find_critical_pos(precision_rel)",
      details = "Use precision_relative instead. Note that precision_relative takes a numeric value, not a logical!"
    )
    precision_relative <- precision_absolute
  }

  result <- mapply(find_one_critical_pos,
                   rho = rho,
                   sample_size_max = sample_size_max,
                   sample_size_min = sample_size_min,
                   n_studies = n_studies,
                   precision_absolute = precision_absolute,
                   precision_relative = precision_relative,
                   lower_limit = lower_limit,
                   upper_limit = upper_limit,
                   MoreArgs = list(confidence_levels = confidence_levels,
                                   n_cores = n_cores,
                                   pop_size = pop_size,
                                   progress = progress),
                   SIMPLIFY = FALSE)
  summary <- lapply(result, function(x) x[[1]])
  summary <- plyr::ldply(summary)
  sum_n_not_breached <- sum(summary$n_not_breached)
  if (sum_n_not_breached > 0) {
    warning("\n", sum_n_not_breached,
            " simulation[s] did not reach the corridor of stability",
            ".\nIncrease sample_size_max and rerun the simulation.",
            sep = "")
  }
  summary
}

.onUnload <- function(libpath) {
  library.dynam.unload("fastpos", libpath)
}

#' @importFrom tibble lst
create_corridor_absolute <- function(rho, precision_absolute,
                                     precision_relative,
                                     lower_limit,
                                     upper_limit) {
  limits <- rho + c(-1, 1) * precision_absolute
  precision_relative <- NA
  lower_limit <- limits[1]
  upper_limit <- limits[2]
  return(tibble::lst(lower_limit, upper_limit, precision_absolute,
                     precision_relative))
}

#' @importFrom tibble lst
create_corridor_relative <- function(rho, precision_absolute,
                                     precision_relative, lower_limit,
                                     upper_limit) {
  limits <- rho * (1 + c(-1, 1) * precision_relative)
  precision_absolute <- NA
  lower_limit <- limits[1]
  upper_limit <- limits[2]
  return(tibble::lst(lower_limit, upper_limit, precision_absolute,
                     precision_relative))
}

#' @importFrom tibble lst
create_corridor_manual <- function(rho, precision_absolute,
                                   precision_relative, lower_limit,
                                   upper_limit) {
  precision_absolute <- NA
  precision_relative <- NA
  return(tibble::lst(lower_limit, upper_limit, precision_absolute,
                     precision_relative))
}

#' @importFrom tibble lst
create_corridor_error <- function() {
  stop("Your corridor parameters are not correct. Either specify precision_absolute, precision_relative, or lower_limit AND upper_limit")
}

choose_corridor_function <- function(precision_absolute,
                                     precision_relative,
                                     lower_limit, upper_limit) {
  args <- as.numeric(c(precision_absolute, precision_relative, lower_limit,
                       upper_limit))
  df <- expand.grid(0:1, 0:1, 0:1, 0:1)
  cases <- apply(df, 1, paste0, collapse = "")
  case <- which(cases == paste(args, collapse = ""))

  f <- rep_f(length(cases), create_corridor_error)
  f[13:16] <- rep_f(4, create_corridor_manual)
  f[[2]] <- create_corridor_absolute
  f[3:4] <- rep_f(2, create_corridor_relative)
  f[[case]]
}

rep_f <- function(n, f) {
  lapply(1:n, function(x) f)
}

show_progress <- function() {
  # it is also possible to use isatty(stdout) and Sys.getenv("RSTUDIO"), which is 1
  # when RSTUDIO is used
  progress <- interactive()
  return(progress)
}