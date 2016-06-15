
CREATE procedure wOPImportDateImplSalarii @sesiune varchar(50), @parXML XML
as
begin try
	declare @stergere int, @caleFisier varchar(1000), @fisier varchar(1000), @mesaj varchar(500)
	set @stergere = isnull(@parXML.value('(/*/@stergere)[1]', 'int'),0)
	set @fisier = @parXML.value('(/*/@fisier)[1]', 'varchar(1000)')
	if @fisier=''
		raiserror('Selectati un fisier pentru import date!',11,1)

	set @caleFisier=isnull((select Val_alfanumerica from par where Tip_parametru='AR' and Parametru='CALEFORM'),'')
	set @fisier=rtrim(@caleFisier)+'uploads\'+rtrim(@fisier)

	declare @sub char(9), @sql varchar(8000), @utilizator varchar(20), @input XML, 
		@implementare int, @LunaImpl int, @AnulImpl int, @DataImpl datetime, @DataImplNext datetime 
	
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
	exec luare_date_par 'PS', 'IMPLEMENT', @implementare output, 0, ''
	set @LunaImpl=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNAIMPL'), 1)
	set @AnulImpl=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANULIMPL'), 1901)
	set @DataImpl=dbo.Eom(convert(datetime,str(@LunaImpl,2)+'/01/'+str(@AnulImpl,4)))
	set @DataImplNext=dbo.Eom(DateADD(month,1,@DataImpl))

	set @utilizator=dbo.fIaUtilizator(null)

	if exists (select 1 from sys.servers where name='#importDIS' and provider='Microsoft.ACE.OLEDB.12.0')
		EXEC sp_dropserver  @server = N'#importDIS'

	EXEC sp_addlinkedserver @server = N'#importDIS', 
	@srvproduct=N'ACE 12.0', 
	@provider=N'Microsoft.ACE.OLEDB.12.0', 
	@datasrc=@fisier,
	@provstr=N'EXCEL 12.0';

	IF OBJECT_ID('tempdb..#importDIS') IS NOT NULL drop table #importDIS
	create table #importDIS (cat varchar(50), schem varchar(50), nume varchar(50), type varchar(50), remarks varchar(200))

--	import numele sheet-urilor din Excel
	insert into #importDIS
	EXECUTE sp_tables_ex  '#importDIS'
--	select * from #importDIS

	delete from #importDIS where type <>'table'
	
	declare @crs cursor, @sheet varchar(50), @comanda nvarchar(4000)
