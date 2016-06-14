select cod_gestiune,locatie,SUM(stoc)
-- select *
from stocuri s where s.Stoc>0 and s.Cod_gestiune like '700%'
group by s.Cod_gestiune,s.Locatie
order by s.Cod_gestiune,s.Locatie