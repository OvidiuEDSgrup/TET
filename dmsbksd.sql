select * from istoricstocuri where Cod_gestiune='300'
select * from istoricstocuri where cod='08028100            '
select * from stocuri where cod='08028100            '
SELECT * FROM STOCURIMPL_ISTORIC
SELECT * 
into istoricstocuri_rezervate
FROM istoricstocuri where data<>'2012-01-01'

--delete istoricstocuri
----into istoricstocuri_rezervate
--FROM istoricstocuri where data<>'2012-01-01'