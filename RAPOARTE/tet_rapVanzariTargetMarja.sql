--drop procedure [dbo].[tet_rapVanzariTargetMarja] GO
declare/* pt teste decomenteaza aici
ALTER procedure [dbo].[tet_rapVanzariTargetMarja] 
--*/
	@Data_doc_de_la datetime=null,@Data_doc_pana_la datetime=null
	,@Loc_de_munca nvarchar(4000)=null,@Tert nvarchar(4000)=null,@Grupa_articole nvarchar(4000)=null,@Cod_articol nvarchar(4000)=null
	,@Doar_pachete bit=null,@Echipa nvarchar(4000)=null,@Grupa_terti nvarchar(4000)=null

--/* si comenteaza aici
select @Data_doc_de_la='2012-01-01 00:00:00',@Data_doc_pana_la='2013-06-30 00:00:00'
	,@Loc_de_munca=null,@Tert=NULL,@Grupa_articole=null,@Cod_articol=NULL,@Doar_pachete=0,@Echipa=null
--*/as

set transaction isolation level read uncommitted
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
	select c.Subunitate, c.data, c.Cod, p.Gestiune_primitoare, p.Cod_intrare_primitor
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

if OBJECT_ID('tempdb..#pozdoc') is not null drop table #pozdoc

select --*/*
 a.An,a.Luna,a.LunaAlfa,a.Data_lunii,a.Trimestru,a.Saptamana,a.Zi,a.Zi_alfa,a.Data
,Tert=rtrim(t.Tert),Den_tert=RTRIM(t.Denumire),Cod_fiscal_tert=RTRIM(t.Cod_fiscal)
,Agent=RTRIM(i.Loc_munca), Den_agent=RTRIM(ag.Denumire)
,Agent_parinte=RTRIM(ag.Cod_parinte),Echipa=RTRIM(ep.Valoare)
,SM=rtrim(sm.Valoare),MKT=RTRIM(mk.Valoare),Subcontractant=isnull(RTRIM(sc.Valoare),'')
,Grupa_terti=RTRIM(t.Grupa), Den_grupa_terti=RTRIM(gt.Denumire)
,Judet=RTRIM(t.Judet), Den_judet=RTRIM(j.denumire)
,t.Sold_maxim_ca_beneficiar,Termen_livrare=i.sold_ben,Termen_scadenta=i.discount
,Scadenta_contr=bf.Scadenta
,Loc_de_munca_doc=RTRIM(p.Loc_de_munca), Den_loc_de_munca_doc=RTRIM(lm.Denumire)
,Loc_de_munca_parinte_doc=RTRIM(lm.Cod_parinte)
,Articol=RTRIM(p.Cod), Den_articol=RTRIM(n.Denumire)
,Grupa_articol=RTRIM(n.Grupa),Den_grupa_articol=RTRIM(g.Denumire)
,Furnizor=RTRIM(n.Furnizor), Den_furnizor=RTRIM(f.Denumire)
,Note_articol=RTRIM(n.Loc_de_munca)
,Tip_articol=RTRIM(n.tip),Den_tip_articol=dbo.denTipNomenclator(n.tip) 
,Tip_doc=rtrim(p.Tip),Data_doc=p.Data,Numar_doc=RTRIM(p.Numar)
,Factura=rtrim(p.Factura),p.Data_facturii,p.Data_scadentei
,p.Cantitate
,Pret_catalog_doc=p.Pret_valuta
,p.Cantitate*p.Pret_valuta as val_catalog
,Pret_vanzare_doc=p.Pret_vanzare
,round(convert(decimal(17,5),(case when p.Cont_venituri like '707%' then p.cantitate*p.pret_vanzare else 0 end)),@rotunjire) as val_vanzare
,round(convert(decimal(17,5),(case when p.Cont_venituri like '707%' and a.Luna<=MONTH(@Data_doc_pana_la) then p.cantitate*p.pret_vanzare else 0 end)),@rotunjire) as val_vanzare_ian_lc
,round(convert(decimal(17,5),(case when p.Cont_venituri like '707%' and a.Luna=MONTH(@Data_doc_pana_la) then p.cantitate*p.pret_vanzare else 0 end)),@rotunjire) as val_vanzare_lc
,round(convert(decimal(17,5),(case when p.Cont_venituri like '709%' then p.cantitate*p.pret_vanzare else 0 end)),@rotunjire) as val_reducere_comerciala
,round(convert(decimal(17,5),(case when p.Cont_venituri like '709%' and a.Luna<=MONTH(@Data_doc_pana_la) then p.cantitate*p.pret_vanzare else 0 end)),@rotunjire) as val_red_com_ian_lc
,round(convert(decimal(17,5),(case when p.Cont_venituri like '709%' and a.Luna=MONTH(@Data_doc_pana_la) then p.cantitate*p.pret_vanzare else 0 end)),@rotunjire) as val_red_com_lc
,Disc_doc=p.Discount
,p.Cantitate*p.Pret_valuta -p.Cantitate*p.Pret_vanzare as val_disc_doc
,(case when p.Cantitate*p.Pret_vanzare!=0 then  1-round((p.Cantitate*p.Pret_valuta/p.Cantitate*p.Pret_vanzare),2) else 0 end) as procent_disc_doc
,Pret_intrare_doc=isnull(c.pret_intrare,p.Pret_de_stoc)
,isnull(p.cantitate*c.pret_intrare,p.Cantitate*p.Pret_de_stoc) as val_intrare
,(case when a.Luna<=MONTH(@Data_doc_pana_la) then isnull(p.cantitate*c.pret_intrare,p.Cantitate*p.Pret_de_stoc) else 0 end) as val_intrare_ian_lc
,Pret_catalog_curent=pr.Pret_vanzare
,disc_max_grupa=dx.disc_max_grupa
,disc_max_contr=bf.Discount
,target_tert=convert(float,0.00)
,target_sezon=convert(float,0.00)
,target_lc=convert(float,0.00)
,Nr_opp_tert=0, Val_opp_tert=0
,Tip_perioada=(CASE a.Data_lunii WHEN dbo.EOM(@Data_doc_pana_la) THEN 'Curenta' ELSE 'Anterioara' END)
--*/select *
into #pozdoc
from pozdoc p 
	outer apply (select top 1 * from #coduri c
		where c.Subunitate=p.Subunitate and c.Cod=p.Cod and c.Gestiune=p.Gestiune and c.Cod_intrare=p.Cod_intrare
		order by ABS(DATEDIFF(M,c.Data,p.Data)), sign(DATEDIFF(M,c.Data,p.Data)) desc) c
	left join doc d on  p.Data=d.Data and p.Numar=d.Numar and p.Tip=d.Tip
	outer apply (select top 1 cod_produs,um,tip_pret,Pret_vanzare,Pret_cu_amanuntul
				from preturi pr where pr.cod_produs=p.cod and pr.um='1') pr
	left join nomencl n on  n.Cod=p.Cod and n.Cod=p.Cod 
	left join CalStd a on a.Data=p.Data
	left join terti f on f.Subunitate=p.Subunitate and f.Tert=n.Furnizor
	left join grupe g on  n.Grupa=g.Grupa
	left join terti t on t.Subunitate=p.Subunitate and p.Tert=t.Tert
	left join infotert i on i.Subunitate=t.Subunitate and i.Tert=t.Tert and i.Identificator=''
	outer apply (select top 1 cn.Contract_coresp,cn.Scadenta,pc.* from pozcon pc left join con cn on cn.Subunitate=pc.Subunitate and cn.Tip=pc.Tip 
		and cn.Tert=pc.Tert and cn.Contract=pc.Contract and cn.Data=pc.Data
		where pc.Subunitate=p.Subunitate and pc.Tip='BK' and pc.Tert=t.Tert and pc.Contract=p.Contract
			and pc.cod=p.Cod and n.Grupa like RTRIM(pc.Cod)+'%' 
		order by abs(DATEDIFF(D,pc.Data,p.Data)),ABS(pc.Pret-p.Pret_valuta)) bk
	outer apply (select top 1 cn.Scadenta,pc.* from pozcon pc left join con cn on cn.Subunitate=pc.Subunitate and cn.Tip=pc.Tip and cn.Tert=pc.Tert 
			and cn.Contract=pc.Contract and cn.Data=pc.Data 
		where pc.Subunitate=t.Subunitate and pc.Tip='BF' and pc.Tert=t.Tert
			and pc.Mod_de_plata='G' and n.Grupa like RTRIM(pc.Cod)+'%' 
		order by (case pc.Contract when bk.Contract_coresp then 0 else 1 end),pc.Data desc,pc.Contract desc,pc.Cod desc,pc.Discount desc) bf
	OUTER APPLY (select top 1 * from targetag tg where tg.Client=t.tert and YEAR(tg.Data_lunii)=a.An) tg
	left join gterti gt on gt.Grupa=t.Grupa
	left join tet_sezonalitate z on z.An=a.An and z.Luna=a.Luna
	left join judete j on j.cod_judet=t.Judet
	outer apply (select top 1 * from proprietati pr where pr.Tip='TERT' and pr.Cod_proprietate='SM' and pr.Cod=t.Tert and pr.valoare<>'') sm
	outer apply (select top 1 * from proprietati pr where pr.Tip='TERT' and pr.Cod_proprietate='VZ_MKT' and pr.Cod=t.Tert and pr.valoare<>'') mk
	outer apply (select top 1 * from proprietati pr where pr.Tip='TERT' and pr.Cod_proprietate='ECHIPA' and pr.Cod=t.Tert and pr.valoare<>'') ep
	outer apply (select top 1 * from proprietati pr where pr.Tip='TERT' and pr.Cod_proprietate='SUBCONTRACTANT' and pr.Cod=t.Tert and pr.valoare<>'') sc
	outer apply (select top 1 disc_max_grupa=(CASE ISNUMERIC(valoare) when 1 then CONVERT(float,replace(Valoare,',','')) else null end)
				from proprietati where Valoare<>'' and Cod<>'' and tip='GRUPA' and cod_proprietate='DISCMAX' and n.Grupa like RTRIM(Cod)+'%' 
				order by cod desc, Valoare desc) dx
	left join lm on lm.Cod=p.Loc_de_munca
	left join lm ag on ag.Cod=i.Loc_munca
