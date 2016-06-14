select * from LOCATORI
select * from locatii


--insert locatii
select DISTINCT
LEFT(locator,13)	--Cod_locatie	char	13
,0	--Este_grup	bit	1
,''	--Cod_grup	char	13
,''	--UM	char	3
,0	--Capacitate	float	8
,LEFT(GESTIUNE,9)	--Cod_gestiune	char	9
,0	--Incarcare	bit	1
,1	--Nivel	smallint	2
,LEFT(LOCATOR,30)	--Descriere	char	30
from LOCATORI
order by LEFT(locator,13)

SELECT LOCATOR 
FROM LOCATORI L
GROUP BY LOCATOR

SELECT * FROM LOCATORI
WHERE ARTICOL =''