;WITH baseTable AS
(
    SELECT 'RM1' AS RM, 'ADR1' AS ADR
    UNION ALL SELECT 'RM1' AS RM, 'ADR1' AS ADR
    UNION ALL SELECT 'RM2' AS RM, 'ADR1' AS ADR
    UNION ALL SELECT 'RM2' AS RM, 'ADR2' AS ADR
    UNION ALL SELECT 'RM2' AS RM, 'ADR2' AS ADR
    UNION ALL SELECT 'RM2' AS RM, 'ADR3' AS ADR
    UNION ALL SELECT 'RM3' AS RM, 'ADR1' AS ADR
    UNION ALL SELECT 'RM2' AS RM, 'ADR1' AS ADR
    UNION ALL SELECT 'RM3' AS RM, 'ADR1' AS ADR
    UNION ALL SELECT 'RM3' AS RM, 'ADR2' AS ADR
)
,CTE AS
(
    SELECT RM, ADR, DENSE_RANK() OVER(PARTITION BY RM ORDER BY ADR) AS dr 
    FROM baseTable
)
SELECT
     RM
    ,ADR

    ,COUNT(CTE.ADR) OVER (PARTITION BY CTE.RM ) AS cnt1 
    ,COUNT(CTE.ADR) OVER (PARTITION BY CTE.RM) AS cnt2 
    -- Geht nicht 
    --,COUNT(DISTINCT CTE.ADR) OVER (PARTITION BY CTE.RM ORDER BY CTE.ADR) AS cntDist
    ,MAX(CTE.dr) OVER (PARTITION BY CTE.RM ) AS cntDistEmu 
FROM CTE