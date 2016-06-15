--***
Create procedure Declaratia112 
	@dataJos datetime
	,@dataSus datetime
	,@tipdecl int --TipDeclaratie=0 Standard, 1 Rectificativa
	,@ImpozitPL int --ImpozitPePuncteDeLucru 0 = Nu, 1=Da
	,@numedecl varchar(75)
	,@prendecl varchar(75)
	,@functiedecl varchar(75)
	,@inXML int
	,@cDirector varchar(254)	-->	cale generare fisier XML
	,@OptiuniGenerare int	-->	Generare declaratie=0 (completare date ASIS sau import fisiere XML)+generare XML, 1-Import Fisiere XML, 2-Editare tabele declaratie, 3-Generare XML
	,@lm char(9)=''	-->	pentru filtrare loc de munca like (ANAR-pt. verificare 112 la nivel de SGA)
	,@ContCASSAgricol varchar(13)=''	--> Cont asigurari de sanatate retinute la achizitia de cereale 
	,@ContImpozitAgricol varchar(13)=''	--> Cont impozit retinut la achizitia de cereale
	,@tipRectificare int=0
	,@faraMesaj int=0
as  
Begin try
	declare @utilizator varchar(20), @lista_lm int, @multiFirma int, @lmUtilizator varchar(9), @denlmUtilizator varchar(9), 
	@ImpPLFaraSal int, @SalMediu decimal(10), @pSomajInd decimal(3,2), @rezultat varchar(max), @Luna int, @An int, @LunaAlfa varchar(15), 
	@numeFisier varchar(max), @cFisier varchar(254), @raspunsCmd int, @msgeroare varchar(1000),
	@Cod_declaratie varchar(3), @DataScad datetime, @vcif varchar(13), @cif varchar(13), @rgCom varchar(14), @caen varchar(4), @den varchar(200), @adrSoc varchar(1000),
	@telSoc varchar(15), @faxSoc varchar(15), @mailSoc varchar(200), @adrFisc varchar(1000), @telFisc varchar(15), @faxFisc varchar(15), 
	@mailFisc varchar(200), @casaAng varchar(2), @tRisc decimal(4,3), @dat char(1), @totalPlata_A decimal(15),
	@NrAsigSomaj int, @NrAsigCCI int, @NrAsigCAS int, @brutSalarii decimal(15), @NrSalariati int, 
	@BazaSomajAsigurati decimal(10), @SomajAngajator decimal(10), @BazaFondGarantare decimal(10), @FondGarantare decimal(10),
	@NrAsigSomajAlte int, @E1_venit decimal(10), @F1_suma decimal(10), @C4_scutitaSo decimal(10), @xml xml, @versiune varchar(1)

	set @utilizator = dbo.fIaUtilizator(null)
	set @lista_lm=dbo.f_areLMFiltru(@utilizator)
	set @multiFirma=0
	if exists (select * from sysobjects where name ='par' and xtype='V')
		set @multiFirma=1
	if @multiFirma=1 
	begin
		select @lmUtilizator=isnull(min(Cod),'') from LMfiltrare where utilizator=@utilizator and cod in (select cod from lm where Nivel=1)
		select @denlmUtilizator=isnull(min(Denumire),'') from lm where cod=@lmUtilizator
	end

	set @ImpPLFaraSal=dbo.iauParL('PS','D112IPLFS')
	set @SalMediu=dbo.iauParLN(@dataSus,'PS','SALMBRUT')
	set @pSomajInd=dbo.iauParLN(@dataSus,'PS','SOMAJIND')

--	citire date unitate
	select @DataScad=DateAdd(day,25,@dataSus), @Cod_declaratie='112'
	select @vcif=dbo.iauParA('PS','CODFISC')
	if @vcif=''
		set @vcif=dbo.iauParA('GE','CODFISC')
	select @rgCom=dbo.iauParA('GE','ORDREG'), @caen=dbo.iauParA('PS','CODCAEN'),
		@den=dbo.iauParA('GE','NUME'), @adrSoc=dbo.iauParA('GE','ADRESA'), @telSoc=dbo.iauParA('GE','TELFAX'), 
		@faxSoc=(case when dbo.iauParA('GE','FAX')='' then dbo.iauParA('GE','TELFAX') else dbo.iauParA('GE','FAX') end), 
		@mailSoc=dbo.iauParA('GE','EMAIL'), @casaAng=dbo.iauParA('PS','CODJUDETA'),
		@tRisc=dbo.iauParLN(@dataSus,'PS','0.5%ACCM')
	Select @adrFisc=@adrSoc, @telFisc=@telSoc, @faxFisc=@faxSoc, @mailFisc=@mailSoc
	Select @cif=ltrim(rtrim((case when left(upper(@vcif),2)='RO' then substring(@vcif,3,13)
		when left(upper(@vcif),1)='R' then substring(@vcif,2,13) else @vcif end)))
	select @luna=month(@dataSus), @An=year(@dataSus), @dat=(case when @tRisc<>0 then '1' else '0' end)
	set @versiune=(case when @dataSus>='01/01/2014' then '2' else '1' end)

	if @OptiuniGenerare in ('0','1') and exists (select 1 from sysobjects where [type]='P' and [name]='Declaratie112SP')
		exec Declaratie112SP @dataJos, @dataSus

	if @OptiuniGenerare=0
	Begin
--	sterg tabelele temporare
		if object_id('tempdb..#brut') is not null drop table #brut
		if object_id('tempdb..#brutMarca') is not null drop table #brutMarca
		if object_id('tempdb..#net') is not null drop table #net
		if object_id('tempdb..#SalariiZilieri') is not null drop table #SalariiZilieri
		if object_id('tempdb..#Zilieri') is not null drop table #Zilieri
		if object_id('tempdb..#conmed') is not null drop table #conmed
		if object_id('tempdb..#istpers') is not null drop table #istpers
		if object_id('tempdb..#D112CodObligatie') is not null drop table #D112CodObligatie
		if object_id('tempdb..#D112Impozit') is not null drop table #D112Impozit
		if object_id('tempdb..#D112Subventii') is not null drop table #D112Subventii
		if object_id('tempdb..#D112BassAngajator') is not null drop table #D112BassAngajator
		if object_id('tempdb..#D112CMFnuass') is not null drop table #D112CMFnuass
		if object_id('tempdb..#D112CMFaambp') is not null drop table #D112CMFaambp
		if object_id('tempdb..#D112Asigurati') is not null drop table #D112Asigurati
		if object_id('tempdb..#D112DateCCI') is not null drop table #D112DateCCI
		if object_id('tempdb..#ingrcopil') is not null drop table #ingrcopil
		if object_id('tempdb..#D112AsiguratE1') is not null drop table #D112AsiguratE1
		if object_id('tempdb..#D112AsiguratE2') is not null drop table #D112AsiguratE2
		if object_id('tempdb..#impozitIpotetic') is not null drop table #impozitIpotetic

-->	selectez din extinfop, pozitia pentru salariatii care au impozit ipotetic (HG84/2013) valabila la data declaratiei. Acest impozit ipotetic nu trebuie cuprins in D112.
		create table #impozitIpotetic (data datetime, marca varchar(6), ImpozitIpotetic varchar(100))
		insert into #impozitIpotetic 
		select data, marca, ImpozitIpotetic 
		from dbo.fSalariatiCuImpozitIpotetic (@dataJos, @dataSus, @lm, null)

		declare @parXML xml
		set @parXML=(select @dataJos datajos, @dataSus datasus, 'LR' lunaApelare, @lm lm for xml raw)
--	creez tabele temporare #brut si #net cu structura similara tabelelor brut si net, care se completeaza prin procedura BrutNetCuRectificari 
--	cu datele din tabele brut si net, plus rectificarile aferente acestor tabele
		select top 0 Data, Marca, Loc_de_munca, Loc_munca_pt_stat_de_plata, Total_ore_lucrate, Ore_lucrate__regie, Realizat__regie, Ore_lucrate_acord, Realizat_acord, 
			Ore_suplimentare_1, Indemnizatie_ore_supl_1, Ore_suplimentare_2, Indemnizatie_ore_supl_2, Ore_suplimentare_3, Indemnizatie_ore_supl_3, Ore_suplimentare_4, 
			Indemnizatie_ore_supl_4, Ore_spor_100, Indemnizatie_ore_spor_100, Ore_de_noapte, Ind_ore_de_noapte, Ore_lucrate_regim_normal, Ind_regim_normal, 
			Ore_intrerupere_tehnologica, Ind_intrerupere_tehnologica, Ore_obligatii_cetatenesti, Ind_obligatii_cetatenesti, Ore_concediu_fara_salar, Ind_concediu_fara_salar, 
			Ore_concediu_de_odihna, Ind_concediu_de_odihna, Ore_concediu_medical, Ind_c_medical_unitate, Ind_c_medical_CAS, Ore_invoiri, Ind_invoiri, Ore_nemotivate, Ind_nemotivate, 
			Salar_categoria_lucrarii, CMCAS, CMunitate, CO, Restituiri, Diminuari, Suma_impozabila, Premiu, Diurna, Cons_admin, Sp_salar_realizat, Suma_imp_separat, 
			Spor_vechime, Spor_de_noapte, Spor_sistematic_peste_program, Spor_de_functie_suplimentara, Spor_specific, 
			Spor_cond_1, Spor_cond_2, Spor_cond_3, Spor_cond_4, Spor_cond_5, Spor_cond_6, Compensatie, 
			VENIT_TOTAL, Salar_orar, Venit_cond_normale, Venit_cond_deosebite, Venit_cond_speciale, Spor_cond_7, Spor_cond_8, Spor_cond_9, Spor_cond_10
		into #brut from brut where data between @datajos and @datasus
		create unique index [Data_Marca_Locm] ON #brut (Data, Marca, Loc_de_munca)

		select top 0 * into #brutMarca from #brut where data between @datajos and @datasus
		create unique index [Data_Marca] ON #brutMarca (Data, Marca)
		
		select top 0 Data, Marca, Loc_de_munca, VENIT_TOTAL, CM_incasat, CO_incasat, Suma_incasata, Suma_neimpozabila, Diferenta_impozit, Impozit, Pensie_suplimentara_3, Somaj_1, 
			Asig_sanatate_din_impozit, Asig_sanatate_din_net, Asig_sanatate_din_CAS, VENIT_NET, Avans, Premiu_la_avans, Debite_externe, Rate, Debite_interne, Cont_curent, REST_DE_PLATA, 
			CAS, Somaj_5, Fond_de_risc_1, Camera_de_Munca_1, Asig_sanatate_pl_unitate, Coef_tot_ded, Grad_invalid, Coef_invalid, Alte_surse, VEN_NET_IN_IMP, Ded_baza, Ded_suplim, 
			VENIT_BAZA, Chelt_prof, Baza_CAS, Baza_CAS_cond_norm, Baza_CAS_cond_deoseb, Baza_CAS_cond_spec
		into #net from net where data between @datajos and @datasus
		create unique index [Data_Marca] ON #net (Data, Marca)
		
		insert into #brut 
		exec BrutCuRectificari @parXML
		
--		insert into #net
--	tabela #net se completeaza in procedura NetCuRectificari
		exec NetCuRectificari @parXML

