library(dbr)
library(testthat)

library(logger)
log_threshold_bak <- log_threshold()
log_threshold(FATAL)
log_threshold(FATAL, namespace = 'dbr')
example_layout <- layout_glue_generator(format = '{node}/{pid}/{namespace}/{fn} {time} {level}: {msg}')
log_layout(example_layout, namespace = 'dbr')

config_path_bak <- getOption('dbr.db_config_path')
options('dbr.db_config_path' = system.file('example_db_config.yaml', package = 'dbr'))

## #############################################################################

context('DB helpers')

con <- db_connect('sqlite')
test_that('connection', {
    expect_s4_class(con, 'SQLiteConnection')
})

test_that('static sql', {
    expect_equal(db_query('select 42', db = con)[[1]], 42)
    expect_equal(db_query('select 42', con)[[1]], 42)
    expect_equal(db_query('select 42', db = 'sqlite')[[1]], 42)
})
db_close(con)

test_that('cache', {
    con <- db_connect('sqlite', cache = TRUE)
    expect_equal(db_query('select 42', db = con)[[1]], 42)
    expect_equal(db_query('select 42', 'sqlite')[[1]], 42)
    con <- db_connect('sqlite', cache = FALSE)
    expect_equal(db_query('select 42', db = con)[[1]], 42)
    db_close(con)
})

test_that('refresh', {
    res <- db_query('select 42', db = 'sqlite')
    expect_equal(db_refresh(res)[[1]], 42)
    expect_true(attr(res, 'when') < attr(db_refresh(res), 'when'))
})


## #############################################################################

context('sql chunks')

bak_chunk_files <- sql_chunk_files()
sql_chunk_files(system.file('example_sql_chunks.yaml', package = 'dbr'))
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
      sql_chunk_files(system.file("example_sql_chunks.yaml", package = "dbr"))
      x <- 42
      sql_chunk("dbr.unittests.fallback")', file = t)
    expect_equal(
        system(paste('Rscript', t), intern = TRUE),
        'x == 42')

    cat('
      library(dbr)
      sql_chunk_files(system.file("example_sql_chunks.yaml", package = "dbr"))
      x <- 42
      sql_chunk("dbr.unittests.fallback", x = 0)', file = t)
    expect_equal(
        system(paste('Rscript', t), intern = TRUE),
        'x == 0')

    cat('
      library(dbr)
      sql_chunk_files(system.file("example_sql_chunks.yaml", package = "dbr"))
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

context('sql formatter')

formatter_bak <- getOption('dbr.sql_formatter')
library(glue)
options('dbr.sql_formatter' = glue)
.x <- 2

con <- db_connect('sqlite')
test_that('glueing', {
    expect_equal(db_query('SELECT 42', db = con)[[1]], 42)
    expect_equal(db_query('SELECT {42}', db = con)[[1]], 42)
    expect_equal(db_query('SELECT {40 + 2}', db = con)[[1]], 42)
    expect_equal(db_query('SELECT {40 + x}', x = 2, db = con)[[1]], 42)
    expect_equal(db_query('SELECT {y + x}', y = 40 , x = 2, db = con)[[1]], 42)
    expect_equal(db_query('SELECT {40 + .x}', db = con)[[1]], 42)
})
db_close(con)

## #############################################################################

rm(.x)
options('dbr.db_config_path' = config_path_bak)
options('dbr.sql_formatter' = formatter_bak)
sql_chunk_files(bak_chunk_files, add = FALSE)
log_threshold(log_threshold_bak)
