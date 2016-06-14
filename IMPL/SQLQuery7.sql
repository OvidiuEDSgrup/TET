select CASE LEFT(d.Numar,2) WHEN 'NT' THEN '1MKT19' WHEN 'CJ' THEN '1MKT20' ELSE d.Loc_munca END
,* from doc d where d.Tip='TE' and LEFT(d.Numar,2) IN ('NT','CJ')

 --UPDATE doc 
set Loc_munca= CASE LEFT(d.Numar,2) WHEN 'NT' THEN '1MKT19' WHEN 'CJ' THEN '1MKT20' ELSE d.Loc_munca END
from doc d where d.Tip='TE' and LEFT(d.Numar,2) IN ('NT','CJ')

select CASE LEFT(d.Numar,2) WHEN 'NT' THEN '1MKT19' WHEN 'CJ' THEN '1MKT20' ELSE d.Loc_de_munca END
,* from pozdoc d where d.Tip='TE' and LEFT(d.Numar,2) IN ('NT','CJ')

--update pozdoc
set Loc_de_munca= CASE LEFT(d.Numar,2) WHEN 'NT' THEN '1MKT19' WHEN 'CJ' THEN '1MKT20' ELSE d.Loc_de_munca END
--,* 
from pozdoc d where d.Tip='TE' and LEFT(d.Numar,2) IN ('NT','CJ')


--update pozdoc
set Loc_de_munca= CASE LEFT(d.Numar,2) WHEN 'NT' THEN '1MKT19' WHEN 'CJ' THEN '1MKT20' ELSE d.Loc_de_munca END
--,* 
from pozdoc d where d.Tip='TE' and LEFT(d.Numar,2) IN ('NT','CJ')

 --UPDATE doc 
set Loc_munca= CASE LEFT(d.Numar,2) WHEN 'NT' THEN '1MKT19' WHEN 'CJ' THEN '1MKT20' ELSE d.Loc_munca END
from doc d where d.Tip='TE' and LEFT(d.Numar,2) IN ('NT','CJ')