declare @datai datetime,@dataf datetime
select @datai='2016-01-01 00:00:00',@dataf='2016-05-11 00:00:00'

--V_DISC      V_Marja_Tot_MB---------am adaugat pe 28 nov 2013, disc_contract,disc_max....
--/*TEO
;WITH Script_DC AS ( --TEO*/
	select p.Subunitate,p.Tip,p.Data,p.Numar,p.Tert,p.Factura,
		LTRIM(RTRIM(t.denumire)) as client,t.Judet,
		LTRIM(RTRIM(lm.denumire)) as agent_doc,

		(SELECT TOP 1 rtrim(l.Cod_parinte) FROM lm AS l WHERE (p.Loc_de_munca = Cod)) AS locm_doc_parinte ,
		LTRIM(RTRIM(it.loc_munca)) loc_munca_tert,
		(select ltrim(rtrim(lm.Cod_parinte)) from lm lm where  it.Loc_munca=lm.Cod ) locm_tert_parinte,
		(select LTRIM(RTRIM(lm.Denumire)) from lm lm where  it.Loc_munca=lm.Cod ) AGV_tert,
		LTRIM(RTRIM(p.Cod)) as articol,
		LTRIM(RTRIM(n.Denumire)) as denumire,
		sum(p.Cantitate) as cantitate,
		sum(p.Cantitate*p.Pret_vanzare) as valVanzare,
		---val intr
		isnull(
		(select SUM(cm.cantitate*cm.Pret_de_stoc) 
		from pozdoc cm
			left join pozdoc pp on pp.Subunitate=cm.Subunitate and pp.Data=cm.Data and pp.Numar=cm.Numar and pp.Tip='PP'
			left join pozdoc t on t.Subunitate=pp.Subunitate and t.Gestiune=pp.Gestiune and t.Cod=pp.Cod and t.Cod_intrare=pp.Cod_intrare and t.Tip='TE'
			left join pozdoc c on c.Subunitate=t.Subunitate and c.Tip=t.Tip and c.Gestiune=t.Gestiune_primitoare and c.Cod=t.Cod and c.Cod_intrare=t.Grupa
		where cm.Tip='CM' and pp.cod=p.Cod 
			and p.Gestiune=coalesce(c.gestiune_primitoare,t.gestiune_primitoare,pp.gestiune) 
			and p.Cod_intrare=coalesce(c.grupa,t.grupa,pp.cod_intrare))
			,sum(p.Cantitate*p.Pret_de_stoc)) as valIntrare,
		null red_com,  ---camp ce se completeaza ulterior	
		---marja
		round(sum(p.Cantitate*p.Pret_vanzare)-   --valVanzare
		isnull((select SUM(cm.cantitate*cm.Pret_de_stoc) 
				from pozdoc cm
				left join pozdoc pp on pp.Subunitate=cm.Subunitate and pp.Data=cm.Data and pp.Numar=cm.Numar and pp.Tip='PP'
				left join pozdoc t on t.Subunitate=pp.Subunitate and t.Gestiune=pp.Gestiune and t.Cod=pp.Cod and t.Cod_intrare=pp.Cod_intrare and t.Tip='TE'
				left join pozdoc c on c.Subunitate=t.Subunitate and c.Tip=t.Tip and c.Gestiune=t.Gestiune_primitoare and c.Cod=t.Cod and c.Cod_intrare=t.Grupa
				where cm.Tip='CM' and pp.cod=p.Cod 
				and p.Gestiune=coalesce(c.gestiune_primitoare,t.gestiune_primitoare,pp.gestiune) 
				and p.Cod_intrare=coalesce(c.grupa,t.grupa,pp.cod_intrare)),sum(p.Cantitate*p.Pret_de_stoc)),2) marja , null as 'proc_marja'    ------marja=valVanzare-valIntrare
			,sum(p.Cantitate*pr.Pret_vanzare) as valCatalog,
			round(sum(p.Cantitate*pr.Pret_vanzare -p.Cantitate*p.Pret_vanzare),2) as discount, null as 'proc_disc'   --
		,LTRIM(RTRIM(n.grupa)) grupa_art,ltrim(rtrim(g.Denumire)) as den_grupa_art,year(p.Data) an , MONTH(p.data) luna,DAY(p.data) zi
		,(select top 1 t1.Sold_maxim_ca_beneficiar from terti t1 where p.Tert=t1.Tert) limita_credit
		,(select top 1 it.Discount from infotert it where it.Identificator not in ('1') and  p.Tert=it.Tert) Termen_plata
		,(select top 1 tg.Comision_suplimentar from targetag tg where p.Tert=tg.Client) target_val
		,(select top 1 LTRIM(RTRIM(t.Grupa)) from terti t where p.Tert=t.Tert) grupa_tert  
		,(select top 1 LTRIM(RTRIM(g.Denumire)) from gterti g where (select t.Grupa from terti t where p.Tert=t.Tert)=g.Grupa ) den_grupa_terti 
		,round(p.Pret_de_stoc,2) pret_de_stoc,round(p.Pret_vanzare,2)pret_vanzare
		,p.Discount discount_fact
		,p.Pret_valuta pret_cat_la_vanz
		,(SELECT TOP 1 Pret_vanzare FROM preturi AS p WHERE (n.Cod = Cod_produs) AND (UM = '1')) AS pret_catalog_actual 
		,convert(decimal,pt.valoare) disc_max
		,convert(decimal,pc.Discount) disc_contr
		 , p.Cod_intrare serie_cod_intrare   
		 ,(SELECT TOP 1 rtrim(Valoare)  FROM proprietati AS pt WHERE (Tip = 'TERT') AND (Cod_proprietate = 'SUBCONTRACTANT') AND
							 ((SELECT TOP 1 Tert FROM terti AS t WHERE (p.Tert = Tert)) = RTRIM(Cod))) AS subcontractant
		,p.contract com_liv

		,(select c.data from con c where p.Contract=c.Contract ) data_comliv
		,p.lot 	
	 from pozdoc p left join doc d on  p.Data=d.Data and p.Numar=d.Numar and p.Tip=d.Tip
	  left join (select cod_produs,um,max(tip_pret) as tip_pret,MAX(Pret_vanzare) as Pret_vanzare,MAX(Pret_cu_amanuntul) as Pret_cu_amanuntul 
					from preturi group by cod_produs,um) pr on  pr.cod_produs=p.cod and pr.um=d.discount_suma
	  left join nomencl n on  n.Cod=p.Cod and n.Cod=p.Cod 
	  left join grupe g on  n.Grupa=g.Grupa
	  left join lm on  lm.Cod=p.Loc_de_munca
	  left join  terti t on  p.Tert=t.Tert
	  left join infotert it on it.Subunitate=t.Subunitate and t.tert=it.tert and it.Identificator=''
	  left join proprietati pt on  n.Grupa=g.grupa and  g.grupa=pt.Cod   and pt.Tip='GRUPA' and pt.Cod_proprietate='DISCMAX'
	  left join pozcon pc on p.Tert=pc.Tert and n.grupa=pc.Cod 
	where  (p.Tip IN ('AC', 'AP')) AND (p.Jurnal <> 'MFX')  and left(p.Cont_venituri,3) in ('707','709')
	AND (p.Data BETWEEN @datai AND @dataf)
	     
	group by p.Subunitate,p.Loc_de_munca,lm.Denumire,p.Tert,t.Denumire,p.Pret_de_stoc,p.Pret_vanzare,n.Grupa,g.Denumire,p.Gestiune,p.Cod,n.Denumire,p.Cod_intrare,n.Tip,t.Judet,
			 p.Numar,p.Factura,p.tip,p.Data ,it.loc_munca,p.Pret_valuta, p.Discount,n.cod,pt.Valoare,pc.Discount
	,p.contract,p.lot
	having SUM(p.cantitate)!=0
 --/*TEO
	)
 SELECT dc.*,
	are_comision=
	(case when 
		(case when rs.valuta='' then round(convert(decimal(18,5),rs.cantitate*round(rs.pret_valuta*(1+
			(case when abs(rs.discount+rs.cota_TVA*100.00/(rs.cota_TVA+100.00))<0.01 then convert(decimal(12,4),-rs.cota_TVA*100.00/(rs.cota_TVA+100.00)) 
			else convert(decimal(12,4),rs.discount) end)/100),5)),2) when rs.tip='RP' then rs.cantitate*rs.pret_valuta else 
			round(convert(decimal(18,5),rs.cantitate*round(convert(decimal(18,5),rs.pret_valuta*rs.curs*(case when rs.numar_dvi='' or rs.tip='RS' then 
			(1+convert(decimal(18,5),rs.discount/100)) else 1 end)),5)),2) end)
		+(case when not ((rs.numar_DVI<>'' and rs.tip='RM') or ((rs.numar_DVI='' and rs.tip='RM' or rs.tip in ('RP','RS')) and rs.procent_vama = 1)) then rs.tva_deductibil else 0 end)
		>=0.01 
	then 'Da' else 'Nu' end),
	tip_doc_comision=rs.tip, data_doc_comision=rs.Data, nr_doc_comision=rs.Numar,
	fact_comision=rs.Factura, data_fact_comision=rs.Data_facturii, intermediar=i.Tert, den_intermediar=i.Denumire,	
	este_achitat_fact_vanzare=(case when pp.achitat>=0.01 then 'Da' else 'Nu' end)
FROM Script_DC AS dc
  left join yso_LegComisionVanzari cv on cv.subDoc = dc.Subunitate and cv.tipDoc = dc.Tip and cv.dataDoc = dc.Data and cv.nrDoc = dc.Numar
  left join pozdoc rs on rs.idPozDoc = cv.idPozDoc left join terti i on i.Subunitate=rs.Subunitate and i.Tert=rs.Tert
  left join (select pp.subunitate,pp.tert,pp.factura, --pp.plata_incasare,pp.numar,pp.data,		
		achitat=SUM((CASE WHEN e.Nr_efect is not null THEN 0 ELSE 1 END)*(case when pp.plata_incasare in ('PS','IS') then -1 else 1 end)*(pp.suma-suma_dif)), 		
		achitat_valuta=SUM((CASE WHEN e.Nr_efect is not null THEN 0 ELSE 1 END)*(case when pp.valuta='' then 0 when plata_incasare in ('PS','IS') then -1 else 1 end)*achit_fact)
	from pozplin pp left join conturi c on pp.cont=c.cont and c.sold_credit='8'
			left join efecte e on e.subunitate='1' and pp.tert=e.tert and pp.efect=e.nr_efect and e.tip='I'
				and (/*e.data_decontarii<@dataf and*/ abs(e.sold)>0.01 /*or e.data_decontarii>@dataf*/ or e.Valoare=0)		
	where pp.subunitate='1' and pp.plata_incasare in ('IB','IR','PS')
		/*and pp.data between @datai and @dataf and pp.tert=p.Tert and pp.factura=p.Factura */
	GROUP BY pp.subunitate,pp.tert,pp.factura
	) pp ON pp.subunitate=dc.subunitate and pp.Tert=dc.Tert and pp.Factura=dc.Factura
 --TEO*/