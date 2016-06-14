select  n.Stare,stare=(case isnull(n.Stare,0) when 0 then 0 when 1 then 1 else 2 end),denstare=RTRIM(s.denumire) 
,*
			from PozContracte p 
				left join necesaraprov n on n.numar='GL910002' and p.idPozContract=n.Numar_pozitie
				outer apply (select top 1 stare from JurnalContracte jc where jc.idContract=45 order by data desc,idJurnal desc) uj
				left join StariContracte s on s.tipContract='rn' and s.stare=(case isnull(n.Stare,0) when 0 then 0 when 1 then 1 else 2 end)
			where  45=p.idContract --and ISNULL(n.Stare,0)<>isnull(uj.stare,0)
			
			order by (case isnull(n.Stare,0) when 0 then 0 when 1 then 1 else 2 end)
			