where p.tip in ('AP','AC','AS')
	 and p.data>=@Data_doc_de_la and p.data<=@Data_doc_pana_la
	 and left(p.Cont_venituri,3) in ('707','709')
	--and p.Cantitate!=0
	AND (isnull(@Loc_de_munca,  '') = '' OR p.Loc_de_munca = rtrim(rtrim(@Loc_de_munca)))
	AND (isnull(@tert,  '') = '' OR p.tert = rtrim(rtrim(@tert)))
	--AND (isnull(@grupa,  '') = '' OR n.grupa = rtrim(rtrim(@grupa)))
	AND (isnull(@Cod_articol,  '') = '' OR p.cod = rtrim(rtrim(@Cod_articol)))
	and (@Doar_pachete=0 or n.tip='P')
--union all
create nonclustered index tert on #pozdoc (tert)
----targete
select 
z.An,z.Luna,z.LunaAlfa,z.Data_lunii,z.Trimestru,Saptamana=0,Zi=0,Zi_alfa='',Data=''
,Tert=rtrim(t.Tert),Den_tert=RTRIM(t.Denumire),Cod_fiscal_tert=RTRIM(t.Cod_fiscal)
,Agent=RTRIM(i.Loc_munca), Den_agent=RTRIM(ag.Denumire)
,Agent_parinte=RTRIM(ag.Cod_parinte),Echipa=RTRIM(ep.Valoare)
,SM=rtrim(sm.Valoare),MKT=RTRIM(mk.Valoare),Subcontractant=isnull(RTRIM(sc.Valoare),'')
,Grupa_terti=RTRIM(t.Grupa), Den_grupa_terti=RTRIM(gt.Denumire)
,Judet=RTRIM(t.Judet), Den_judet=RTRIM(j.denumire)
,t.Sold_maxim_ca_beneficiar,Termen_livrare=i.sold_ben,Termen_scadenta=i.discount
,Scadenta_contr=bf.Scadenta

