-- Calculate quantiles.
SELECT MAX(CASE WHEN rownum <= cnt*.25 THEN <col> END) AS first_quantile,
		MAX(CASE WHEN rownum <= cnt*.5 THEN <col> END) AS second_quantile,
		MAX(CASE WHEN rownum <= cnt*.75 THEN <col> END) AS third_quantile
FROM
(SELECT ROW_NUMBER() OVER (ORDER BY <col>) AS rownum, COUNT(*) OVER() AS cnt, <col>
FROM <tbl>) sq;
