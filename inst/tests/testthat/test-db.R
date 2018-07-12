library(dbr)
library(testthat)

context('DB helpers')

bak <- getOption('db_config_path')
options('db_config_path' = system.file('db_config.yml', package = 'dbr'))
con <- db_connect('sqlite')

test_that('connection', {
    expect_s4_class(con, 'SQLiteConnection')
})

test_that('static sql', {
    expect_equal(db_query('select 42', db = con)[[1]], 42)
    expect_equal(db_query('select 42', con)[[1]], 42)
    expect_equal(db_query('select 42', db = 'sqlite')[[1]], 42)
})

options('db_config_path' = bak)
