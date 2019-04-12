dbs <- new.env(hash = TRUE, parent = emptyenv(), size = 29L)

.onLoad <- function(libname, pkgname) {

    ## use sprintf for the logger formatter not to depend on glue
    logger::log_formatter(logger::formatter_sprintf, namespace = pkgname)

    ## path to the default DB config YAML file
    options('dbr.db_config_path' = function() file.path(getwd(), 'db_config.yaml'))

    ## default SQL formatter does not do anything
    options('dbr.sql_formatter' = identity)

    ## by default, return data as standard data.frame
    ## as data.table or tibble might not be available / preferred
    options('dbr.output_format' = 'data.frame')

}
