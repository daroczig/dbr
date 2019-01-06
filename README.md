# dbr: Convenient database connections and queries from R

Vignette coming, until then, please check the slides presented at the useR! 2018 conference: http://bit.ly/user2018-dbr

## Setting up a config file for the database connections

To be able to connect to a database, the connection parameters are to be specified in a YAML file. 

By default, `dbr` will look for a file named `db_config.yaml` in the current working directory, that can be override via the `db_config_path` global option, eg to the example config bundled in this package:

```r
options('db_config_path' = system.file('example_db_config.yaml', package = 'dbr'))
```

## Querying databases

Once the connection parameters are loaded from a config file, making SQL queries are as easy as specifying the SQL statement and the name of the connection:

```r
db_query('show tables', 'shinydemo')
#> INFO [2019-01-06 01:06:18] Connecting to shinydemo 
#> INFO [2019-01-06 01:06:19] Executing:**********
#> INFO [2019-01-06 01:06:19] show tables
#> INFO [2019-01-06 01:06:19] ********************
#> INFO [2019-01-06 01:06:19] Finished in 0.1336 secs returning 3 rows
#> INFO [2019-01-06 01:06:19] Closing connection to shinydemo
#>   Tables_in_shinydemo
#> 1                City
#> 2             Country
#> 3     CountryLanguage
```

For more advanced usage, check `?db_connect` and the above mentioned vignette.
