--***
Create procedure rapAnchetaSalarii3 
	(@dataJos datetime, @dataSus datetime, @judet varchar(20)=null, @setlm varchar(20)=null, @marca varchar(6)=null)
as
declare @eroare varchar(2000)
begin try
	set transaction isolation level read uncommitted
	if object_id('tempdb..#s3') is not null drop table #s3
	if object_id('tempdb..#nrsalzi') is not null drop table #nrsalzi
	if object_id('tempdb..#brutMarca') is not null drop table #brutMarca
	if object_id('tempdb..#tichete') is not null drop table #tichete

	declare @q_dataJos datetime, @q_dataSus datetime, @zile_cal float, @utilizator varchar(20), @lista_lm int

	select @q_dataJos=dbo.BOM(@dataJos), @q_dataSus=dbo.EOM(@dataSus)	-- se va genera raportul pe luni intregi
	set @zile_cal = datediff(day,@q_dataJos,@q_dataSus)+1
	
	set @utilizator = dbo.fIaUtilizator(null)	-- pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)
	set @lista_lm=dbo.f_areLMFiltru(@utilizator)

	select data, marca, valoare_tichete into #tichete from fDecl205Tichete (@dataJos, @dataSus) 

	select p.sex, count(distinct i.marca) nr_salariati_la_zi_sex
	into #nrsalzi
	from istPers i 
		left outer join personal p on p.Marca=i.Marca
		left outer join judete j on j.denumire=i.judet
	where i.Data=@q_dataSus and (@marca is null or i.Marca=@marca)
		and (@judet is null or i.Judet=@judet or j.cod_judet=@judet)
		and (@lista_lm=0 or exists (select 1 from lmfiltrare l where l.utilizator=@utilizator and l.cod=i.loc_de_munca))
		and (@setlm is null or exists (select 1 from proprietati p where p.Cod_proprietate='TIPBALANTA' and p.Tip='LM' and valoare=@setlm and rtrim(i.Loc_de_munca) like rtrim(p.cod)+'%'))
		and (i.Grupa_de_munca in ('N','D','S') or i.Grupa_de_munca='C' and i.Tip_colab='' or i.Grupa_de_munca='P' and i.Tip_colab in ('AS2','AS7'))
	group by Sex 

	select b.data, b.marca, sum(venit_total) as venit_total, sum(ore_lucrate_regim_normal) as ore_lucrate, 
		sum(Ore_suplimentare_1+Ore_suplimentare_2+Ore_suplimentare_3+Ore_suplimentare_4) as ore_suplimentare, 
		sum(ore_concediu_de_odihna+ore_intrerupere_tehnologica+ore_obligatii_cetatenesti+Ore_concediu_medical) as ore_nelucrate, 
		sum(Ind_concediu_de_odihna+Ind_intrerupere_tehnologica+Ind_obligatii_cetatenesti+Ind_invoiri) as sume_timp_nelucrat,
		sum(Ind_c_medical_unitate) as cm_unitate, SUM(Ind_c_medical_CAS) as cm_fnuass, sum(Spor_cond_9) as cm_faambp,
		sum(premiu) as premiu, max((case when Spor_cond_10=0 then 8 else Spor_cond_10 end)) as regim_de_lucru 
	into #brutMarca
	from brut b
		left outer join istpers i on i.marca=b.marca and i.data=b.data
		left outer join judete j on j.denumire=i.judet
	where b.Data between @q_dataJos and @q_datasus 
		and (@marca is null or b.Marca=@marca)
		and (@lista_lm=0 or exists (select 1 from lmfiltrare l where l.utilizator=@utilizator and l.cod=i.loc_de_munca))
		and (@setlm is null or exists (select 1 from proprietati p where p.Cod_proprietate='TIPBALANTA' and p.Tip='LM' and valoare=@setlm and rtrim(i.Loc_de_munca) like rtrim(p.cod)+'%'))
		and (@judet is null or i.Judet=@judet or j.cod_judet=@judet)
	group by b.data, b.marca
	
	select (case when convert(char(1),p.Sex)='1' then 'M' else 'F' end) as Sex,
--	numar salariati la data de final a raportului
	max(nr.nr_salariati_la_zi_sex) as numar_salariati_la_zi,
