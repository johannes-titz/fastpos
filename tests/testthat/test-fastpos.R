test_that("previous values can be reproduced", {
  set.seed(20191204)
  cpos <- suppressWarnings(
    find_critical_pos(rho = c(.1, .7), sample_size_max = 1e3,
                      n_studies = 40e3)
  )
  # https://github.com/nicebread/corEvol
  nicebread <- matrix(c(252, 66, 360, 96, 474, 129), nrow = 2)

  cpos_old <- read.csv("cpos4.csv")
  cpos_old$precision_rel <- as.numeric(c(NA, NA))

  diff_rel <- (nicebread - cpos[, 2:4]) / nicebread

  expect_equal(cpos, cpos_old, check.attributes = FALSE)
  # average relative deviation within 4%
  expect_true(abs(mean(unlist(diff_rel))) < 0.04,
              info = print(round(abs(mean(unlist(diff_rel))), 2)))
  # individual relative deviation within 10%
  expect_true(all(abs(diff_rel) < .10), info = print(diff_rel))

  cpos_mc <- suppressWarnings(
    find_critical_pos(rho = c(.1, .7), sample_size_max = 1e3,
                      n_studies = 40e3,
                      n_cores = future::availableCores())
  )

  diff_rel_mc <- (nicebread - cpos_mc[, 2:4]) / nicebread

  # average relative deviation within 4%
  expect_true(abs(mean(unlist(diff_rel_mc))) < 0.04,
              info = print(round(abs(mean(unlist(diff_rel_mc))), 2)))
  # individual relative deviation within 10%
  expect_true(all(abs(diff_rel_mc) < .10), info = print(diff_rel_mc))

  diff_rel_mc_replace <- (nicebread - cpos_mc[, 2:4]) / nicebread

  cpos_mc_replace <- suppressWarnings(
    find_critical_pos(rho = c(.1, .7), sample_size_max = 1e3,
                      n_studies = 40e3,
                      n_cores = future::availableCores(),
                      replace = FALSE)
  )
  # average relative deviation within 4%
  expect_true(abs(mean(unlist(diff_rel_mc_replace))) < 0.04,
              info = round(abs(mean(unlist(diff_rel_mc_replace))), 2))
  # individual relative deviation within 10%
  expect_true(all(abs(diff_rel_mc_replace) < .10),
              info = print(diff_rel_mc_replace))
})

test_that("unloading package works", {
          expect_null(detach(package:fastpos, unload = TRUE))
  })

test_that("create_pop_inexact (not used atm) works", {
          expect_equal(round(cor(create_pop_inexact(0.5, 1e6))[1, 2], 2), 0.50)
  })

test_that("create_pop works", {
          expect_equal(round(cor(create_pop(0.5, 1e6))[1, 2], 2), 0.50)
  })
