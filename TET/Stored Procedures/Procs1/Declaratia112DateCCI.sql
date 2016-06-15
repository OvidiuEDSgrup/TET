--***
Create procedure Declaratia112DateCCI
	(@dataJos datetime, @dataSus datetime, @Marca char(6)=null, @Alfabetic int, @Lm char(9), @Strict int, @SirMarci char(200)=null, @CasaSan char(20)=null, @TipD int)
as
begin
	declare @utilizator varchar(20), @lista_lm int, @Somesana int, @Pasmatex int, @CodJudetSan char(2)

	set @utilizator = dbo.fIaUtilizator(null)
	set @lista_lm=dbo.f_areLMFiltru(@utilizator)

	set @Somesana=dbo.iauParL('SP','SOMESANA')
	set @Pasmatex=dbo.iauParL('SP','PASMATEX')
	set @CodJudetSan=dbo.iauParA('PS','CODJUDETA')

	if object_id('tempdb..#stagiu') is not null drop table #stagiu

--	pun intr-o tabela temporara stagiu de cotizare (nu merge citirea din stagiu_cm in scriptul de insert facut cu group by
	select a.data, a.marca, a.data_inceput, 
	isnull((select Baza_Stagiu from dbo.stagiu_cm (a.Data, a.Marca, a.Data_inceput, dbo.data_inceput_cm(a.Data, a.marca, a.Data_inceput, 1), 
		(case when a.Zile_luna_anterioara>0 or e.Serie_certificat_cm_initial<>'' then 1 else 0 end), 6)),0) as baza_stagiu, 
	isnull((select Zile_Stagiu from dbo.stagiu_cm (a.Data, a.Marca, a.Data_inceput, dbo.data_inceput_cm(a.Data, a.marca, a.Data_inceput, 1), 
		(case when a.Zile_luna_anterioara>0 or e.Serie_certificat_cm_initial<>'' then 1 else 0 end), 6)),0) as zile_stagiu
	into #stagiu
	from #conmed a
		left outer join infoconmed e on e.marca=a.marca and e.data=a.data and e.data_inceput=a.data_inceput
	where a.data_inceput between @dataJos and @dataSus 

	select @TipD as TipD, (case when @TipD=1 then 'M' else '' end)  as Tip_rectificare, a.Data, max(a.Marca) as marca, max(a.Tip_diagnostic) as Tip_diagnostic, 
		a.Data_inceput, max(a.Data_sfarsit) as Data_sfarsit, max(a.Zile_luna_anterioara) as Zile_luna_anterioara, 
		max(p.Nume) as Nume_asig, p.Cod_numeric_personal as CNP, max(e.Cnp_copil) as CNP_copil,
		max((case when 1=0 then rtrim(@CodJudetSan) when SUBSTRING(ADRESA,CHARINDEX(',',ADRESA)+1,2)<>'' then SUBSTRING(ADRESA,CHARINDEX(',',ADRESA)+1,2) else p.adresa end)) as CAS_Asig, 
		isnull(max(round((bm.ore_lucrate_regim_normal
			+(case when @Somesana=1 and 1=0 then 0 else bm.ORE_CONCEDIU_DE_ODIHNA+(case when @Pasmatex=0 then bm.ORE_INTRERUPERE_TEHNOLOGICA else 0 end)+bm.ORE_OBLIGATII_CETATENESTI end))
			/(case when bm.spor_cond_10=0 then 8 else bm.spor_cond_10 end),2)),0) as Total_zile_lucrate, 
		max(e.Serie_certificat_CM) as Serie_CCM, max(e.Nr_certificat_CM) as Numar_CCM, 
		max(e.Serie_certificat_CM_initial) as Serie_CCM_initial, max(e.Nr_certificat_CM_initial) as Numar_CCM_initial, 
		max((case when e.Data_acordarii='01/01/1901' then a.Data_inceput else e.Data_acordarii end)) as Data_acordarii, 
		max((case when right(a.tip_diagnostic,1)='-' then '0' else '' end)+(case when right(a.tip_diagnostic,1)='-' then left(a.tip_diagnostic,1) else a.tip_diagnostic end)) as Cod_indemnizatie, 
		round(max(a.Zile_cu_reducere*(case when a.Tip_diagnostic='10' then 0.25 else 1 end)),0) as Zile_prestatii_ang, 
		round(max((a.Zile_lucratoare-a.Zile_cu_reducere)*(case when a.Tip_diagnostic='10' then 0.25 else 1 end)),0) as Zile_prestatii_Fnuass, 
		round(max(a.Zile_lucratoare*(case when a.Tip_diagnostic='10' then 0.25 else 1 end)),0) as Zile_prestatii, 
		max(e.Loc_prescriere) as Loc_prescriere, sum(a.Indemnizatie_unitate) as Indemnizatie_ang, sum(a.Indemnizatie_CAS) as Indemnizatie_Fnuass, 
		max(e.Cod_urgenta) as Cod_urgenta, max(e.Cod_boala_grpA) as Cod_boala_grpA, 
--	am facut SUM (in loc de MAX) pe Baza_stagiu pt. cazul in care sunt 2 marci pe acelasi CNP cu concediu medical (trebuie declarat stagiul cumulat)
		SUM(case when a.Indemnizatia_zi=0 and Indemnizatii_calc_manual=1 then 0 else s.baza_stagiu end) as Baza_calcul, 
		MAX(s.zile_stagiu) as Zile_baza_calcul, 
--	am facut max (in loc de SUM) pe media zilnica pt. cazul in care sunt 2 marci pe acelasi CNP cu concediu medical 
--	(in acest isi vor completa cu mana media zilnica tinand cont de stagiul cumulat)
		max(round(a.Indemnizatia_zi,(case when a.data_inceput<'02/01/2011' then 4 else 2 end))) as Media_zilnica, 
		max(e.Nr_aviz_me) as Nr_aviz_me, 0 as P_faambp 
	from #conmed a 
		left outer join personal p on p.marca=a.marca 
		left outer join infoconmed e on e.marca=a.marca and e.data=a.data and e.data_inceput=a.data_inceput
		left outer join #stagiu s on s.marca=a.marca and s.data=a.data and s.data_inceput=a.data_inceput
		left outer join #brutMarca bm on bm.data=a.data and bm.marca=a.marca 
	where (a.tip_diagnostic not in ('2-','3-','4-','0-')) 
		and (@Marca is null or a.Marca=@Marca) and a.Marca=p.Marca and a.data_inceput between @dataJos and @dataSus 
		and (@SirMarci is null or charindex(','+rtrim(ltrim(a.marca))+',',@SirMarci)>0) 
		and (@CasaSan is null or p.adresa=@CasaSan) 
	group by a.Data, a.Data_inceput, p.Cod_numeric_personal
	order by max((case when @Alfabetic=0 then a.Marca else p.Nume  end))

	return
end

/*
	exec Declaratia112DateCCI '11/01/2012', '11/30/2012', null, 0, '', 0, null, null, 0
*/