--	numar mediu si timp lucrat
	round(sum(o.ore*(case when i.Grupa_de_munca='C' then 8/b.regim_de_lucru else 1 end))/@zile_cal,1) as nr_mediu, 
	round(sum((case when i.Grupa_de_munca in ('N','D','S') then o.ore else 0 end))/@zile_cal,1) as nr_mediu_timp_complet, 
	round(sum((case when i.Grupa_de_munca='C' then o.ore*8/b.regim_de_lucru else 0 end))/@zile_cal,1) as nr_mediu_timp_partial, 
	round(sum(o.ore)/@zile_cal,1) as nr_mediu_echiv_timp_complet,
	sum(case when i.Grupa_de_munca in ('N','D','S') then b.ore_lucrate+b.ore_suplimentare else 0 end) as ore_lucr_timp_complet,
	sum(case when i.Grupa_de_munca='C' then b.ore_lucrate+b.ore_suplimentare else 0 end) as ore_lucr_timp_partial,
	sum(case when i.Grupa_de_munca in ('N','D','S') then b.Ore_nelucrate else 0 end) as ore_nelucr_timp_complet,
	sum(case when i.Grupa_de_munca='C' then b.Ore_nelucrate else 0 end) as ore_nelucr_timp_partial,
--	sume brute platite
	sum(b.VENIT_TOTAL-round((b.sume_timp_nelucrat),0)-(b.cm_unitate+b.cm_fnuass+b.cm_faambp)) as sume_timp_lucrat,
	sum(b.Premiu) as premii, sum(b.Premiu) as premii_ocazionale,
	sum(b.cm_unitate+round(b.sume_timp_nelucrat,0)) as sume_timp_nelucrat,
	sum(b.cm_unitate) as cm_unitate, sum(b.cm_fnuass+b.cm_faambp) as cm_fnuass, sum(b.cm_faambp) as cm_faambp, 
	0 as drepturi_in_natura, 0 as sume_anterioare, 0 as sume_din_profit_net, sum(isnull(t.Valoare_tichete,0)) as sume_alte_fonduri,
	sum(n.Somaj_1) as somaj, sum(n.Pensie_suplimentara_3) as cas, sum(n.Asig_sanatate_din_net) as cass, sum(n.Impozit) as impozit
	into #s3
	from #brutMarca b
		left outer join istpers i on i.marca=b.marca and i.data=b.data
		left outer join net n on n.marca=b.marca and n.data=b.data
		left outer join personal p on b.marca=p.marca6
		left outer join fOreNumarMediuSalariati (@q_dataJos, @q_dataSus, '', '', 'zzz', '', @judet, null) o on o.Data=b.Data and o.Marca=b.Marca
		left outer join #nrsalzi nr on nr.sex=p.Sex
		left outer join #tichete t on t.marca=b.marca and t.data=b.data
	group by convert(char(1),p.Sex) 

