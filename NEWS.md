# dbr (master branch)

* create `pkgdown` site for documentation
* better unit-test coverage

# dbr 0.1.0.9004 (2020-06-08)

* add `aws` prefix for the AWS-related secrets handler(s)
* add function parameter for passing in temporarily SQL formatter function
* make `botor` dependency optional
* improve documentation and examples
* add support for reading config values from AWS System Manager's Parameter Store
* add support for SQL chunks to be defined in files and folders outside of the YAML definitions

# dbr 0.1.0.9003 (2019-01-15)

* add support for `gzip` when inserting records into Redshift

# dbr 0.1.0.9002 (2019-01-14)

* add helper function to write JSON lines
* add support for passing database parameters not required for making the connection
* add support for inserting records into Redshift via S3 staging and `COPY FROM`

# dbr 0.1.0.9001 (2019-01-09)

* optionally return `data.table` or `tibble` instead of base `data.frame`
* improve documentation
* more unit tests

# dbr 0.1.0.9000 (2019-01-09)

* switch versioning to "in-development" schema
* drop `futile.logger` dependency for `logger`
* drop `AWR` dependencies for `botor`
* add functionality to write to tables
* improve documentation and examples on YAML definitions
* introduce support for SQL templating

# dbr 0.1 (2018-07-04)

Initial release after open-sourcing at System1.
