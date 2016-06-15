--***
/**	procedura ce completeaza/returneaza datele privind concediile medicale grupate pe marca	*/
Create procedure pSume_cm_marca 
	@dataJos datetime, @dataSus datetime, @pMarca char(6)
As
Begin try
	declare @Salar_minim float, @Salar_mediu float
	set @Salar_minim=dbo.iauParLN(@dataSus,'PS','S-MIN-BR')
	set @Salar_mediu=dbo.iauParLN(@dataSus,'PS','SALMBRUT')
	
	if object_id('tempdb..#tmpCMmarca') is not null drop table #tmpCMmarca

	select a.data as data, a.marca, sum(indemnizatie_unitate) as indcm_unit_19, sum(indemnizatie_cas) as indcm_cas_19, 
		max(zile_lucratoare_in_luna*8) as ore_luna_cm, sum(indemnizatie_unitate+indemnizatie_cas) as indcm,
		sum((case when tip_diagnostic<>'0-' then indemnizatie_cas else 0 end)) as indcm_cas_18, 
		round(sum((case when tip_diagnostic<>'0-' and not(tip_diagnostic='2-' or tip_diagnostic='3-' or tip_diagnostic='4-' or 
			(tip_diagnostic='10' or tip_diagnostic='11') and suma=1) and tip_diagnostic<>'15' 
				then round(zile_lucratoare*(case when Tip_diagnostic='10' then 0.25 else 1 end),0) else 0 end)),0) as zcm_18, 
		round(sum((case when tip_diagnostic<>'0-' and not(tip_diagnostic='2-' or tip_diagnostic='3-' or tip_diagnostic='4-' or 
			(tip_diagnostic='10' or tip_diagnostic='11') and suma=1) and tip_diagnostic<>'15' and data_inceput<@dataJos 
				then round(zile_lucratoare*(case when Tip_diagnostic='10' then 0.25 else 1 end),0) else 0 end)),0) as zcm_18_ant, 
		sum((case when tip_diagnostic<>'0-' and not(tip_diagnostic='2-' or tip_diagnostic='3-' or tip_diagnostic='4-' or 
			(tip_diagnostic='10' or tip_diagnostic='11') and suma=1) and data_inceput<@dataJos then 
			round(round(zile_lucratoare*(case when Tip_diagnostic='10' then 0.25 else 1 end),0)*
				(case when data_inceput<@dataJos then isnull(l.val_numerica,@Salar_minim) else @Salar_minim end)/convert(float,zile_lucratoare_in_luna),0) else 0 end)) as baza_casi_ant,
		sum((case when tip_diagnostic<>'0-' and not(tip_diagnostic='2-' or tip_diagnostic='3-' or tip_diagnostic='4-' or 
			(tip_diagnostic='10' or tip_diagnostic='11') and suma=1) and data_inceput<@dataJos 
			then round(round(zile_lucratoare*(case when Tip_diagnostic='10' then 0.25 else 1 end),0)*
				(case when data_inceput<@dataJos then isnull(l.val_numerica,@Salar_minim) else @Salar_minim end)/convert(float,zile_lucratoare_in_luna),0) else 0 end)) as baza_cascm_ant,
		sum((case when tip_diagnostic in ('2-','3-','4-') or tip_diagnostic in ('10','11') and suma=1 then zile_lucratoare else 0 end)) as zcm_2341011, 
		sum((case when tip_diagnostic in ('2-','3-','4-') then (case when a.data>='08/01/2008' then 0 else indemnizatie_unitate end)+indemnizatie_cas else 0 end)) as indcm_234, 
		sum((case when tip_diagnostic in ('2-','3-','4-') then indemnizatie_unitate else 0 end)) as indcm_unit_234, 
		sum((case when tip_diagnostic in ('15') then zile_lucratoare else 0 end)) as zcm15, 
		sum((case when tip_diagnostic in ('8-','9-','15') then zile_lucratoare else 0 end)) as zcm_8915, 
		sum((case when tip_diagnostic in ('8-','9-','15') then indemnizatie_cas else 0 end)) as indcm_8915, 
		sum((case when tip_diagnostic in ('7-','8-') then zile_lucratoare else 0 end)) as zcm_78,
		sum((case when tip_diagnostic in ('7-','8-') then indemnizatie_cas else 0 end)) as indcm_78, 
		sum((case when tip_diagnostic not in ('7-','8-') then indemnizatie_cas else 0 end)) as indcm_somaj, 
		isnull((select count(1) from conmed c where c.data=a.data and c.marca=a.marca and c.tip_diagnostic in ('0-','7-','8-')),0) as ingrijire_copil_sarcina,
		sum((case when tip_diagnostic<>'0-' then Zile_cu_reducere else 0 end)) as zcm_unitate,
		round(sum((case when tip_diagnostic<>'0-' then round((Zile_lucratoare-Zile_cu_reducere)*(case when Tip_diagnostic='10' then 0.25 else 1 end),0) else 0 end)),0) as zcm_fonduri,
		sum((case when isnull(de.Data_inf,'01/01/1901')<a.Data_inceput or isnull(dc.Data_inf,'01/01/1901')>a.Data_sfarsit or tip_diagnostic='0-' then 0 
			else a.Zile_lucratoare end)) as zcm_subv_somaj
	into #tmpCMmarca	
	from conmed a
		left outer join par_lunari l on l.data=dbo.eom(a.data_inceput) and l.tip='PS' and l.parametru='S-MIN-BR'
		left outer join extinfop dc on dc.marca=a.marca and dc.cod_inf='DCONVSOMAJ'
		left outer join extinfop de on de.marca=a.marca and de.cod_inf='DEXPSOMAJ'
	where a.data between @dataJos and @dataSus and (@pMarca='' or a.marca=@pMarca)
	group by a.data, a.marca

	if object_id('tempdb..#Sume_cm_marca') is not null 
		insert into #Sume_cm_marca
		select Data, Marca, indcm_unit_19, indcm_cas_19, ore_luna_cm, indcm, indcm_cas_18, zcm_18, zcm_18_ant, baza_casi_ant, baza_cascm_ant, 
			zcm_2341011, indcm_234, indcm_unit_234, zcm15, zcm_8915, indcm_8915, zcm_78, indcm_78, indcm_somaj, ingrijire_copil_sarcina, 
			zcm_unitate, zcm_fonduri, zcm_subv_somaj
		from #tmpCMmarca
	else
		select Data, Marca, indcm_unit_19, indcm_cas_19, ore_luna_cm, indcm, indcm_cas_18, zcm_18, zcm_18_ant, baza_casi_ant, baza_cascm_ant, 
			zcm_2341011, indcm_234, indcm_unit_234, zcm15, zcm_8915, indcm_8915, zcm_78, indcm_78, indcm_somaj, ingrijire_copil_sarcina, 
			zcm_unitate, zcm_fonduri, zcm_subv_somaj
		from #tmpCMmarca
		
	if object_id('tempdb..#tmpCMmarca') is not null drop table #tmpCMmarca	
End try

Begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura pSume_cm_marca (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
End catch