--	scos rollup pentru ca merge doar pe compatilitate 100
/*
	select 'Tot. unit.' as activitate, '00' as cod_caen, (case when GROUPING(s.Sex)=1 then 'Total salariati' else 'Feminin' end) as categorie, 
		sum(numar_salariati_la_zi) as numar_salariati_la_zi, sum(nr_mediu) as nr_mediu, 
		sum(nr_mediu_timp_complet) as nr_mediu_timp_complet, sum(nr_mediu_timp_partial) as nr_mediu_timp_partial, sum(nr_mediu_echiv_timp_complet) as nr_mediu_echiv_timp_complet,
		sum(ore_lucr_timp_complet) as ore_lucr_timp_complet, sum(ore_lucr_timp_partial) as ore_lucr_timp_partial, 
		sum(ore_nelucr_timp_complet) as ore_nelucr_timp_complet, sum(ore_nelucr_timp_partial) as ore_nelucr_timp_partial, 
		sum(sume_timp_lucrat) as sume_timp_lucrat, sum(premii) as premii, sum(premii_ocazionale) as premii_ocazionale, 
		sum(sume_timp_nelucrat) as sume_timp_nelucrat, sum(cm_unitate) as cm_unitate, sum(cm_fnuass) as cm_fnuass, sum(cm_faambp) as cm_faambp, 
		sum(drepturi_in_natura) as drepturi_in_natura, sum(sume_anterioare) as sume_anterioare, sum(sume_din_profit_net) as sume_din_profit_net, sum(sume_alte_fonduri) as sume_alte_fonduri,
		sum(somaj) as somaj, sum(cas) as cas, sum(cass) as cass, sum(impozit) as impozit
	from #s3 s
	GROUP BY rollup(Sex)
	having Sex is null or Sex='F'
	order by GROUPING(Sex) desc
*/	
	select 'Tot. unit.' as activitate, '00' as cod_caen, 'Total salariati' as categorie, 
		sum(numar_salariati_la_zi) as numar_salariati_la_zi, sum(nr_mediu) as nr_mediu, 
		sum(nr_mediu_timp_complet) as nr_mediu_timp_complet, sum(nr_mediu_timp_partial) as nr_mediu_timp_partial, sum(nr_mediu_echiv_timp_complet) as nr_mediu_echiv_timp_complet,
		sum(ore_lucr_timp_complet) as ore_lucr_timp_complet, sum(ore_lucr_timp_partial) as ore_lucr_timp_partial, 
		sum(ore_nelucr_timp_complet) as ore_nelucr_timp_complet, sum(ore_nelucr_timp_partial) as ore_nelucr_timp_partial, 
		sum(sume_timp_lucrat) as sume_timp_lucrat, sum(premii) as premii, sum(premii_ocazionale) as premii_ocazionale, 
		sum(sume_timp_nelucrat) as sume_timp_nelucrat, sum(cm_unitate) as cm_unitate, sum(cm_fnuass) as cm_fnuass, sum(cm_faambp) as cm_faambp, 
		sum(drepturi_in_natura) as drepturi_in_natura, sum(sume_anterioare) as sume_anterioare, sum(sume_din_profit_net) as sume_din_profit_net, sum(sume_alte_fonduri) as sume_alte_fonduri,
		sum(somaj) as somaj, sum(cas) as cas, sum(cass) as cass, sum(impozit) as impozit
	from #s3 s
	union all
		select 'Tot. unit.' as activitate, '00' as cod_caen, 'Feminin' as categorie, 
		sum(numar_salariati_la_zi) as numar_salariati_la_zi, sum(nr_mediu) as nr_mediu, 
		sum(nr_mediu_timp_complet) as nr_mediu_timp_complet, sum(nr_mediu_timp_partial) as nr_mediu_timp_partial, sum(nr_mediu_echiv_timp_complet) as nr_mediu_echiv_timp_complet,
		sum(ore_lucr_timp_complet) as ore_lucr_timp_complet, sum(ore_lucr_timp_partial) as ore_lucr_timp_partial, 
		sum(ore_nelucr_timp_complet) as ore_nelucr_timp_complet, sum(ore_nelucr_timp_partial) as ore_nelucr_timp_partial, 
		sum(sume_timp_lucrat) as sume_timp_lucrat, sum(premii) as premii, sum(premii_ocazionale) as premii_ocazionale, 
		sum(sume_timp_nelucrat) as sume_timp_nelucrat, sum(cm_unitate) as cm_unitate, sum(cm_fnuass) as cm_fnuass, sum(cm_faambp) as cm_faambp, 
		sum(drepturi_in_natura) as drepturi_in_natura, sum(sume_anterioare) as sume_anterioare, sum(sume_din_profit_net) as sume_din_profit_net, sum(sume_alte_fonduri) as sume_alte_fonduri,
		sum(somaj) as somaj, sum(cas) as cas, sum(cass) as cass, sum(impozit) as impozit
	from #s3 s
	where Sex='F'
end try

begin catch
	set @eroare='Procedura rapAnchetaSalarii3 (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch

if object_id('tempdb..#s3') is not null drop table #s3
if object_id('tempdb..#nrsalzi') is not null drop table #nrsalzi
if object_id('tempdb..#brutMarca') is not null drop table #brutMarca
if object_id('tempdb..#tichete') is not null drop table #tichete

/*
	exec rapAnchetaSalarii3 '03/01/2012', '03/31/2012', null, '108'
	exec rapAnchetaSalarii3 '01/01/2012', '12/31/2012', null, null
	
	select * from fCalcul_cnph ('01/01/2012', '02/29/2012', '', '', 'zzz', '', null)
	select * from fCalcul_cnph ('01/01/2012', '01/31/2012', '', '', 'zzz', '', null)
	select * from fCalcul_cnph ('02/01/2012', '02/29/2012', '', '', 'zzz', '', null)
	select * from fCalcul_cnph ('03/01/2012', '03/31/2012', '', '', 'zzz', '', null)
	select * from fCalcul_cnph ('04/01/2012', '04/30/2012', '', '', 'zzz', '', null)
	select * from fCalcul_cnph ('05/01/2012', '05/31/2012', '', '', 'zzz', '', null)
	select * from fCalcul_cnph ('01/01/2012', '05/31/2012', '', '', 'zzz', '', null)
*/
