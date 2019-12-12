#' Load DB connection parameters
#'
#' Load DB connection parameters from a YAML file and optionally decrypt secrets via Amazon KMS or load values from Amazon System Manager's Parameter Store.
#'
#' The YAML file should include all connection parameters, including the Database Driver as an R object, see eg
#'
#' \preformatted{dbreference:
#'   host: localhost
#'   port: 3306
#'   drv: !expr RMySQL::MySQL()
#'   username: foo
#'   password: bar}
#'
#' KMS-encrypted secrets should be specified with the \code{aws_kms} type in the YAML file, such as:
#'
#' \preformatted{dbreference:
#'   ...
#'   password: !aws_kms |
#'     ciphertext}
#'
#' AWS Parameter Store values can be loaded by specifying the \code{aws_parameter} type in the YAML file, such as:
#'
#' \preformatted{dbreference:
#'   ...
#'   password: !aws_parameter |
#'     /path/to/value}
#'
#' Fields that should not be passed to \code{drv} (eg extra params not used for making the DB connection) should be specified with the \code{attr} type that will be added as attributes to the returned list.
#' @param db database name reference
#' @param db_config_path file path specified by the \code{dbr.db_config_path} global option as a string or function returning a string, which defaults to the \code{db_config.yaml} file in the current working directory
#' @return list of database parameters (eg \code{hostname}, \code{port}, \code{username}, \code{password} etc)
#' @export
#' @note You need to install the \code{botor} package and also have access to the related KMS key to be able to decrypt cipher-text.
#' @importFrom memoise memoise
#' @importFrom utils hasName
#' @importFrom yaml yaml.load_file
#' @importFrom logger log_debug
db_config <- memoise(function(db, db_config_path = getOption('dbr.db_config_path')) {

    if (is.function(db_config_path)) {
        db_config_path <- db_config_path()
    }

    if (!file.exists(db_config_path)) {
        stop(paste('DB config file not found at', db_config_path))
    }

    withclass <- function(class) {
        force(class)
        function(x) structure(x, class = class)
    }

    ## parse config file
    params <- yaml.load_file(
        db_config_path,
        ## keep classes
        handlers = list(
            'attr'          = withclass('attr'),
            ## legacy, use aws_kms instead, remove this in CRAN version
            'kms'           = withclass('aws_kms'),
            'aws_kms'       = withclass('aws_kms'),
            'aws_kms_file'  = withclass('aws_kms_file'),
            'aws_parameter' = withclass('aws_parameter')),
        eval.expr = TRUE)

    hasName(params, db) || stop('Database ', db, ' not found, check ', db_config_path)

    log_debug('Looking up config for %s', db)
    params <- params[[db]]

    ## check if we need botor package
    if (any(grepl('aws_', rapply(params, class, how = 'list')))) {
        if (!requireNamespace('botor', quietly = TRUE)) {
            stop('Please install the "botor" package to be able to use the AWS-specific configs.')
        }
    }

    ## hit KMS with each base64-encoded cipher-text (if any) and decrypt
    params <- rapply(params, function(param) {
        switch(
            class(param),

            ## decrypt base64-encoded ciphertext via Amazon KMS
            'aws_kms' = botor::kms_decrypt(param),

            ## decrypt file via a data encryption key and Amazon KMS
            'aws_kms_file' = {

                ## decrypt to tempfile
                t <- tempfile()
                on.exit(unlink(t))
                botor::kms_decrypt_file(param, return = t)

                ## load R object then cleanup
                readRDS(t)

            },

            ## get value from Amazon Systems Manager's Parameter Store
            'aws_parameter' = botor::ssm_get_parameter(param),

            ## default (no transformation)
            param)},
        how = 'replace')

    ## move attr list values from list to attributes
    attributes <- params[sapply(params, class) == 'attr']
    params <- params[setdiff(names(params), names(attributes))]
    for (attribute in names(attributes)) {
        attr(params, attribute) <- attributes[[attribute]]
    }

    params

})


#' Invalidates the cached secret storage
#' @export
#' @importFrom memoise forget
#' @importFrom logger log_info
db_config_invalidate_cache <- function() {
    log_info('Invalidating cache on already loaded DB config(s)')
    invisible(forget(db_config))
}


#' Encrypt a secret via KMS and prints the base64-encoded cipher-text to the console
#' @param secret string of the actual secret to be encrypted/stored
#' @param key Amazon KMS key to be used for the encryption
#' @return base64-encoded cipher-text
#' @export
#' @note You need to have access to the related KMS key to be able to decrypt cipher-text
#' @examples \dontrun{
#' encrypt_secret('secret sentence I want to store in the YAML file')
#' }
db_config_encrypt_secret <- function(secret, key) {
    assert_botor_available()
    structure(botor::kms_encrypt(key = key, text = secret), class = 'base64')
}

#' @export
print.base64 <- function(x, ...) {
    cat(sapply(
        split(strsplit(x, '')[[1]], rep(1:ceiling(nchar(x) / 76), each = 76, length.out = nchar(x))),
        paste, collapse = ''), sep = '\n')
}
