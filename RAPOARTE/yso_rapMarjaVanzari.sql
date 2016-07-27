drop FUNCTION yso_fTransferuriPachete 
go
CREATE FUNCTION yso_fTransferuriPachete 
(	
	-- Add the parameters for the function here
	@subunitate varchar(10)
	,@cod varchar(20)
	,@gestiune varchar(10)
	,@cod_intrare varchar(20)
	,@data datetime
	--,@nrluni int
)
RETURNS TABLE 
AS
RETURN 
(with transferuri as
	(select p.Subunitate, p.Data, p.Cod
		,Gestiune=(case when p.Cantitate>=0.001 then p.Gestiune else p.Gestiune_primitoare end)
		,Cod_intrare=(case when p.Cantitate>=0.001 then p.Cod_intrare else p.Grupa end)
		,Gestiune_primitoare=(case when p.Cantitate>=0.001 then p.Gestiune_primitoare else p.Gestiune end)
		,Cod_intrare_primitor=(case when p.Cantitate>=0.001 then p.Grupa else p.Cod_intrare end)
	from pozdoc p where p.Subunitate='1' and p.Tip='TE' and abs(p.Cantitate)>=0.001)
	-- Add the SELECT statement with parameter references here
	select distinct p.Subunitate, p.Gestiune_primitoare, p.Cod_intrare_primitor
	from transferuri p
	where p.Subunitate=@subunitate and p.Cod=@cod 
		and p.Gestiune=@gestiune and p.Cod_intrare=@cod_intrare
)
GO
drop procedure yso_rapMarjaVanzari 
go
/*
exec yso_rapMarjaVanzari
	@Data_doc_de_la=@Data_doc_de_la
	,@Data_doc_pana_la=@Data_doc_pana_la
	,@Loc_de_munca=@Loc_de_munca
	,@Tert=@Tert
	,@Grupa_articole=@Grupa_articole
	,@Cod_articol=@Cod_articol
	,@Doar_pachete=@Doar_pachete
	,@Echipa=@Echipa
	
*/
create procedure yso_rapMarjaVanzari @Data_doc_de_la datetime,@Data_doc_pana_la datetime,@Loc_de_munca nvarchar(4000),@Tert nvarchar(4000)
	,@Grupa_articole nvarchar(4000),@Cod_articol nvarchar(4000),@Doar_pachete bit,@Echipa nvarchar(4000)
as
--select @Data_doc_de_la='2012-01-01 00:00:00',@Data_doc_pana_la='2013-06-30 00:00:00'
--	,@Loc_de_munca=null,@Tert=null,@Grupa_articole=null,@Cod_articol=NULL,@Doar_pachete=0,@Echipa=null

declare @subunitate varchar(20)='1', @rotunjire int='2'
select @subunitate=(case when parametru='SUBPRO' then val_alfanumerica else @subunitate end),  
   @rotunjire=(case when parametru='ROTUNJ' and val_logica=1 then val_numerica else @rotunjire end)  
 from par where par.Tip_parametru='GE' and Parametru in ('SUBPRO', 'ROTUNJ')  

if OBJECT_ID('tempdb..#coduri') is not null drop table #coduri

--begin try
;with 
consumuri as
	(select p.Subunitate, p.Numar, p.Data
		,cant_consum=SUM(p.Cantitate)
		,val_consum=SUM(p.Cantitate*p.Pret_de_stoc)	
	from pozdoc p where p.Subunitate='1' and p.Tip='CM'
	group by p.Subunitate, p.Numar, p.Data)
,predari as
	(select p.Subunitate, p.Numar, p.Data, p.Cod, p.Gestiune, p.Cod_intrare
		,cant_predare=SUM(p.Cantitate),val_predare=SUM(p.Cantitate*p.Pret_de_stoc)
		,cant_consum=max(c.cant_consum),val_consum=max(c.val_consum)
		,pret_intrare=max(c.val_consum)/sum(sum(p.Cantitate)) over(partition by p.subunitate,p.numar,p.data)	
	from pozdoc p 
		inner join consumuri c on p.Subunitate=c.Subunitate and p.Numar=c.Numar and p.Data=c.Data
	where p.Subunitate='1' and p.Tip='PP' --and p.idPozDoc=38631
	group by p.Subunitate, p.Numar, p.Data, p.Cod, p.Gestiune, p.Cod_intrare)
