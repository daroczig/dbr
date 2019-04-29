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

#' Checks if a database reference or connection is Redshift or not
#' @param db database reference by name or object
#' @return boolean
#' @keywords internal
is.redshift <- function(db) {
    config <- db_config(ifelse(is.object(db), attr(db, 'db'), db))
    class(config$drv) =="PostgreSQLDriver" && config$port == 5439
}

#' Dumps a data frame to disk, copies to S3 and runs COPY FROM on Redshift
#'
#' Note that the related database's YAML config should include \code{s3_copy_bucket} and \code{s3_copy_iam_role} fields with \code{attr} type pointing to a staging S3 bucket (to which the current node has write access, and the Redshift IAM Role has read access) and the full ARN of the Redshift IAM Role.
#' @param df \code{data.frame}
#' @param table Redshift schema and table name (separated by a dot)
#' @inheritParams db_query
#' @export
redshift_insert_via_copy_from_s3 <- function(df, table, db) {

    assert_botor_available()

    ## TODO split JSON into smaller chunks and provide a Manifest file
    ##      to speed up operations and also to fix current limit of ~4Gb data

    ## extract database name if actual DB connection was passed
    dbname <- ifelse(is.object(db), attr(db, 'db'), db)

    ## load and test if required params set for DB
    config <- db_config(dbname)
    if (!all(c('s3_copy_bucket', 's3_copy_iam_role') %in% names(attributes(config)))) {
        stop('Need to specify s3_copy_bucket and s3_copy_iam_role in the database config YAML')
    }

    ## dump data frame to S3 as jsonlines
    s3 <- tempfile(tmpdir = attr(config, 's3_copy_bucket', exact = TRUE), fileext = '.json.gz')
    botor::s3_write(df, write_jsonlines, s3, compress = 'gzip')

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
    botor::s3_delete(s3)

}

