library(dbr)
library(testthat)

library(logger)
log_threshold_bak <- log_threshold()
log_threshold(FATAL)
log_threshold(FATAL, namespace = 'dbr')
example_layout <- layout_glue_generator(format = '{node}/{pid}/{namespace}/{fn} {time} {level}: {msg}')
log_layout(example_layout, namespace = 'dbr')

bak <- getOption('dbr.db_config_path')
options('dbr.db_config_path' = system.file('example_db_config.yaml', package = 'dbr'))
con <- db_connect('sqlite')

## #############################################################################

context('DB helpers')

test_that('connection', {
    expect_s4_class(con, 'SQLiteConnection')
})

test_that('static sql', {
    expect_equal(db_query('select 42', db = con)[[1]], 42)
    expect_equal(db_query('select 42', con)[[1]], 42)
    expect_equal(db_query('select 42', db = 'sqlite')[[1]], 42)
})

## #############################################################################

context('sql chunks')

test_that('static chunk works', {
    expect_equal(sql_chunk('dbr.unittests.static'), 'x')
})

test_that('variable substitution with fallback works', {
    expect_equal(sql_chunk('dbr.unittests.fallback'), 'x == 5')
    expect_equal(sql_chunk('dbr.unittests.fallback', x = 42), 'x == 42')
})

test_that('nested chunk works', {
    expect_equal(sql_chunk('dbr.unittests.nested'), 'xx == x')
    expect_equal(sql_chunk('dbr.unittests.nested2'), 'xxx == 42 | xx == x')
    expect_equal(sql_chunk('dbr.unittests.nested2', x = 6), 'xxx == 6 | xx == x')
})

test_that('global env overrides works', {

    t <- tempfile()

    cat('
      library(dbr)
      x <- 42
      sql_chunk("dbr.unittests.fallback")', file = t)
    expect_equal(
        system(paste('Rscript', t), intern = TRUE),
        'x == 42')

    cat('
      library(dbr)
      x <- 42
      sql_chunk("dbr.unittests.fallback", x = 0)', file = t)
    expect_equal(
        system(paste('Rscript', t), intern = TRUE),
        'x == 0')

    cat('
      library(dbr)
      x <- 42
      f <- function() sql_chunk("dbr.unittests.fallback", x = 0)
      f()', file = t)
    expect_equal(
        system(paste('Rscript', t), intern = TRUE),
        'x == 0')

    unlink(t)

    expect_equal(sql_chunk('dbr.unittests.fallback'), 'x == 5')
})

## #############################################################################

options('dbr.db_config_path' = bak)
log_threshold(log_threshold_bak)
