set.seed(20191204)
cpos <- find_critical_pos(rho = c(.1, .7), sample_size_max = 1000,
                          n_studies = 40000)
sim <- find_critical_pos(rho = .5, precision_rel = T)

# cpos_old <- read.csv("tests/testthat/cpos4.csv")
# write.csv(cpos, "tests/testthat/cpos4.csv", row.names = F)
cpos_old <- read.csv("cpos4.csv")
test_that("previous values can be reproduced", {
  expect_equal(cpos, cpos_old, check.attributes = F)
})

# https://github.com/nicebread/corEvol
nicebread <- matrix(c(252, 66, 360, 96, 474, 129), nrow = 2)
diff_rel <- (nicebread-cpos[,2:4])/nicebread

test_that("Schoenbrodt and Perugini's values are close to fastpos' values for
          rho = .1 and .7", {
  # average relative deviation within 1%
  expect_true(abs(mean(unlist(diff_rel))) < 0.01)
  # individual relative deviation within 2%
  expect_true(all(abs(diff_rel) < .02))
})

cpos_mc <- find_critical_pos(rho = c(.1, .7), sample_size_max = 1000,
                             n_studies = 40000,
                             n_cores = future::availableCores())

diff_rel_mc <- (nicebread-cpos_mc[,2:4])/nicebread

test_that("Schoenbrodt and Perugini's values are close to fastpos' values for
          rho = .1 and .7 (with multiple cores)", {
  # average relative deviation within 1%
  expect_true(abs(mean(unlist(diff_rel_mc))) < 0.01)
  # individual relative deviation within 2%
  expect_true(all(abs(diff_rel_mc) < .02))
})

test_that("unloading package works",
          expect_null(detach(package:fastpos, unload = T)))


test_that("relative precision works",
          expect_equal(c(sim$lower_limit, sim$upper_limit), c(.45, .55)))


