
CREATE procedure wOPImportRectificariSalarii @sesiune varchar(50), @parXML XML
as
begin try
	declare @tippreluare int, @data datetime, @datajos datetime, @datasus datetime, 
		@datarectificata datetime, @datarjos datetime, @datarsus datetime, @marca varchar(6), @mesaj varchar(500), 
		@docRectificari xml, @bazaRectificare varchar(100), @bazaCurenta varchar(100), @comandaSQL nvarchar(max)

	set @tippreluare = isnull(@parXML.value('(/*/@tippreluare)[1]', 'int'),0)
	set @data = @parXML.value('(/*/@data)[1]', 'datetime')
	set @datarectificata = @parXML.value('(/*/@datarectificata)[1]', 'datetime')
	set @marca = @parXML.value('(/*/@marca)[1]', 'varchar(6)')
	set @bazaRectificare = @parXML.value('(/*/@bazarectificare)[1]', 'varchar(50)')
	select @bazaCurenta=DB_NAME()

	set @datajos=dbo.BOM(@data)
	set @datasus=dbo.EOM(@data)
	
	set @datarjos=dbo.BOM(@datarectificata)
	set @datarsus=dbo.EOM(@datarectificata)

	if @datarsus>=@data
		raiserror('Luna rectificata nu poate fi mai mare sau egala cu luna de lucru!!',11,1)
	if @bazaRectificare=''
		raiserror('Numele bazei de date in care s-au recalculat salariile este necompletat!!',11,1)
	if @bazaRectificare=@bazaCurenta
		raiserror('Baze de date in care s-au recalculat salariile nu poate sa coincida cu baza de date curenta!!',11,1)

	if @tippreluare=0
	Begin
		if OBJECT_ID('tempdb..#pozdesters') is not null drop table #pozdesters
		select pr.* into #pozdesters
		from PozRectificariSalarii  pr
			inner join AntetRectificariSalarii ar on ar.data=@datasus and (isnull(@marca,'')='' or ar.marca=@marca)
		where pr.data_rectificata=@datarsus
		
		delete pr from PozRectificariSalarii  pr
			inner join AntetRectificariSalarii ar on ar.data=@datasus and (isnull(@marca,'')='' or ar.marca=@marca)
		where pr.data_rectificata=@datarsus

		delete a from AntetRectificariSalarii a
			inner join #pozdesters p on a.idRectificare=p.idRectificare
		where data=@datasus and (isnull(@marca,'')='' or marca=@marca)
		if OBJECT_ID('tempdb..#pozdesters') is not null drop table #pozdesters
	End	
		
	if OBJECT_ID('tempdb..#brutInitial') is not null drop table #brutInitial
	if OBJECT_ID('tempdb..#brutRecalculat') is not null drop table #brutRecalculat
	if OBJECT_ID('tempdb..#netInitial') is not null drop table #netInitial
	if OBJECT_ID('tempdb..#netRecalculat') is not null drop table #netRecalculat
	if OBJECT_ID('tempdb..#net1Initial') is not null drop table #net1Initial
	if OBJECT_ID('tempdb..#net1Recalculat') is not null drop table #net1Recalculat
	if OBJECT_ID('tempdb..#diferente') is not null drop table #diferente
	if OBJECT_ID('tempdb..#rectifAnt') is not null drop table #rectifAnt
	
	create table #brutRecalculat (Data datetime, Marca varchar(6), Loc_de_munca varchar(9), camp varchar(50), suma float)
	create table #netRecalculat (Data datetime, Marca varchar(6), Loc_de_munca varchar(9), camp varchar(50), suma float)
	create table #net1Recalculat (Data datetime, Marca varchar(6), Loc_de_munca varchar(9), camp varchar(50), suma float)

--	pun intr-o tabela temporara eventualele rectificari anterioare (importate deja)
	select a.marca, max(p.loc_de_munca) as loc_de_munca, p.tip_suma, sum(p.suma) as suma
	into #rectifAnt
	from PozRectificariSalarii p
		left outer join AntetRectificariSalarii a on a.idRectificare=p.idRectificare
	where data_rectificata=@datarsus
	group by marca, tip_suma

