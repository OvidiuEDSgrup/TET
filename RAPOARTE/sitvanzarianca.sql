declare @data1 datetime,@data2 datetime,@lm nvarchar(4000),@tert nvarchar(4000),@grupa nvarchar(4000),@cod nvarchar(4000),@pachete bit,@echipa nvarchar(4000)
select @data1='2012-01-01 00:00:00',@data2='2013-06-30 00:00:00',@lm=null,@tert=null,@grupa=null,@cod=NULL,@pachete=0,@echipa=null

declare @subunitate varchar(20)='1', @rotunjire int='2'
select @subunitate=(case when parametru='SUBPRO' then val_alfanumerica else @subunitate end),  
   @rotunjire=(case when parametru='ROTUNJ' and val_logica=1 then val_numerica else @rotunjire end)  
 from par where par.Tip_parametru='GE' and Parametru in ('SUBPRO', 'ROTUNJ')  
 
select /*
pretvanzare-pretintrare,
valvanzare=pretvanzare,
pretvanzare=pretvanzare/cantitate,
valintrare=pretintrare,
pretintrare/cantitate,
cantitate,
*--*/--r.grupa,
--SUM(pretvanzare-pretintrare) 
 --*
 --r.cont_venituri,r.Tip,
-- ,CASE P.Tip WHEN 'AC' then case when ab.Factura is null then P.Tip else 'BC' end else p.Tip end
--,CASE when n.Tip not in ('S','R') then '' else p.Cod end as cod 
 --sum(r.pretintrare) as pretintrare
 --,sum(r.pretVanzare) as pretVanzare
 *
 into #vechi
from
(
select p.Tip,p.Cont_venituri,
ltrim(rtrim(p.Loc_de_munca)) +' - '+LTRIM(RTRIM(lm.denumire)) as agent,
ltrim(rtrim(p.Tert))+' - '+LTRIM(RTRIM(t.denumire)) as client,
ltrim(rtrim(n.Grupa))+' - '+ltrim(rtrim(g.Denumire)) as grupa,
p.Cod as articol,
n.Denumire as descriere,
sum(p.Cantitate) as cantitate,
sum(p.Cantitate*pr.Pret_vanzare) as pretCatalog,
sum(round(convert(decimal(17,5),p.cantitate*p.pret_vanzare),@rotunjire)) as pretVanzare,
sum(p.Cantitate*pr.Pret_vanzare -p.Cantitate*p.Pret_vanzare) as discount,
(case when sum(p.Cantitate*p.Pret_vanzare)!=0 then  1-round((sum(p.Cantitate*pr.Pret_vanzare)/sum(p.Cantitate*p.Pret_vanzare)),2) else 0 end) as discountProcent,
/*
--sum(p.Cantitate*p.Pret_de_stoc) as pretIntrare,
sum(p.Cantitate*p.Pret_vanzare-p.Cantitate*p.Pret_de_stoc) as marja,
round((sum(p.Cantitate*p.Pret_vanzare)/sum(p.Cantitate*p.Pret_de_stoc))*100,2) as marjaProcent,*/
--(case when n.tip!='P' then sum(p.Cantitate*p.Pret_de_stoc) else 
--(case when isnull((select max(te.grupa) from pozdoc te where te.tip='TE' and te.cod=p.cod and p.cod_intrare=te.grupa and te.Gestiune_primitoare=p.Gestiune),'')='' 
--then isnull((select SUM(cm.cantitate*cm.Pret_de_stoc) from pozdoc pp,pozdoc cm where pp.cod=p.Cod and pp.Cod_intrare=p.Cod_intrare and pp.tip='PP' and cm.Tip='CM' and pp.Numar=cm.Numar and pp.Data=cm.data),sum(p.Cantitate*p.Pret_de_stoc))
--else 
isnull(sum(p.cantitate)*
(select SUM(cm.cantitate*cm.Pret_de_stoc)/MAX(pp.cantitate) 
from pozdoc cm
	inner join pozdoc pp on pp.Subunitate=cm.Subunitate and pp.Data=cm.Data and pp.Numar=cm.Numar and pp.Tip='PP'
	left join pozdoc t on t.Subunitate=pp.Subunitate and t.Gestiune=pp.Gestiune and t.Cod=pp.Cod and t.Cod_intrare=pp.Cod_intrare and t.Tip='TE'
	left join pozdoc c on c.Subunitate=t.Subunitate and c.Tip=t.Tip and c.Gestiune=t.Gestiune_primitoare and c.Cod=t.Cod and c.Cod_intrare=t.Grupa
where cm.Tip='CM' and pp.cod=p.Cod 
	and p.Gestiune in (pp.gestiune,isnull(c.gestiune_primitoare,t.gestiune_primitoare))
	and p.Cod_intrare in (pp.cod_intrare,isnull(c.grupa,t.grupa)))
,sum(p.Cantitate*p.Pret_de_stoc)) as pretIntrare,
--end) 
--end )
(select valoare from proprietati where Cod_proprietate='ECHIPA' and tip='TERT' and cod=p.tert) as echipa
 from   pozdoc p left join doc d on  p.Data=d.Data and p.Numar=d.Numar and p.Tip=d.Tip
	left join (select cod_produs,um,max(tip_pret) as tip_pret,MAX(Pret_vanzare) as Pret_vanzare,MAX(Pret_cu_amanuntul) as Pret_cu_amanuntul 
				from preturi group by cod_produs,um) pr on  pr.cod_produs=p.cod and pr.um=p.Accize_cumparare
	left join nomencl n on  n.Cod=p.Cod and n.Cod=p.Cod 
	left join grupe g on  n.Grupa=g.Grupa
	left join lm on  lm.Cod=p.Loc_de_munca
	left join  terti t on  p.Tert=t.Tert
where p.tip in ('AP','AC')
 and p.data>=@data1 and p.data<=@data2
 and left(p.Cont_venituri,3) in ('707','709')
--and p.Cantitate!=0
AND (isnull(@lm,  '') = '' OR p.Loc_de_munca = rtrim(rtrim(@lm)))
AND (isnull(@tert,  '') = '' OR p.tert = rtrim(rtrim(@tert)))
--AND (isnull(@grupa,  '') = '' OR n.grupa = rtrim(rtrim(@grupa)))
AND (isnull(@cod,  '') = '' OR p.cod = rtrim(rtrim(@cod)))
and (@pachete=0 or n.tip='P')
group by p.Loc_de_munca,lm.Denumire,p.Tert,t.Denumire,n.Grupa,g.Denumire,p.Gestiune,p.Cod,n.Denumire,p.Cod_intrare,n.Tip
,p.Cont_venituri,p.Tip
--having  SUM(p.cantitate)!=0
)r
where (isnull(@echipa,  '') = '' OR r.echipa = rtrim(rtrim(@echipa))) 
--and r.articol like 'PKSONEP150_11%'
--order by r.articol
--group by r.Cont_venituri,r.tip

select 
sum(r.pretintrare) as pretintrare
 ,sum(r.pretVanzare) as pretVanzare
 from #vechi r