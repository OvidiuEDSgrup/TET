exec sp_executesql N'SELECT Subunitate,Cod_gestiune,Cod,Data,Stoc_min,Stoc_max,Tip_gestiune FROM TET ..stoclim WHERE Subunitate = @P1 
AND Cod_gestiune = @P2 AND Cod = @P3 AND Data < DATEADD (day, 1, @P4)    
ORDER BY Subunitate ASC ,Tip_gestiune ASC ,Cod_gestiune ASC ,Cod ASC ,Data ASC ',N'@P1 char(9),@P2 char(9),@P3 char(20),@P4 datetime'
,'1        ','         ','25-ISO4-26-BL       ','2999-01-01 00:00:00'