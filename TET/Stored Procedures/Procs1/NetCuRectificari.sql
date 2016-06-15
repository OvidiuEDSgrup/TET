/*
	procedura permite obtinerea unei rezultat cu structura tabelei net, unind datele din tabela net si rectificari pe tabela net
*/
Create procedure NetCuRectificari @parXML xml
as
/*
	@locapelare='LR' - > apelare procedura din luna rectificata (inchisa dpdv. contabil) - cea pe care se declara diferentele in D112
	@locapelare='LC' - > apelare procedura din luna curenta - cea pe care se inregistreaza contabil diferentele
*/	
Begin try
	declare @utilizator varchar(20), @lista_lm int, @multiFirma int, @datajos datetime, @datasus datetime, @lunaApelare char(2), @lm varchar(9), @marca varchar(6), 
		@comandaSQL nvarchar(max), @parXMLRectif xml, @ceselectez int, @nc int
/*
	@ceselectez=0 -> se selecteaza atat datele din brut cat si cele ce provin din rectificari
	@ceselectez=1 -> se selecteaza DOAR datele din NET
	@ceselectez=2 -> se selecteaza DOAR datele din rectificari
*/
	set @utilizator = dbo.fIaUtilizator(null)
	set @lista_lm=dbo.f_areLMFiltru(@utilizator)
	set @multiFirma=0
--	daca tabela par este view inseamna ca se lucreaza cu parametrii pe locuri de munca (in aceeasi BD sunt mai multe unitati)	
	if exists (select * from sysobjects where name ='par' and xtype='V')
		set @multiFirma=1
	
	set @datajos = @parXML.value('(/*/@datajos)[1]', 'datetime')
	set @datasus = @parXML.value('(/*/@datasus)[1]', 'datetime')
	set @lunaApelare = @parXML.value('(/*/@lunaApelare)[1]', 'char(2)')
	set @lm = isnull(@parXML.value('(/*/@lm)[1]', 'varchar(9)'),'')
	set @marca = isnull(@parXML.value('(/*/@marca)[1]', 'varchar(6)'),'')
	set @ceselectez = isnull(@parXML.value('(/*/@ceselectez)[1]', 'int'),0)
	set @nc = @parXML.value('(/*/@nc)[1]', 'int')

