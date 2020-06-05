SELECT Name
FROM City
WHERE CountryCode IN ({sql_chunk('dbr.shinydemo.countries.europe', indent_after_linebreak = 2)})
