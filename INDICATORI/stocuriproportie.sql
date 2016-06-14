select d.Data_lunii,isnull(d.DenGest,d.gestiune),
sum ((d.stoci+d.intrari-d.iesiri)*d.pret) 
from (select c.Data_lunii, r.subunitate, r.cont,r.cod,r.cod_intrare,r.gestiune,
	(case when r.data<RTRIM(c.An)+'-'+rtrim(c.luna)+'-01' then RTRIM(c.An)+'-'+rtrim(c.luna)+'-01' else r.data end) as data,
								sum((case when in_out=1 then 1
								when (in_out=2 and r.data<RTRIM(c.An)+'-'+rtrim(c.luna)+'-01') then 1
								when (in_out=3 and r.data<RTRIM(c.An)+'-'+rtrim(c.luna)+'-01') then -1
								else 0 end)*r.cantitate) as stoci,
	 sum((case when in_out=2 and r.data between RTRIM(c.An)+'-'+rtrim(c.luna)+'-01' and c.data_lunii then r.cantitate else 0 end)) as intrari,
	sum((case when in_out=3 and r.data between RTRIM(c.An)+'-'+rtrim(c.luna)+'-01' and c.data_lunii then cantitate else 0 end)) as iesiri,
	g.denumire_gestiune as DenGest,(case when ''='F' then r.loc_de_munca else '' end) as loc_de_munca
	, max(r.predator) predator,
	max(case when '0'='0' or '0'='2' and g.Tip_gestiune<>'A' then r.pret
			when '0'='1' or '0'='2' and g.Tip_gestiune='A' then r.pret_cu_amanuntul else 0 end) as pret
from calstd c 
left join (select distinct Data_lunii from istoricstocuri) i on  i.Data_lunii=c.Data_lunii
cross apply dbo.fStocuri(RTRIM(c.An)+'-'+rtrim(c.luna)+'-01',c.Data_lunii,null,null,null,null,'D',null,0,null,null,null,null,null,null) r
left join gestiuni g on g.subunitate=r.subunitate and g.Tip_gestiune=r.tip_gestiune and g.Cod_gestiune=r.gestiune
where c.Data=c.Data_lunii and (i.Data_lunii is not null or c.Data_lunii<=dateadd(day,-day(getdate()),dateadd(month,1,GETDATE())))
group by c.Data_lunii, r.subunitate,
	r.cont,r.cod,r.cod_intrare,r.gestiune,r.pret,r.pret_cu_amanuntul,
	(case when r.data<RTRIM(c.An)+'-'+rtrim(c.luna)+'-01' then 'SI' else r.tip_document end),
	(case when r.data<RTRIM(c.An)+'-'+rtrim(c.luna)+'-01' then '' else r.numar_document end),
	(case when r.data<RTRIM(c.An)+'-'+rtrim(c.luna)+'-01' then RTRIM(c.An)+'-'+rtrim(c.luna)+'-01' else r.data end),
	(case when r.data<RTRIM(c.An)+'-'+rtrim(c.luna)+'-01' then '' else r.tert end),
	g.denumire_gestiune,(case when ''='F' then r.loc_de_munca else '' end)
having
	(
								sum((case when in_out=1 then 1
								when (in_out=2 and r.data<RTRIM(c.An)+'-'+rtrim(c.luna)+'-01') then 1
								when (in_out=3 and r.data<RTRIM(c.An)+'-'+rtrim(c.luna)+'-01') then -1
								else 0 end)*r.cantitate)<>0
	or
	 sum((case when in_out=2 and r.data between RTRIM(c.An)+'-'+rtrim(c.luna)+'-01' and c.data_lunii then r.cantitate else 0 end))<>0
	or
	sum((case when in_out=3 and r.data between RTRIM(c.An)+'-'+rtrim(c.luna)+'-01' and c.data_lunii then cantitate else 0 end))<>0
	)) d
where 1=1
EXPANDEZ({d.data_lunii},{isnull(d.DenGest,d.gestiune)})
group by d.data_lunii,isnull(d.DenGest,d.gestiune)