--	creez cursor prin care parcurg numele sheet-urilor si apoi vom importa datele din fiecare sheet.	
	set @crs = cursor for select distinct (case when left(nume,1)='''' then substring(nume,2,len(rtrim(nume))-2) else nume end) from #importDIS 
	open @crs
	fetch next from @crs into @sheet
	while @@FETCH_STATUS=0
	begin
/*
		set @sql = 'select * into ##importDS
		from opendatasource(''Microsoft.ACE.OLEDB.12.0'',
		''Data Source='+@fisier+';Extended Properties=Excel 12.0'')'+'...'+'['+@sheet+']'
*/
		set @sql = 'SELECT * into ##importDS
		FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',
			''Excel 12.0;Database='+@fisier+';Extended Properties="Excel 12.0;HDR=Yes;IMEX=1;TypeGuessRows=0;ImportMixedTypes=Text"'', 
			''SELECT * FROM ['+@Sheet+']'')'

		IF OBJECT_ID('tempdb..##importDS') IS NOT NULL drop table ##importDS
		exec(@sql)

		if @sheet='Functii$'
		begin
			IF OBJECT_ID('tempdb..#functii') IS NOT NULL drop table #functii
			select * into #functii from ##importDS
		end
		if @sheet='Personal$'
		begin
			IF OBJECT_ID('tempdb..#personal') IS NOT NULL drop table #personal
			select * into #personal from ##importDS
		end
		if @sheet='Persintr$'
		begin
			IF OBJECT_ID('tempdb..#Persintr') IS NOT NULL drop table #Persintr
			select * into #Persintr from ##importDS
		end
		if @sheet='Benret$'
		begin
			IF OBJECT_ID('tempdb..#Benret') IS NOT NULL drop table #Benret
			select * into #Benret from ##importDS
		end
		if @sheet='Retineri$'
		begin
			IF OBJECT_ID('tempdb..#Retineri') IS NOT NULL drop table #Retineri
			select * into #Retineri from ##importDS
		end
		if @sheet='StagiuCM$'
		begin
			IF OBJECT_ID('tempdb..#StagiuCM') IS NOT NULL drop table #StagiuCM
			select * into #StagiuCM from ##importDS
		end
		if @sheet='DateD205$'
		begin
			IF OBJECT_ID('tempdb..#DateD205') IS NOT NULL drop table #DateD205
			select * into #DateD205 from ##importDS
		end
		if @sheet='DateIstorice$'
		begin
			IF OBJECT_ID('tempdb..#DateIstorice') IS NOT NULL drop table #DateIstorice
			select * into #DateIstorice from ##importDS
		end
		if @sheet='Conmed$'
		begin
			IF OBJECT_ID('tempdb..#Conmed') IS NOT NULL drop table #Conmed
			select * into #Conmed from ##importDS
		end

		fetch next from @crs into @sheet
	end

	EXEC sp_dropserver  @server = N'#importDIS'
	IF OBJECT_ID('tempdb..##importDS') IS NOT NULL drop table ##importDS
---------------------------------------------------------------------------------   

--	preiau tabela de functii
	if object_id('tempdb..#functii') is not null 
		if exists (select 1 from #functii)
		Begin
			delete from #functii where [Cod functie] is null
			if @stergere=1
				delete from functii 
			insert into functii
				(Cod_functie, Denumire, Nivel_de_studii)
			select [Cod functie], [Denumire], isnull([Nivel studii],'')
			from #functii
		end

--	preiau tabela personal
	if object_id('tempdb..#Personal') is not null
		if exists (select 1 from #personal)
		Begin
			delete from #personal where Marca is null
			if @stergere=1
				delete p from personal p where isnull(p.detalii.value('/row[1]/@impl', 'varchar(20)'),'')='1'
			alter table #personal add cnp_c varchar(13) not null default ''
			update #personal set cnp_c=convert(char(13),convert(decimal(13),[cnp]))
			insert into personal 
				(marca,nume,cod_functie,loc_de_munca,loc_de_munca_din_pontaj,categoria_salarizare,grupa_de_munca,salar_de_incadrare,salar_de_baza,salar_lunar_de_baza,salar_orar,
				tip_salarizare,tip_impozitare,pensie_suplimentara,somaj_1,as_sanatate,
				Indemnizatia_de_conducere,Spor_vechime,Spor_de_noapte,Spor_sistematic_peste_program,Spor_de_functie_suplimentara,
				Spor_specific,Spor_conditii_1,Spor_conditii_2,Spor_conditii_3,Spor_conditii_4,Spor_conditii_5,Spor_conditii_6,
				Sindicalist,zile_concediu_de_odihna_an,zile_concediu_efectuat_an,zile_absente_an,vechime_totala,
				data_angajarii_in_unitate,banca,Cont_in_banca,poza,Sex,Data_nasterii,Cod_numeric_personal,Studii,Profesia,
				Adresa,copii,Loc_ramas_vacant,Localitate,Judet,Strada,Numar,Cod_postal,Bloc,Scara,Etaj,Apartament,Sector,Mod_angajare,Data_plec,Tip_colab,
				grad_invalid,coef_invalid,alte_surse,fictiv,detalii)
			select [marca], [nume], [Cod functie], [Loc de munca], 0, isnull([Categoria salarizare],''), isnull([Grupa de munca],'N'), isnull([Salar de incadrare],0), isnull([Salar de incadrare],0), 
				isnull([Regim de lucru],8), 0, 
				isnull([Tip salarizare],'1'), isnull([Tip impozitare],'1'), 0, isnull([Somaj 1],1), isnull([As sanatate],55), isnull([Indemnizatia de conducere],0), 
				isnull([Spor vechime],0), isnull([Spor de noapte],0), isnull([Spor sistematic peste program],0), isnull([Spor de functie suplimentara],0), isnull([Spor specific],0), 
				isnull([Spor conditii 1],0), isnull([Spor conditii 2],0), isnull([Spor conditii 3],0), isnull([Spor conditii 4],0), isnull([Spor conditii 5],0), isnull([Spor conditii 6],0), 
				isnull([Sindicalist],0), isnull([Zile concediu de odihna an],0), 0, 0, 
				isnull([Vechime totala],'1899-01-01'), isnull([Data angajarii],'01/01/1901'), isnull([Banca],''), isnull([Cont in banca],''), '', 
				(case when left([cnp_c],1) in ('1','3','5','7','9') then 1 else 0 end), dbo.fDataNasterii([cnp_c]) as data_nasterii, 
				[cnp_c], '' as studii, '' as Profesia, 
				isnull([Casa de sanatate],''), isnull([Date buletin],''), isnull([Loc ramas vacant],0), isnull([Localitate],''), isnull([Judet],''), isnull([Strada],''), 
				isnull([Numar],''), isnull([Cod postal],''), isnull([Bloc],''), isnull([Scara],''), isnull([Etaj],''), isnull([Apartament],''), 
				isnull([Sector],0), isnull([Mod angajare],'N'), isnull([Data plecarii],'01/01/1901'), isnull([Ded personala/tip colab],''), isnull([Grad invaliditate],'0'), 
				isnull([Deducere somaj],0), 0, 0, '<row impl="1" />'
			from #personal
--	preiau tabela infopers
			if @stergere=1
				delete ip
				from infopers ip
					left outer join personal p on p.Marca=ip.Marca 
				where isnull(p.detalii.value('/row[1]/@impl', 'varchar(20)'),'')='1'
			insert into infopers (marca,permis_auto_categoria,limbi_straine,nationalitatea,cetatenia,starea_civila,marca_sot_sotie,nume_sot_sotie,religia,evidenta_militara,
				telefon,email,observatii,actionar,centru_de_cost_exceptie,vechime_studii,poza,loc_munca_precedent,loc_munca_nou,vechime_la_intrare,vechime_in_meserie,
				nr_contract,spor_cond_7,spor_cond_8,spor_cond_9,spor_cond_10)
			select [marca], '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', isnull([nr contract],''), 0, 0, 0, 0
			from #personal
		End

--	preiau tabela de persoane in intretinere
	if object_id('tempdb..#Persintr') is not null 
		if exists (select 1 from #persintr)
		Begin
			delete from #persintr where Marca is null
			if @stergere=1
				delete from persintr where Data=@DataImplNext
			alter table #persintr add cnp_c varchar(13) not null default ''
			update #persintr set cnp_c=convert(char(13),convert(decimal(13),[cnp]))
			insert into persintr
				(Marca, Tip_intretinut, Cod_personal, Nume_pren, data, Grad_invalid, Coef_ded, Data_nasterii)
			select Marca, left([Tip intretinut],1), [cnp_c], [Nume], @DataImplNext, 0, left(Deducere,1), dbo.fDataNasterii([cnp_c])
			from #persintr
		end

--	preiau tabela de beneficiari de retineri
	if object_id('tempdb..#benret') is not null 
		if exists (select 1 from #benret)
		Begin
			delete from #benret where [Cod beneficiar] is null
			if @stergere=1 and @implementare=1
				delete from benret
			insert into benret
				(Cod_beneficiar, Tip_retinere, Denumire_beneficiar, Obiect_retinere, Cod_fiscal, Banca, Cont_banca, Permane, Cont_debitor, Cont_creditor, Analitic_marca)
			select [Cod beneficiar], isnull([Tip retinere],1), [Denumire beneficiar], isnull([Obiect retinere],''), isnull([Cod fiscal],''), isnull([Banca],''), isnull([Cont banca],''), 0, 
				isnull([Cont debitor],''), isnull([Cont creditor],''), 0
			from #benret
			where not exists (select 1 from benret b where b.cod_beneficiar=[Cod beneficiar])
		end

--	preiau tabela de retineri (cu data implementarii si prima luna de lucru)
	if object_id('tempdb..#Retineri') is not null 
		if exists (select 1 from #retineri)
		Begin
			delete from #retineri where Data is null or Marca is null
			if exists (select * from sysobjects WHERE id = OBJECT_ID(N'tr_ValidResal') AND type='TR')
				alter table resal disable trigger tr_ValidResal

			if @stergere=1
				delete from resal where Data<=@DataImplNext
			insert into resal
				(Data, Marca, Cod_beneficiar, Numar_document, Data_document, Valoare_totala_pe_doc, Valoare_retinuta_pe_doc, 
				Retinere_progr_la_avans, Retinere_progr_la_lichidare, Procent_progr_la_lichidare, Retinut_la_avans, Retinut_la_lichidare)
			select Data, Marca, [Cod beneficiar], isnull([Numar document],''), isnull([Data document],@DataImpl), isnull([Valoare totala],0), isnull([Valoare retinuta],0), 
				isnull([Retinere programata la avans],0), isnull([Retinere programata la lichidare],0), 
				isnull([Procent programat la lichidare],0), isnull([Retinere programata la avans],0), isnull([Retinut la lichidare],0)
			from #retineri

			insert into resal
				(Data, Marca, Cod_beneficiar, Numar_document, Data_document, Valoare_totala_pe_doc, Valoare_retinuta_pe_doc, 
				Retinere_progr_la_avans, Retinere_progr_la_lichidare, Procent_progr_la_lichidare, Retinut_la_avans, Retinut_la_lichidare)
			select @DataImplNext, Marca, [Cod beneficiar], isnull([Numar document],''), isnull([Data document],@DataImpl), isnull([Valoare totala],0), isnull([Valoare retinuta],0), 
				isnull([Retinere programata la avans],0), isnull([Retinere programata la lichidare],0), 
				isnull([Procent programat la lichidare],0), isnull([Retinere programata la avans],0), isnull([Retinut la lichidare],0)
			from #retineri
			where Data=@DataImpl

			if exists (select * from sysobjects WHERE id = OBJECT_ID(N'tr_ValidResal') AND type='TR')
				alter table resal enable trigger tr_ValidResal
		end

--	preiau tabela pentru stagiu concedii medicale
	if object_id('tempdb..#StagiuCM') is not null 
		if exists (select 1 from #StagiuCM)
		Begin
			delete from #StagiuCM where Marca is null or Data is null
			if @stergere=1
				delete from net where day(data)=15 and Data<=@DataImpl
			insert into net 
				(Data, Marca, Loc_de_munca, VENIT_TOTAL, CM_incasat, CO_incasat, Suma_incasata, Suma_neimpozabila, Diferenta_impozit, Impozit, Pensie_suplimentara_3, Somaj_1, 
				Asig_sanatate_din_impozit, Asig_sanatate_din_net, Asig_sanatate_din_CAS, VENIT_NET, Avans, Premiu_la_avans, Debite_externe, Rate, Debite_interne, Cont_curent, REST_DE_PLATA, CAS,
				Somaj_5, Fond_de_risc_1, Camera_de_Munca_1, Asig_sanatate_pl_unitate, Coef_tot_ded, Grad_invalid, Coef_invalid, Alte_surse, VEN_NET_IN_IMP, Ded_baza, Ded_suplim, 
				VENIT_BAZA, Chelt_prof, Baza_CAS, Baza_CAS_cond_norm, Baza_CAS_cond_deoseb, Baza_CAS_cond_spec)
			select DateADD(day,14,dbo.BOM(convert(datetime,a.data,103))), a.Marca, isnull(p.Loc_de_munca,''), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,0,0,0,0,0,0,0, 
				0, 0, 0, 0, 0, 0, '', 0, 0, 0, 0, a.[Zile stagiu], 0, 0, a.[Baza stagiu], 0, 0, 0
			from #StagiuCM a
				left outer join personal p on p.Marca=a.Marca
		end

--	preiau tabela cu date pt. declaratia 205
	if object_id('tempdb..#DateD205') is not null 
		if exists (select 1 from #DateD205)
		Begin
			delete from #DateD205 where Data is null or Marca is null
			if @stergere=1
				delete from net where (data=dbo.BOM(data) or data=dbo.EOM(data)) and Data<=@DataImpl
--	pensie facultativa
			insert into net 
				(Data, Marca, Loc_de_munca, VENIT_TOTAL, CM_incasat, CO_incasat, Suma_incasata, Suma_neimpozabila, Diferenta_impozit, Impozit, Pensie_suplimentara_3, Somaj_1, 
				Asig_sanatate_din_impozit, Asig_sanatate_din_net, Asig_sanatate_din_CAS, VENIT_NET, Avans, Premiu_la_avans, Debite_externe, Rate, Debite_interne, Cont_curent, REST_DE_PLATA, CAS,
				Somaj_5, Fond_de_risc_1, Camera_de_Munca_1, Asig_sanatate_pl_unitate, Coef_tot_ded, Grad_invalid, Coef_invalid, Alte_surse, VEN_NET_IN_IMP, 
				Ded_baza, Ded_suplim, VENIT_BAZA, Chelt_prof, Baza_CAS, Baza_CAS_cond_norm, Baza_CAS_cond_deoseb, Baza_CAS_cond_spec)
			select dbo.BOM(convert(datetime,a.data,103)), a.Marca, isnull(p.Loc_de_munca,''), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
				0, 0, 0, 0, 0, 0, '', 0, 0, 0, a.[Pensie facultativa], 0, 0, 0, 0, 0, 0, 0
			from #DateD205 a
				left outer join personal p on p.Marca=a.Marca

--	celelalte elemente pt. D205 (venit total, deducere personala, venit baza, impozit, venit net)
			insert into net 
				(Data, Marca, Loc_de_munca, VENIT_TOTAL, CM_incasat, CO_incasat, Suma_incasata, Suma_neimpozabila, Diferenta_impozit, Impozit, Pensie_suplimentara_3, Somaj_1, 
				Asig_sanatate_din_impozit, Asig_sanatate_din_net, Asig_sanatate_din_CAS, VENIT_NET, Avans, Premiu_la_avans, Debite_externe, Rate, Debite_interne, Cont_curent, REST_DE_PLATA, CAS,
				Somaj_5, Fond_de_risc_1, Camera_de_Munca_1, Asig_sanatate_pl_unitate, Coef_tot_ded, Grad_invalid, Coef_invalid, Alte_surse, VEN_NET_IN_IMP, 
				Ded_baza, Ded_suplim, VENIT_BAZA, Chelt_prof, Baza_CAS, Baza_CAS_cond_norm, Baza_CAS_cond_deoseb, Baza_CAS_cond_spec)
			select dbo.EOM(convert(datetime,a.data,103)), a.Marca, isnull(p.Loc_de_munca,''), a.[Venit total], 0, 0, 0, 0, 0, a.[Impozit], 0, 0, 0, 0, 0, a.[Venit net], 0, 0, 0, 0, 0, 0, 0, 
				0, 0, 0, 0, 0, 0, '', 0, 0, 0, a.[Deducere personala], 0, a.[Venit baza], 0, 0, 0, 0, 0
			from #DateD205 a
				left outer join personal p on p.Marca=a.Marca
		end

--	preiau date in tabele brut / net (date istorice)
	if object_id('tempdb..#DateIstorice') is not null 
		if exists (select 1 from #DateIstorice)
		Begin
			delete from #DateIstorice where Marca is null or Data is null
			if @stergere=1
			begin
				delete from net where (data=dbo.BOM(data) or data=dbo.EOM(data)) and Data<=@DataImpl
				delete from brut where Data<=@DataImpl
			end

--	pozitii in tabela brut
		insert into brut (Data,Marca,Loc_de_munca,Loc_munca_pt_stat_de_plata,Total_ore_lucrate,Ore_lucrate__regie, Realizat__regie, Ore_lucrate_acord, Realizat_acord, 
			Ore_suplimentare_1, Indemnizatie_ore_supl_1, Ore_suplimentare_2, Indemnizatie_ore_supl_2, Ore_suplimentare_3,Indemnizatie_ore_supl_3, Ore_suplimentare_4,
			Indemnizatie_ore_supl_4,Ore_spor_100, Indemnizatie_ore_spor_100,Ore_de_noapte,Ind_ore_de_noapte, Ore_lucrate_regim_normal,Ind_regim_normal, 
			Ore_intrerupere_tehnologica, Ind_intrerupere_tehnologica, Ore_obligatii_cetatenesti, Ind_obligatii_cetatenesti, Ore_concediu_fara_salar, Ind_concediu_fara_salar,
			Ore_concediu_de_odihna, Ind_concediu_de_odihna, Ore_concediu_medical, Ind_c_medical_unitate, Ind_c_medical_CAS, Ore_invoiri, Ind_invoiri, Ore_nemotivate, Ind_nemotivate, 
			Salar_categoria_lucrarii, CMCAS, CMunitate, CO, Restituiri, Diminuari, Suma_impozabila, Premiu, Diurna, Cons_admin, Sp_salar_realizat, Suma_imp_separat, Spor_vechime, Spor_de_noapte, 
			Spor_sistematic_peste_program, Spor_de_functie_suplimentara, Spor_specific, Spor_cond_1, Spor_cond_2, Spor_cond_3, Spor_cond_4, Spor_cond_5, Spor_cond_6, Compensatie, VENIT_TOTAL, 
			Salar_orar,	Venit_cond_normale,Venit_cond_deosebite,Venit_cond_speciale,Spor_cond_7,Spor_cond_8,Spor_cond_9,Spor_cond_10)
		select dbo.EOM(convert(datetime,a.data,103)), rtrim(a.Marca), rtrim(p.Loc_de_munca), 1, 
			isnull(a.[Ore regie]+a.[Ore acord],0), isnull(a.[Ore regie],0), isnull(a.[Realizat regie],0), isnull(a.[Ore acord],0), isnull(a.[Realizat acord],0), 
			isnull(a.[Ore suplimentare 1],0), isnull(a.[Indemnizatie ore supl 1],0), isnull(a.[Ore suplimentare 2],0), isnull(a.[Indemnizatie ore supl 2],0), 
			isnull(a.[Ore suplimentare 3],0), isnull(a.[Indemnizatie ore supl 3],0), isnull(a.[Ore suplimentare 4],0), isnull(a.[Indemnizatie ore supl 4],0), 
			isnull(a.[Ore spor 100],0), isnull(a.[Indemnizatie ore spor 100],0), isnull(a.[Ore de noapte],0), isnull(a.[Ind ore de noapte],0), 
			isnull(a.[ore regim normal],0), isnull(a.[ind ore regim normal],0), 
			isnull(a.[ore intrerupere tehnologica],0), isnull(a.[Ind intrerupere tehnologica],0), isnull(a.[Ore obligatii cetatenesti],0), isnull(a.[Ind obligatii cetatenesti],0), 
			isnull(a.[Ore concediu fara salar],0), 0, isnull(a.[Ore concediu de odihna],0), isnull(a.[Ind concediu de odihna],0), 
			isnull(a.[Ore concediu medical],0), isnull(a.[Ind cm unitate],0), isnull(a.[Ind cm fnuass],0), 
			isnull(a.[Ore invoiri],0), isnull(a.[Ind intrerupere tehnologica 2],0), isnull(a.[Ore nemotivate],0), isnull(a.[Ind conducere],0), isnull(a.[Salar categoria lucrarii],0), 
			0 as CMCAS, 0 as CMUnitate, 0 as CO, 0 as Restituiri, 0 as Diminuari, 0 as Suma_neimpozabila, isnull(a.[Premiu],0) as premiu, 0 as Diurna, 
			0 as Cons_admin, 0 as Sp_salar_realizat, 0 as Suma_imp_separat, 
			isnull(a.[Spor vechime],0) as spor_vechime, 0 as Spor_de_noapte, 0 as Spor_sistematic_peste_program, 0 as Spor_de_functie_suplimentara, 0  as Spor_specific, 
			0 as Spor_cond_1, 0 as Spor_cond_2, 0 as Spor_cond_3, 0 as Spor_cond_4, 0 as Spor_cond_5, 0 as Spor_cond_6, 0 as Compensatie, isnull(a.[Venit total],0), 0, 
			isnull(a.[Venit total],0), 0 as Venit_cond_deosebite, 0 as Venit_cond_speciale, 0 as Spor_cond_7, 0 as Spor_cond_8, isnull(a.[Ind cm faambp],0), isnull(a.[Regim de lucru],8)
		from #DateIstorice a
			left outer join personal p on p.Marca=a.Marca

--	pozitii in net cu data de prima zi a lunii
			insert into net 
				(Data, Marca, Loc_de_munca, VENIT_TOTAL, CM_incasat, CO_incasat, Suma_incasata, Suma_neimpozabila, Diferenta_impozit, Impozit, Pensie_suplimentara_3, Somaj_1, 
				Asig_sanatate_din_impozit, Asig_sanatate_din_net, Asig_sanatate_din_CAS, VENIT_NET, Avans, Premiu_la_avans, Debite_externe, Rate, Debite_interne, Cont_curent, REST_DE_PLATA, CAS,
				Somaj_5, Fond_de_risc_1, Camera_de_Munca_1, Asig_sanatate_pl_unitate, Coef_tot_ded, Grad_invalid, Coef_invalid, Alte_surse, VEN_NET_IN_IMP, 
				Ded_baza, Ded_suplim, VENIT_BAZA, Chelt_prof, Baza_CAS, Baza_CAS_cond_norm, Baza_CAS_cond_deoseb, Baza_CAS_cond_spec)
			select dbo.BOM(convert(datetime,a.data,103)), rtrim(a.Marca), rtrim(isnull(p.Loc_de_munca,'')), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
				0, 0, 0, 0, 0, 0, '', 0, 0, 0, isnull(a.[Pensie facultativa],0), 0, 0, 0, 0, 0, 0, 0
			from #DateIstorice a
				left outer join personal p on p.Marca=a.Marca

--	pozitii in net cu data de ultima zi a lunii
			insert into net 
				(Data, Marca, Loc_de_munca, VENIT_TOTAL, CM_incasat, CO_incasat, Suma_incasata, Suma_neimpozabila, Diferenta_impozit, Impozit, Pensie_suplimentara_3, Somaj_1, 
				Asig_sanatate_din_impozit, Asig_sanatate_din_net, Asig_sanatate_din_CAS, VENIT_NET, Avans, Premiu_la_avans, Debite_externe, Rate, Debite_interne, Cont_curent, REST_DE_PLATA, CAS,
				Somaj_5, Fond_de_risc_1, Camera_de_Munca_1, Asig_sanatate_pl_unitate, Coef_tot_ded, Grad_invalid, Coef_invalid, Alte_surse, VEN_NET_IN_IMP, 
				Ded_baza, Ded_suplim, VENIT_BAZA, Chelt_prof, Baza_CAS, Baza_CAS_cond_norm, Baza_CAS_cond_deoseb, Baza_CAS_cond_spec)
			select dbo.EOM(convert(datetime,a.data,103)), rtrim(a.Marca), rtrim(isnull(p.Loc_de_munca,'')), a.[Venit total], 0, 0, 0, 0, 0, 
				isnull(a.[Impozit],0), isnull(a.[CAS individual],0), isnull(a.[Somaj individual],0), 0, isnull(a.[CASS individual],0), 0, isnull(a.[Venit net],0), isnull(a.[Avans],0), 
				0, 0, 0, 0, 0, isnull(a.[Rest de plata],0), 
				0 as CAS, 0 as Somaj_5, 0 as Fond_de_risc_1, 0 as Camera_de_munca_1, 0 as Asig_sanatate_pl_unitate, 0 as Coef_tot_ded, '' as Grad_invalid, 0 as Coef_invalid, 0 as Alte_surse, 
				0 as VEN_NET_IN_IMP, a.[Deducere personala], 0, a.[Baza impozit], 0 as Chelt_prof, 
				a.[Venit total]-isnull(a.[Ind cm unitate],0)-isnull(a.[Ind cm fnuass],0)-isnull(a.[Ind cm faambp],0), 
				a.[Venit total]-isnull(a.[Ind cm unitate],0)-isnull(a.[Ind cm fnuass],0)-isnull(a.[Ind cm faambp],0), 0, 0
			from #DateIstorice a
				left outer join personal p on p.Marca=a.Marca
		end
--	preiau tabela de concedii medicale anterioare implementarii
	if object_id('tempdb..#Conmed') is not null 
		if exists (select 1 from #Conmed)
		Begin
			delete from #Conmed where Data is null or Marca is null
			if exists (select * from sysobjects WHERE id = OBJECT_ID(N'tr_ValidConmed') AND type='TR')
				alter table conmed disable trigger tr_ValidConmed
			if exists (select * from sysobjects WHERE id = OBJECT_ID(N'tr_ValidInfoconmed') AND type='TR')
				alter table infoconmed disable trigger tr_ValidInfoconmed

			if @stergere=1
			begin
				delete from conmed where Data<=@DataImpl
				delete from infoconmed where Data<=@DataImpl
			end
			insert into conmed 
				(Data, Marca, Tip_diagnostic, Data_inceput, Data_sfarsit, Zile_lucratoare, Zile_cu_reducere, Zile_luna_anterioara, Indemnizatia_zi, Procent_aplicat, Indemnizatie_unitate, 
				Indemnizatie_CAS, Baza_calcul, Zile_lucratoare_in_luna, Indemnizatii_calc_manual, Suma)
			select dbo.EOM(convert(datetime,data,103)), Marca, isnull(rtrim([Tip diagnostic]),'')+(case when len(isnull(rtrim([Tip diagnostic]),''))=1 then '-' else '' end), 
				convert(datetime,[Data inceput],103), convert(datetime,[Data sfarsit],103), 
				(case when isnull([Zile lucratoare CM],0)=0 then dbo.Zile_lucratoare(convert(datetime,[data inceput],103),convert(datetime,[data sfarsit],103)) else isnull([Zile lucratoare CM],0) end), 
				isnull([Zile pl unitate],0), isnull([Zile CM anterior],0), 
				isnull([Media zilnica],0), isnull([Procent],0), isnull([Indemnizatie unitate],0), isnull([Indemnizatie fond],0), isnull([Media zilnica]*[Zile lucratoare CM],0), 
				isnull(dbo.Zile_lucratoare(dbo.BOM(convert(datetime,data,103)),dbo.EOM(convert(datetime,data,103))),0), 0, 0
			from #Conmed a

			insert into infoconmed 
				(Data, Marca, Data_inceput, Serie_certificat_CM, Nr_certificat_CM, Serie_certificat_CM_initial, Nr_certificat_CM_initial, Indemnizatie_FAMBP, Zile_CAS, Zile_FAMBP, 
				Cod_urgenta, Cod_boala_grpA, Data_rez, Data_acordarii, Cnp_copil, Loc_prescriere, Medic_prescriptor, Unitate_sanitara, Nr_aviz_me, Valoare, Valoare1, Alfa, Alfa1, Numar_pozitie)
			select dbo.EOM(convert(datetime,data,103)), Marca, convert(datetime,[Data inceput],103), 
				isnull([Serie certificat CM],''), isnull([Numar certificat CM],''), isnull([Serie certificat CM initial],''), isnull([Numar certificat CM initial],''), 
				0, 0, 0, isnull([Cod urgenta],''), isnull([Cod boala grp A],''), '', convert(datetime,[Data acordarii],103), isnull([Cnp copil],''), isnull([Loc prescriere],'1'), 
				isnull([Medic prescriptor],''), isnull([Unitate sanitara],''), isnull([Nr aviz medic expert],''), 0, 0, isnull([Cod diagnostic],''), '', 1
			from #Conmed a

			if exists (select * from sysobjects WHERE id = OBJECT_ID(N'tr_ValidConmed') AND type='TR')
				alter table conmed enable trigger tr_ValidConmed
			if exists (select * from sysobjects WHERE id = OBJECT_ID(N'tr_ValidInfoconmed') AND type='TR')
				alter table infoconmed enable trigger tr_ValidInfoconmed

		end
		
	select 'Terminat operatie!' as textMesaj, 'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')

end try

begin catch
	set @mesaj = 'Procedura wOPImportDateImplSalarii (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror (@mesaj, 11, 1)
end catch

/*
	declare @parXML xml
	set @parXML=(select 1 stergere, 'D:\Fisiere\Date implementare salarii.xlsx' fisier for xml raw)
	exec wOPImportDateImplSalarii '', @parXML
*/	
