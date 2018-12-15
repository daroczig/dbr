#' Load DB configs from a YAML file and decrypt secrets via KMS if found
#' @param db database name reference
#' @param db_config_path file path specified by the \code{db_config_path} global option as a string or function returning a string, which defaults to the \code{db_config.yaml} file in the current working directory
#' @return list of database parameters (eg \code{hostname}, \code{port}, \code{username}, \code{password} etc)
#' @export
#' @note You need to have access to the related KMS key to be able to decrypt cipher-text
#' @importFrom AWR.KMS kms_decrypt kms_decrypt_file
#' @importFrom memoise memoise
#' @importFrom utils hasName
#' @importFrom yaml yaml.load_file
#' @importFrom logger log_debug
db_config <- memoise(function(db, db_config_path = getOption('db_config_path')) {

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
        handlers = list('kms' = function(x) structure(x, class = c('kms'))))

    hasName(db_secrets, db) || stop('Database ', db, ' not found, check ', db_config_path)

    log_debug('Looking up config for {db}')

    ## hit KMS with each base64-encoded cipher-text (if any) and decrypt
    rapply(db_secrets[[db]], kms_decrypt, classes = 'kms', how = 'replace')

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
#' @importFrom AWR.KMS kms_encrypt
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
