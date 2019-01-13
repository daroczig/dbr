#' Load DB connection parameters
#'
#' Load DB connection parameters from a YAML file and decrypt secrets via KMS if found.
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
#' KMS-encrypted secrets should be specified with the \code{kms} type in the YAML file, such as:
#'
#' \preformatted{dbreference:
#'   ...
#'   password: !kms |
#'     ciphertext}
#'
#' Fields that should not be passed to \code{drv} (eg extra params not used for making the DB connection) should be specified with the \code{attr} type that will be added as attributes to the returned list.
#' @param db database name reference
#' @param db_config_path file path specified by the \code{dbr.db_config_path} global option as a string or function returning a string, which defaults to the \code{db_config.yaml} file in the current working directory
#' @return list of database parameters (eg \code{hostname}, \code{port}, \code{username}, \code{password} etc)
#' @export
#' @note You need to have access to the related KMS key to be able to decrypt cipher-text.
#' @importFrom botor kms_decrypt kms_decrypt_file
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

    ## parse config file
    db_secrets <- yaml.load_file(
        db_config_path,
        ## add KMS classes
        handlers = list('kms'  = function(x) structure(x, class = c('kms')),
                        'attr' = function(x) structure(x, class = c('attr'))))

    hasName(db_secrets, db) || stop('Database ', db, ' not found, check ', db_config_path)

    log_debug('Looking up config for %s', db)
    db_secrets <- db_secrets[[db]]

    ## hit KMS with each base64-encoded cipher-text (if any) and decrypt
    db_secrets <- rapply(db_secrets, kms_decrypt, classes = 'kms', how = 'replace')

    ## move attr list values from list to attributes
    attributes <- db_secrets[sapply(db_secrets, class) == 'attr']
    db_secrets <- db_secrets[setdiff(names(db_secrets), names(attributes))]
    for (attribute in names(attributes)) {
        attr(db_secrets, attribute) <- attributes[[attribute]]
    }

    db_secrets

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
#' @importFrom botor kms_encrypt
#' @examples \dontrun{
#' encrypt_secret('secret sentence I want to store in the YAML file')
#' }
db_config_encrypt_secret <- function(secret, key) {
    structure(kms_encrypt(key = key, text = secret), class = 'base64')
}

#' @export
print.base64 <- function(x, ...) {
    cat(strwrap(x, 76), sep = '\n')
}
