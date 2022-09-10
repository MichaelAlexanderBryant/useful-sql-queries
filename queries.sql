-- Calculate quantiles of a column.
SELECT MAX(CASE WHEN rownum <= cnt*.25 THEN <col> END) AS first_quantile,
		MAX(CASE WHEN rownum <= cnt*.5 THEN <col> END) AS second_quantile,
		MAX(CASE WHEN rownum <= cnt*.75 THEN <col> END) AS third_quantile
FROM
(SELECT ROW_NUMBER() OVER (ORDER BY <col>) AS rownum, COUNT(*) OVER() AS cnt, <col>
FROM <tbl>) sq;

-- Calculate summary statistics for a column. Includes: number of distinct values, minimum and maximum values, mode, antimode, frequency of minimum and maximum values,
-- frequency of mode and antimode, number of values that occur only one time, number of modes, number of anymodes. The second subquery produces: minimum and maximum
-- frequency, minimum and maximum values, and number of NULL values.
WITH tsum AS (
	SELECT '<col>' as col, <col> as val, COUNT(*) AS freq
	FROM <tbl> t
	GROUP BY <col>
	)
SELECT tsum.col, COUNT(*) AS numvalues,
	MAX(freqnull) AS freqnull,
	MIN(minval) AS minval,
	SUM(CASE WHEN val = minval THEN freq ELSE 0 END) AS numminvals,
	MAX(maxval) AS maxval,
	SUM(CASE WHEN val = maxval THEN freq ELSE 0 END) AS nummaxvals,
	MIN(CASE WHEN freq = maxfreq THEN val END) AS mode,
	SUM(CASE WHEN freq = maxfreq THEN 1 ELSE 0 END) AS nummodes,
	MAX(maxfreq) AS modefreq,
	MIN(CASE WHEN freq = minfreq THEN val END) AS antimode,
	SUM(CASE WHEN freq = minfreq THEN 1 ELSE 0 END) AS numantimodes,
	MAX(minfreq) AS antimodefreq,
	SUM(CASE WHEN freq = 1 THEN freq ELSE 0 END) AS numuniques
FROM tsum CROSS JOIN
	(SELECT MIN(freq) AS minfreq, MAX(freq) AS maxfreq,
	 	MIN(val) AS minval, MAX(val) AS maxval,
	 	SUM(CASE WHEN val IS NULL THEN freq ELSE 0 END) AS freqnull
	 FROM tsum
	 ) summary
GROUP BY tsum.col;

-- Get all columns in a table.
SELECT (table_schema + '.' + table_name) AS table_name, column_name, ordinal_position
FROM INFORMATION_SCHEMA.COLUMNS c
WHERE LOWER(table_name) = '<tbl>';

-- Column information from a table: column name, number of values, number of NULL values, number of minimum values, number of maximum values,
-- and number of unique values. Replace <query from below> with the second query on one line.
SELECT REPLACE(REPLACE(REPLACE('<query from below>', '<col>', column_name), '<tbl>', table_name), '<start>',
	       (CASE WHEN ordinal_position = 1 THEN '' ELSE 'UNION ALL ' END))
FROM (SELECT table_name, column_name, ordinal_position
      FROM INFORMATION_SCHEMA.COLUMNS
      WHERE LOWER(table_name) = '<tbl>') tc
-- Replace <tbl> in final WHERE clause of FROM with the actual table name.	       
<start>SELECT ''<col>'' AS colname, COUNT(*) AS numvalues,
	       MAX(freqnull) AS freqnull,
	       CAST(MIN(minval) AS VARCHAR(255)) AS minval,
	       SUM(CASE WHEN <col> = maxval THEN freq ELSE 0 END) AS numminvals,
	       CAST(MAX(maxval) AS VARCHAR(255)) AS maxval,
	       SUM(CASE WHEN <col> = maxval THEN freq ELSE 0 END) AS nummaxvals,
	       SUM(CASE WHEN freq = 1 THEN freq ELSE 0 END) AS numuniques
FROM (SELECT <col>, COUNT(*) AS freq
      FROM <tbl>
      GROUP BY <col>) tsum CROSS JOIN
	(SELECT MIN(<col>) AS minval, MAX(<col>) AS maxval,
	 	SUM(CASE WHEN <col> IS NULL THEN 1 ELSE 0 END) AS freqnull
	 FROM <tbl>
	 ) summary

