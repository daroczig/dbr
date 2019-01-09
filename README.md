# dbr: Convenient database connections and queries from R

Vignette coming, until then, please check the slides presented at the useR! 2018 conference: http://bit.ly/user2018-dbr

## Setting up a config file for the database connections

To be able to connect to a database, the connection parameters are to be specified in a YAML file. 

By default, `dbr` will look for a file named `db_config.yaml` in the current working directory, that can be override via the `dbr.db_config_path` global option, eg to the example config bundled in this package:

```r
options(dbr.'db_config_path' = system.file('example_db_config.yaml', package = 'dbr'))
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

For more advanced usage, eg caching database connections, check `?db_connect` and the above mentioned vignette.

## SQL templating

To resuse SQL chunks, you may list your SQL queries (or parts of it) in a structured YAML file, like in the bundled example config at https://github.com/daroczig/dbr/blob/master/inst/example_sql_chunks.yaml

Use `sql_chunk_files` to list or update the currently used SQL template YAML files.

Then you may refer to any key in the list by a string that consist of the keys in hierarchy separated by a dot, so eg getting the `count` key from for the `countries` item in `dbr`'s `shinydemo` section, you could do something like:

```r
sql_chunk('dbr.shinydemo.countries.count')
#> SELECT COUNT(*) FROM Country
```

And pass it right away to `db_query`:

```r
countries <- db_query(sql_chunk('dbr.shinydemo.countries.count'), 'shinydemo')
#> INFO [2019-01-06 01:33:33] Connecting to shinydemo
#> INFO [2019-01-06 01:33:34] Executing:**********
#> INFO [2019-01-06 01:33:34] SELECT COUNT(*) FROM Country
#> INFO [2019-01-06 01:33:34] ********************
#> INFO [2019-01-06 01:33:34] Finished in 0.1291 secs returning 1 rows
#> INFO [2019-01-06 01:33:34] Closing connection to shinydemo
```

The power of this templating approach is that you can easily reuse SQL chunks, eg for the list of European countries in:

```r
cities <- db_query(sql_chunk('dbr.shinydemo.cities.europe'), 'shinydemo')
#> INFO [2019-01-06 01:32:02] Connecting to shinydemo
#> INFO [2019-01-06 01:32:02] Executing:**********
#> INFO [2019-01-06 01:32:02] SELECT Name
#> FROM City
#> WHERE CountryCode IN (
#>   SELECT Code
#>   FROM Country
#>   WHERE Continent = 'Europe')
#> INFO [2019-01-06 01:32:02] ********************
#> INFO [2019-01-06 01:32:02] Finished in 0.1225 secs returning 643 rows
#> INFO [2019-01-06 01:32:02] Closing connection to shinydemo
```

Where the `Country`-related subquery was specified in the `dbr.shinydemo.countries.europe` key as per:

```sql
SELECT Name
FROM City
WHERE CountryCode IN (
  {sql_chunk('dbr.shinydemo.countries.europe', indent_after_linebreak = 2)})
```

The `indent_after_linebreak` parameter is just for cosmetic updates in the query to align `FROM` and `WHERE` on the same character in the SQL statement.

Even more complex / nested example:

```sql
sql_chunk('dbr.shinydemo.cities.europe_large')
#> SELECT Name
#> FROM City
#> WHERE
#>   Population > 1000000 AND
#>   Name IN (
#>     SELECT Name
#>     FROM City
#>     WHERE CountryCode IN (
#>       SELECT Code
#>       FROM Country
#>       WHERE Continent = 'Europe')))
```