,coduri as
	(select p.Subunitate, p.data, p.Cod, Gestiune=convert(char(13),p.Gestiune), p.Cod_intrare
		,p.pret_intrare
		,Nivel=0
	from predari p
	union all
	select c.Subunitate, c.data, c.Cod, p.Gestiune_primitoare, convert(char(20),p.Cod_intrare_primitor)
		,c.pret_intrare
		,Nivel=c.Nivel+1
	from coduri c 
		cross apply yso_fTransferuriPachete(c.Subunitate,c.Cod,c.Gestiune,c.Cod_intrare,c.data) p
	where c.Nivel<=10)

select * 
into #coduri
from coduri c 

create nonclustered index princ on #coduri (subunitate,data,cod,gestiune,cod_intrare)

--option (MAXRECURSION 3)
--end try
--begin catch
--end catch

if OBJECT_ID('tempdb..#nou') is not null drop table #nou

select 
p.Tip,p.Cont_venituri,
	p.Data,a.An,a.Luna,a.LunaAlfa,a.Zi,a.Zi_alfa,a.Saptamana,a.Trimestru,
ltrim(rtrim(i.Loc_munca)) +' - '+LTRIM(RTRIM(lm.denumire)) as agent,
ltrim(rtrim(p.Tert))+' - '+LTRIM(RTRIM(t.denumire)) as client,
ltrim(rtrim(t.Judet))+' - '+LTRIM(RTRIM(j.denumire)) as judet,
ltrim(rtrim(n.Grupa))+' - '+ltrim(rtrim(g.Denumire)) as grupa,
p.Cod as articol,
n.Denumire as descriere,
p.Cantitate as cantitate,
p.Cantitate*pr.Pret_vanzare as pretCatalog,
round(convert(decimal(17,5),p.cantitate*p.pret_vanzare),@rotunjire) as pretVanzare,
p.Cantitate*pr.Pret_vanzare -p.Cantitate*p.Pret_vanzare as discount,
(case when p.Cantitate*p.Pret_vanzare!=0 then  1-round((p.Cantitate*pr.Pret_vanzare/p.Cantitate*p.Pret_vanzare),2) else 0 end) as discountProcent,
isnull(p.cantitate*c.pret_intrare,p.Cantitate*p.Pret_de_stoc) as pretIntrare,
p.gestiune,p.cod_intrare,
(select top 1 valoare from proprietati where Cod_proprietate='ECHIPA' and tip='TERT' and cod=p.tert and valoare<>'') as echipa 
--into #nou
from  pozdoc p 
	outer apply (select top 1 * from #coduri c
		where c.Subunitate=p.Subunitate and c.Cod=p.Cod and c.Gestiune=p.Gestiune and c.Cod_intrare=p.Cod_intrare
		order by ABS(DATEDIFF(M,c.Data,p.Data)), sign(DATEDIFF(M,c.Data,p.Data)) desc) c
	left join doc d on  p.Data=d.Data and p.Numar=d.Numar and p.Tip=d.Tip
	left join (select cod_produs,um,max(tip_pret) as tip_pret,MAX(Pret_vanzare) as Pret_vanzare,MAX(Pret_cu_amanuntul) as Pret_cu_amanuntul 
				from preturi group by cod_produs,um) pr on  pr.cod_produs=p.cod and pr.um=p.Accize_cumparare
	left join nomencl n on  n.Cod=p.Cod and n.Cod=p.Cod 
	left join grupe g on  n.Grupa=g.Grupa
	left join terti t on  p.Tert=t.Tert
	left join judete j on j.cod_judet=t.Judet
	outer apply (select top 1 * from proprietati pr where pr.Tip='TERT' and pr.Cod_proprietate='VZ_SM' and pr.Cod=t.Tert and pr.valoare<>'') sm
	left join infotert i on i.Subunitate=t.Subunitate and i.Tert=t.Tert and i.Identificator=''
	left join lm on lm.Cod=i.Loc_munca
	left join CalStd a on a.Data=p.Data
