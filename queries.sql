-- Calculate quantiles of a column.
SELECT MAX(CASE WHEN rownum <= cnt*.25 THEN <col> END) AS first_quantile,
		MAX(CASE WHEN rownum <= cnt*.5 THEN <col> END) AS second_quantile,
		MAX(CASE WHEN rownum <= cnt*.75 THEN <col> END) AS third_quantile
FROM
(SELECT ROW_NUMBER() OVER (ORDER BY <col>) AS rownum, COUNT(*) OVER() AS cnt, <col>
FROM <tbl>) sq;

-- Query data for histogram grouping categories with less than a count of 100 in 'other' category.
SELECT (CASE WHEN cnt >= 100 THEN <col> ELSE 'OTHER' END) AS <col>, SUM(cnt) AS cnt
FROM (SELECT t.<col>, COUNT(*) AS cnt
      FROM <tbl> AS t
      GROUP BY t.<col>
      ) sq
GROUP BY (CASE WHEN cnt >=100  THEN <col> ELSE 'OTHER' END)
ORDER BY cnt DESC;

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

-- Random sample 10% of table.
SELECT TOP 10 PERCENT *
FROM <tbl>
ORDER BY NEWID();

-- Proportional stratified sampling 10% of <col2> where <col1> is the column being stratified. Proportional stratified is sampling at a pre-defined rate.
WITH cte AS (
	SELECT *,
		ROW_NUMBER() OVER (ORDER BY <col1>, <col2>) AS seqnum
	FROM <tbl>
)
SELECT <col2>
FROM cte
WHERE seqnum % 10 = 1;

-- Balanced stratified sampling (each value appearsan equal amount of times). This particular example samples 200 rows from two categories in <col2>. 
-- <col1> is the indicator column of <col2> and <col3> is the value of interest that is being sampled.
WITH cte AS (
	SELECT *,
		ROW_NUMBER() OVER (PARTITION BY <col1>
				   ORDER BY NEWID()) AS seqnum
	FROM (SELECT *,
	      		(CASE WHEN <col2> = '<col2 category1>' THEN 1 ELSE 0 END) AS <col1>
	      FROM <tbl>
	      ) sq
	)
SELECT (CASE WHEN <col1> = 1 THEN <col3> END) AS <col2 category1>,
	(CASE WHEN <col1> = 0 THEN <col3> END) AS <col2 category2>
FROM cte
WHERE seqnum <= 100
