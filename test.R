library(fastpos)
tic <- Sys.time()
res <- fastpos(seq(0.1, 0.7, 0.1), 20, 3000, n_studies = 1e5)
toc <- Sys.time()
toc-tic

tic <- Sys.time()
res2 <- fastpos(seq(.1, .7, .1), 20, 1500, n_studies = 1e5)
toc <- Sys.time()
toc-tic
res2

tic <- Sys.time()
res2 <- fastpos(.7, 20, 1500, n_studies = 1e4, confidence_levels = .8)
toc <- Sys.time()
toc-tic
res2

set.seed(20190417)
pop <- fastpos::create_pop(.5, 100000)
smpl <- sample(1:nrow(pop), 1000)
x <- pop[, 1]
y <- pop[, 2]
index_pop <- 1:nrow(pop)
fastpos::get_one_n(x, y, index_pop, 0.4, 0.6, replace = T, samplesize = 100)
fastpos::get_several_n(x, y, 0.4, 0.6, replace = T, samplesize = 1000, number_of_studies = 100)

res <- fastpos::run_sim(0.5, sample_size = 1000, n_studies = 100000)
res$summary

res <- run_sim(0.5, 100)
table(res$n)

start_profiler("/tmp/profile.out")
fastpos::get_several_n(x, y, 0.4, 0.6, replace = T, samplesize = 1000, number_of_studies = 100000)
stop_profiler()

microbenchmark::microbenchmark(
  fastpos::get_several_n(x, y, 0.4, 0.6, replace = T, samplesize = 1000, number_of_studies = 1000)
)
