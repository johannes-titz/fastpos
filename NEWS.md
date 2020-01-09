# fastpos 0.2.0

* If the corridor of stability is not reached, NA is returned by an internal
function that *simulate_pos* build upon. *n_not_breached* is simply the number of
NA values. The maximum sample size is still used for the calculation of the
quantiles if the corridor was not reached, which should be better than ignoring
the specific study altogether (i.e. treating it as an NA value). 

* *simulate_pos* now returns an IntegerVector (instead of NumericVector) to
better handle NA values.

* A simple test for relative precision was added. Another test was added that
unloads the package. Code coverage is now 100%.

* The vignette and readme were improved substantially. Word choice and grammar
were checked by an editor. A section on the speed of *fastpos* in comparison to
*corEvol* was added including a theoretical argument and an empirical test.

# fastpos 0.1.0

* First release