--	mut datele pe randuri
--	datele din tabela brut din baza in care s-au refacut calculele
	set @comandaSQL=
	'select Data, Marca, Loc_de_munca, camp, suma '+char(13)+'
	from '+char(13)+'
	(select Data, Marca, Loc_de_munca, '+char(13)+'
		convert(float,Total_ore_lucrate) as Total_ore_lucrate, convert(float,Ore_lucrate__regie) as Ore_lucrate__regie, Realizat__regie, '+char(13)+'
		convert(float,Ore_lucrate_acord) as Ore_lucrate_acord, Realizat_acord, '+char(13)+'
		convert(float,Ore_suplimentare_1) as Ore_suplimentare_1, Indemnizatie_ore_supl_1, '+char(13)+'
		convert(float,Ore_suplimentare_2) as Ore_suplimentare_2, Indemnizatie_ore_supl_2, '+char(13)+'
		convert(float,Ore_suplimentare_3) as Ore_suplimentare_3, Indemnizatie_ore_supl_3, '+char(13)+'
		convert(float,Ore_suplimentare_4) as Ore_suplimentare_4, Indemnizatie_ore_supl_4, '+char(13)+'
		convert(float,Ore_spor_100) as Ore_spor_100, Indemnizatie_ore_spor_100, convert(float,Ore_de_noapte) as Ore_de_noapte, Ind_ore_de_noapte, '+char(13)+'
		convert(float,Ore_lucrate_regim_normal) as Ore_lucrate_regim_normal, Ind_regim_normal, '+char(13)+'
		convert(float,Ore_intrerupere_tehnologica) as Ore_intrerupere_tehnologica, Ind_intrerupere_tehnologica, '+char(13)+'
		convert(float,Ore_obligatii_cetatenesti) as Ore_obligatii_cetatenesti, Ind_obligatii_cetatenesti, '+char(13)+'
		convert(float,Ore_concediu_fara_salar) as Ore_concediu_fara_salar, Ind_concediu_fara_salar, '+char(13)+'
		convert(float,Ore_concediu_de_odihna) as Ore_concediu_de_odihna, Ind_concediu_de_odihna, '+char(13)+'
		convert(float,Ore_concediu_medical) as Ore_concediu_medical, Ind_c_medical_unitate, Ind_c_medical_CAS, '+char(13)+'
		convert(float,Ore_invoiri) as Ore_invoiri, Ind_invoiri, '+char(13)+'
		convert(float,Ore_nemotivate) as Ore_nemotivate, Ind_nemotivate, Salar_categoria_lucrarii, '+char(13)+'
		CMCAS, CMunitate, CO, Restituiri, Diminuari, Suma_impozabila, Premiu, Diurna, Cons_admin, Sp_salar_realizat, Suma_imp_separat, Spor_vechime, Spor_de_noapte, '+char(13)+'
		Spor_sistematic_peste_program, Spor_de_functie_suplimentara, Spor_specific, Spor_cond_1, Spor_cond_2, Spor_cond_3, Spor_cond_4, Spor_cond_5, Spor_cond_6, Compensatie, '+char(13)+'
		VENIT_TOTAL, Salar_orar, Venit_cond_normale, Venit_cond_deosebite, Venit_cond_speciale, Spor_cond_7, Spor_cond_8, Spor_cond_9, Spor_cond_10'+char(13)+'
	from '+@bazaRectificare+'..brut '+char(13)+'
	where data='+char(39)+convert(char(10),@datarsus,101)+char(39)+') a '+char(13)+'
		unpivot (suma for camp in '+char(13)+'
			(Total_ore_lucrate, Ore_lucrate__regie, Realizat__regie, Ore_lucrate_acord, Realizat_acord, '+char(13)+'
			Ore_suplimentare_1, Indemnizatie_ore_supl_1, Ore_suplimentare_2, Indemnizatie_ore_supl_2, Ore_suplimentare_3, Indemnizatie_ore_supl_3, Ore_suplimentare_4, Indemnizatie_ore_supl_4, '+char(13)+'
			Ore_spor_100, Indemnizatie_ore_spor_100, Ore_de_noapte, Ind_ore_de_noapte, Ore_lucrate_regim_normal, Ind_regim_normal, Ore_intrerupere_tehnologica, Ind_intrerupere_tehnologica, '+char(13)+'
			Ore_obligatii_cetatenesti, Ind_obligatii_cetatenesti, Ore_concediu_fara_salar, Ind_concediu_fara_salar, Ore_concediu_de_odihna, Ind_concediu_de_odihna, '+char(13)+'
			Ore_concediu_medical, Ind_c_medical_unitate, Ind_c_medical_CAS, Ore_invoiri, Ind_invoiri, Ore_nemotivate, Ind_nemotivate, Salar_categoria_lucrarii, '+char(13)+'
			CMCAS, CMunitate, CO, Restituiri, Diminuari, Suma_impozabila, Premiu, Diurna, Cons_admin, Sp_salar_realizat, Suma_imp_separat, Spor_vechime, Spor_de_noapte, '+char(13)+'
			Spor_sistematic_peste_program, Spor_de_functie_suplimentara, Spor_specific, Spor_cond_1, Spor_cond_2, Spor_cond_3, Spor_cond_4, Spor_cond_5, Spor_cond_6, '+char(13)+'
			Compensatie, VENIT_TOTAL, Salar_orar, Venit_cond_normale, Venit_cond_deosebite, Venit_cond_speciale, Spor_cond_7, Spor_cond_8, Spor_cond_9, Spor_cond_10)) b'
	
	insert into #brutRecalculat
	exec (@comandaSQL)

