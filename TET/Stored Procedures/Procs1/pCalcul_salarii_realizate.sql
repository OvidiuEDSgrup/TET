--***
/**	procedura pentru calcul salarii realizate */
Create procedure pCalcul_salarii_realizate
	@dataJos datetime, @dataSus datetime, @marcaJos char(6), @marcaSus char(6), @lmJos char(9), @lmSus char(9) 
As
Begin try
	declare @CorL_SREAC int
	set @CorL_SREAC=dbo.iauParL('PS','SREAC-L')

--	sterg pozitiile generate dintr-un calcul anterior
	delete net where data between @dataJos and @dataSus and marca between @marcaJos and @marcaSus 
		and loc_de_munca between @lmJos and @lmSus and avans=0 and premiu_la_avans=0
	delete brut from brut
		left outer join personal on personal.Marca=brut.Marca
	where data between @dataJos and @dataSus and brut.Marca between @marcaJos and @marcaSus 
--		and brut.Loc_de_munca between @lmJos and @lmSus
		and personal.Loc_de_munca between @lmJos and @lmSus

--	calculez in tabela temporara salar orar/regim de lucru/ore lucrate - nu se recalculeaza in tabela pontaj din motiv de replicare
	if object_id('tempdb..#salor') is not null drop table #salor
	Create table #salor 
		(Data datetime, Marca char(6), Salar_orar decimal(12,4), Loc_de_munca char(9), Ore_lucrate int, Regim_de_lucru decimal(5,2), Numar_curent int)
	Create Unique Clustered Index Marca_lm_nrc on #salor (Data, Marca, Loc_de_munca, Numar_curent)
	exec pCalcul_salor @dataJos,@dataSus,@marcaJos,@marcaSus,@lmJos,@lmSus 

	if @CorL_SREAC=1
		Exec completez_curscor @dataJos,@dataSus,@marcaJos,@lmJos

--	inserare date calculate in tabela brut
	exec pInsert_brut @dataJos,@dataSus,@marcaJos,@marcaSus,@lmJos,@lmSus

	if object_id('tempdb..#brut_cond') is not null drop table #brut_cond
	Create table #brut_cond (Data datetime,Marca char(6),Loc_de_munca char(9),Venit_conditii float)
	Create Unique Clustered Index Data_marca_lm on #brut_cond (Data,Marca,Loc_de_munca)

--	calcul venit pe conditii normale de munca
	exec pCalcul_venit_conditii_munca @dataJos,@dataSus,@marcaJos,@marcaSus,@lmJos,@lmSus,'N'
	update brut set Venit_cond_normale=b.Venit_conditii
	from #brut_cond b
		left outer join personal p on p.Marca=b.Marca
	where brut.data=@dataSus and brut.marca between @marcaJos and @marcaSus 
		and b.Data=brut.Data and b.Marca=brut.Marca and b.Loc_de_munca=brut.Loc_de_munca
--		and brut.loc_de_munca between @lmJos and @lmSus 
		and p.loc_de_munca between @lmJos and @lmSus 
	delete from #brut_cond

--	calcul venit pe conditii deosebite de munca
	exec pCalcul_venit_conditii_munca @dataJos,@dataSus,@marcaJos,@marcaSus,@lmJos,@lmSus,'D'
	update brut set Venit_cond_deosebite=b.Venit_conditii
	from #brut_cond b
		left outer join personal p on p.Marca=b.Marca
	where brut.data=@dataSus and brut.marca between @marcaJos and @marcaSus 
		and b.Data=brut.Data and b.Marca=brut.Marca and b.Loc_de_munca=brut.Loc_de_munca
--		and brut.loc_de_munca between @lmJos and @lmSus 
		and p.loc_de_munca between @lmJos and @lmSus 
	delete from #brut_cond

--	calcul venit pe conditii speciale de munca
	exec pCalcul_venit_conditii_munca @dataJos,@dataSus,@marcaJos,@marcaSus,@lmJos,@lmSus,'S'
	update brut set Venit_cond_speciale=b.Venit_conditii
	from #brut_cond b
		left outer join personal p on p.Marca=b.Marca
	where brut.data=@dataSus and brut.marca between @marcaJos and @marcaSus 
		and b.Data=brut.Data and b.Marca=brut.Marca and b.Loc_de_munca=brut.Loc_de_munca
--		and brut.loc_de_munca between @lmJos and @lmSus 
		and p.loc_de_munca between @lmJos and @lmSus 
	delete from #brut_cond

--	exec pCalcul_regim_normal @dataJos,@dataSus,@marcaJos,@marcaSus,@lmJos,@lmSus
	exec pRecalcul_sporuri @dataJos,@dataSus,@marcaJos,@marcaSus,@lmJos,@lmSus
	exec pRecalcul_salarii_specifice @dataJos,@dataSus,@marcaJos,@marcaSus,@lmJos,@lmSus

	if object_id('tempdb..#salor') is not null drop table #salor
	if object_id('tempdb..#brut_cond') is not null drop table #brut_cond
End try

Begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura pCalcul_salarii_realizate (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
End catch