--	creez tabela temporara #rectificariNet cu structura similara tabelei net in care pun diferentele rezultate din rectificari
	if object_id('tempdb..#rectificariNet') is not null drop table #rectificariNet
	if object_id('tempdb..#tmpnet') is not null drop table #tmpnet
	
	select top 0 Data, Marca, Loc_de_munca, VENIT_TOTAL, CM_incasat, CO_incasat, Suma_incasata, Suma_neimpozabila, Diferenta_impozit, Impozit, Pensie_suplimentara_3, Somaj_1, 
		Asig_sanatate_din_impozit, Asig_sanatate_din_net, Asig_sanatate_din_CAS, VENIT_NET, Avans, Premiu_la_avans, Debite_externe, Rate, Debite_interne, Cont_curent, REST_DE_PLATA, 
		CAS, Somaj_5, Fond_de_risc_1, Camera_de_Munca_1, Asig_sanatate_pl_unitate, Coef_tot_ded, Grad_invalid, Coef_invalid, Alte_surse, VEN_NET_IN_IMP, Ded_baza, Ded_suplim, 
		VENIT_BAZA, Chelt_prof, Baza_CAS, Baza_CAS_cond_norm, Baza_CAS_cond_deoseb, Baza_CAS_cond_spec
	into #rectificariNet from net where data between @datajos and @datasus

	set @parXMLRectif=(select @datajos datajos, @dataSus datasus, @lunaApelare lunaApelare, null marca, @nc nc for xml raw)
	if @ceselectez in (0,2)
		insert into #rectificariNet
		select Data, Marca, Loc_de_munca, VENIT_TOTAL, CM_incasat, CO_incasat, Suma_incasata, Suma_neimpozabila, Diferenta_impozit, Impozit, Pensie_suplimentara_3, Somaj_1, 
			Asig_sanatate_din_impozit, Asig_sanatate_din_net, Asig_sanatate_din_CAS, VENIT_NET, Avans, Premiu_la_avans, Debite_externe, Rate, Debite_interne, Cont_curent, REST_DE_PLATA, 
			CAS, Somaj_5, Fond_de_risc_1, Camera_de_Munca_1, Asig_sanatate_pl_unitate, Coef_tot_ded, Grad_invalid, Coef_invalid, Alte_surse, VEN_NET_IN_IMP, Ded_baza, Ded_suplim, 
			VENIT_BAZA, Chelt_prof, Baza_CAS, Baza_CAS_cond_norm, Baza_CAS_cond_deoseb, Baza_CAS_cond_spec
		from dbo.fRectificariNet (@parXMLRectif) 

	select n.Data as Data, n.Marca as Marca, max(n.Loc_de_munca) as Loc_de_munca, 
		sum(VENIT_TOTAL) as VENIT_TOTAL, sum(CM_incasat) as CM_incasat, sum(CO_incasat) as CO_incasat, sum(Suma_incasata) as Suma_incasata, 
		sum(Suma_neimpozabila) as Suma_neimpozabila, sum(Diferenta_impozit) as Diferenta_impozit, sum(Impozit) as Impozit, sum(Pensie_suplimentara_3) as Pensie_suplimentara_3, 
		sum(Somaj_1) as Somaj_1, sum(Asig_sanatate_din_impozit) as Asig_sanatate_din_impozit, sum(Asig_sanatate_din_net) as Asig_sanatate_din_net, 
		sum(Asig_sanatate_din_CAS) as Asig_sanatate_din_CAS, sum(VENIT_NET) as VENIT_NET, sum(Avans) as Avans, sum(Premiu_la_avans) as Premiu_la_avans, 
		sum(Debite_externe) as Debite_externe, sum(Rate) as Rate, sum(Debite_interne) as Debite_interne, sum(Cont_curent) as Cont_curent, 
		sum(REST_DE_PLATA) as REST_DE_PLATA, sum(CAS) as CAS, sum(Somaj_5) as Somaj_5, sum(Fond_de_risc_1) as Fond_de_risc_1, sum(Camera_de_Munca_1) as Camera_de_Munca_1, 
		sum(Asig_sanatate_pl_unitate) as Asig_sanatate_pl_unitate, 
		max(Coef_tot_ded) as Coef_tot_ded, max(n.Grad_invalid) as Grad_invalid, max(n.Coef_invalid) as Coef_invalid, max(convert(int,n.Alte_surse)) as Alte_surse, 
		sum(VEN_NET_IN_IMP) as VEN_NET_IN_IMP, sum(Ded_baza) as Ded_baza, sum(Ded_suplim) as Ded_suplim, 
		sum(VENIT_BAZA) as VENIT_BAZA, sum(Chelt_prof) as Chelt_prof, sum(Baza_CAS) as Baza_CAS, 
		sum(Baza_CAS_cond_norm) as Baza_CAS_cond_norm, sum(Baza_CAS_cond_deoseb) as Baza_CAS_cond_deoseb, sum(Baza_CAS_cond_spec) as Baza_CAS_cond_spec
	into #tmpnet
	from 
		(select Data, Marca, Loc_de_munca, VENIT_TOTAL, CM_incasat, CO_incasat, Suma_incasata, Suma_neimpozabila, Diferenta_impozit, Impozit, Pensie_suplimentara_3, Somaj_1, 
			Asig_sanatate_din_impozit, Asig_sanatate_din_net, Asig_sanatate_din_CAS, VENIT_NET, Avans, Premiu_la_avans, Debite_externe, Rate, Debite_interne, Cont_curent, REST_DE_PLATA, 
			CAS, Somaj_5, Fond_de_risc_1, Camera_de_Munca_1, Asig_sanatate_pl_unitate, Coef_tot_ded, Grad_invalid, Coef_invalid, Alte_surse, VEN_NET_IN_IMP, Ded_baza, Ded_suplim, 
			VENIT_BAZA, Chelt_prof, Baza_CAS, Baza_CAS_cond_norm, Baza_CAS_cond_deoseb, Baza_CAS_cond_spec 
		from net where data between @datajos and @datasus and @ceselectez in (0,1)
		union all 
		select Data, Marca, Loc_de_munca, VENIT_TOTAL, CM_incasat, CO_incasat, Suma_incasata, Suma_neimpozabila, Diferenta_impozit, Impozit, Pensie_suplimentara_3, Somaj_1, 
			Asig_sanatate_din_impozit, Asig_sanatate_din_net, Asig_sanatate_din_CAS, VENIT_NET, Avans, Premiu_la_avans, Debite_externe, Rate, Debite_interne, Cont_curent, REST_DE_PLATA, 
			CAS, Somaj_5, Fond_de_risc_1, Camera_de_Munca_1, Asig_sanatate_pl_unitate, Coef_tot_ded, Grad_invalid, Coef_invalid, Alte_surse, VEN_NET_IN_IMP, Ded_baza, Ded_suplim, 
			VENIT_BAZA, Chelt_prof, Baza_CAS, Baza_CAS_cond_norm, Baza_CAS_cond_deoseb, Baza_CAS_cond_spec 
		from #rectificariNet) n 
	left outer join istpers i on i.Data=dbo.eom(n.Data) and i.Marca=n.Marca 
	left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=i.loc_de_munca
	where (@lm='' or i.Loc_de_munca like rtrim(@lm)+'%')
		and (@marca='' or n.marca=@marca)
		and (@multiFirma=0 and @nc=1 or @lista_lm=0 or lu.cod is not null) 
	group by n.data, n.marca

	if object_id('tempdb..#net') is not null 
		insert into #net 
		select Data, Marca, Loc_de_munca, VENIT_TOTAL, CM_incasat, CO_incasat, Suma_incasata, Suma_neimpozabila, Diferenta_impozit, Impozit, Pensie_suplimentara_3, Somaj_1, 
			Asig_sanatate_din_impozit, Asig_sanatate_din_net, Asig_sanatate_din_CAS, VENIT_NET, Avans, Premiu_la_avans, Debite_externe, Rate, Debite_interne, Cont_curent, REST_DE_PLATA, 
			CAS, Somaj_5, Fond_de_risc_1, Camera_de_Munca_1, Asig_sanatate_pl_unitate, Coef_tot_ded, Grad_invalid, Coef_invalid, Alte_surse, VEN_NET_IN_IMP, Ded_baza, Ded_suplim, 
			VENIT_BAZA, Chelt_prof, Baza_CAS, Baza_CAS_cond_norm, Baza_CAS_cond_deoseb, Baza_CAS_cond_spec
		from #tmpnet
	else 		
		select Data, Marca, Loc_de_munca, VENIT_TOTAL, CM_incasat, CO_incasat, Suma_incasata, Suma_neimpozabila, Diferenta_impozit, Impozit, Pensie_suplimentara_3, Somaj_1, 
			Asig_sanatate_din_impozit, Asig_sanatate_din_net, Asig_sanatate_din_CAS, VENIT_NET, Avans, Premiu_la_avans, Debite_externe, Rate, Debite_interne, Cont_curent, REST_DE_PLATA, 
			CAS, Somaj_5, Fond_de_risc_1, Camera_de_Munca_1, Asig_sanatate_pl_unitate, Coef_tot_ded, Grad_invalid, Coef_invalid, Alte_surse, VEN_NET_IN_IMP, Ded_baza, Ded_suplim, 
			VENIT_BAZA, Chelt_prof, Baza_CAS, Baza_CAS_cond_norm, Baza_CAS_cond_deoseb, Baza_CAS_cond_spec
		from #tmpnet

	if object_id('tempdb..#rectificariNet') is not null drop table #rectificariNet
	if object_id('tempdb..#tmpnet') is not null drop table #tmpnet
End try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura NetCuRectificari (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch

/*
	declare @parXML xml
	set @parXML='<row datajos="2012-01-31" datasus="2012-12-31" lunaApelare="LC" grupareremarul="0" />'
	exec NetCuRectificari @parXML
*/	