--	datele din baza de date curenta cea in care sunt datele in forma initiala
	select Data, Marca, Loc_de_munca, camp, suma
	into #brutInitial
	from
	(select Data, Marca, Loc_de_munca, 
		convert(float,Total_ore_lucrate) as Total_ore_lucrate, convert(float,Ore_lucrate__regie) as Ore_lucrate__regie, Realizat__regie, 
		convert(float,Ore_lucrate_acord) as Ore_lucrate_acord, Realizat_acord, 
		convert(float,Ore_suplimentare_1) as Ore_suplimentare_1, Indemnizatie_ore_supl_1, 
		convert(float,Ore_suplimentare_2) as Ore_suplimentare_2, Indemnizatie_ore_supl_2, 
		convert(float,Ore_suplimentare_3) as Ore_suplimentare_3, Indemnizatie_ore_supl_3, 
		convert(float,Ore_suplimentare_4) as Ore_suplimentare_4, Indemnizatie_ore_supl_4, 
		convert(float,Ore_spor_100) as Ore_spor_100, Indemnizatie_ore_spor_100, convert(float,Ore_de_noapte) as Ore_de_noapte, Ind_ore_de_noapte, 
		convert(float,Ore_lucrate_regim_normal) as Ore_lucrate_regim_normal, Ind_regim_normal, 
		convert(float,Ore_intrerupere_tehnologica) as Ore_intrerupere_tehnologica, Ind_intrerupere_tehnologica, 
		convert(float,Ore_obligatii_cetatenesti) as Ore_obligatii_cetatenesti, Ind_obligatii_cetatenesti, 
		convert(float,Ore_concediu_fara_salar) as Ore_concediu_fara_salar, Ind_concediu_fara_salar, 
		convert(float,Ore_concediu_de_odihna) as Ore_concediu_de_odihna, Ind_concediu_de_odihna, 
		convert(float,Ore_concediu_medical) as Ore_concediu_medical, Ind_c_medical_unitate, Ind_c_medical_CAS, 
		convert(float,Ore_invoiri) as Ore_invoiri, Ind_invoiri, 
		convert(float,Ore_nemotivate) as Ore_nemotivate, Ind_nemotivate, Salar_categoria_lucrarii, 
		CMCAS, CMunitate, CO, Restituiri, Diminuari, Suma_impozabila, Premiu, Diurna, Cons_admin, Sp_salar_realizat, Suma_imp_separat, Spor_vechime, Spor_de_noapte, 
		Spor_sistematic_peste_program, Spor_de_functie_suplimentara, Spor_specific, Spor_cond_1, Spor_cond_2, Spor_cond_3, Spor_cond_4, Spor_cond_5, Spor_cond_6, Compensatie, 
		VENIT_TOTAL, Salar_orar, Venit_cond_normale, Venit_cond_deosebite, Venit_cond_speciale, Spor_cond_7, Spor_cond_8, Spor_cond_9, Spor_cond_10
	from brut
	where data=@datarsus) a
		unpivot (suma for camp in 
			(Total_ore_lucrate, Ore_lucrate__regie, Realizat__regie, Ore_lucrate_acord, Realizat_acord, 
			Ore_suplimentare_1, Indemnizatie_ore_supl_1, Ore_suplimentare_2, Indemnizatie_ore_supl_2, Ore_suplimentare_3, Indemnizatie_ore_supl_3, Ore_suplimentare_4, Indemnizatie_ore_supl_4, 
			Ore_spor_100, Indemnizatie_ore_spor_100, Ore_de_noapte, Ind_ore_de_noapte, Ore_lucrate_regim_normal, Ind_regim_normal, Ore_intrerupere_tehnologica, Ind_intrerupere_tehnologica, 
			Ore_obligatii_cetatenesti, Ind_obligatii_cetatenesti, Ore_concediu_fara_salar, Ind_concediu_fara_salar, Ore_concediu_de_odihna, Ind_concediu_de_odihna, 
			Ore_concediu_medical, Ind_c_medical_unitate, Ind_c_medical_CAS, Ore_invoiri, Ind_invoiri, Ore_nemotivate, Ind_nemotivate, Salar_categoria_lucrarii, 
			CMCAS, CMunitate, CO, Restituiri, Diminuari, Suma_impozabila, Premiu, Diurna, Cons_admin, Sp_salar_realizat, Suma_imp_separat, Spor_vechime, Spor_de_noapte, 
			Spor_sistematic_peste_program, Spor_de_functie_suplimentara, Spor_specific, Spor_cond_1, Spor_cond_2, Spor_cond_3, Spor_cond_4, Spor_cond_5, Spor_cond_6, 
			Compensatie, VENIT_TOTAL, Salar_orar, Venit_cond_normale, Venit_cond_deosebite, Venit_cond_speciale, Spor_cond_7, Spor_cond_8, Spor_cond_9, Spor_cond_10)) b

