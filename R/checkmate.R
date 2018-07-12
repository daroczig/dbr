#' Check if object has an attribute
#' @param x R object
#' @param attribute string
#' @importFrom checkmate makeAssertionFunction makeTestFunction makeExpectationFunction makeAssertion vname makeExpectation
check_attr <- function(x, attribute) {
    xname <- deparse(substitute(x))
    if (is.null(attr(x, attribute))) {
        return(paste(shQuote(xname), 'does not have the', attribute, 'attribute'))
    }
    TRUE
}
assert_attr <- makeAssertionFunction(check_attr)
test_attr   <- makeTestFunction(check_attr)
expect_attr <- makeExpectationFunction(check_attr)
