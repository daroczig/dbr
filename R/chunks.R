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

    unique(chunkfiles)

}


#' Look up all SQL chunks from YAML definitions
#' @return list
#' @export
sql_chunks <- function() {

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

    ## read SQL bits from files
    chunk <- rapply(chunk, function(chunk) {

        ## normal chunk, exit early
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
            stop('Multiple SQL chunk files found at ',
                 paste(file.path(paths, chunk), collapse = ' and '))
        }

        ## chunk defined in a file
        if (isFALSE(file.info(files)$isdir)) {
            log_trace('Found a file reference for %s at %s', chunk, files)
            return(paste(readLines(files, warn = FALSE), collapse = '\n'))
        }

        ## chunks defined in a folder
        log_trace('Found a folder reference for %s at %s', chunk, files)
        files <- list.files(files, full.names = TRUE)
        setNames(lapply(files, function(file) {
            paste(readLines(file, warn = FALSE), collapse = '\n')
        }), sub('\\.sql$', '', basename(files)))

    }, how = 'replace')

    ## handle special meaning of `~!` index (moving a level up)
    list_remove_intermediate_level_by_name(chunk, '~!')

}


#' Look up common SQL chunks from YAML definitions to be reused in SQL queries
#'
#' For more details and examples, please see the package \code{README.md}.
#' @param key optional key defined in \code{\link{sql_chunk_files}} to filter for
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

    chunk <- sql_chunks()

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


#' Remove intermediate list by moving up the children by one level
#' @param l list
#' @param n list name of levels to be removed (but keeping children)
#' @return list
#' @keywords internal
#' @examples \dontrun{
#' l <- list(a = 1, b = list('removeme' = 2))
#' list_remove_intermediate_level_by_name(l, 'removeme')
#' }
list_remove_intermediate_level_by_name <- function(l, n) {
    if (!is.list(l)) return(l)
    if (length(l) == 1 && names(l) == n) {
        return(l[[1]])
    }
    for (i in which(names(l) == n)) {
        l <- c(l[-i], l[[i]])
    }
    return(lapply(l, list_remove_intermediate_level_by_name, n = n))
}
