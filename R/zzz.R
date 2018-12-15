dbs <- new.env(hash = TRUE, parent = emptyenv(), size = 29L)

.onLoad <- function(libname, pkgname) {

    ## use sprintf for the logger formatter not to depend on glue
    logger::log_formatter(logger::formatter_sprintf, namespace = pkgname)

    ## path to the default DB config YAML file
    options('db_config_path' = function() file.path(getwd(), 'db_config.yml'))

}
