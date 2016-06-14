-- 
--while @@ROWCOUNT>0
--
-- insert LegaturiStornare (idSursa,idStorno)
select --t.*,r.*,
t.idPozDoc,r.idPozDoc
--,n.Denumire,t.*,r.*
-- dif_cant,dif_tip,rank_tip,r.Cantitate,r.Tip,t.* 
from pozdoc r join nomencl n on n.Cod=r.cod
	outer apply (select total_vandut=SUM(e.Cantitate) from pozdoc e join LegaturiStornare l on e.idPozDoc=l.idSursa where l.idStorno=r.idPozDoc) e
	cross apply 
		(select top (1) 
			dif_cant=abs(t.Cantitate-r.Cantitate), 
			dif_tip=DIFFERENCE(t.Tip,r.Tip), 
			rank_tip=(CASE t.Tip WHEN 'AP' THEN 0 WHEN 'AC' THEN 1 WHEN 'AE' THEN 2 ELSE 3 END)
			--,o.total_returnat
			, t.* 
		from pozdoc t left join LegaturiStornare s on s.idStorno=r.idPozDoc and s.idSursa=t.idPozDoc
			--outer apply (select total_returnat=sum(o.Cantitate) from pozdoc o join LegaturiStornare g on g.idStorno=o.idPozDoc where g.idSursa=t.idPozDoc) o
		where t.Tip_miscare='E' and t.Tip IN ('AP','AC') and t.Cantitate>0 
			and t.Data<=r.Data and t.Cod=r.Cod and t.Gestiune=r.Gestiune and t.Tert=r.Tert
			and s.idStorno is null
			--and t.Cantitate-abs(isnull(o.total_returnat,0))>=0
		order by t.Data desc,
			abs(t.Cantitate-r.Cantitate), DIFFERENCE(t.Tip,r.Tip) DESC, (CASE t.Tip WHEN 'AP' THEN 0 WHEN 'AC' THEN 1 WHEN 'AE' THEN 2 ELSE 3 END)
		) t 
where r.Tip_miscare='E' and r.Tip IN ('AP','AC') and r.Cantitate<0
	and abs(r.Cantitate)-isnull(e.total_vandut,0)>0
	--and r.idPozDoc=540107 and t.idPozDoc<>540178
	--and r.Data>='2016-01-01'


