set.seed(20191204)
cpos <- find_critical_pos(rho = c(.1, .7), sample_size_max = 1000,
                          n_studies = 40000)
sim <- find_critical_pos(rho = .5, precision_rel = 0.1)

cpos_old <- read.csv("cpos4.csv")
cpos_old$precision_rel <- as.numeric(c(NA, NA))
test_that("previous values can be reproduced", {
  expect_equal(cpos, cpos_old, check.attributes = FALSE)
})

# https://github.com/nicebread/corEvol
nicebread <- matrix(c(252, 66, 360, 96, 474, 129), nrow = 2)
diff_rel <- (nicebread - cpos[, 2:4]) / nicebread

test_that("Schoenbrodt and Perugini's values are close to fastpos' values for
          rho = .1 and .7", {
  # average relative deviation within 4%
  expect_true(abs(mean(unlist(diff_rel))) < 0.04,
              info = print(round(abs(mean(unlist(diff_rel))), 2)))
  # individual relative deviation within 10%
  expect_true(all(abs(diff_rel) < .10),
              info = print(diff_rel))
})

cpos_mc <- find_critical_pos(rho = c(.1, .7), sample_size_max = 1000,
                             n_studies = 40000,
                             n_cores = future::availableCores())

diff_rel_mc <- (nicebread - cpos_mc[, 2:4]) / nicebread

test_that("Schoenbrodt and Perugini's values are close to fastpos' values for
          rho = .1 and .7 (with multiple cores)", {
  # average relative deviation within 4%
  expect_true(abs(mean(unlist(diff_rel_mc))) < 0.04,
              info = print(round(abs(mean(unlist(diff_rel_mc))), 2)))
  # individual relative deviation within 10%
  expect_true(all(abs(diff_rel_mc) < .10),
              info = print(diff_rel_mc))
})

cpos_mc_replace <- find_critical_pos(rho = c(.1, .7), sample_size_max = 1000,
                             n_studies = 40000,
                             n_cores = future::availableCores(),
                             replace = FALSE)

diff_rel_mc_replace <- (nicebread - cpos_mc[, 2:4]) / nicebread

test_that("Schoenbrodt and Perugini's values are close to fastpos' values for
          rho = .1 and .7 (with multiple cores) and replace = TRUE", {
  # average relative deviation within 4%
  expect_true(abs(mean(unlist(diff_rel_mc_replace))) < 0.04,
              info = round(abs(mean(unlist(diff_rel_mc_replace))), 2))
  # individual relative deviation within 10%
  expect_true(all(abs(diff_rel_mc_replace) < .10),
              info = print(diff_rel_mc_replace))
})

test_that("unloading package works",
          expect_null(detach(package:fastpos, unload = TRUE)))


test_that("relative precision works",
          expect_equal(c(sim$lower_limit, sim$upper_limit), c(.45, .55)))

sim_b <- find_critical_pos(rhos = c(0.1, 0.2, 0.3),
                          lower_limits = c(0.05, 0.18, 0.2),
                          upper_limits = c(0.13, 0.25, 0.4))
sim_bsingle <- find_one_critical_pos(rho = 0.5,
                                     lower_limit = 0.37,
                                     upper_limit = 0.63)

test_that("lower limit and upper limit works",
          expect_equal(as.numeric(c(sim_bsingle$summary["lower_limit"],
                         sim_bsingle$summary["upper_limit"])),
                       c(0.37, .63)))

test_that("lower limits and upper limits works",
          expect_equal(c(sim_b$lower_limit, sim_b$upper_limit),
                       c(.05, 0.18, 0.2, 0.13, 0.25, 0.4)))

test_that("create_pop_inexact (not used atm) works",
          expect_equal(round(cor(create_pop_inexact(0.5, 1e6))[1, 2], 2), 0.50))
