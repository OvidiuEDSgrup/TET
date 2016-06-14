select * -- delete p
from pozdoc p where p.Subunitate='1' and p.Tip in ('AC','te') and p.Cantitate<=-0.001
--and p.Pret_de_stoc=p.Pret_vanzare 
and p.Numar='20001' AND P.Data='2013-06-22'
--and p.Data='2013-'
--and p.Cod='EK 20'
--and p.Cod='ek 20'
order by p.Data desc

select * from pozdoc p where p.Tip_miscare='E' 
AND p.Cod='ek 20'
--and p.Cod='9-3690-530-00-24-01'
and p.Tert='1820116125847'
and p.Cantitate>0
order by p.data desc

SELECT *
					FROM dbo.pozdoc p 
					WHERE 
						Subunitate='1'
						AND cod='ek 20' --/*sp
						AND Tip_miscare='E' AND p.Cantitate>0 AND p.Tip IN ('AP','AC') --AND p.Data<='2013-07-05'
						AND charindex(';'+RTrim(p.Gestiune)+';',';210.cj;')>0
--sp*/					AND Tip_miscare='I'
					ORDER BY Data desc
					
					--select * from preturi
select * from antetbonuri a where a.Data_bon='2013-06-22' and a.Casa_de_marcat=2 and a.Numar_bon=1 
					
SELECT *
		FROM stocuri
		WHERE subunitate = '1'
			--AND tip_gestiune = 'a'
			AND cod_gestiune = isnull('210.cj', '')
			AND cod = isnull('ek 20', '')
			--AND cod_intrare = isnull('SE117190D-C8D', '')