select sum(p.Cantitate*p.Pret_vanzare) 
from pozdoc p inner join calstd c on c.Data=p.Data 
left join terti t on t.Subunitate=p.Subunitate and t.Tert=p.Tert left join lm on lm.Cod=p.Loc_de_munca left join nomencl n on n.Cod=p.Cod left join grupe g on g.Grupa=n.Grupa 
left join (select cod_produs,um,max(tip_pret) as tip_pret,MAX(Pret_vanzare) as Pret_vanzare,MAX(Pret_cu_amanuntul) as Pret_cu_amanuntul 
				from preturi group by cod_produs,um) pr on pr.cod_produs=p.cod and pr.um=p.Accize_cumparare
left join (select p.Cod,echipa=max(valoare) from proprietati p where Cod_proprietate='ECHIPA' and tip='TERT' group by p.Cod) pp
	on pp.cod=p.tert 
where p.tip in ('AP','AC') and left(p.Cont_venituri,3) in ('707','709')
EXPANDEZ({c.DATA_LUNII}
,{isnull(pp.echipa,'FARA ECHIPA')}
,{isnull(lm.denumire,'FARA AGENT')}
,{isnull(t.denumire,'FARA CLIENT')}
,{isnull(g.denumire,'FARA')}
,{ISNULL(n.denumire,'FARA ARTICOL')})