/*
drop proc calculIndVMB
go
create proc calculIndVMB @dataj datetime='', @datas datetime='' as

*/
declare @dataj datetime='2012-08-01', @datas datetime='2012-08-31'
delete from expval where cod_indicator='VMB' --and ((data is null) and tip='E')
/*select 
p.Cantitate*p.Pret_vanzare-p.Cantitate*isnull(pk.pret_intrare_pachet,p.Pret_de_stoc)	,
valvanzare=p.Cantitate*p.Pret_vanzare,
pretvanzare=p.pret_vanzare,
p.Cantitate*isnull(pk.pret_intrare_pachet,p.Pret_de_stoc),
isnull(pk.pret_intrare_pachet,p.Pret_de_stoc),
Cantitate,
*--*/--n.Grupa,
--insert Expval (Cod_indicator,Tip,Data,Element_1,Element_2,Element_3,Element_4,Element_5,Valoare)
select indicator='VMB',tip='E'
,c.DATA_LUNII
,echipa=isnull(pp.echipa,'FARA ECHIPA')
,agent=isnull(lm.denumire,'FARA AGENT')
,client=isnull(t.denumire,'FARA CLIENT')
,grupa=isnull(g.denumire,'FARA GRUPA')
,articol=ISNULL(n.denumire,'FARA ARTICOL')
,valoare=sum(p.Cantitate*p.Pret_vanzare-p.Cantitate*isnull(pk.pret_intrare_pachet,p.Pret_de_stoc)) 
from pozdoc p inner join calstd c on c.Data=p.Data 
left join terti t on t.Subunitate=p.Subunitate and t.Tert=p.Tert left join lm on lm.Cod=p.Loc_de_munca left join nomencl n on n.Cod=p.Cod left join grupe g on g.Grupa=n.Grupa 
left join (select cod_produs,um,max(tip_pret) as tip_pret,MAX(Pret_vanzare) as Pret_vanzare,MAX(Pret_cu_amanuntul) as Pret_cu_amanuntul 
				from preturi group by cod_produs,um) pr on pr.cod_produs=p.cod and pr.um=p.Accize_cumparare
left join (select p.Cod,echipa=max(valoare) from proprietati p where Cod_proprietate='ECHIPA' and tip='TERT' group by p.Cod) pp
	on pp.cod=p.tert 
left join (select pp.Gestiune, Gestiune_primitoare=coalesce(c.gestiune_primitoare,t.gestiune_primitoare,'')
			,pp.cod_intrare,cod_intrare_primitor=coalesce(c.grupa,t.grupa,''), pp.Cod
			,pret_intrare_pachet=SUM(cm.cantitate*cm.Pret_de_stoc)/MAX(pp.cantitate) 
		from pozdoc cm
			inner join pozdoc pp on pp.Subunitate=cm.Subunitate and pp.Data=cm.Data and pp.Numar=cm.Numar and pp.Tip='PP'
			left join pozdoc t on t.Subunitate=pp.Subunitate and t.Gestiune=pp.Gestiune and t.Cod=pp.Cod and t.Cod_intrare=pp.Cod_intrare and t.Tip='TE'
			left join pozdoc c on c.Subunitate=t.Subunitate and c.Tip=t.Tip and c.Gestiune=t.Gestiune_primitoare and c.Cod=t.Cod and c.Cod_intrare=t.Grupa
		where cm.Tip='CM' 
		group by pp.Gestiune,coalesce(c.gestiune_primitoare,t.gestiune_primitoare,'')
			,pp.cod_intrare,coalesce(c.grupa,t.grupa,''), pp.Cod) pk
	on pk.cod=p.Cod and p.Gestiune in (pk.gestiune,pk.gestiune_primitoare)
		and p.Cod_intrare in (pk.cod_intrare,pk.cod_intrare_primitor)
where p.tip in ('AP','AC') and left(p.Cont_venituri,3) in ('707','709')
EXPANDEZ({c.DATA_LUNII}
,{isnull(pp.echipa,'FARA ECHIPA')}
,{isnull(lm.denumire,'FARA AGENT')}
,{isnull(t.denumire,'FARA CLIENT')}
,{isnull(g.denumire,'FARA GRUPA')}
,{ISNULL(n.denumire,'FARA ARTICOL')})
--and c.Data_lunii='2012-08-31' and p.Loc_de_munca='1SRV04' 
--and pp.echipa='Proiectanti' --and n.Grupa='A031' order by 1
group by 
c.DATA_LUNII
,isnull(pp.echipa,'FARA ECHIPA')
,isnull(lm.denumire,'FARA AGENT')
,isnull(t.denumire,'FARA CLIENT')
,isnull(g.denumire,'FARA GRUPA')
,ISNULL(n.denumire,'FARA ARTICOL')
go
