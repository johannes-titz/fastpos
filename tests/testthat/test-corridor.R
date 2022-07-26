test_that("relative precision works", {
          sim_a <- suppressWarnings(find_critical_pos(rho = .5, precision_rel = 0.1,
                                                      n_studies = 1e2))
          expect_equal(c(sim_a$lower_limit, sim_a$upper_limit), c(.45, .55))
})

test_that("lower limit and upper limit works", {
          sim_c <- suppressWarnings(
            find_one_critical_pos(
              rho = 0.5,
              lower_limit = 0.37,
              upper_limit = 0.63, n_studies = 1e2
            )
          )
          expect_equal(as.numeric(c(sim_c$summary["lower_limit"],
                                    sim_c$summary["upper_limit"])),
                       c(0.37, .63))
})

test_that("lower limits and upper limits works", {
          sim_b <- suppressWarnings(
            find_critical_pos(
              rhos = c(0.1, 0.2, 0.3),
              lower_limits = c(0.05, 0.18, 0.2),
              upper_limits = c(0.13, 0.25, 0.4),
              n_studies = 1e2
            )
          )
          expect_equal(c(sim_b$lower_limit, sim_b$upper_limit),
                       c(.05, 0.18, 0.2, 0.13, 0.25, 0.4))
})
