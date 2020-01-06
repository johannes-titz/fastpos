set.seed(20191204)
cpos <- find_critical_pos(rho = c(.1, .7), sample_size_max = 1000,
                          n_studies = 10000)
cpos_old <- read.csv("cpos.csv")
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