--	datele din tabela net, pozitia cu ULTIMA zi din luna, din baza de date in care s-au refacut calculele
	set @comandaSQL=
	'select data, marca, loc_de_munca, camp, suma '+char(13)+'
	from '+char(13)+'
	(select Data, Marca, Loc_de_munca, VENIT_TOTAL, CM_incasat, CO_incasat, Suma_incasata, Suma_neimpozabila, Diferenta_impozit, Impozit,  '+char(13)+'
		Pensie_suplimentara_3, Somaj_1, Asig_sanatate_din_impozit, Asig_sanatate_din_net, Asig_sanatate_din_CAS, VENIT_NET, Avans, Premiu_la_avans, '+char(13)+'
		Debite_externe, Rate, Debite_interne, Cont_curent, REST_DE_PLATA, CAS, Somaj_5, Fond_de_risc_1, Camera_de_Munca_1, Asig_sanatate_pl_unitate, '+char(13)+'
		Coef_tot_ded, Grad_invalid, Coef_invalid, Alte_surse, VEN_NET_IN_IMP, Ded_baza, Ded_suplim, VENIT_BAZA, Chelt_prof, '+char(13)+'
		Baza_CAS, Baza_CAS_cond_norm, Baza_CAS_cond_deoseb, Baza_CAS_cond_spec '+char(13)+'
	from '+@bazaRectificare+'..net'+char(13)+
	'where data='+char(39)+convert(char(10),@datarsus,101)+char(39)+') a '+char(13)+'
		unpivot (suma for camp in (VENIT_TOTAL, CM_incasat, CO_incasat, Suma_incasata, Suma_neimpozabila, Diferenta_impozit, Impozit, Pensie_suplimentara_3, Somaj_1, '+char(13)+'
			Asig_sanatate_din_impozit, Asig_sanatate_din_net, Asig_sanatate_din_CAS, VENIT_NET, Avans, Premiu_la_avans, Debite_externe, Rate, Debite_interne, Cont_curent, 
			REST_DE_PLATA, CAS, Somaj_5, Fond_de_risc_1, Camera_de_Munca_1, Asig_sanatate_pl_unitate, VEN_NET_IN_IMP, Ded_baza, Ded_suplim, '+char(13)+'
			VENIT_BAZA, Chelt_prof, Baza_CAS, Baza_CAS_cond_norm, Baza_CAS_cond_deoseb, Baza_CAS_cond_spec)) b'

	insert into #netRecalculat
	exec (@comandaSQL)

--	datele din tabela net, pozitia cu ULTIMA zi din luna, din baza in care s-au refacut calculele	
	select data, marca, loc_de_munca, camp, suma
	into #netInitial
	from
	(select Data, Marca, Loc_de_munca, VENIT_TOTAL, CM_incasat, CO_incasat, Suma_incasata, Suma_neimpozabila, Diferenta_impozit, Impozit, Pensie_suplimentara_3, Somaj_1, 
		Asig_sanatate_din_impozit, Asig_sanatate_din_net, Asig_sanatate_din_CAS, VENIT_NET, Avans, Premiu_la_avans, Debite_externe, Rate, Debite_interne, Cont_curent, REST_DE_PLATA, 
		CAS, Somaj_5, Fond_de_risc_1, Camera_de_Munca_1, Asig_sanatate_pl_unitate, Coef_tot_ded, Grad_invalid, Coef_invalid, Alte_surse, VEN_NET_IN_IMP, Ded_baza, Ded_suplim, 
		VENIT_BAZA, Chelt_prof, Baza_CAS, Baza_CAS_cond_norm, Baza_CAS_cond_deoseb, Baza_CAS_cond_spec 
	from net 
	where data=@datarsus) a
		unpivot (suma for camp in (VENIT_TOTAL, CM_incasat, CO_incasat, Suma_incasata, Suma_neimpozabila, Diferenta_impozit, Impozit, Pensie_suplimentara_3, Somaj_1, 
			Asig_sanatate_din_impozit, Asig_sanatate_din_net, Asig_sanatate_din_CAS, VENIT_NET, Avans, Premiu_la_avans, Debite_externe, Rate, Debite_interne, Cont_curent, REST_DE_PLATA, 
			CAS, Somaj_5, Fond_de_risc_1, Camera_de_Munca_1, Asig_sanatate_pl_unitate, VEN_NET_IN_IMP, Ded_baza, Ded_suplim, 
			VENIT_BAZA, Chelt_prof, Baza_CAS, Baza_CAS_cond_norm, Baza_CAS_cond_deoseb, Baza_CAS_cond_spec)) b

--	datele din tabela net, pozitia cu PRIMA zi din luna, din baza de date in care s-au refacut calculele
	set @comandaSQL=
	'select data, marca, loc_de_munca, camp, suma '+char(13)+'
	from '+char(13)+'
	(select Data, Marca, Loc_de_munca, VENIT_TOTAL, CM_incasat, CO_incasat, Suma_incasata, Suma_neimpozabila, Diferenta_impozit, Impozit,  '+char(13)+'
		Pensie_suplimentara_3, Somaj_1, Asig_sanatate_din_impozit, Asig_sanatate_din_net, Asig_sanatate_din_CAS, VENIT_NET, Avans, Premiu_la_avans, '+char(13)+'
		Debite_externe, Rate, Debite_interne, Cont_curent, REST_DE_PLATA, CAS, Somaj_5, Fond_de_risc_1, Camera_de_Munca_1, Asig_sanatate_pl_unitate, '+char(13)+'
		Coef_tot_ded, Grad_invalid, Coef_invalid, Alte_surse, VEN_NET_IN_IMP, Ded_baza, Ded_suplim, VENIT_BAZA, Chelt_prof, '+char(13)+'
		Baza_CAS, Baza_CAS_cond_norm, Baza_CAS_cond_deoseb, Baza_CAS_cond_spec '+char(13)+'
	from '+@bazaRectificare+'..net'+char(13)+
	'where data='+char(39)+convert(char(10),@datarjos,101)+char(39)+') a '+char(13)+'
		unpivot (suma for camp in (VENIT_TOTAL, CM_incasat, CO_incasat, Suma_incasata, Suma_neimpozabila, Diferenta_impozit, Impozit, Pensie_suplimentara_3, Somaj_1, '+char(13)+'
			Asig_sanatate_din_impozit, Asig_sanatate_din_net, Asig_sanatate_din_CAS, VENIT_NET, Avans, Premiu_la_avans, Debite_externe, Rate, Debite_interne, Cont_curent, 
			REST_DE_PLATA, CAS, Somaj_5, Fond_de_risc_1, Camera_de_Munca_1, Asig_sanatate_pl_unitate, VEN_NET_IN_IMP, Ded_baza, Ded_suplim, '+char(13)+'
			VENIT_BAZA, Chelt_prof, Baza_CAS, Baza_CAS_cond_norm, Baza_CAS_cond_deoseb, Baza_CAS_cond_spec)) b'

	insert into #net1Recalculat
	exec (@comandaSQL)

--	datele din tabela net, pozitia cu PRIMA zi din luna, baza de date curenta cea in care sunt datele in forma initiala
	select data, marca, loc_de_munca, camp, suma
	into #net1Initial
	from
	(select Data, Marca, Loc_de_munca, VENIT_TOTAL, CM_incasat, CO_incasat, Suma_incasata, Suma_neimpozabila, Diferenta_impozit, Impozit, Pensie_suplimentara_3, Somaj_1, 
		Asig_sanatate_din_impozit, Asig_sanatate_din_net, Asig_sanatate_din_CAS, VENIT_NET, Avans, Premiu_la_avans, Debite_externe, Rate, Debite_interne, Cont_curent, REST_DE_PLATA, 
		CAS, Somaj_5, Fond_de_risc_1, Camera_de_Munca_1, Asig_sanatate_pl_unitate, Coef_tot_ded, Grad_invalid, Coef_invalid, Alte_surse, VEN_NET_IN_IMP, Ded_baza, Ded_suplim, 
		VENIT_BAZA, Chelt_prof, Baza_CAS, Baza_CAS_cond_norm, Baza_CAS_cond_deoseb, Baza_CAS_cond_spec 
	from net 
	where data=@datarjos) a
		unpivot (suma for camp in (VENIT_TOTAL, CM_incasat, CO_incasat, Suma_incasata, Suma_neimpozabila, Diferenta_impozit, Impozit, Pensie_suplimentara_3, Somaj_1, 
			Asig_sanatate_din_impozit, Asig_sanatate_din_net, Asig_sanatate_din_CAS, VENIT_NET, Avans, Premiu_la_avans, Debite_externe, Rate, Debite_interne, Cont_curent, REST_DE_PLATA, 
			CAS, Somaj_5, Fond_de_risc_1, Camera_de_Munca_1, Asig_sanatate_pl_unitate, VEN_NET_IN_IMP, Ded_baza, Ded_suplim, 
			VENIT_BAZA, Chelt_prof, Baza_CAS, Baza_CAS_cond_norm, Baza_CAS_cond_deoseb, Baza_CAS_cond_spec)) b

--	inserez diferentele pe tabela brut
	select 'brut' as tabela, a.Data, a.marca, a.Loc_de_munca, a.camp, a.suma-isnull(b.suma,0) as suma
	into #diferente
	from #brutRecalculat a
		left outer join #brutInitial b on a.Data=b.Data and a.Marca=b.Marca and a.Loc_de_munca=b.Loc_de_munca and a.camp=b.camp
	where a.suma-isnull(b.suma,0)<>0

--	inserez diferentele pe tabela net pozitia cu ULTIMA zi din luna
	insert into #diferente
	select 'net' as tabela, a.Data, a.marca, a.Loc_de_munca, a.camp, a.suma-isnull(b.suma,0) as suma
	from #netRecalculat a
		left outer join #netInitial b on a.Data=b.Data and a.Marca=b.Marca and a.Loc_de_munca=b.Loc_de_munca and a.camp=b.camp
	where a.suma-isnull(b.suma,0)<>0

--	inserez diferentele pe tabela net pozitia cu PRIMA zi din luna	
	insert into #diferente
	select 'net1' as tabela, a.Data, a.marca, a.Loc_de_munca, a.camp, a.suma-isnull(b.suma,0) as suma
	from #net1Recalculat a
		left outer join #net1Initial b on a.Data=b.Data and a.Marca=b.Marca and a.Loc_de_munca=b.Loc_de_munca and a.camp=b.camp
	where a.suma-isnull(b.suma,0)<>0

	exec setare_par 'PS', 'BDRECTIF', 'Baza de date pt. rectificare', 0, 0, @bazaRectificare
	
	set @docRectificari=
		(select rtrim(a.marca) marca, convert(char(10),@datasus,101) data, 
			(select convert(char(10),@datarsus,101) datarectificata, d.Loc_de_munca lm, rtrim(ts.tip_suma) tipsuma, d.camp, 
				convert(decimal(12,2),d.suma-isnull(r.suma,0)) suma
			from #diferente d
				left outer join fTipSumeSalarii() ts on ts.tabela=d.tabela and ts.camp_tabela=d.camp
				left outer join #rectifAnt r on r.Marca=d.Marca and r.tip_suma=ts.tip_suma
			where d.marca=a.marca
			for xml raw,type)
		from #diferente a 
		where isnull(@marca,'')='' or a.marca=@marca
		group by a.marca
		for xml raw,root('Date'))
--	select @docRectificari
		exec wScriuPozRectificariSalarii @sesiune=@sesiune, @parXML=@docRectificari
		
	select 'Terminat operatie!' as textMesaj, 'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')

end try

begin catch
	set @mesaj = ERROR_MESSAGE() + ' (wOPImportRectificariSalarii)'
	raiserror (@mesaj, 11, 1)
end catch

/*
	declare @parXML xml
	set @parXML=(select 0 tippreluare, '11/30/2012' data, '11/30/2011' datarectificata, 'BRANTNER08022012' bazarectificare, '1275' marca for xml raw)
	exec wOPImportRectificariSalarii '', @parXML
*/	
