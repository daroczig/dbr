SELECT Name
FROM City
WHERE
  Population > 1000000 AND
  Name IN ({sql_chunk('dbr.shinydemo.cities.europe', indent_after_linebreak = 4)}))
