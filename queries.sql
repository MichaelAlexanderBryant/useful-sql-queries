SELECT MAX(CASE WHEN rownum <= cnt*.25 THEN total_cases END) AS first_quantile,
		MAX(CASE WHEN rownum <= cnt*.5 THEN total_cases END) AS second_quantile,
		MAX(CASE WHEN rownum <= cnt*.75 THEN total_cases END) AS third_quantile
FROM
(SELECT ROW_NUMBER() OVER (ORDER BY ISNULL(total_cases,0)) AS rownum, COUNT(*) OVER() AS cnt, ISNULL(total_cases,0) AS total_cases
FROM CovidCases) sq;