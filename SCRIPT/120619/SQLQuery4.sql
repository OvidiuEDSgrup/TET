exec sp_executesql N'SELECT Subunitate,Tip,Tert,Contract,Data,Gestiune 
FROM TESTOV ..con WHERE Subunitate = @P1 AND Tip = @P2 AND Tert = @P3 AND Contract = @P4    ORDER BY Subunitate ASC ,Tip ASC ,Data ASC ,Contract ASC ,Tert ASC '
,N'@P1 char(9),@P2 char(2),@P3 char(13),@P4 char(20)'
,'1        ','BK','RO5228299','3395.1'