,Loc_de_munca_doc='', Den_loc_de_munca_doc=''
,Loc_de_munca_parinte_doc=''
,Articol='', Den_articol=''
,Grupa_articol='',Den_grupa_articol=''
,Furnizor='', Den_furnizor=''
,Note_articol=''
,Tip_articol='',Den_tip_articol='' 

,Tip_doc='',Data_doc='',Numar_doc=''
,Factura='',Data_facturii='',Data_scadentei=''
,Cantitate=0
,Pret_catalog_doc=0
,0 as val_catalog
,Pret_vanzare_doc=0
,0 as val_vanzare
,0 as val_vanzare_ian_lc
,0 as val_vanzare_lc
,0 as val_reducere_comerciala
,0 as val_red_com_ian_lc
,0 as val_red_com_lc
,Disc_doc=0
,0 as val_disc_doc
,0 as procent_disc_doc
,Pret_intrare_doc=0
,0 as val_intrare
,0 as val_intrare_ian_lc
,Pret_catalog_curent=0
,disc_max_grupa=0
,disc_max_contr=bf.Discount
,target_tert=(case when tg.Data_lunii between dbo.BOM(z.Data_lunii) and dbo.EOM(z.Data_lunii) then tg.Comision_suplimentar else 0 end)
,target_sezon=tg.Comision_suplimentar*z.Procent/100
,target_lc=(case z.Luna when MONTH(@Data_doc_pana_la) then tg.Comision_suplimentar*z.Procent/100 else 0 end)
,Nr_opp_tert=(case when o.Data_lunii between dbo.BOM(z.Data_lunii) and dbo.EOM(z.Data_lunii) then o.Nr_opp else 0 end)
,Val_opp_tert=(case when o.Data_lunii between dbo.BOM(z.Data_lunii) and dbo.EOM(z.Data_lunii) then o.Val_opp else 0 end)
,Tip_perioada=(CASE z.Data_lunii WHEN dbo.EOM(@Data_doc_pana_la) THEN 'Curenta' ELSE 'Anterioara' END)
from tet_sezonalitate z
	left join terti t on z.Data_lunii between dbo.BOY(@Data_doc_pana_la) and dbo.EOM(@Data_doc_pana_la)
	cross APPLY (select top 1 * from targetag tg where tg.Client=t.tert and YEAR(tg.Data_lunii)=z.An) tg
	left join infotert i on i.Subunitate=t.Subunitate and i.Tert=t.Tert and i.Identificator=''
	outer apply (select top 1 cn.Scadenta,pc.* from pozcon pc left join con cn on cn.Subunitate=pc.Subunitate and cn.Tip=pc.Tip and cn.Tert=pc.Tert 
			and cn.Contract=pc.Contract and cn.Data=pc.Data 
		where pc.Subunitate=t.Subunitate and pc.Tip='BF' and pc.Tert=t.Tert
		order by pc.Data desc,pc.Contract desc,pc.Cod desc,pc.Discount desc) bf 
	left join judete j on j.cod_judet=t.Judet
	outer apply (select top 1 * from proprietati pr where pr.Tip='TERT' and pr.Cod_proprietate='SM' and pr.Cod=t.Tert and pr.valoare<>'') sm
	outer apply (select top 1 * from proprietati pr where pr.Tip='TERT' and pr.Cod_proprietate='VZ_MKT' and pr.Cod=t.Tert and pr.valoare<>'') mk
	outer apply (select top 1 * from proprietati pr where pr.Tip='TERT' and pr.Cod_proprietate='ECHIPA' and pr.Cod=t.Tert and pr.valoare<>'') ep
	outer apply (select top 1 * from proprietati pr where pr.Tip='TERT' and pr.Cod_proprietate='SUBCONTRACTANT' and pr.Cod=t.Tert and pr.valoare<>'') sc
	left join gterti gt on gt.Grupa=t.Grupa
	left join lm ag on ag.Cod=i.Loc_munca
	left join tet_oportunitati o on o.Tert=t.Tert
where (t.Grupa not in ('201','202','203','204','300','301') or t.Tert in (select p.tert from #pozdoc p))
	AND (isnull(@Loc_de_munca,  '') = '' OR i.Loc_munca= rtrim(rtrim(@Loc_de_munca)))
	AND (isnull(@tert,  '') = '' OR t.tert = rtrim(rtrim(@tert)))
union all
select * from #pozdoc p 
