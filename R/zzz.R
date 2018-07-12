dbs <- new.env(hash = TRUE, parent = emptyenv(), size = 29L)

.onLoad <- function(libname, pkgname) {

    ## path to the DB config YAML file
    options('db_config_path' = function() file.path(getwd(), 'db_config.yml'))

}
