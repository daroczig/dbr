#' Writes each row of a data frame as JSON into a file separated by line breaks as per \url{http://jsonlines.org}
#' @param df data frame
#' @param file path
#' @export
#' @examples \dontrun{
#' t <- tempfile()
#' write_jsonlines(mtcars, t)
#' }
#' @importFrom checkmate assert_data_frame assert_directory_exists
#' @importFrom logger fail_on_missing_package
write_jsonlines <- function(df, file = tempfile()) {
    assert_data_frame(df)
    assert_directory_exists(dirname(file))
    fail_on_missing_package('jsonlite')
    jsonlite::stream_out(df, file(file), verbose = FALSE)
}