where p.tip in ('AP','AC')
	 and p.data>=@Data_doc_de_la and p.data<=@Data_doc_pana_la
	 and left(p.Cont_venituri,3) in ('707','709')
	--and p.Cantitate!=0
	AND (isnull(@Loc_de_munca,  '') = '' OR p.Loc_de_munca = rtrim(rtrim(@Loc_de_munca)))
	AND (isnull(@tert,  '') = '' OR p.tert = rtrim(rtrim(@tert)))
	--AND (isnull(@grupa,  '') = '' OR n.grupa = rtrim(rtrim(@grupa)))
	AND (isnull(@Cod_articol,  '') = '' OR p.cod = rtrim(rtrim(@Cod_articol)))
	and (@Doar_pachete=0 or n.tip='P')


--declare @data1 datetime,@data2 datetime,@lm nvarchar(4000),@tert nvarchar(4000),@grupa nvarchar(4000),@cod nvarchar(4000),@pachete bit,@echipa nvarchar(4000)
--select @data1='2012-08-01 00:00:00',@data2='2012-08-31 00:00:00',@lm='1MKT19',@tert='1490218272624',@grupa=null,@cod=NULL,@pachete=0,@echipa=NULL
/*
if OBJECT_ID('tempdb..#vechi') is not null drop table #vechi

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
isnull(sum(p.cantitate)*max(cp.pretintrare),sum(p.Cantitate*p.Pret_de_stoc)) as pretIntrare,
data=max(p.data),
data_pp=max(cp.Data),numar_pp=max(cp.numar),
p.gestiune,p.cod_intrare,
--end) 
--end )
(select valoare from proprietati where Cod_proprietate='ECHIPA' and tip='TERT' and cod=p.tert) as echipa
 from   pozdoc p 
 outer apply (select top 1 data=pp.Data,numar=max(pp.Numar),pretintrare=SUM(cm.cantitate*cm.Pret_de_stoc)/MAX(pp.cantitate) 
			from pozdoc cm
				inner join pozdoc pp on pp.Subunitate=cm.Subunitate and pp.Data=cm.Data and pp.Numar=cm.Numar and pp.Tip='PP'
				outer apply (select top 1 * from pozdoc t where t.Subunitate=pp.Subunitate and t.Gestiune=pp.Gestiune and t.Cod=pp.Cod and t.Cod_intrare=pp.Cod_intrare and t.Tip='TE'
					order by ABS(DATEDIFF(M,t.Data,p.Data)), sign(DATEDIFF(M,t.Data,p.Data)) desc) t
				outer apply (select top 1 * from pozdoc c where c.Subunitate=t.Subunitate and c.Tip=t.Tip and c.Gestiune=t.Gestiune_primitoare and c.Cod=t.Cod and c.Cod_intrare=t.Grupa
					order by ABS(DATEDIFF(M,t.Data,p.Data)), sign(DATEDIFF(M,t.Data,p.Data)) desc) c
			where cm.Tip='CM' and pp.cod=p.Cod 
				and p.Gestiune in (pp.gestiune,isnull(c.gestiune_primitoare,t.gestiune_primitoare))
				and p.Cod_intrare in (pp.cod_intrare,isnull(c.grupa,t.grupa))
			group by pp.data order by ABS(DATEDIFF(M,pp.Data,p.Data)), sign(DATEDIFF(M,pp.Data,p.Data)) desc) cp
 left join doc d on  p.Data=d.Data and p.Numar=d.Numar and p.Tip=d.Tip
	left join (select cod_produs,um,max(tip_pret) as tip_pret,MAX(Pret_vanzare) as Pret_vanzare,MAX(Pret_cu_amanuntul) as Pret_cu_amanuntul 
				from preturi group by cod_produs,um) pr on  pr.cod_produs=p.cod and pr.um=p.Accize_cumparare
	left join nomencl n on  n.Cod=p.Cod and n.Cod=p.Cod 
	left join grupe g on  n.Grupa=g.Grupa
	left join lm on  lm.Cod=p.Loc_de_munca
	left join  terti t on  p.Tert=t.Tert
where p.tip in ('AP','AC')
 and p.data>=@Data_doc_de_la and p.data<=@Data_doc_pana_la
 and left(p.Cont_venituri,3) in ('707','709')
--and p.Cantitate!=0
AND (isnull(@Loc_de_munca,  '') = '' OR p.Loc_de_munca = rtrim(rtrim(@Loc_de_munca)))
AND (isnull(@tert,  '') = '' OR p.tert = rtrim(rtrim(@tert)))
--AND (isnull(@grupa,  '') = '' OR n.grupa = rtrim(rtrim(@grupa)))
AND (isnull(@Cod_articol,  '') = '' OR p.cod = rtrim(rtrim(@Cod_articol)))
and (@Doar_pachete=0 or n.tip='P')
group by p.Loc_de_munca,lm.Denumire,p.Tert,t.Denumire,n.Grupa,g.Denumire,p.Gestiune,p.Cod,n.Denumire,p.Cod_intrare,n.Tip
,p.Cont_venituri,p.Tip
--having  SUM(p.cantitate)!=0
)r
where (isnull(@echipa,  '') = '' OR r.echipa = rtrim(rtrim(@echipa))) 
--and r.articol like 'PKSONEP150_11%'
--order by r.articol
--group by r.Cont_venituri,r.tip
*/
/*
select * from 
(select 
agent,client,grupa,articol,gestiune,cod_intrare,--data,
pretintrare=sum(pretintrare) 
,pretvanzare=sum(pretvanzare) 
from #vechi v 
--where v.echipa like 'filiala cj'
group by agent,client,grupa,articol,gestiune,cod_intrare--,data
) v 
full outer join
(select 
agent,client,grupa,articol,gestiune,cod_intrare,--data,
pretintrare=sum(pretintrare) 
,pretvanzare=sum(pretvanzare)
from #nou 
group by agent,client,grupa,articol,gestiune,cod_intrare--,data
) n 
on 1=1 
and n.agent=v.agent and n.client=v.client and n.grupa=v.grupa and n.articol=v.articol and n.gestiune=v.gestiune and n.cod_intrare=v.cod_intrare
--and n.Data=v.data
where abs(n.pretintrare-v.pretintrare)>=0.5
--*/
/*
--1VZ_CJ_00 - CLUJ FILIALA	1620723120651 - ROSU OVIDIU	A02 - PACHETE SI MODULE TET	MALK50_11           
--1VZ_CJ_00 - CLUJ FILIALA	RO21654199 - SCN NAPOCA LEX	A02 - PACHETE SI MODULE TET	MALK50_11           
--1VZ_MH_01 - MEHEDINTI1	20120125 - TITAN CRIS SRL	A02 - PACHETE SI MODULE TET	PKSONEP150_11  
--1VZ_MH_01 - MEHEDINTI1	20120125 - TITAN CRIS SRL	A02 - PACHETE SI MODULE TET	PKSONEP150_11            
--1VZ_DJ_00 - DOLJ FILIALA	1800531165657 - GRIGORAN IONUT	A02 - PACHETE SI MODULE TET	PKSONEP150_11       
--1VZ_DJ_02 - DOLJ2	RO18567335 - ACV INSTAL SRL	A02 - PACHETE SI MODULE TET	PKSONEP150_11       
--1VZ_MH_01 - MEHEDINTI1	20120125 - TITAN CRIS SRL	A02 - PACHETE SI MODULE TET	PKSONEP150_11       
--1VZ_SV_03 - SUCEAVA3	RO18836620 - ROBOTERMO SRL	A02 - PACHETE SI MODULE TET	SLME3HP30X1CA_11    

select cp.*,p.* 
from pozdoc p 
outer apply (select top 1 data=pp.Data,numar=max(pp.Numar),pretintrare=SUM(cm.val_consum)/SUM(pp.cantitate) 
	,val_consum=SUM(cm.val_consum),cant_predare=SUM(pp.cantitate) 
			from pozdoc pp
				cross apply (select val_consum=SUM(cm.cantitate*cm.Pret_de_stoc) 
					from pozdoc cm where pp.Subunitate=cm.Subunitate and pp.Data=cm.Data and pp.Numar=cm.Numar and cm.Tip='CM'
					having isnull(SUM(cm.cantitate*cm.Pret_de_stoc),0)>0) cm
				outer apply (select top 1 * from pozdoc t where t.Subunitate=pp.Subunitate and t.Gestiune=pp.Gestiune and t.Cod=pp.Cod and t.Cod_intrare=pp.Cod_intrare and t.Tip='TE'
					order by ABS(DATEDIFF(M,t.Data,p.Data)), sign(DATEDIFF(M,t.Data,p.Data)) desc) t
				outer apply (select top 1 * from pozdoc c where c.Subunitate=t.Subunitate and c.Tip=t.Tip and c.Gestiune=t.Gestiune_primitoare and c.Cod=t.Cod and c.Cod_intrare=t.Grupa
					order by ABS(DATEDIFF(M,t.Data,p.Data)), sign(DATEDIFF(M,t.Data,p.Data)) desc) c
			where PP.Tip='pp' and pp.cod=p.Cod 
				and p.Gestiune in (pp.gestiune,isnull(c.gestiune_primitoare,t.gestiune_primitoare))
				and p.Cod_intrare in (pp.cod_intrare,isnull(c.grupa,t.grupa))
			group by pp.data order by ABS(DATEDIFF(M,pp.Data,p.Data)), sign(DATEDIFF(M,pp.Data,p.Data)) desc) cp
where p.Subunitate='1' and p.Cod='SLME3HP30X1CA_11       ' and p.Cod_intrare LIKE '12002A           ' and p.Gestiune='101'

select * from pozdoc p where p.Tip='pp' and p.Numar='12      '

select * from #coduri c
		where c.Subunitate='1' and c.Cod='SLME3HP30X1CA_11       ' and c.Cod_intrare LIKE '12002A           ' and c.Gestiune='101'
		order by ABS(DATEDIFF(M,c.Data,'2012-06-27 00:00:00.000')), sign(DATEDIFF(M,c.Data,'2012-06-27 00:00:00.000')) desc

select * from pozdoc c
		where c.Subunitate='1' and c.Cod='PKSONEP150_11' and '101' in (c.Gestiune,c.Gestiune_primitoare) 
			and '61/03001AAC         ' in (c.Cod_intrare,c.Grupa)
			order by c.Data
			
select * from pozdoc c
		where c.Subunitate='1' and c.Cod='PKSONEP150_11' and '400' in (c.Gestiune,c.Gestiune_primitoare) 
			and '61/03001AAC' in (c.Cod_intrare,c.Grupa)
	


;with 
consumuri as
	(select p.Subunitate, p.Numar, p.Data
		,cant_consum=SUM(p.Cantitate)
		,val_consum=SUM(p.Cantitate*p.Pret_de_stoc)	
	from pozdoc p where p.Subunitate='1' and p.Tip='CM'
	group by p.Subunitate, p.Numar, p.Data)
select C.*,p.*
		--,cant_predare=SUM(p.Cantitate),val_predare=SUM(p.Cantitate*p.Pret_de_stoc)
		--,cant_consum=max(c.cant_consum),val_consum=max(c.val_consum)
		--,pret_intrare=max(c.val_consum)/sum(sum(p.Cantitate)) over(partition by p.subunitate,p.numar,p.data)	
	from pozdoc p 
		inner join pozdoc c on p.Subunitate=c.Subunitate and c.Tip='CM' and p.Numar=c.Numar and p.Data=c.Data
	where p.Subunitate='1' and p.Tip='PP' --and p.idPozDoc=38631
	and p.Cod='PKSONEP150_11' and p.Cod_intrare='61/03001A' and p.Gestiune='101'
	--group by p.Subunitate, p.Numar, p.Data, p.Cod, p.Gestiune, p.Cod_intrare
--select * from pozdoc p where p.Numar='61/03'

--*/
go
--/*
declare @Data_doc_de_la datetime,@Data_doc_pana_la datetime,@Loc_de_munca nvarchar(4000),@Tert nvarchar(4000)
	,@Grupa_articole nvarchar(4000),@Cod_articol nvarchar(4000),@Doar_pachete bit,@Echipa nvarchar(4000)

select @Data_doc_de_la='2012-01-01 00:00:00',@Data_doc_pana_la='2013-06-30 00:00:00'
	,@Loc_de_munca=null,@Tert=null,@Grupa_articole=null,@Cod_articol=NULL,@Doar_pachete=0,@Echipa=null
exec yso_rapMarjaVanzari
	@Data_doc_de_la=@Data_doc_de_la
	,@Data_doc_pana_la=@Data_doc_pana_la
	,@Loc_de_munca=@Loc_de_munca
	,@Tert=@Tert
	,@Grupa_articole=@Grupa_articole
	,@Cod_articol=@Cod_articol
	,@Doar_pachete=@Doar_pachete
	,@Echipa=@Echipa
--*/