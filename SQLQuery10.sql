;WITH T(C) AS
(
SELECT 'A' UNION ALL
SELECT 'B' UNION ALL
SELECT 'C' UNION ALL
SELECT 'D' UNION ALL
select 'a' union all
select 'b' union all
select 'c' union all
select 'd'
)
SELECT *
FROM T
ORDER BY C COLLATE Latin1_General_CS_AS