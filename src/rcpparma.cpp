// -*- mode: C++; c-indent-level: 4; c-basic-offset: 4; indent-tabs-mode: nil; -*-

// we only include RcppArmadillo.h which pulls Rcpp.h in for us
#include "RcppArmadillo.h"
#include <RcppArmadilloExtensions/sample.h>
using namespace Rcpp;

#if _WIN32
#include <io.h>
#define ISATTY _isatty
#define FILENO _fileno
#else
#include <unistd.h>
#define ISATTY isatty
#define FILENO fileno
#endif

// [[Rcpp::depends(RcppProgress)]]
#include <progress.hpp>
#include <progress_bar.hpp>
//
// via the depends attribute we tell Rcpp to create hooks for
// RcppArmadillo so that the build process will know what to do
//
// [[Rcpp::depends(RcppArmadillo)]]

//' Run a single sequential study to find a critical n.
//' @param x_pop First vector of population.
//' @param y_pop Second vector of population.
//' @param index_pop Vector from 1:length(x_pop) (more efficient than to
//'   create).
//' @param lower_limit Lower limit of corridor of stability.
//' @param upper_limit Upper limit of corridor of stability.
//' @param replace Whether drawing samples is with replacement or not.
//' @param sample_size_max How many participants to draw at maximum.
//' @param sample_size_min Minimum sample size to start in corridor of
//'   stability.
//' @return Sample size where corridor of stability is reached.
//' @noRd
// [[Rcpp::export]]
int simulate_one_pos(NumericVector x_pop,
              NumericVector y_pop,
              NumericVector index_pop,
              int sample_size_min,
              int sample_size_max,
              bool replace,
              float lower_limit,
              float upper_limit){

  NumericVector index = RcppArmadillo::sample(index_pop, sample_size_max,
                                              replace);

  NumericVector X = x_pop[index];
  NumericVector Y = y_pop[index];
  // change n to sample
  int n = sample_size_max;

  float sum_X = 0, sum_Y = 0, sum_XY = 0;
  float squareSum_X = 0, squareSum_Y = 0;
  float corr = 0;

  for (int i = 0; i < n; i++) {
    // sum of elements of array X.
    sum_X += X[i];

    // sum of elements of array Y.
    sum_Y += Y[i];

    // sum of X[i] * Y[i].
    sum_XY = sum_XY + X[i] * Y[i];

    // sum of square of array elements.
    squareSum_X += X[i] * X[i];
    squareSum_Y += Y[i] * Y[i];
  }

  corr = float(n * sum_XY - sum_X * sum_Y)
    / sqrt((n * squareSum_X - sum_X * sum_X)
             * (n * squareSum_Y - sum_Y * sum_Y));
  // if the correlation is outside for the whole sample, there is no
  // point of stability (sample size is too small)
  if ((corr < lower_limit) | (corr > upper_limit)) {
    n = NA_INTEGER;
  } else {
  while ((corr >= lower_limit) & (corr <= upper_limit) & (n > sample_size_min)) {
    // use formula for calculating correlation coefficient.
    sum_X -= X[n-1];

    // sum of elements of array Y.
    sum_Y -= Y[n-1];

    // sum of X[i] * Y[i].
    sum_XY -= X[n-1] * Y[n-1];

    // sum of square of array elements.
    squareSum_X -= X[n-1] * X[n-1];
    squareSum_Y -= Y[n-1] * Y[n-1];

    n--;
    corr = float(n * sum_XY - sum_X * sum_Y)
      / sqrt((n * squareSum_X - sum_X * sum_X)
               * (n * squareSum_Y - sum_Y * sum_Y));
               // now subtract the last value

  }
  }
  return n;
}

//' Simulate several points of stability
//'
//' Runs several simulations and returns the points of stability, which can then
//' be further processed to calculate the critical point of stability. This
//' function should only be used if you need the specific points of stability.
//' For instance, if you want to study the method in more detail and the higher
//' level functions are not sufficient.
//'
//' If you just want to calculate a quantile of the distribution, use the main
//' function of the package [fastpos::find_critical_pos()]).
//'
//' @param x_pop First vector of population.
//' @param y_pop Second vector of population.
//' @param lower_limit Lower limit of corridor of stability.
//' @param upper_limit Upper limit of corridor of stability.
//' @param replace Whether drawing samples is with replacement or not.
//' @param sample_size_max How many participants to draw at maximum.
//' @param n_studies How many studies to conduct.
//' @param sample_size_min Minimum sample size to start in corridor of
//'   stability.
//' @param progress Should progress bar be displayed? Boolean, default is FALSE.
//' @return Vector of sample sizes at which corridor of stability was reached.
//' @examples
//' # set up a population
//' pop <- fastpos::create_pop(rho = 0.5, size = 1e6)
//' # create a distribution of points of stability
//' pos <- simulate_pos(x_pop = pop[,1], y_pop = pop[,2], n_studies = 100,
//'                     sample_size_min = 20, sample_size_max = 1e3,
//'                     replace = TRUE, lower_limit = 0.4, upper_limit = 0.6,
//'                     progress = TRUE)
//' # calculate quantiles or any other parameter of the distribution
//' quantile(pos, c(.8, .9, .95), na.rm = TRUE)
//' @export
// [[Rcpp::export]]
IntegerVector simulate_pos(NumericVector x_pop,
                           NumericVector y_pop,
                           int n_studies,
                           int sample_size_min,
                           int sample_size_max,
                           bool replace,
                           float lower_limit,
                           float upper_limit,
                           bool progress){
  IntegerVector ret(n_studies);
  int npop = x_pop.size();
  NumericVector index_pop(npop);
  for (int i = 0; i < npop; i++){
    index_pop[i] = i;
  }
  Progress p(n_studies, progress);
  for (int k = 0; k < n_studies; k++){
    if (k % 5000 == 0){
      if (Progress::check_abort()){
        return(IntegerVector::create(-1));
      }
    }
    p.increment();
    ret[k] = simulate_one_pos(x_pop, y_pop, index_pop, sample_size_min,
                              sample_size_max, replace, lower_limit,
                              upper_limit);
  }
  return(ret);
}
