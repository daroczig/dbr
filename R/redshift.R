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
    ## TODO move to botor package?
    assert_data_frame(df)
    assert_directory_exists(dirname(file))
    fail_on_missing_package('jsonlite')
    jsonlite::stream_out(df, file(file), verbose = FALSE)
}


#' Dumps a data frame to disk, copies to S3 and runs COPY FROM on Redshift
#'
#' Note that the related database's YAML config should include \code{s3_copy_bucket} and \code{s3_copy_iam_role} fields with \code{attr} type pointing to a staging S3 bucket (to which the current node has write access, and the Redshift IAM Role has read access) and the full ARN of the Redshift IAM Role.
#' @param df \code{data.frame}
#' @param table Redshift schema and table name (separated by a dot)
#' @inheritParams db_connect
#' @export
#' @importFrom botor s3_write s3_delete
redshift_insert_via_copy_from_s3 <- function(df, table, db) {

    ## load and test if required params set for DB
    config <- db_config(db)
    if (!all(c('s3_copy_bucket', 's3_copy_iam_role') %in% names(attributes(config)))) {
        stop('Need to specify s3_copy_bucket and s3_copy_iam_role in the database config YAML')
    }

    ## dump data frame to S3 as jsonlines
    s3 <- tempfile(tmpdir = attr(config, 's3_copy_bucket', exact = TRUE), fileext = '.json')
    s3_write(df, write_jsonlines, s3, compress = 'gzip')

    ## load data from S3 into Redshift
    iam_role <- attr(config, 's3_copy_iam_role', exact = TRUE)
    db_query(
        paste(
            "COPY", paste(table, collapse = '.'),
            "FROM", shQuote(s3, type = 'sh'),
            "iam_role", shQuote(iam_role, type = 'sh'),
            "JSON 'auto' GZIP"),
        db = db)

    ## clean up
    s3_delete(s3)

}

