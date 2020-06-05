chunkfiles <- NULL


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
#' @param ... passed to \code{glue} for string interpolation
#' @param indent_after_linebreak integer for extra indent
#' @return string
#' @export
#' @importFrom glue glue
#' @examples \dontrun{
#' sql_chunk_files(system.file('example_sql_chunks.yaml', package = 'dbr'))
#' sql_chunk('dbr.shinydemo.countries.count')
#'
#' ## pass it right away to a database
#' countries <- db_query(sql_chunk('dbr.shinydemo.countries.count'), 'shinydemo')
#'
#' ## example for a more complex query
#' cities <- db_query(sql_chunk('dbr.shinydemo.cities.europe'), 'shinydemo')
#' }
#' @importFrom logger log_trace log_warn %except%
sql_chunk <- function(key, ..., indent_after_linebreak = 0) {

    ## path where looking for SQL chunk files
    paths <- dirname(sql_chunk_files())

    ## parse config file(s)
    chunk <- unlist(lapply(sql_chunk_files(), function(chunkfile) {
        if (!file.exists(chunkfile)) {
            log_warn('%s SQL chunk file not found', chunkfile)
        } else {
            yaml.load_file(
                chunkfile,
                handlers = list('include' = function(x) structure(x, class = 'include')))
        }
    }), recursive = FALSE)

    ## read file chunks
    chunk <- rapply(chunk, function(chunk) {

        if (!inherits(chunk, 'include')) {
            return(chunk)
        }

        files <- list.files(paths, pattern = '*\\.sql$', full.names = TRUE)
        files <- files[basename(files) == chunk]

        if (length(files) < 0) {
            stop('SQL chunk file not found at ',
                 paste(file.path(paths, chunk), collapse = '; '))
        }

        if (length(files) > 1) {
            stop('Multiple SQL chunk files found for ', key, ' at ',
                 paste(file.path(paths, chunk), collapse = ' and '))
        }

        log_trace('Found a chunk file reference for %s at %s', chunk, files)
        if (isFALSE(file.info(files)$isdir)) {
            return(paste(readLines(files, warn = FALSE), collapse = '\n'))
        }

    }, how = 'replace')

    for (keyi in strsplit(key, '.', fixed = TRUE)[[1]]) {

        if (!hasName(chunk, keyi)) {
            stop(shQuote(keyi), ' from ', key, ' not found in the SQL chunk files')
        }

        ## get the SQL chunk
        chunk <- chunk[[keyi]]

    }

    ## string interpolation
    chunk <- do.call(glue, c(list(chunk, .trim = FALSE), list(...)))

    ## optional extra indent
    indent_spaces <- paste(rep(' ', indent_after_linebreak), collapse = '')
    gsub('\n', paste0('\n', indent_spaces), chunk)

}
