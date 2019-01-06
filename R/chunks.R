chunkfiles <- system.file('example_sql_chunks.yaml', package = 'dbr')


#' List or update the list of SQL chunk files to be used in \code{\link{sql_chunk}}
#' @param file path
#' @param add by default, the new \code{file} will be added to the list of active SQL chunk files, but when set to \code{FALSE}, it will override the old list instead of appending
#' @return character vector of the active SQL chunk files (invisibly after update)
#' @export
#' @importFrom utils assignInMyNamespace
sql_chunk_files <- function(file, add = TRUE) {

    if (!missing(file)) {
        if (add == TRUE) {
            newchunkfiles <- c(chunkfiles, file)
        } else {
            newchunkfiles <- file
        }
        assignInMyNamespace('chunkfiles', newchunkfiles)
        return(invisible(newchunkfiles))
    }

    chunkfiles

}


#' Look up common SQL chunks to be reused in SQL queries
#' @param key key defined in \code{\link{sql_chunk_files}}
#' @return string
#' @export
#' @importFrom glue glue
#' @examples \dontrun{
#' sql_chunk('dbr.shinydemo.countries.count')
#'
#' ## pass it right away to a database
#' countries <- db_query(sql_chunk('dbr.shinydemo.countries.count'), 'shinydemo')
#'
#' ## example for a more complex query
#' cities <- db_query(sql_chunk('dbr.shinydemo.cities.europe'), 'shinydemo')
#' }
sql_chunk <- function(key, ..., indent_after_linebreak = 0) {

    ## parse config file(s)
    chunk <- unlist(lapply(chunkfiles, yaml.load_file), recursive = FALSE)

    for (keyi in strsplit(key, '.', fixed = TRUE)[[1]]) {

        if (!hasName(chunk, keyi)) {
            stop(shQuote(keyi), ' from ', key, ' not found in the SQL chunk files')
        }

        ## get the SQL chunk
        chunk <- chunk[[keyi]]

    }

    ## extra indent
    indent_spaces <- paste(rep(' ', indent_after_linebreak), collapse = '')
    chunk <- gsub('\n', paste0('\n', indent_spaces), chunk)

    ## return after string interpolation
    glue(chunk, ..., .trim = FALSE)

}
