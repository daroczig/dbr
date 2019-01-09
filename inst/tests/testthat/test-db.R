library(dbr)
library(testthat)

context('DB helpers')

library(logger)
log_threshold(TRACE, namespace = 'dbr')
example_layout <- layout_glue_generator(format = '{node}/{pid}/{namespace}/{fn} {time} {level}: {msg}')
log_layout(example_layout, namespace = 'dbr')

bak <- getOption('dbr.db_config_path')
options('dbr.db_config_path' = system.file('example_db_config.yaml', package = 'dbr'))
con <- db_connect('sqlite')

test_that('connection', {
    expect_s4_class(con, 'SQLiteConnection')
})

test_that('static sql', {
    expect_equal(db_query('select 42', db = con)[[1]], 42)
    expect_equal(db_query('select 42', con)[[1]], 42)
    expect_equal(db_query('select 42', db = 'sqlite')[[1]], 42)
})

options('dbr.db_config_path' = bak)
