library(dbr)
library(testthat)

context('checkmate')

test_that('check_attr', {
    expect_true(check_attr(mtcars, 'names'))
    expect_equal(check_attr(mtcars, 'foobar'), "'mtcars' does not have the foobar attribute")
    expect_error(assert_attr(mtcars, 'foobar'))
})

test_that('assert_botor_available', {
    if ('botor' %in% rownames(installed.packages())) {
        expect_error(assert_botor_available(), NA)
    } else {
        expect_error(assert_botor_available())
    }
})
