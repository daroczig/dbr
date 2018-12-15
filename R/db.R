#' Connect to a database using YAML configs
#' @param db name of database, must be present in the file specified by \code{getOption('db_config_path')}
#' @param cache optional caching of the connection. If set to \code{TRUE}, the connection will be cached in the background and an all future \code{db_connect} calls will simply return that (even if called automatically from eg \code{db_query}) until the end of the R session or when caching on the \code{db} is disabled in a future \code{db_connect} call with explic \code{cache = FALSE}. See the examples for more details.
#' @param ... extra parameters passed to the database driver, even ones overriding the default values loaded from the YAML config
#' @importFrom DBI dbConnect dbDriver
#' @export
#' @seealso \code{\link{db_close}} \code{\link{db_query}}
#' @examples \dontrun{
#' ## create new connection
#' optbak <- options()
#' options('db_config_path' = system.file('db_config.yml', package = 'dbr'))
#' con <- db_connect('sqlite')
#' str(con)
#' db_query('SELECT 42', 'sqlite')
#'
#' ## reusing the connection
#' str(db_connect('sqlite', cache = TRUE))
#' str(db_connect('sqlite'))
#' str(db_connect('sqlite'))
#' ## kill cached connection
#' db_close(db_connect('sqlite', cache = FALSE))
#'
#' ## restore options
#' options(optbak)
#' }
db_connect <- function(db, cache, ...) {

    cache <- ifelse(missing(cache), 'default', cache)

    if (exists(db, dbs)) {
        if (cache != FALSE) {
            return(dbs[[db]])
        }
        else {
            ## reset cached connection
            db_close(dbs[[db]])
            rm(list = db, envir = dbs)
        }
    }

    params <- db_config(db)

    ## override defaults
    extraparams <- list(...)
    for (i in seq_len(length(extraparams))) {
        params[[names(extraparams)[i]]] <- extraparams[[i]]
    }
    extralog <- ifelse(
        length(extraparams) > 0,
        paste0(' [', paste(paste(names(extraparams), extraparams, sep = '='), collapse = ', '), ']'),
        '')

    log_info(paste('Connecting to', db, extralog))
    con <- structure(do.call(dbConnect, params), db = db, cached = cache)

    ## cache connection
    if (isTRUE(cache)) {
        dbs[[db]] <- con
    }

    con

}


#' Close a database connection
#' @param db database object returned by \code{\link{db_connect}}
#' @importFrom DBI dbDisconnect
#' @export
#' @seealso \code{\link{db_connect}}
#' @note To close a cached connection, call \code{db_close} on an object returned by \code{db_connect(..., cache = FALSE)}
db_close <- function(db) {
    assert_attr(db, 'db')
    if (!isTRUE(attr(db, 'cached'))) {
        log_info(paste('Closing connection to', attr(db, 'db')))
        dbDisconnect(db)
    }
}


#' Execute an SQL query in a database
#' @param sql string
#' @param db database reference by name or object
#' @param ... passed to \code{db_connect}
#' @return data.frame with query metadata
#' @export
#' @importFrom DBI dbGetQuery
#' @importFrom logger log_info skip_formatter
#' @importFrom checkmate assert_string
#' @seealso \code{\link{db_connect}} \code{\link{db_refresh}}
db_query <- function(sql, db, ...) {

    if (!is.object(db)) {
        db <- db_connect(db, ...)
        on.exit({
          db_close(db)
        })
    }

    assert_attr(db, 'db')
    assert_string(sql)

    log_info('Executing:**********')
    log_info(skip_formatter(sql))
    log_info('********************')

    start <- Sys.time()
    result_set <- dbGetQuery(db, sql)
    time_to_exec <- Sys.time() - start

    log_info('Finished in %s returning %s rows', format(time_to_exec, digits = 4), nrow(result_set))

    attr(result_set, 'when') <- start
    attr(result_set, 'db') <- attr(db, 'db')
    attr(result_set, 'time_to_exec') <- time_to_exec
    attr(result_set, 'statement') <-  sql

    result_set

}


#' Refresh SQL query
#' @param x object returned by \code{db_query}
#' @seealso \code{\link{db_query}}
#' @importFrom checkmate assert_data_frame
#' @export
db_refresh <- function(x) {
    assert_data_frame(x)
    assert_attr(x, 'db')
    assert_attr(x, 'statement')
    with(attributes(x), db_query(statement, db))
}



#' Insert rows into a database table
#' @param df data.frame
#' @param table character vector of an optional schema and table name
#' @inheritParams db_close
#' @param ... further parameters passed to \code{dbWriteTable}, eg to modify \code{row.names} or \code{append} (depends on driver)
#' @seealso \code{RMySQL::\link[RMySQL]{dbWriteTable}}, \code{RPostgreSQL::\link[RPostgreSQL]{dbReadTable-methods}}
#' @importFrom DBI dbWriteTable
#' @importFrom checkmate assert_character
#' @export
#' @seealso \code{\link{db_append}}
#' @examples \dontrun{
#' options('db_config_path' = system.file('db_config.yml', package = 'dbr'))
#' db_insert(mtcars, 'mtcars', 'sqlite')
#' db_append(mtcars, c('dm', 'mtcars'), 'sqlite')
#' }
db_insert <- function(df, table, db, ...) {

    if (!is.object(db)) {
        db <- db_connect(db)
        on.exit({
          db_close(db)
        })
    }

    assert_data_frame(df)
    assert_character(table, min.len = 1)
    assert_attr(db, 'db')

    log_info('Inserting %s rows into %s', nrow(df), paste(table, collapse = "."))
    dbWriteTable(conn = db, name = table, value = df, ...)

}


#' Append rows into a database table
#'
#' This is a wrapper around \code{\link{db_insert}} with the default parameters set to append to a table.
#' @inheritParams db_insert
#' @export
db_append <- function(df, table, db, ...) {
    db_insert(df, table, db, overwrite = FALSE, append = TRUE, row.names = FALSE, ...)
}
