SELECT 
UPDATE infotert
set Loc_munca= lm.Cod
--,* 
from infotert i inner join terti t on i.Tert=t.Tert
left join lm on lm.Denumire like rtrim(i.Loc_munca)+'%'
where Loc_munca not in (select cod from lm)
and Loc_munca <>''




select i.Responsabil,personal.Nume,lm.Denumire,*
from con i inner join terti t on i.Tert=t.Tert
left join personal on marca=responsabil or personal.nume like rtrim(i.Responsabil)+'%'
LEFT JOIN lm on lm.Cod='1VNZ'+LTRIM(personal.Marca) or lm.Denumire like RTRIM(responsabil)+'%'
where Responsabil not in (select marca from personal)
--and Loc_de_munca<>'' 
and Responsabil<>''
	
--NASTASIE DANIEL- ION
select * from con
update con
set Responsabil=ISNULL(personal.Marca,lm.denumire),
Loc_de_munca=lm.Cod
from con i inner join terti t on i.Tert=t.Tert
left join personal on marca=responsabil or personal.nume like rtrim(i.Responsabil)+'%'
LEFT JOIN lm on lm.Cod='1VNZ'+LTRIM(personal.Marca) or lm.Denumire like RTRIM(responsabil)+'%'
where Responsabil not in (select marca from personal)
--and Loc_de_munca<>'' 
and Responsabil<>'' 
and tip in ('BF','FA')

SELECT * FROM par WHERE Parametru LIKE 'MODTAPROB'