-->	pentru salariatii care au impozit ipotetic (HG84/2013) la data declaratiei pun 0 impozitul in tabela #net. Ca sa nu umblu in toate procedurile apelate din procedura curenta.
		update n set n.Impozit=(case when upper(isnull(ii.ImpozitIpotetic,0))='DA' then 0 else n.Impozit end)
		from #net n 
			left outer join #impozitIpotetic ii on ii.Marca=n.Marca
		
		set @parXML=(select @dataJos datajos, @dataSus datasus, 'LR' lunaApelare, @lm lm, 1 gruparepemarca for xml raw)		
		insert into #brutMarca
		exec BrutCuRectificari @parXML

--	Pun tabela SalariiZilieri intr-o tabela temporara pt. a nu face filtru pe loc de munca/proprietate LOCMUNCA in fiecare select/procedura apelata
		select sz.* into #SalariiZilieri 
		from SalariiZilieri sz
			left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=sz.loc_de_munca
		where sz.Data between @dataJos and @dataSus
			and (@lm='' or sz.Loc_de_munca like rtrim(@lm)+'%')
			and (@lista_lm=0 or lu.cod is not null) 

--	Pun tabela Zilieri intr-o tabela temporara pt. a nu face filtru pe loc de munca/proprietate LOCMUNCA in fiecare select/procedura apelata, tinand cont de datele lunare ale zilierilor
		select z.* into #Zilieri 
		from Zilieri z
			left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=z.loc_de_munca
		where exists (select 1 from #SalariiZilieri sz where sz.Marca=z.Marca) 
			and (@lm='' or z.Loc_de_munca like rtrim(@lm)+'%')
			and (@lista_lm=0 or lu.cod is not null) 

--	Pun tabela conmed intr-o tabela temporara pt. a nu face filtru pe loc de munca/proprietate LOCMUNCA in fiecare select/procedura apelata
		select cm.* into #conmed 
		from conmed cm
			left outer join istPers i on i.Data=cm.Data and i.Marca=cm.Marca
			left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=loc_de_munca
		where cm.Data between @dataJos and @dataSus
			and (@lm='' or i.Loc_de_munca like rtrim(@lm)+'%')
			and (@lista_lm=0 or lu.cod is not null) 

--	Pun tabela istpers intr-o tabela temporara pt. a nu face filtru pe loc de munca in fiecare select de mai jos
		Select i.* into #istpers 
		from istPers i
			left outer join personal p on p.Marca=i.Marca
			left outer join infopers ip on ip.Marca=i.Marca
			left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=i.loc_de_munca
		where i.Data=@dataSus 
			and (@lm='' or i.Loc_de_munca like rtrim(@lm)+'%')
			and (@lista_lm=0 or lu.cod is not null) 
			and not (convert(int,p.Loc_ramas_vacant)=1 and p.Data_plec<@datajos and upper(left(ip.Loc_munca_nou,7))='DETASAT')
			and (i.Grupa_de_munca in ('N','D','S','C') and (p.Loc_ramas_vacant=0 and exists (select 1 from net where net.marca=i.marca and net.data=i.data) or p.Loc_ramas_vacant=1)
				or exists (select 1 from net where net.marca=i.marca and net.data=i.data))
		create unique index [Data_Marca] ON #istpers (Data, Marca)

--	pun in tabela temporara ultima suspendare pentru ingrijire copil pana la 2 ani aferenta fiecarei marci
		select * into #ingrcopil from 
		(select Marca, Data_inceput, Data_sfarsit, Data_incetare, RANK() over (partition by Marca order by Data_inceput Desc) as ordine
		from fRevisalSuspendari ('01/01/1901', @dataSus, '') where Temei_legal in ('Art51Alin1LiteraA','Art51Alin1LiteraB')) a
		where ordine=1

--	citire obligatii bugetare pe coduri
		create table #D112CodObligatie
		(Cod_contributie char(20), Cod_declaratie char(20), Punct_de_lucru char(20), Data datetime, 
			Cod_bugetar char(20), Numar_evidenta_platii char(40), Suma_datorata decimal(10), Suma_deductibila decimal(10), 
			Suma_de_plata decimal(10), Suma_de_recuperat decimal(10), Explicatii char(200), Notatie char(100))
		insert into #D112CodObligatie
		exec Declaratia112CodObligatie @dataJos, @dataSus, @DataScad, @Cod_declaratie, @lm, @ContCASSAgricol, @ContImpozitAgricol

--	citire impozit pe puncte de lucru
		create table #D112Impozit
			(Data datetime, CodFiscal char(13), idCodFiscal int, Sediu char(2), Impozit decimal(10))
		insert into #D112Impozit
		exec Declaratia112Impozit @dataJos, @dataSus, @ImpozitPL, @lm

--	citire subventii
		create table #D112Subventii
			(Data datetime, TipSubventie int, Recuperat decimal(10), Restituit decimal(10))
		insert into #D112Subventii
		exec Declaratia112Subventii @dataJos, @dataSus, @lm

--	date privind tipul de asigurat
		create table #TagAsigurat 
			(Data datetime, Marca char(6), TagAsigurat char(20), Tip_asigurat int, Pensionar int, Tip_contract char(2), Tip_functie char(1), Regim_de_lucru float)
		insert into #TagAsigurat
		exec Declaratia112TagAsigurat @dataJos, @dataSus, @lm

--	citire date asigurati
		create table #D112Asigurati
		(Data datetime, TagAsigurat char(20), Marca char(6), Nume char(50), CNP char(13), Tip_asigurat int, Pensionar int, Tip_contract char(2), Tip_functie varchar(1), 
			Data_angajarii datetime, Total_zile int, Zile_CN int, Zile_CD int, Zile_CS int, TV decimal (10), TVN decimal (10), TVD decimal (10), TVS decimal (10), 
			Ore_norma int, IND_CS int, NRZ_CFP int, Norma_luna int,
			Zile_lucrate int, Ore_lucrate int, Zile_suspendate int, Ore_suspendate int, OreSST int, ZileSST int, BazaST int, 
			Venit_total decimal(10), Venit_fara_CM decimal(10), Baza_CAS decimal(10), CAS_individual decimal (10), 
			Baza_somaj decimal(10), Somaj_individual decimal(7), Baza_CASS decimal(10), CASS_individual decimal(7), Baza_FG decimal(10), Regim_de_lucru float, 
			Contributii_sociale decimal(10), Valoare_tichete decimal(10), nr_persintr int, Deduceri_personale decimal(10), Alte_deduceri decimal(10), 
			Baza_impozit decimal(10), Impozit decimal(10), Salar_net decimal(10), Tip_personal char(1))
		create unique index [Data_Marca_Locm] ON #D112Asigurati (Data, Marca, TagAsigurat, CNP, Tip_asigurat, Tip_contract, Tip_functie)
		insert into #D112Asigurati
		exec Declaratia112Asigurati @dataJos, @dataSus, null, @lm, 0, null, null

--	citire date angajator pentru BASS
		create table #D112BassAngajator 
		(Data datetime, VenitCN decimal(10), BassCN decimal(10), ScutireCN decimal(10), 
			VenitCD decimal(10), BassCD decimal(10), ScutireCD decimal(10), VenitCS decimal(10), BassCS decimal(10), ScutireCS decimal(10), 
			TotalVenit decimal(10), TotalBass decimal(10), TotalScutire decimal(10), CASAngajator decimal(10), BazaST decimal(10), 
			DeRecuperatBass decimal(10), DeRecuperatFambp decimal(10))
		insert into #D112BassAngajator
		exec Declaratia112BassAngajator @dataJos, @dataSus, null, @lm, 0

--	citire date angajator pentru FNUASS
		create table #D112CMFnuass
		(Data datetime, NrCazuriIT int, NrCazuriPI int, NrCazuriSL int, NrCazuriICB int, NrCazuriRM int, 
			ZileCM int, ZileCMIT int, ZileCMPI int, ZileCMSL int, ZileCMICB int, ZileCMRM int, 
			ZileCMIT_angajator int, ZileCMIT_fnuass int, ZileCMPI_fnuass int, ZileCMSL_fnuass int, ZileCMICB_fnuass int, ZileCMRM_fnuass int, 
			Indemniz_angajator decimal(10), IndemnizIT_angajator decimal(10), 
			IndemnizIT_fnuass decimal(10), IndemnizPI_fnuass decimal(10), IndemnizSL_fnuass decimal(10), IndemnizICB_fnuass decimal(10), IndemnizRM_fnuass decimal(10),
			Total_CCI_angajator decimal(10), Total_CCI_fambp decimal(10), Total_CCI decimal(10), 
			Indemniz_fnuass decimal(10), Total_recuperat decimal(10), Total_de_virat decimal(10), Ramas_de_recuperat decimal(10))
		insert into #D112CMFnuass 
		exec Declaratia112CMFnuass @dataJos, @dataSus, null, @lm, 0

--	citire date angajator pentru FAAMBP
		Create table #D112CMFambp
		(Data datetime, NrCazuriIT int, NrCazuriTT int, NrCazuriRT int, NrCazuriCC int, ZileCM int, ZileCMIT int, ZileCMTT int, ZileCMRT int, ZileCMCC int, 
			Indemnizatie decimal(10), IndemnizatieIT decimal(10), IndemnizatieTT decimal(10), IndemnizatieRT decimal(10), IndemnizatieCC decimal(10), 
			IndemnizatieFambp decimal(10), IndemnizITFambp decimal(10), IndemnizTTFambp decimal(10), IndemnizRTFambp decimal(10), IndemnizCCFambp decimal(10), 
			NrCazuriAjDeces int, SumaAjDeces decimal(10))
		insert into #D112CMFambp
		exec Declaratia112CMFambp @dataJos, @dataSus, null, @lm, 0

--	citire date CM pe asigurati = CNP
		create table #D112CMAsigurat
		(Data datetime, TagAsigurat char(20), Marca char(6), CNP char(13), Zile_prestatii_CN int, Zile_prestatii_CD int, Zile_prestatii_CS int, 
			Zile_CM_fnuass int, Zile_CM_faambp int, Zile_faambp int, NRZ_CFP int, Baza_CASCM decimal (10), 
			Indemniz_angajator_faambp decimal(10), Indemniz_Faambp decimal(10), Total_indemniz decimal(10),
			Indemniz_angajator_fnuass decimal(10), Indemniz_fnuass decimal(10))
		insert into #D112CMAsigurat
		exec Declaratia112CMAsigurat @dataJos, @dataSus, @lm

--	citire date pentru concedii si indemnizatii (sectiunea AsiguratD)
		Create table #D112DateCCI
		(TipD int, Tip_rectificare char(1), Data datetime, Marca char(6), 
			Tip_diagnostic char(2), Data_inceput datetime, Data_sfarsit datetime, Zile_luna_anterioara int, Nume_asig char(50), 
			CNP char(13), Cnp_copil char(13), CAS_asig char(2), Total_zile_lucrate int, Serie_CCM char(5), Numar_CCM char(10), Serie_CCM_initial char(5), Numar_CCM_initial char(10), 
			Data_acordarii datetime, Cod_indemnizatie char(2), Zile_prestatii_ang int, Zile_prestatii_Fnuass int, Zile_prestatii int, Loc_prescriere int, 
			Indemnizatie_ang decimal(10), Indemnizatie_Fnuass decimal(10), Cod_urgenta char(3), Cod_boala_grpA char(2), Baza_calcul decimal(10), Zile_baza_calcul int, 
			Media_zilnica decimal(10,4), Nr_aviz_me char(10), P_faambp decimal(10))
		insert into #D112DateCCI
		exec Declaratia112DateCCI @dataJos, @dataSus, null, 0, @lm, 0, null, null, 0

--	Incep calculele
		select @totalPlata_A=sum(Suma_de_plata) 
		from #D112CodObligatie
		where Cod_contributie<>'810'
--	calcul totaluri pt. somaj
		select @NrAsigSomaj=count (distinct p.Cod_numeric_personal), @BazaSomajAsigurati=isnull(sum(Asig_sanatate_din_cas),0), @SomajAngajator=isnull(sum(somaj_5),0)
		from #net n 
			left outer join personal p on n.Marca=p.Marca 
			left outer join #istpers i on i.Data=n.Data and i.Marca=n.Marca 
		where n.data=@dataSus and (n.somaj_1+n.somaj_5<>0 or exists (select c.Marca from conmed c where c.Data=@dataSus and c.Marca=n.Marca and c.Tip_diagnostic<>'0-' and c.Indemnizatie_CAS<>0) 
			and p.coef_invalid<>5 and p.Somaj_1<>0)
			and not (i.Grupa_de_munca='O' and i.Tip_colab in ('DAC','CCC','ECT'))
		select @NrAsigSomajAlte=count (distinct p.Cod_numeric_personal) 
		from #net n 
			left outer join #istpers i on i.data=n.data and i.marca=n.marca
			left outer join personal p on n.Marca=p.Marca 
		where n.data=@dataSus and n.somaj_1<>0 and i.Grupa_de_munca='O' and i.tip_colab in ('DAC','CCC','ECT')
--	calcul totaluri pt. fond de garantare
		select @BazaFondGarantare=isnull(sum((case when YEAR(n.Data)<=2011 or n.CM_incasat=0 then isnull(n1.Asig_sanatate_din_CAS,0) else n.CM_incasat end)),0), 
			@FondGarantare=isnull(sum(n.somaj_5),0)
		from #net n 
			left outer join #net n1 on n1.Data=dbo.eom(n.Data) and n1.Marca=n.Marca
		where n.data=@dataJos and n.somaj_5<>0
--	calcul numar asigurati pt. CCI
		select @NrAsigCCI=count (distinct p.Cod_numeric_personal) 
		from #net n 
			left outer join personal p on n.Marca=p.Marca 
		where n.data=@dataSus and (n.ded_suplim<>0 or exists (select c.Marca from conmed c where c.Data=@dataSus and c.Marca=n.Marca and c.Tip_diagnostic<>'0-' and c.Indemnizatie_CAS<>0))
--	calcul numar asigurati pt. CAS
		select @NrAsigCAS=count (distinct p.Cod_numeric_personal) 
		from #net n 
			left outer join personal p on n.Marca=p.Marca 
			left outer join #net n1 on n1.data=dbo.bom(n.data) and n1.marca=n.marca
		where n.data=@dataSus and (n.cas+n1.cas<>0 or exists (select marca from fDeclaratia112Scutiri (@dataJos, @dataSus, 1, @lm) where Motiv_scutire=3 and Marca=n.Marca))

		select @brutSalarii=isnull(sum(Baza_CAS),0) from #net where data=@dataJos 
			and marca in (select marca from #net n1 where n1.Data=@dataSus and n1.ded_suplim<>0)
		select @C4_scutitaSo=isnull(round(convert(decimal(10),sum(Scutire_angajator)*@pSomajInd/100),0),0) from dbo.fDeclaratia112Scutiri (@dataJos, @dataSus, 0, @lm)

--Creare tabele
--		exec CreareTabeleD112 --am mutat crearea in +tabelePS.sql
--Golire tabele
		exec GolireTabeleD112 @dataJos, @dataSus
--Asigurati
		Create table #DateAsigurat (Data datetime, TagAsigurat char(20), Marca char(6), Nume char(50), CNP char(13), Tip_asigurat int, Pensionar int, Tip_contract char(2), --Tip_functie varchar(1), 
			Total_zile int, Zile_CN int, Zile_CD int, Zile_CS int, TV decimal (10), TVN decimal (10), TVD decimal (10), TVS decimal (10), 
			Ore_norma int, IND_CS int, NRZ_CFP int, Norma_luna int, Zile_lucrate int, Ore_lucrate int, Zile_suspendate int, Ore_suspendate int, 
			OreSST int, ZileSST int, BazaST int, Venit_total decimal(10), Venit_fara_CM decimal(10), 
			Baza_CAS decimal(10), CAS_individual decimal (10), Baza_somaj decimal(10), Somaj_individual decimal(7), 
			Baza_CASS decimal(10), CASS_individual decimal(7), Baza_FG decimal(10), 
			Zile_prestatii_CN int, Zile_prestatii_CD int, Zile_prestatii_CS int, Zile_faambp int, Zile_CM_fnuass int, 
			Baza_CASCM decimal(10), Zile_CM_faambp int, Indemniz_faambp decimal(10), Indemniz_angajator_faambp decimal(10), 
			Total_venit_prest decimal(10), Indemniz_angajator_fnuass decimal(10), Indemniz_fnuass decimal(10), 
			Contributii_sociale decimal(10), Valoare_tichete decimal(10), nr_persintr int, Deduceri_personale decimal(10), Alte_deduceri decimal(10), 
			Baza_impozit decimal(10), Impozit decimal(10), Salar_net decimal(10))
		Create Unique Clustered Index [Data_Marca_CNP] ON #DateAsigurat (Data Asc, Marca Asc, CNP Asc, TagAsigurat asc, Tip_asigurat Asc, Tip_contract Asc/*, Tip_functie Asc*/)

		insert into #DateAsigurat
		select a.Data, max(a.TagAsigurat), max(a.Marca), max(Nume), a.CNP, a.Tip_asigurat, max(a.Pensionar), a.Tip_contract, /*a.Tip_functie,*/ max(Total_zile), 
			(case when max(Zile_CN)+max(isnull(Zile_prestatii_CN,0))>max(Norma_luna)/max(Regim_de_lucru) 
				then max(Zile_CN)-(max(Zile_CN)+max(isnull(Zile_prestatii_CN,0))-max(Norma_luna)/max(Regim_de_lucru)) else max(Zile_CN) end) as Zile_CN, 
			(case when max(Zile_CD)+max(isnull(Zile_prestatii_CD,0))>max(Norma_luna)/max(Regim_de_lucru) 
				then max(Zile_CD)-(max(Zile_CD)+max(isnull(Zile_prestatii_CD,0))-max(Norma_luna)/max(Regim_de_lucru)) else max(Zile_CD) end) as Zile_CD, 
			(case when max(Zile_CS)+max(isnull(Zile_prestatii_CS,0))>max(Norma_luna)/max(Regim_de_lucru) 
				then max(Zile_CS)-(max(Zile_CS)+max(isnull(Zile_prestatii_CS,0))-max(Norma_luna)/max(Regim_de_lucru)) else max(Zile_CS) end) as Zile_CS,
			sum(TV), sum(TVN), sum(TVD), sum(TVS), max(Ore_norma), max(IND_CS), max(a.NRZ_CFP), max(Norma_luna),
			(case when max(Zile_lucrate)+max(Zile_suspendate)>max(Norma_luna)/max(Regim_de_lucru) 
				then max(Zile_lucrate)-(max(Zile_lucrate)+max(Zile_suspendate)-max(Norma_luna)/max(Regim_de_lucru)) else max(Zile_lucrate) end) as Zile_lucrate, 
			(case when max(Ore_lucrate)+max(Ore_suspendate)>max(Norma_luna) 
				then max(Ore_lucrate)-(max(Ore_lucrate)+max(Ore_suspendate)-max(Norma_luna)) else max(Ore_lucrate) end) as Ore_lucrate, 
			max(Zile_suspendate), max(Ore_suspendate), max(OreSST), max(ZileSST), max(BazaST), 
			sum(Venit_total), sum(Venit_fara_CM), sum(Baza_CAS), sum(CAS_individual), sum(Baza_somaj), 
			sum(Somaj_individual), sum(Baza_CASS), sum(CASS_individual), sum(Baza_FG), 
			isnull(max(Zile_prestatii_CN),0), isnull(max(Zile_prestatii_CD),0), isnull(max(Zile_prestatii_CS),0), isnull(max(Zile_faambp),0), 
			isnull(max(Zile_CM_fnuass),0), isnull(sum(Baza_CASCM),0), isnull(max(Zile_CM_faambp),0), isnull(sum(Indemniz_faambp),0), 
			isnull(sum(Indemniz_angajator_faambp),0), isnull(sum(Indemniz_angajator_faambp+Indemniz_faambp+Baza_CASCM),0),
			isnull(sum(Indemniz_angajator_fnuass),0), isnull(sum(Indemniz_fnuass),0), 
			sum(Contributii_sociale), sum(Valoare_tichete), max(nr_persintr), sum(Deduceri_personale), sum(Alte_deduceri), sum(Baza_impozit), sum(Impozit), sum(Salar_net)
		from #D112Asigurati a
			left outer join #D112CMAsigurat cm on cm.data=a.data and cm.Marca=a.Marca
		group by a.Data, a.TagAsigurat, a.CNP, a.Tip_asigurat, a.Tip_contract--, a.Tip_functie

--	calcul numar salariati (persoane cu contract de munca)
		select @NrSalariati=count (distinct cnp) 
		from #D112Asigurati  
		where Tip_asigurat='1'

		select @E1_venit=sum(Baza_CAS) from #DateAsigurat da where 'asiguratC' like rtrim(da.TagAsigurat)+'%'
		select @F1_suma=Impozit	from #D112Impozit where Sediu='P'
		select @F1_suma=isnull(@F1_suma,0)

--Populare tabele angajator
		insert into D112angajatorA (Data, Loc_de_munca, A_codOblig, A_codBugetar, A_datorat, A_deductibil, A_plata)
		select @dataSus, @lmUtilizator, rtrim(Cod_contributie) as A_codOblig, rtrim(Cod_bugetar) as A_codBugetar, rtrim(convert(char(15),Suma_datorata)) as A_datorat, 
		rtrim(convert(char(15),Suma_deductibila)) as A_deductibil, rtrim(convert(char(15),Suma_de_plata)) as A_plata
		from #D112CodObligatie
		where Cod_contributie<>'810'
	
		insert into D112angajatorB (Data, Loc_de_munca, B_cnp, B_sanatate, B_pensie, B_brutSalarii, B_sal, totalPlata_A, C1_11, C1_12 , C1_13, C1_21, C1_22, C1_23, 
			C1_31, C1_32, C1_33, C1_T1, C1_T2, C1_T, C1_T3, C1_5, C1_6, C1_7, 
			C2_11, C2_12, C2_13, C2_14, C2_15, C2_16, C2_21, C2_22, C2_24, C2_26, C2_31, C2_32, C2_34, C2_36, C2_41, C2_42, C2_44, C2_46, 
			C2_51, C2_52, C2_54, C2_56, C2_T6, C2_7, C2_8, C2_9, C2_10, C2_110, C2_120, C2_130, 
			C3_11, C3_12, C3_13, C3_14,	C3_21, C3_22, C3_23, C3_24,	C3_31, C3_32, C3_33, C3_34,
			C3_41, C3_42, C3_43, C3_44, C3_total, C3_suma, C3_aj_nr, C3_aj_suma,C4_scutitaSo, 
			C6_baza, C6_ct, C7_baza, C7_ct, D1, E1_venit, F1_suma)
		select @dataSus, @lmUtilizator, rtrim(convert(char(6),@NrAsigSomaj)) as B_cnp, rtrim(convert(char(6),@NrAsigCCI)) as B_sanatate, rtrim(convert(char(5),@NrAsigCAS)) as B_pensie, 
			rtrim(convert(char(15),@brutSalarii)) as B_brutSalarii, rtrim(convert(char(6),@NrSalariati)) as B_sal, rtrim(convert(char(15),@totalPlata_A)), 
			rtrim(convert(char(10),c1.VenitCN)) as C1_11, rtrim(convert(char(10),c1.BassCN)) as C1_12, rtrim(convert(char(10),c1.ScutireCN)) as C1_13, 
			rtrim(convert(char(10),c1.VenitCD)) as C1_21, rtrim(convert(char(10),c1.BassCD)) as C1_22, rtrim(convert(char(10),c1.ScutireCD)) as C1_23, 
			rtrim(convert(char(10),c1.VenitCS)) as C1_31, rtrim(convert(char(10),c1.BassCS)) as C1_32, rtrim(convert(char(10),c1.ScutireCS)) as C1_33, 
			rtrim(convert(char(10),c1.TotalVenit)) as C1_T1, rtrim(convert(char(10),c1.TotalBass)) as C1_T2, rtrim(convert(char(10),c1.TotalScutire)) as C1_T, 
			rtrim(convert(char(10),c1.CASAngajator)) as C1_T3, rtrim(convert(char(10),c1.BazaST)) as C1_5, 
			rtrim(convert(char(10),c1.DeRecuperatBass)) as C1_6, rtrim(convert(char(10),c1.DeRecuperatFambp)) as C1_7,
			rtrim(convert(char(6),c2.NrCazuriIT)) as C2_11, rtrim(convert(char(5),c2.ZileCMIT)) as C2_12, 
			rtrim(convert(char(5),c2.ZileCMIT_angajator)) as C2_13, rtrim(convert(char(5),c2.ZileCMIT_fnuass)) as C2_14, 
			rtrim(convert(char(10),c2.IndemnizIT_angajator)) as C2_15, rtrim(convert(char(10),c2.IndemnizIT_fnuass)) as C2_16, 
			rtrim(convert(char(6),c2.NrCazuriPI)) as C2_21, rtrim(convert(char(5),c2.ZileCMPI)) as C2_22, 
			rtrim(convert(char(5),c2.ZileCMPI_fnuass)) as C2_24, rtrim(convert(char(10),c2.IndemnizPI_fnuass)) as C2_26,
			rtrim(convert(char(6),c2.NrCazuriSL)) as C2_31, rtrim(convert(char(5),c2.ZileCMSL)) as C2_32, 
			rtrim(convert(char(5),c2.ZileCMSL_fnuass)) as C2_34, rtrim(convert(char(10),c2.IndemnizSL_fnuass)) as C2_36, 
			rtrim(convert(char(6),c2.NrCazuriICB)) as C2_41, rtrim(convert(char(5),c2.ZileCMICB)) as C2_42, rtrim(convert(char(5),c2.ZileCMICB_fnuass)) as C2_44, 
			rtrim(convert(char(10),c2.IndemnizICB_fnuass)) as C2_46, 
			rtrim(convert(char(6),c2.NrCazuriRM)) as C2_51, rtrim(convert(char(5),c2.ZileCMRM)) as C2_52, rtrim(convert(char(5),c2.ZileCMRM_fnuass)) as C2_54, 
			rtrim(convert(char(10),c2.IndemnizRM_fnuass)) as C2_56, rtrim(convert(char(10),c2.Indemniz_fnuass)) as C2_T6, 
			rtrim(convert(char(10),c2.Total_CCI_angajator)) as C2_7, rtrim(convert(char(10),c2.Total_CCI_fambp)) as C2_8, 
			rtrim(convert(char(10),c2.Total_CCI)) as C2_9, 
			rtrim(convert(char(10),c2.Indemniz_fnuass)) as C2_10, rtrim(convert(char(10),c2.Total_recuperat)) as C2_110, 
			rtrim(convert(char(10),c2.Total_de_virat)) as C2_120, rtrim(convert(char(10),c2.Ramas_de_recuperat)) as C2_130,
			rtrim(convert(char(6),c3.NrCazuriIT)) as C3_11, rtrim(convert(char(5),c3.ZileCMIT)) as C3_12,
			rtrim(convert(char(10),c3.IndemnizatieIT)) as C3_13, rtrim(convert(char(6),c3.IndemnizITFambp)) as C3_14,
			rtrim(convert(char(6),c3.NrCazuriTT)) as C3_21, rtrim(convert(char(5),c3.ZileCMTT)) as C3_22,
			rtrim(convert(char(10),c3.IndemnizatieTT)) as C3_23, rtrim(convert(char(10),c3.IndemnizTTFambp)) as C3_24,
			rtrim(convert(char(6),c3.NrCazuriRT)) as C3_31, rtrim(convert(char(5),c3.ZileCMRT)) as C3_32,
			rtrim(convert(char(10),c3.IndemnizatieRT)) as C3_33, rtrim(convert(char(6),c3.IndemnizRTFambp)) as C3_34,
			rtrim(convert(char(6),c3.NrCazuriCC)) as C3_41, rtrim(convert(char(5),c3.ZileCMCC)) as C3_42,
			rtrim(convert(char(10),c3.IndemnizatieCC)) as C3_43, rtrim(convert(char(10),c3.IndemnizCCFambp)) as C3_44,
			rtrim(convert(char(10),c3.Indemnizatie)) as C3_total, rtrim(convert(char(10),c3.IndemnizatieFambp)) as C3_suma, 
			rtrim(convert(char(6),c3.NrCazuriAjDeces)) as C3_aj_nr, rtrim(convert(char(10),c3.SumaAjDeces)) as C3_aj_suma, 
			rtrim(convert(char(10),@C4_scutitaSo)), rtrim(convert(char(10),@BazaSomajAsigurati)) as C6_baza, 
			rtrim(convert(char(15),@SomajAngajator+@C4_scutitaSo)) as C6_ct, 
			rtrim(convert(char(15),@BazaFondGarantare)) as C7_baza, rtrim(convert(char(15),@FondGarantare)) as C7_ct, 
			rtrim(convert(char(15),@NrAsigSomajAlte)) as D1, rtrim(convert(char(15),@E1_venit)) as E1_venit, rtrim(convert(char(15),@F1_suma)) as F1_suma 
		from #D112BassAngajator c1
			left outer join #D112CMFnuass c2 on 1=1
			left outer join #D112CMFambp c3 on 1=1

		insert into D112angajatorC5 (Data, Loc_de_munca, C5_subv, C5_recuperat, C5_restituit) 
		select Data, @lmUtilizator, rtrim(convert(char(10),TipSubventie)) as C5_subv, rtrim(convert(char(10),Recuperat)) as C5_recuperat, 
			rtrim(convert(char(10),Restituit)) as C5_restituit
		from #D112Subventii

		insert into D112angajatorF2 (Data, Loc_de_munca, F2_cif, F2_id, F2_suma)
		select @dataSus, @lmUtilizator, rtrim(CodFiscal) as F2_cif, rtrim(convert(char(10),idCodFiscal)) as F2_id, 
			rtrim(convert(char(10),Impozit)) as F2_suma 
		from #D112Impozit where Sediu='S' and (Impozit<>0 or @ImpPLFaraSal=1)

		create table #idasig (cnp char(13), idAsig int identity(1,1))
		insert into #idasig
		select distinct p.Cod_numeric_personal 
		from #istpers i
			left outer join personal p on i.marca=p.marca
			left outer join #net n on i.Marca=n.Marca and n.Data=@dataSus
		where i.data=@dataSus and (@lm='' or i.Loc_de_munca like rtrim(@lm)+'%')
		
--	inserez idasig pentru asiguratii din Activitati Agricole
		insert into #idasig
		select distinct a.CNP
		from dbo.fDecl112ActivAgricole (@dataJos, @dataSus, @lm, @ContCASSAgricol, @ContImpozitAgricol) a 
		where Tip_contributie='AS' and not exists (select cnp from #idasig b where b.cnp=a.cnp)

--	inserez idasig pentru asiguratii din zilieri
		insert into #idasig
		select distinct a.Cod_numeric_personal
		from #Zilieri a 
		where not exists (select cnp from #idasig b where b.cnp=a.Cod_numeric_personal)

--	Populare tabele asigurati
		insert into D112Asigurat (Data, Loc_de_munca, cnpAsig, idAsig, numeAsig, prenAsig, cnpAnt, numeAnt, prenAnt, dataAng, dataSf, casaSn, asigCI, asigSO)
		select @dataSus, @lmUtilizator, rtrim(p.Cod_numeric_personal) as cnpAsig, rtrim(convert(char(6),max(id.idAsig))) as idAsig,
			max(rtrim(left(i.nume, charindex(' ',i.nume)))) as numeAsig, max(rtrim(substring(i.nume,charindex(' ',i.nume)+1,25))) as prenAsig,
			'' as cnpAnt, '' as numeAnt, '' as prenAnt, 
			convert(char(10),min((case when isnull(ic.Data_incetare,'01/01/1901')<>'01/01/1901' and ic.Data_incetare<=@dataSus then ic.Data_incetare else p.Data_angajarii_in_unitate end)),104) as dataAng,
			isnull(convert(char(10),min((case when p.Loc_ramas_vacant=1 and dbo.eom(p.Data_plec)=@dataSus 
				then p.Data_plec
				when isnull(ic.Data_inceput,'01/01/1901')<>'01/01/1901' and isnull(ic.Data_incetare,'01/01/1901')='01/01/1901' 
					and ic.Data_sfarsit>@dataSus then ic.Data_inceput end)),104),'') as dataSf,
			max(rtrim(p.Adresa)) as casaSn, rtrim((case when max(n.Ded_suplim)<>0 or isnull(max(cm.Indemnizatie_CAS),0)<>0 then '1' else '2' end)) as asigCI, 
			rtrim((case when max(n.Somaj_1+n.Somaj_5)<>0 or isnull(max(cm.Indemnizatie_CAS),0)<>0 and max(p.coef_invalid)<>5 then '1' else '2' end)) as asigSO
		from #istpers i
			left outer join personal p on i.marca=p.marca
			left outer join #net n on i.Marca=n.Marca and n.Data=@dataSus
			left outer join #idasig id on id.CNP=p.Cod_numeric_personal
			left outer join #ingrcopil ic on ic.Marca=i.Marca 
			left outer join (select Data, Marca, sum(Indemnizatie_CAS) as Indemnizatie_CAS 
				from conmed c where c.Data=@dataSus and c.Tip_diagnostic<>'0-' group by c.Data, c.Marca) cm on i.Data=cm.Data and i.Marca=cm.Marca
		where i.data=@dataSus
		group by p.Cod_numeric_personal

--	daca exista pe CNP o marca activa, DataSf trebuie sa fie necompletata
		update d set DataSf=''
		from D112Asigurat d
		where Data=@dataSus and (@multiFirma=0 or @lm='' or d.Loc_de_munca like rtrim(@lm)+'%')
			and exists (select 1 from #istpers i inner join personal p on i.Marca=p.Marca where i.data=@dataSus and p.Cod_numeric_personal=d.cnpAsig and p.Loc_ramas_vacant=1)
			and exists (select 1 from #istpers i inner join personal p on i.Marca=p.Marca where i.data=@dataSus and p.Cod_numeric_personal=d.cnpAsig and p.Loc_ramas_vacant=0)

--	inserez asiguratii din Activitati Agricole
		insert into D112Asigurat (Data, Loc_de_munca, cnpAsig, idAsig, numeAsig, prenAsig, cnpAnt, numeAnt, prenAnt, dataAng, dataSf, casaSn, asigCI, asigSO)		
		select @dataSus, @lmUtilizator, rtrim(a.cnp) as cnpAsig, rtrim(convert(char(6),id.idAsig)) as idAsig,
			rtrim(left(a.nume, charindex(' ',a.nume))) as numeAsig, rtrim(substring(a.nume,charindex(' ',a.nume)+1,25)) as prenAsig,
			'' as cnpAnt, '' as numeAnt, '' as prenAnt, convert(char(10),@dataJos,104) as dataAng,
			convert(char(10),@dataSus,104) as dataSf, rtrim(a.Casa_sanatate) as casaSn, '2' as asigCI, '2' as asigSO
		from dbo.fDecl112ActivAgricole (@dataJos, @dataSus, @lm, @ContCASSAgricol, @ContImpozitAgricol) a
			left outer join #idasig id on id.CNP=a.Cnp
		where Tip_contributie='AS' and not exists (select cnpAsig from D112Asigurat b where b.Data=@dataSus and b.cnpAsig=a.cnp and (@lmUtilizator is null or b.Loc_de_munca like rtrim(@lmUtilizator)+'%'))

--	inserez asiguratii din zilieri
		insert into D112Asigurat (Data, Loc_de_munca, cnpAsig, idAsig, numeAsig, prenAsig, cnpAnt, numeAnt, prenAnt, dataAng, dataSf, casaSn, asigCI, asigSO)		
		select @dataSus, @lmUtilizator, rtrim(a.Cod_numeric_personal) as cnpAsig, rtrim(convert(char(6),id.idAsig)) as idAsig,
			max(rtrim(left(a.nume, charindex(' ',a.nume)))) as numeAsig, max(rtrim(substring(a.nume,charindex(' ',a.nume)+1,25))) as prenAsig,
			'' as cnpAnt, '' as numeAnt, '' as prenAnt, min(convert(char(10),a.Data_angajarii,104)) as dataAng,
			max(convert(char(10),(case when a.Plecat=1 and dbo.eom(a.Data_plecarii)=@dataSus then a.Data_plecarii end),104)) as dataSf, 
			rtrim(@casaAng) as casaSn, '2' as asigCI, '2' as asigSO
		from #zilieri a
			left outer join #idasig id on id.CNP=a.Cod_numeric_personal
		where not exists (select cnpAsig from D112Asigurat b where b.Data=@dataSus and b.cnpAsig=a.Cod_numeric_personal and (@lmUtilizator is null or b.Loc_de_munca like rtrim(@lmUtilizator)+'%'))
		group BY a.cod_numeric_personal, id.idAsig
		
		insert into D112coAsigurati (Data, Loc_de_munca, cnpAsig, tip, cnp, nume, prenume)
		select @dataSus, @lmUtilizator, p.Cod_numeric_personal, (case when max(a.tip_intretinut) in ('R','I') then 'P' else max(tip_intretinut) end) as "@tip" , rtrim(a.cod_personal) as "@cnp" , 
			max(rtrim(left(a.nume_pren, charindex(' ',a.nume_pren)))) as "@nume", max(rtrim(substring(a.nume_pren,charindex(' ',a.nume_pren)+1,25))) as "@prenume"  
		from persintr a 
			inner join personal p on p.marca=a.marca
			inner join #istPers i on i.Data=a.Data and i.marca=a.marca
			inner join #idasig id on id.CNP=p.Cod_numeric_personal
		where a.data=@dataSus and a.Tip_intretinut in ('S','R','I') and (@lm='' or i.Loc_de_munca like rtrim(@lm)+'%')
		group by p.Cod_numeric_personal, a.Cod_personal

		insert into D112AsiguratA (Data, Loc_de_munca, cnpAsig, A_1, A_2, A_3, A_4, A_5, A_6, A_7, A_8, A_9, A_10, A_11, A_12, A_13, A_14, A_20)
		select @dataSus, @lmUtilizator, da.cnp as cnpAsig, rtrim(convert(char(2),Tip_asigurat)) as A_1, rtrim(convert(char(1),Pensionar)) as A_2, 
			rtrim(Tip_contract) as A_3, rtrim(convert(char(1),Ore_norma)) as A_4, rtrim(convert(char(10),Baza_FG)) as A_5, 
			rtrim(convert(char(3),Ore_lucrate)) as A_6, rtrim(convert(char(3),Ore_suspendate)) as A_7, 
			rtrim(convert(char(5),Zile_lucrate)) as A_8, rtrim(convert(char(10),Baza_somaj)) as A_9,	
			rtrim(convert(char(10),Somaj_individual)) as A_10, rtrim(convert(char(10),Baza_CASS)) as A_11, 
			rtrim(convert(char(10),CASS_individual)) as A_12, rtrim(convert(char(10),Baza_CAS)) as A_13, 
			rtrim(convert(char(10),CAS_individual)) as A_14, rtrim(convert(char(10),TVN+TVD+TVS/*Baza_CASS*/)) as A_20
		from #DateAsigurat da 
			left outer join #idasig id on id.CNP=da.CNP
		where 'asiguratA' like rtrim(da.TagAsigurat)+'%'

		insert into D112AsiguratB1 (Data, Loc_de_munca, cnpAsig, B1_1, B1_2, B1_3, B1_4, B1_5, B1_6, B1_7, B1_8, B1_9 , B1_10, B1_15)
		select @dataSus, @lmUtilizator, da.cnp as cnpAsig, rtrim(convert(char(2),Tip_asigurat)) as B1_1, rtrim(convert(char(1),Pensionar)) as B1_2, 
			rtrim(Tip_contract) as B1_3, rtrim(convert(char(1),Ore_norma)) as B1_4, rtrim(convert(char(10),Baza_FG)) as B1_5,
			rtrim(convert(char(3),Ore_lucrate)) as B1_6, rtrim(convert(char(3),Ore_suspendate)) as B1_7, 
			rtrim(convert(char(5),OreSST)) as B1_8, rtrim(convert(char(5),ZileSST)) as B1_9,
			rtrim(convert(char(10),Baza_somaj)) as B1_10, rtrim(convert(char(10),Zile_lucrate)) as B1_15
		from #DateAsigurat da 
			left outer join #idasig id on id.CNP=da.CNP
		where 'asiguratB1' like rtrim(da.TagAsigurat)+'%' 

		insert into D112AsiguratB11 (Data, Loc_de_munca, cnpAsig, B11_1, B11_2, B11_3, B11_41, B11_42, B11_43, B11_5, B11_6, B11_71, B11_72, B11_73)
		select @dataSus, @lmUtilizator, sc.cnp as cnpAsig, rtrim(convert(char(2),Motiv_scutire)) as B11_1, 
			rtrim(convert(char(10),Scutire_angajator)) as B11_2, rtrim(convert(char(10),Scutire_angajator)) as B11_3, 
			rtrim(convert(char(10),Scutire_angajator_CN)) as B11_41, rtrim(convert(char(10),Scutire_angajator_CD)) as B11_42, 
			rtrim(convert(char(10),Scutire_angajator_CS)) as B11_43, rtrim(convert(char(10),Scutire_asigurat)) as B11_5, 
			rtrim(convert(char(10),Scutire_asigurat)) as B11_6, rtrim(convert(char(10),Scutire_asigurat_CN)) as B11_71, 
			rtrim(convert(char(10),Scutire_asigurat_CD)) as B11_72, rtrim(convert(char(10),Scutire_asigurat_CS)) as B11_73
		from dbo.fDeclaratia112Scutiri (@dataJos, @dataSus, 0, @lm) sc 
			left outer join personal p on p.marca=sc.marca
			left outer join #idasig id on id.CNP=p.Cod_numeric_personal

		insert into D112AsiguratB234 (Data, Loc_de_munca, cnpAsig, B2_1, B2_2, B2_3, B2_4, B2_5, B2_6, B2_7, B3_1, B3_2, B3_3, B3_4, B3_5, B3_6, B3_7, B3_8, B3_9, 
			B3_10, B3_11, B3_12, B3_13, B4_1, B4_2, B4_3, B4_4, B4_5, B4_6, B4_7, B4_8, B4_14)
		select @dataSus, @lmUtilizator, da.cnp as cnpAsig, 
			rtrim(convert(char(2),max(IND_CS))) as B2_1, rtrim(convert(char(2),max(Zile_CN))) as B2_2, 
			rtrim(convert(char(2),max(Zile_CD))) as B2_3, rtrim(convert(char(2),max(Zile_CS))) as B2_4, 
			rtrim(convert(char(10),sum(TVN))) as B2_5, rtrim(convert(char(10),sum(TVD))) as B2_6, rtrim(convert(char(10),sum(TVS))) as B2_7,
			rtrim(convert(char(2),max(Zile_prestatii_CN))) as B3_1, rtrim(convert(char(2),max(Zile_prestatii_CD))) as B3_2, 
			rtrim(convert(char(2),max(Zile_prestatii_CS))) as B3_3, rtrim(convert(char(2),max(Zile_faambp))) as B3_4, 
			'0' as B3_5, rtrim(convert(char(2),max(Zile_CM_fnuass))) as B3_6, rtrim(convert(char(10),sum(Baza_CASCM))) as B3_7, 
			rtrim(convert(char(2),max(Zile_CM_faambp))) as B3_8, rtrim(convert(char(10),sum(Indemniz_faambp))) as B3_9, 
			rtrim(convert(char(10),sum(Indemniz_angajator_faambp))) as B3_10, 
			rtrim(convert(char(10),sum(Total_venit_prest))) as B3_11,
			rtrim(convert(char(10),sum(Indemniz_angajator_fnuass))) as B3_12, rtrim(convert(char(10),sum(Indemniz_fnuass))) as B3_13,
			rtrim(convert(char(2),max(Zile_CN+Zile_CD+Zile_CS))) as B4_1, rtrim(convert(char(2),max(ZileSST))) as B4_2, 
			rtrim(convert(char(10),sum(Baza_somaj))) as B4_3, rtrim(convert(char(10),sum(Somaj_individual))) as B4_4, 
			rtrim(convert(char(10),sum(Baza_CASS))) as B4_5, rtrim(convert(char(10),sum(CASS_individual))) as B4_6, 
			rtrim(convert(char(10),(case when sum(Baza_CAS)>5*@SalMediu then 5*@SalMediu else sum(Baza_CAS) end))) as B4_7, 
			rtrim(convert(char(10),sum(CAS_individual))) as B4_8, 
			rtrim(convert(char(10),sum(Baza_FG))) as B4_14
		from #DateAsigurat da 
			left outer join #idasig id on id.CNP=da.CNP
		where 'asiguratB2' like rtrim(da.TagAsigurat)+'%' 
		group by da.CNP, id.idAsig

		insert into D112AsiguratC (Data, Loc_de_munca, cnpAsig, C_1, C_2, C_3, C_4, C_5, C_6, C_7, C_8, C_9, C_10, C_11, C_17, C_18, C_19)
		select @dataSus, @lmUtilizator, da.cnp as cnpAsig, rtrim(convert(char(2),Tip_asigurat)) as C_1, rtrim(convert(char(5),Zile_CN)) as C_2, 
			'0' as C_3, '0' as C_4, '0' as C_5, rtrim(convert(char(10),Baza_somaj)) as C_6,	rtrim(convert(char(10),Somaj_individual)) as C_7, 
			rtrim(convert(char(10),Baza_CASS)) as C_8, rtrim(convert(char(10),CASS_individual)) as C_9, 
			rtrim(convert(char(10),Baza_CAS)) as C_10, rtrim(convert(char(10),CAS_individual)) as C_11, 
			'0' as C_17, '0' as C_18, rtrim(convert(char(10),Baza_CAS)) as C_19
		from #DateAsigurat da 
			left outer join #idasig id on id.CNP=da.CNP
		where 'asiguratC' like rtrim(da.TagAsigurat)+'%'
		union all
		select @dataSus, @lmUtilizator, cnp, (case when @dataJos>='01/01/2014' then '26' else '21' end) as C_1, '0' as C_2, '0' as C_3, '0' as C_4, '0' as C_5, '0' as C_6, '0' as C_7, 
		rtrim(convert(char(10),Baza)) as C_8, rtrim(convert(char(10),Contributie)) as C_9, 			
		'0' as C_10, '0' as C_11, '0' as C_17, '0' as C_18, '0' as C_19
		from dbo.fDecl112ActivAgricole (@dataJos, @dataSus, @lm, @ContCASSAgricol, @ContImpozitAgricol) where Tip_contributie='AS'

		insert into D112AsiguratD (Data, Loc_de_munca, cnpAsig, D_1, D_2, D_3, D_4, D_5, D_6, D_7, D_8, D_9, D_10, D_11, D_12, D_13, D_14, D_15, D_16, D_17, D_18, D_19, D_20, D_21)
		select @dataSus, @lmUtilizator, a.cnp as cnpAsig, rtrim(Serie_CCM) as "@D_1", rtrim(Numar_CCM) as "@D_2", 
			(case when rtrim(Serie_CCM_initial)<>'' then rtrim(Serie_CCM_initial) end) as "@D_3", 
			(case when rtrim(Numar_CCM_initial)<>'' then rtrim(Numar_CCM_initial) end) as "@D_4",
			convert(char(10),Data_acordarii,104) as "@D_5", convert(char(10),Data_inceput,104) as "@D_6", convert(char(10),Data_sfarsit,104) as "@D_7", 
			(case when rtrim(Cnp_copil)<>'' then rtrim(Cnp_copil) end) as "@D_8", rtrim(Cod_indemnizatie) as "@D_9", rtrim(convert(char(2),loc_prescriere)) as "@D_10",
			(case when rtrim(Cod_urgenta)<>'' then rtrim(Cod_urgenta) end) as "@D_11", (case when rtrim(Cod_boala_grpA)<>'' then rtrim(Cod_boala_grpA) end) as "@D_12", 
			(case when rtrim(Nr_aviz_me)<>'' then rtrim(Nr_aviz_me) end) as "@D_13", rtrim(convert(char(3),Zile_prestatii_ang)) as "@D_14", 
			rtrim(convert(char(3),Zile_prestatii_Fnuass)) as "@D_15", rtrim(convert(char(3),Zile_prestatii)) as "@D_16", 
			rtrim(convert(char(10),Baza_calcul)) as "@D_17", rtrim(convert(char(10),Zile_baza_calcul)) as "@D_18", 
			(case when a.data_inceput<'02/01/2011' then rtrim(convert(char(10),Media_zilnica)) else rtrim(convert(char(10),round(convert(decimal(6,2),Media_zilnica),2))) end) as "@D_19", 
			rtrim(convert(char(10),Indemnizatie_ang)) as "@D_20", 
			rtrim(convert(char(10),Indemnizatie_Fnuass)) as "@D_21"
		from #D112DateCCI a
			left outer join #idasig id on id.CNP=a.CNP

		if @versiune>='2'
			insert into D112AsiguratE3 (Data, Loc_de_munca, cnpAsig, E3_1, E3_2, E3_3, E3_4, E3_5, E3_6, E3_7, E3_8, E3_9, E3_10, E3_11, E3_12, E3_13, E3_14, E3_15, E3_16)
			select a.Data, @lmUtilizator, a.CNP, 
				right(rtrim(a.TagAsigurat),1) as E3_1, rtrim(a.Tip_asigurat) as E3_2, rtrim(a.Tip_functie) as E3_3, 
				'P' as E3_4, '' as E3_5, '' as E3_6, '' as E3_7, --E3_4=P - venituri din perioada de raportare, E3_4=A - venituri din alta perioada
				rtrim(convert(char(15),sum(a.Venit_total))) as E3_8, rtrim(convert(char(15),sum(a.Contributii_sociale))) as E3_9, rtrim(convert(char(15),sum(a.Valoare_tichete))) as E3_10, 
				rtrim(convert(char(15),max(a.nr_persintr))) as E3_11, rtrim(convert(char(15),sum(a.Deduceri_personale))) as E3_12, rtrim(convert(char(15),sum(a.Alte_deduceri))) as E3_13, 
				rtrim(convert(char(15),sum(a.Baza_impozit))) as E3_14, rtrim(convert(char(15),sum(a.Impozit))) as E3_15, rtrim(convert(char(15),sum(a.Salar_net))) as E3_16
			from #D112Asigurati a
			group by a.Data, a.TagAsigurat, a.CNP, a.Tip_asigurat, a.Tip_functie
			union all 
			select @dataSus, @lmUtilizator, s.cnp, 'C' as E3_1, '26' as E3_2, '3' as E3_3, 'P' as E3_4, '' as E3_5, '' as E3_6, '' as E3_7, 
				rtrim(convert(char(10),s.Baza)) as E3_8, rtrim(convert(char(10),s.Contributie)) as E3_9, '0' as E3_10, '0' as E3_11, '0' as E3_12, '0' as E3_13, 
				rtrim(convert(char(10),isnull(i.Baza,0))) as E3_14, rtrim(convert(char(10),isnull(i.Contributie,0))) as E3_15, '0' as E3_16 
			from dbo.fDecl112ActivAgricole (@dataJos, @dataSus, @lm, @ContCASSAgricol, @ContImpozitAgricol) s
				left outer join dbo.fDecl112ActivAgricole (@dataJos, @dataSus, @lm, @ContCASSAgricol, @ContImpozitAgricol) i on i.cnp=s.cnp and i.Tip_contributie='IM'
			where s.Tip_contributie='AS'

		drop table #net
		drop table #istPers
		drop table #DateAsigurat
		drop table #idasig
	End

--	Venituri din salarii obtinute la functia de baza
	create table #D112AsiguratE1 
		(Data datetime, Loc_de_munca varchar(9), cnpAsig varchar(13), E1_1 varchar(15), E1_2 varchar(15), E1_3 varchar(15), 
		E1_4 varchar(15), E1_5 varchar(15), E1_6 varchar(15), E1_7 varchar(15))
--	Venituri din salarii obtinute in afara functiei de baza
	create table #D112AsiguratE2 
		(Data datetime, Loc_de_munca varchar(9), cnpAsig varchar(13), E2_1 varchar(15), E2_2 varchar(15), E2_3 varchar(15), E2_4 varchar(15))

	if @versiune>='2'
	Begin
		insert into #D112AsiguratE1 (Data, Loc_de_munca, cnpAsig, E1_1, E1_2, E1_3, E1_4, E1_5, E1_6, E1_7)
		select Data, Loc_de_munca, cnpAsig, 
			rtrim(convert(char(15),sum(convert(decimal(10),isnull(e3.E3_8,0))))) as E1_1, rtrim(convert(char(15),sum(convert(decimal(10),isnull(e3.E3_9,0))))) as E1_2, 
			rtrim(convert(char(15),sum(convert(decimal(10),isnull(e3.E3_11,0))))) as E1_3, rtrim(convert(char(15),sum(convert(decimal(10),isnull(e3.E3_12,0))))) as E1_4, 
			rtrim(convert(char(15),sum(convert(decimal(10),isnull(e3.E3_13,0))))) as E1_5, rtrim(convert(char(15),sum(convert(decimal(10),isnull(e3.E3_14,0))))) as E1_6,
			rtrim(convert(char(15),sum(convert(decimal(10),isnull(e3.E3_15,0))))) as E1_7 
		from D112AsiguratE3 e3
			left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=e3.loc_de_munca
		where e3.Data=@dataSus and e3.E3_3='1'
			and (@multiFirma=0 or @lm='' or e3.Loc_de_munca like rtrim(@lm)+'%')
			and (@multiFirma=0 or @lista_lm=0 or lu.cod is not null) 
		group by Data, Loc_de_munca, cnpAsig

		insert into #D112AsiguratE2 (Data, Loc_de_munca, cnpAsig, E2_1, E2_2, E2_3, E2_4)
		select Data, Loc_de_munca, cnpAsig, 
			rtrim(convert(char(15),sum(convert(decimal(10),isnull(e3.E3_8,0))))) as E2_1, rtrim(convert(char(15),sum(convert(decimal(10),isnull(e3.E3_9,0))))) as E2_2, 
			rtrim(convert(char(15),sum(convert(decimal(10),isnull(e3.E3_14,0))))) as E2_3, rtrim(convert(char(15),sum(convert(decimal(10),isnull(e3.E3_15,0))))) as E2_4 
		from D112AsiguratE3 e3
			left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=e3.loc_de_munca
		where e3.Data=@dataSus and e3.E3_3='2'
			and (@multiFirma=0 or @lm='' or e3.Loc_de_munca like rtrim(@lm)+'%')
			and (@multiFirma=0 or @lista_lm=0 or lu.cod is not null) 
		group by Data, Loc_de_munca, cnpAsig
	End

--WITH XMLNAMESPACES (DEFAULT 'mfp:anaf:dgti:declaratie_unica:declaratie:v1')
	select @rezultat=
	(select rtrim(convert(char(2),@Luna)) as "@luna_r", convert(char(4),@An) as "@an_r", @tipdecl as "@d_rec", 
	(case when @tipdecl=1 and @dataJos>='07/01/2012' then @tipRectificare end) as "@tip_rec", rtrim(@numedecl) as "@nume_declar", 
	rtrim(@prendecl) as "@prenume_declar", rtrim(@functiedecl) as "@functie_declar", 
	(select rtrim(@cif) as "@cif", (case when rtrim(@rgCom)<>'' then rtrim(@rgCom) end) as "@rgCom", 
	rtrim(@caen) as "@caen", rtrim(@den) as "@den", rtrim(@adrSoc) as "@adrSoc", 
	(case when rtrim(@telSoc)<>'' then rtrim(@telSoc) end) as "@telSoc", (case when rtrim(@faxSoc)<>'' then rtrim(@faxSoc) end) as "@faxSoc", 
	(case when rtrim(@mailSoc)<>'' then rtrim(@mailSoc) end) as "@mailSoc", 
	(case when rtrim(@adrFisc)<>'' then rtrim(@adrFisc) end) as "@adrFisc", (case when rtrim(@telFisc)<>'' then rtrim(@telFisc) end) as "@telFisc", 
	(case when rtrim(@faxFisc)<>'' then rtrim(@faxFisc) end) as "@faxFisc", (case when rtrim(@mailFisc)<>'' then rtrim(@mailFisc) end) as "@mailFisc", 
	rtrim(@casaAng) as "@casaAng", rtrim(convert(char(10),@tRisc)) as "@tRisc", rtrim(@dat) as "@dat", 
	(select rtrim(totalPlata_A) from D112AngajatorB where Data=@dataSus and (@lmUtilizator is null or Loc_de_munca like rtrim(@lmUtilizator)+'%')) as "@totalPlata_A", 
			(select rtrim(A_codOblig) as "@A_codOblig", rtrim(A_codBugetar) as "@A_codBugetar", rtrim(A_datorat) as "@A_datorat", 
			rtrim(A_deductibil) as "@A_deductibil", rtrim(A_plata) as "@A_plata"
		from D112angajatorA where Data=@dataSus and (@lmUtilizator is null or Loc_de_munca like rtrim(@lmUtilizator)+'%') for xml path('angajatorA'), type),
	(select rtrim(B_cnp) as "@B_cnp", rtrim(B_sanatate) as "@B_sanatate", rtrim(B_pensie) as "@B_pensie", 
			rtrim(B_brutSalarii) as "@B_brutSalarii", (case when @versiune>='2' then rtrim(B_sal) end) as "@B_sal"
		from D112AngajatorB where Data=@dataSus and (@lmUtilizator is null or Loc_de_munca like rtrim(@lmUtilizator)+'%') for xml path('angajatorB'), type),
--	angajatorC1
	(select rtrim(C1_11) as "@C1_11", rtrim(C1_12) as "@C1_12", rtrim(C1_13) as "@C1_13", 
	rtrim(C1_21) as "@C1_21", rtrim(C1_22) as "@C1_22", rtrim(C1_23) as "@C1_23", 
	rtrim(C1_31) as "@C1_31", rtrim(C1_32) as "@C1_32", rtrim(C1_33) as "@C1_33", 
	rtrim(C1_T1) as "@C1_T1", rtrim(C1_T2) as "@C1_T2", rtrim(C1_T) as "@C1_T", 
	rtrim(C1_T3) as "@C1_T3", rtrim(C1_5) as "@C1_5", rtrim(C1_6) as "@C1_6", rtrim(C1_7) as "@C1_7"
	from D112AngajatorB where Data=@dataSus and (@lmUtilizator is null or Loc_de_munca like rtrim(@lmUtilizator)+'%') for xml path('angajatorC1'), type),
--	angajatorC2
	(select rtrim(C2_11) as "@C2_11", rtrim(C2_12) as "@C2_12", 
	rtrim(C2_13) as "@C2_13", rtrim(C2_14) as "@C2_14", rtrim(C2_15) as "@C2_15", rtrim(C2_16) as "@C2_16", 
	rtrim(C2_21) as "@C2_21", rtrim(C2_22) as "@C2_22", rtrim(C2_24) as "@C2_24", rtrim(C2_26) as "@C2_26",
	rtrim(C2_31) as "@C2_31", rtrim(C2_32) as "@C2_32", rtrim(C2_34) as "@C2_34", 
	rtrim(C2_36) as "@C2_36", rtrim(C2_41) as "@C2_41", rtrim(C2_42) as "@C2_42", rtrim(C2_44) as "@C2_44", 
	rtrim(C2_46) as "@C2_46", rtrim(C2_51) as "@C2_51", rtrim(C2_52) as "@C2_52", rtrim(C2_54) as "@C2_54", 
	rtrim(C2_56) as "@C2_56", rtrim(C2_T6) as "@C2_T6", rtrim(C2_7) as "@C2_7", rtrim(C2_8) as "@C2_8", 
	rtrim(C2_9) as "@C2_9", rtrim(C2_10) as "@C2_10", rtrim(C2_110) as "@C2_110", rtrim(C2_120) as "@C2_120", rtrim(C2_130) as "@C2_130"
	from D112AngajatorB where Data=@dataSus and (@lmUtilizator is null or Loc_de_munca like rtrim(@lmUtilizator)+'%') for xml path('angajatorC2'), type),
--	angajatorC3
	(select rtrim(C3_11) as "@C3_11", rtrim(C3_12) as "@C3_12",	rtrim(C3_13) as "@C3_13", rtrim(C3_14) as "@C3_14",	
	rtrim(C3_21) as "@C3_21", rtrim(C3_22) as "@C3_22",	rtrim(C3_23) as "@C3_23", rtrim(C3_24) as "@C3_24",
	rtrim(C3_31) as "@C3_31", rtrim(C3_32) as "@C3_32",	rtrim(C3_33) as "@C3_33", rtrim(C3_34) as "@C3_34",
	rtrim(C3_41) as "@C3_41", rtrim(C3_42) as "@C3_42",	rtrim(C3_43) as "@C3_43", rtrim(C3_44) as "@C3_44",
	rtrim(C3_total) as "@C3_total", rtrim(C3_suma) as "@C3_suma", rtrim(C3_aj_nr) as "@C3_aj_nr", rtrim(C3_aj_suma) as "@C3_aj_suma"
	from D112AngajatorB where Data=@dataSus and (@lmUtilizator is null or Loc_de_munca like rtrim(@lmUtilizator)+'%') for xml path('angajatorC3'), type),
--	angajatorC4
	(select rtrim(C4_scutitaSo) as "@C4_scutitaSo" from D112AngajatorB where Data=@dataSus 
		and (@lmUtilizator is null or Loc_de_munca like rtrim(@lmUtilizator)+'%') and C4_scutitaSo<>'' for xml path('angajatorC4'), type),
--	angajatorC5
	(select rtrim(C5_subv) as "@C5_subv", rtrim(C5_recuperat) as "@C5_recuperat", rtrim(C5_restituit) as "@C5_restituit"
		from D112angajatorC5 where Data=@dataSus and (@lmUtilizator is null or Loc_de_munca like rtrim(@lmUtilizator)+'%') for xml path('angajatorC5'), type),
--	angajatorC6
	(select rtrim(C6_baza) as "@C6_baza", rtrim(C6_ct) as "@C6_ct" from D112AngajatorB where Data=@dataSus and (@lmUtilizator is null or Loc_de_munca like rtrim(@lmUtilizator)+'%') for xml path('angajatorC6'), type),
--	angajatorC7
	(select rtrim(C7_baza) as "@C7_baza", rtrim(C7_ct) as "@C7_ct" from D112AngajatorB where Data=@dataSus and (@lmUtilizator is null or Loc_de_munca like rtrim(@lmUtilizator)+'%') 
		and C7_baza<>'' for xml path('angajatorC7'), type),
--	angajatorD
	(select rtrim(D1) as "@D1" from D112AngajatorB where Data=@dataSus and (@lmUtilizator is null or Loc_de_munca like rtrim(@lmUtilizator)+'%') and D1<>'' for xml path('angajatorD'), type),
--	angajatorE1
	(select rtrim(E1_venit) as "@E1_venit" from D112AngajatorB where Data=@dataSus and (@lmUtilizator is null or Loc_de_munca like rtrim(@lmUtilizator)+'%') and E1_venit<>'' for xml path('angajatorE1'), type),
--	angajatorF1
	(select rtrim(F1_suma) as "@F1_suma" from D112AngajatorB where Data=@dataSus and (@lmUtilizator is null or Loc_de_munca like rtrim(@lmUtilizator)+'%') for xml path('angajatorF1'), type),
--	angajatorF2
	(select rtrim(F2_cif) as "@F2_cif", rtrim(F2_id) as "@F2_id", rtrim(F2_suma) as "@F2_suma" 
	from D112AngajatorF2 where Data=@dataSus and (@lmUtilizator is null or Loc_de_munca like rtrim(@lmUtilizator)+'%') for xml path('angajatorF2'), type)
	for xml path('angajator'),  type),
--	asigurat
	(select rtrim(a.cnpAsig) as "@cnpAsig", rtrim(a.idAsig) as "@idAsig", rtrim(a.numeAsig) as "@numeAsig", rtrim(prenAsig) as "@prenAsig",
	(case when cnpAnt<>'' then cnpAnt end) as "@cnpAnt", (case when numeAnt<>'' then numeAnt end) as "@numeAnt", 
	(case when prenAnt<>'' then prenAnt end) as "@prenAnt", (case when dataAng<>'' then dataAng end) as "@dataAng", (case when dataSf<>'' then dataSf end) as "@dataSf",
	rtrim(casaSn) as "@casaSn", rtrim(asigCI) as "@asigCI", rtrim(asigSO) as "@asigSO",
--	CoAsigurati
	(select tip as "@tip" , rtrim(cnp) as "@cnp" , rtrim(nume) as "@nume", rtrim(prenume) as "@prenume"  
		from D112coAsigurati ca where ca.Data=a.Data and ca.cnpAsig=a.cnpAsig and (@lmUtilizator is null or ca.Loc_de_munca=a.Loc_de_munca) for xml path('coAsigurati'), type), 
--	asiguratA
	(select rtrim(A_1) as "@A_1", rtrim(A_2) as "@A_2", rtrim(A_3) as "@A_3", rtrim(A_4) as "@A_4", rtrim(A_5) as "@A_5", 
		rtrim(A_6) as "@A_6", rtrim(A_7) as "@A_7", rtrim(A_8) as "@A_8", rtrim(A_9) as "@A_9",	rtrim(A_10) as "@A_10", 
		rtrim(A_11) as "@A_11", rtrim(A_12) as "@A_12", rtrim(A_13) as "@A_13", rtrim(A_14) as "@A_14", rtrim(A_20) as "@A_20"
	from D112AsiguratA aa where aa.Data=a.Data and aa.cnpAsig=a.cnpAsig and (@lmUtilizator is null or aa.Loc_de_munca=a.Loc_de_munca) for xml path('asiguratA'), type),
--	asiguratB1
	(select rtrim(B1_1) as "@B1_1", rtrim(B1_2) as "@B1_2", rtrim(B1_3) as "@B1_3", rtrim(B1_4) as "@B1_4", 
		rtrim(B1_5) as "@B1_5", rtrim(B1_6) as "@B1_6", rtrim(B1_7) as "@B1_7", rtrim(B1_8) as "@B1_8", 
		rtrim(B1_9) as "@B1_9",	rtrim(B1_10) as "@B1_10", rtrim(B1_15) as "@B1_15",
--	asiguratB11
		(select rtrim(B11_1) as "@B11_1", rtrim(B11_2) as "@B11_2", rtrim(B11_3) as "@B11_3", 
			rtrim(B11_41) as "@B11_41", rtrim(B11_42) as "@B11_42", rtrim(B11_43) as "@B11_43", rtrim(B11_5) as "@B11_5", 
			rtrim(B11_6) as "@B11_6", rtrim(B11_71) as "@B11_71", rtrim(B11_72) as "@B11_72", rtrim(B11_73) as "@B11_73"
		from D112AsiguratB11 ab11 where ab11.Data=a.Data and ab11.cnpAsig=a.cnpAsig and (@lmUtilizator is null or ab11.Loc_de_munca=a.Loc_de_munca) 
		for xml path('asiguratB11'), type)
	from D112AsiguratB1 ab where ab.Data=a.Data and ab.cnpAsig=a.cnpAsig and (@lmUtilizator is null or ab.Loc_de_munca=a.Loc_de_munca)
	for xml path('asiguratB1'), type),
--	asiguratB2
	(select rtrim(B2_1) as "@B2_1", rtrim(B2_2) as "@B2_2", rtrim(B2_3) as "@B2_3", rtrim(B2_4) as "@B2_4", 
		rtrim(B2_5) as "@B2_5", rtrim(B2_6) as "@B2_6", rtrim(B2_7) as "@B2_7"
	from D112AsiguratB234 ab where ab.Data=a.Data and ab.cnpAsig=a.cnpAsig and (@lmUtilizator is null or ab.Loc_de_munca=a.Loc_de_munca) 
		and (B2_1 is not Null or B2_2 is not Null or B2_3 is not Null or B2_4 is not Null or B2_5 is not Null or B2_6 is not Null or B2_7 is not Null)
	for xml path('asiguratB2'), type),
--	asiguratB3
	(select rtrim(B3_1) as "@B3_1", rtrim(B3_2) as "@B3_2", rtrim(B3_3) as "@B3_3", rtrim(B3_4) as "@B3_4", 
		rtrim(B3_5) as "@B3_5", rtrim(B3_6) as "@B3_6", rtrim(B3_7) as "@B3_7", rtrim(B3_8) as "@B3_8", rtrim(B3_9) as "@B3_9", 
		rtrim(B3_10) as "@B3_10", rtrim(B3_11) as "@B3_11",	rtrim(B3_12) as "@B3_12", rtrim(B3_13) as "@B3_13"
	from D112AsiguratB234 ab where ab.Data=a.Data and ab.cnpAsig=a.cnpAsig and (@lmUtilizator is null or ab.Loc_de_munca=a.Loc_de_munca)
		and (B3_1 is not Null or B3_2 is not Null or B3_3 is not Null or B3_4 is not Null or B3_5 is not Null or B3_6 is not Null 
		or B3_7 is not Null or B3_8 is not Null or B3_9 is not Null or B3_10 is not Null or B3_11 is not Null or B3_12 is not Null or B3_13 is not Null)
	for xml path('asiguratB3'), type),
--	asiguratB4
	(select rtrim(B4_1) as "@B4_1", rtrim(B4_2) as "@B4_2", rtrim(B4_3) as "@B4_3", rtrim(B4_4) as "@B4_4", 
		rtrim(B4_5) as "@B4_5", rtrim(B4_6) as "@B4_6", rtrim(B4_7) as "@B4_7", rtrim(B4_8) as "@B4_8", rtrim(B4_14) as "@B4_14"
	from D112AsiguratB234 ab where ab.Data=a.Data and ab.cnpAsig=a.cnpAsig and (@lmUtilizator is null or ab.Loc_de_munca=a.Loc_de_munca)
	for xml path('asiguratB4'), type),
--	asiguratC
	(select rtrim(C_1) as "@C_1", rtrim(C_2) as "@C_2", rtrim(C_3) as "@C_3", rtrim(C_4) as "@C_4", rtrim(C_5) as "@C_5", 
		rtrim(C_6) as "@C_6", rtrim(C_7) as "@C_7", rtrim(C_8) as "@C_8", rtrim(C_9) as "@C_9", 
		rtrim(C_10) as "@C_10", rtrim(C_11) as "@C_11", rtrim(C_17) as "@C_17", rtrim(C_18) as "@C_18", rtrim(C_19) as "@C_19"
	from D112AsiguratC ac where ac.Data=a.Data and ac.cnpAsig=a.cnpAsig and (@lmUtilizator is null or ac.Loc_de_munca=a.Loc_de_munca)  for xml path('asiguratC'), type),
--	asiguratD
	(select rtrim(D_1) as "@D_1", rtrim(D_2) as "@D_2", (case when rtrim(D_3)<>'' then rtrim(D_3) end) as "@D_3", 
		(case when rtrim(D_4)<>'' then rtrim(D_4) end) as "@D_4", rtrim(D_5) as "@D_5", rtrim(D_6) as "@D_6", 
		rtrim(D_7) as "@D_7", (case when rtrim(D_8)<>'' then rtrim(D_8) end) as "@D_8", rtrim(D_9) as "@D_9", 
		rtrim(D_10) as "@D_10",	(case when rtrim(D_11)<>'' then rtrim(D_11) end) as "@D_11", 
		(case when rtrim(D_12)<>'' then rtrim(D_12) end) as "@D_12", 
		(case when rtrim(D_13)<>'' then rtrim(D_13) end) as "@D_13", rtrim(D_14) as "@D_14", rtrim(D_15) as "@D_15", 
		rtrim(D_16) as "@D_16", rtrim(D_17) as "@D_17", rtrim(D_18) as "@D_18", rtrim(D_19) as "@D_19", 
		rtrim(D_20) as "@D_20", rtrim(D_21) as "@D_21"
	from D112AsiguratD ad where ad.Data=a.Data and ad.cnpAsig=a.cnpAsig and (@lmUtilizator is null or ad.Loc_de_munca=a.Loc_de_munca) for xml path('asiguratD'), type), 
--	asiguratE1
	(select rtrim(E1_1) as "@E1_1", rtrim(E1_2) as "@E1_2", rtrim(E1_3) as "@E1_3", rtrim(E1_4) as "@E1_4", rtrim(E1_5) as "@E1_5", rtrim(E1_6) as "@E1_6", rtrim(E1_7) as "@E1_7"
	from #D112AsiguratE1 e1 where @versiune>='2' and e1.Data=a.Data and e1.cnpAsig=a.cnpAsig and (@lmUtilizator is null or e1.Loc_de_munca=a.Loc_de_munca) for xml path('asiguratE1'), type),
--	asiguratE2
	(select rtrim(E2_1) as "@E2_1", rtrim(E2_2) as "@E2_2", rtrim(E2_3) as "@E2_3", rtrim(E2_4) as "@E2_4"
	from #D112AsiguratE2 e2 where @versiune>='2' and e2.Data=a.Data and e2.cnpAsig=a.cnpAsig and (@lmUtilizator is null or e2.Loc_de_munca=a.Loc_de_munca) for xml path('asiguratE2'), type),
--	asiguratE3
	(select rtrim(E3_1) as "@E3_1", rtrim(E3_2) as "@E3_2", rtrim(E3_3) as "@E3_3", rtrim(E3_4) as "@E3_4", 
		(case when E3_5<>'' then rtrim(E3_5) end) as "@E3_5", (case when E3_6<>'' then rtrim(E3_6) end) as "@E3_6", (case when E3_7<>'' then rtrim(E3_7) end) as "@E3_7", 
		rtrim(E3_8) as "@E3_8", rtrim(E3_9) as "@E3_9", rtrim(E3_10) as "@E3_10", 
		(case when E3_3='1' then rtrim(E3_11) end) as "@E3_11", (case when E3_3='1' then rtrim(E3_12) end) as "@E3_12", (case when E3_3='1' then rtrim(E3_13) end) as "@E3_13", 
		rtrim(E3_14) as "@E3_14", rtrim(E3_15) as "@E3_15", rtrim(E3_16) as "@E3_16"
	from D112AsiguratE3 e3 where @versiune>='2' and e3.Data=a.Data and e3.cnpAsig=a.cnpAsig and (@lmUtilizator is null or e3.Loc_de_munca=a.Loc_de_munca) for xml path('asiguratE3'), type)
	from D112Asigurat a where a.Data=@dataSus and (@lmUtilizator is null or a.Loc_de_munca like rtrim(@lmUtilizator)+'%')
	order by a.cnpAsig
	for xml path('asigurat'),  type)
	for xml path('declaratieUnica'))
	
	set @rezultat = '<declaratieUnica xmlns="mfp:anaf:dgti:declaratie_unica:declaratie:v'+@versiune+'" '+SUBSTRING (@rezultat,18,LEN(@rezultat))
--	am incercat sa apelez functia wfPregatestePtXML, dar dupa acea nu am mai putut deschide fisierul.
--	select @rezultat=dbo.wfPregatestePtXML(@rezultat)
--	salvare declaratie ca fisier xml

	set @numeFisier = (case when @multiFirma=1 then REPLACE(@denlmUtilizator,' ','_')+'_' else '' end)
		+'D112_'+rtrim(@cif)+'_'+convert(char(4),@An)+'_'+(case when @Luna<10 then '0' else '' end)+ltrim(rtrim(convert(char(2),@Luna)))+'.xml' 
	set @cFisier=rtrim(@cDirector)+@numeFisier

	if (select count(1) from tempdb..sysobjects where name='##tmpdecl')>0 
		drop table ##tmpdecl

--	salvez declaratia ca si continut in tabela declaratii
	if exists (select * from sysobjects where name ='scriuDeclaratii' and xtype='P')
		exec scriuDeclaratii @cod='112', @tip=@tipdecl, @data=@datasus, @continut=@rezultat

	create table ##tmpdecl (coloana varchar(max))
	if @inXML=1 /* daca inXML trimit fisierul pt. salvarea lui din Flex/AIR */
	begin 
		exec SalvareFisier @rezultat, @cDirector, @numeFisier, @faraMesaj
		--	select @rezultat as document, @numeFisier as fisier, '' as nrFactura, 'wTipFormular' as numeProcedura for xml raw 
	end 
	else 
	begin /* altfel, il salvez in tabela temporara si apoi cu bcp in un fisier pe disk */
		insert into ##tmpdecl values(@rezultat)
		declare @nServer varchar(1000), @comandaBCP varchar(4000) /* comanda trebuie sa ramana varchar(4000) sau mai mica... */
		set @nServer=convert(varchar(1000),serverproperty('ServerName'))
		set @comandaBCP='bcp "select coloana from ##tmpdecl'+'" queryout "'+@cFisier+'" -T -c -r -t -C UTF-8 -S '+@nServer
--	am scos  -x intrucat la anumite versiuni de SQL 2005 nu exista aceasta optiune la bcp.
		exec @raspunsCmd = xp_cmdshell @comandaBCP
--	select @raspunsCmd, @comandaBCP
		if @raspunsCmd != 0 /* xp_cmdshell returneaza 0 daca nu au fost erori, sau altfel, codul de eroare */
		begin
			set @msgeroare = 'Eroare la scrierea formularului pe hard-disk in locatia: '+ ( 
				case len(@cFisier) when 0 then 'NEDEFINIT' else @cFisier end )
			raiserror (@msgeroare ,11 ,1)
		end
		else	/* trimit numele fisierului generat */ 
			select @numeFisier as fisier, 'wTipFormular' as numeProcedura for xml raw
	end

	/*	Apelare procedura pentru semnatura electronica a declaratiei si transformare in PDF. In lucru. */
	if exists (select * from sysobjects where name ='pDeclaratiiInPDF' and type='P')
	begin
		declare @parXMLPdf xml
		set @parXMLPdf=(select 'D112' as tipdecl, @cFisier as fisierxml for xml raw)
		exec pDeclaratiiInPDF @sesiune=null, @parXML=@parXMLPdf
	end

	drop table ##tmpdecl

--	select @rezultat
End try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura Declaratia112 (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch


/*
	exec Declaratia112 '12/01/2012', '12/31/2012', 0, 0, 'TEST', 'TEST', 'DIRECTOR ECONOMIC', 0, '\\lucian\asis\D112\', 0
*/
