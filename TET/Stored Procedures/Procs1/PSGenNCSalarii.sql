--***
/*	procedura generare NC salarii 
	Exemplu de apel
	declare @dataJos datetime, @dataSus datetime
	select @dataJos='12/01/2014', @dataSus='12/31/2014'
	exec PSGenNCSalarii @dataJos=@dataJos, @dataSus=@dataSus
*/
Create procedure PSGenNCSalarii
	@dataJos datetime, @dataSus datetime, @pMarca char(6)='', @StergNCSalarii int=1, @StergNCTichete int=0, @StergNCZilieri int=0, @GenNCSalarii int=1, @GenNCTichete int=0, @GenNCZilieri int=0, @ParteProc int=0
As
Begin try
	declare @userASiS char(10), @Sub char(9), @nLunaBloc int, @nAnulBloc int, @dDataBloc datetime, @SomajInd decimal(5,2), 
	@NCIndBug int, @NCTaxePLM int, @CheltSalComp int, @NCRetCaDecont int, @NCNrDecNrDocRet int, @AnPLImpozit int, @Salubris int, @Somesana int, @Remarul int, @Dafora int, 
	@CreditCheltOcazO varchar(20), @CreditCheltOcazP varchar(20), @NCTichete int, @NCCnph int, @LmNCCnph char(9), @CotizPersHand decimal(10), @DebitCnph varchar(20), @CreditCnph varchar(20), 
	@DebitAvansActiv varchar(20), @CreditAvansActiv varchar(20), @MarcaCreditAvans int, 
	@DebitAvansOcazO varchar(20), @CreditAvansOcazO varchar(20), @MarcaCreditAvansOcazO int, @DebitAvansOcazP varchar(20), @CreditAvansOcazP varchar(20), @MarcaCreditAvansOcazP int,
	@DebitAvansBoln varchar(20), @CreditAvansBoln varchar(20), @DebitSumeIncas varchar(20), @CreditSumeIncas varchar(20), @MarcaCreditSumeIncas int, 
	@DebitCASActivi varchar(20), @CreditCASActivi varchar(20), @DebitCASOcaz varchar(20), @CreditCASOcaz varchar(20), @DebitCASBoln varchar(20), @CreditCASBoln varchar(20), 
		@AtribuireCreditCheltOcazO int, @AtribuireCreditCheltOcazP int, 
	@DebitSomajActivi varchar(20), @CreditSomajActivi varchar(20), @DebitSomajBolnavi varchar(20), @CreditSomajBolnavi varchar(20), @DebitSomajOcaz varchar(20), @CreditSomajOcaz varchar(20), 
	@DebitCassActivi varchar(20), @CreditCassActivi varchar(20), @DebitCassOcazO varchar(20), @CreditCassOcazO varchar(20), @DebitCassOcazP varchar(20), @CreditCassOcazP varchar(20), 
		@AtribContDebitCassOcazO int, @AtribContDebitCassOcazP int, 
	@DebitCassFaambp varchar(20), @CreditCassFaambp varchar(20), @CreditFaambp varchar(20), @CreditCCI varchar(20), 
	@DebitImpozitActivi varchar(20), @CreditImpozitActivi varchar(20), @DebitImpozitBolnavi varchar(20), @CreditImpozitBolnavi varchar(20), @DebitImpozitIpotetic varchar(20), @CreditImpozitIpotetic varchar(20), 
	@DebitImpozitOcazO varchar(20), @CreditImpozitOcazO varchar(20), @DebitImpozitOcazP varchar(20), @CreditImpozitOcazP varchar(20), 
	@DebitImpozitZilieri varchar(20), @CreditImpozitZilieri varchar(20), @ContDebitCorU varchar(20), @ContDebitCorQ varchar(20), 
	@Continuare int, @nTipDoc int, @cTipDoc char(2), @DateTichete char(30), @GestiuneTichete char(9), @CodTichete char(20), @IndBug char(20), 
	@NumarDoc char(8), @cDataDoc char(4), @NumarDoc1 char(10), @cDataDoc1 char(3), @NumarDocTich char(8), @NumarDocRectif char(8), 
	@NrPozitie int, @Explicatii char(50), @DenCorM char(30), @DenCorC char(30), @ContDebitor varchar(20), @ContCreditor varchar(20), 
	@lApelProcNC1 int, @lApelProcNC2 int, @parGNC char(9), @val_a char(200), @val_d datetime,

--	variabile pt. generare NC contributii angajat+avans din net per total unitate
	@LMSumaIncas decimal(10), @LMCOIncasat decimal(10), @LMImpozitActivi decimal(10), @LMImpozitDanes decimal(10), @LMImpozitBoln decimal(10), @LMImpozitBolnDanes decimal(10), @LMImpozitIpotetic decimal(10), 
	@LMImpozitOcazITO decimal(10), @LMImpozitOcazITP decimal(10), @LMImpozitOcazRO decimal(10), @LMImpozitZilieri decimal(10,2),
	@LMCasActivi decimal(10), @LMCasOcazPM decimal(10), @LMCasOcazPCA decimal(10), @LMCasBoln decimal(10), 
	@LMSomajActivi decimal(10), @LMSomajOcaz decimal(10), @LMSomajBoln decimal(10), 
	@LMCassActivi decimal(10), @LMCassOcazP decimal(10), @LMCassOcazO decimal(10), @LMCassFaambp decimal(10), 
	@LMSumaNeimpActivi decimal(10), @LMSumaNeimpBoln decimal(10), 
	@LMAvansActivi decimal(10), @LMAvansBoln decimal(10), @LMAvansOcazO decimal(10), @LMAvansOcazP decimal(10), 
	@LMSubvSomaj decimal(10), @LMCCIFaambp decimal(10), @TSomajUnitate decimal(10,2)

	set @userASiS=dbo.fIaUtilizator(null)
	set @Sub=dbo.iauParA('GE','SUBPRO')
	select @nLunaBloc=(case when tip_parametru='GE' and parametru='LUNABLOC' then val_numerica else @nLunaBloc end), 
		@nAnulBloc=(case when tip_parametru='GE' and parametru='ANULBLOC' then val_numerica else @nAnulBloc end)
	from par where tip_parametru='GE' and parametru in ('LUNABLOC', 'ANULBLOC') 
	set @dDataBloc=dbo.Eom(convert(datetime,str(@nLunaBloc,2)+'/01/'+str(@nAnulBloc,4)))

	select @Continuare=1, @DenCorM='', @IndBug='', @CotizPersHand=0
	select @DenCorM=Denumire from tipcor where tip_corectie_venit='M-'

	declare @lm varchar(9), @multiFirma int
	select @lm='', @multiFirma=0
	if exists (select * from sysobjects where name ='par' and xtype='V')
		set @multiFirma=1


	if @dataSus>@dDataBloc
	Begin
		set @SomajInd=dbo.iauParLN(@dataSus,'PS','SOMAJIND')
		set @NCIndBug=dbo.iauParL('PS','NC-INDBUG')
		set @NCTaxePLM=dbo.iauParL('PS','N-C-TX-LM')
		set @CheltSalComp=dbo.iauParL('PS','NC-CH-CMP')
		set @NCRetCaDecont=dbo.iauParL('PS','NC-RET-M')
		set @NCNrDecNrDocRet=dbo.iauParL('PS','DEC-NDOCR')
		set @AnPLImpozit=dbo.iauParL('PS','AN-PL-IMP')
		set @CreditCheltOcazO=dbo.iauParA('PS','N-C-SAL2C')
		set @CreditCheltOcazP=dbo.iauParA('PS','N-C-SAL3C')
		select @AtribuireCreditCheltOcazO=(case when sold_credit>10 then 0 else sold_credit end) from conturi where Subunitate=@Sub and Cont=@CreditCheltOcazO
		select @AtribuireCreditCheltOcazP=(case when sold_credit>10 then 0 else sold_credit end) from conturi where Subunitate=@Sub and Cont=@CreditCheltOcazP
		set @NCCnph=dbo.iauParL('PS','NC-CPHAND')
		set @LmNCCnph=dbo.iauParA('PS','NC-CPHAND')
		set @DebitCNPH=dbo.iauParA('PS','N-CPH-DEB')
		set @CreditCNPH=dbo.iauParA('PS','N-CPH-CRE')
		set @NCTichete=dbo.iauParL('PS','NC-TICHM')
		set @nTipDoc=dbo.iauParN('PS','NC-TICHM')
		set @cTipDoc=left(convert(char(2),convert(int, @nTipDoc)),1)
		set @cTipDoc=(case when @cTipDoc='' then '2' else @cTipDoc end)
		set @DateTichete=dbo.iauParA('PS','NC-TICHM')
		set @GestiuneTichete=(case when @DateTichete='' then '' else left(@DateTichete,charindex(',',@DateTichete)-1) end)
		set @CodTichete=(case when @DateTichete='' then '' else substring(@DateTichete,charindex(',',@DateTichete)+1,20) end)
		set @ContDebitCorU=dbo.iauParA('PS','N-C-PNEID')
		set @ContDebitCorQ=dbo.iauParA('PS','N-C-AVMD')
		set @DebitAvansActiv=dbo.iauParA('PS','N-AV-ACTD')
		set @CreditAvansActiv=dbo.iauParA('PS','N-AV-ACTC')
		set @MarcaCreditAvans=dbo.iauParL('PS','N-AV-ACTC')
		set @DebitAvansOcazO=dbo.iauParA('PS','N-AV-COLD')
		set @CreditAvansOcazO=dbo.iauParA('PS','N-AV-COLC')
		set @MarcaCreditAvansOcazO=dbo.iauParL('PS','N-AV-COLC')
		set @DebitAvansOcazP=dbo.iauParA('PS','N-AV-CLPD')
		set @CreditAvansOcazP=dbo.iauParA('PS','N-AV-CLPC')
		set @MarcaCreditAvansOcazP=dbo.iauParL('PS','N-AV-CLPC')
		set @DebitAvansBoln=dbo.iauParA('PS','N-AV-BOLD')
		set @CreditAvansBoln=dbo.iauParA('PS','N-AV-BOLC')
		set @DebitSumeIncas=dbo.iauParA('PS','N-AV-RIDD')
		set @CreditSumeIncas=dbo.iauParA('PS','N-AV-RIDC')
		set @MarcaCreditSumeIncas=dbo.iauParL('PS','N-AV-RIDC')
		set @DebitCassOcazO=dbo.iauParA('PS','N-ASNEOD')
		set @DebitCassOcazP=dbo.iauParA('PS','N-ASNEOPD')
		select @AtribContDebitCassOcazO=(case when sold_credit>10 then 0 else sold_credit end) from conturi where Subunitate=@Sub and Cont=@DebitCassOcazO
		select @AtribContDebitCassOcazP=(case when sold_credit>10 then 0 else sold_credit end) from conturi where Subunitate=@Sub and Cont=@DebitCassOcazP
		set @DebitCASActivi=dbo.iauParA('PS','N-AS-P3AD')
		set @CreditCASActivi=dbo.iauParA('PS','N-AS-P3AC')
		set @DebitCASOcaz=dbo.iauParA('PS','N-AS-P3OD')
		set @CreditCASOcaz=dbo.iauParA('PS','N-AS-P3OC')
		set @DebitCASBoln=dbo.iauParA('PS','N-AS-P3BD')
		set @CreditCASBoln=dbo.iauParA('PS','N-AS-P3BC')
		set @DebitSomajActivi=dbo.iauParA('PS','N-ASSJ1AD')
		set @CreditSomajActivi=dbo.iauParA('PS','N-ASSJ1AC')
		set @DebitSomajBolnavi=dbo.iauParA('PS','N-ASSJ1BD')
		set @CreditSomajBolnavi=dbo.iauParA('PS','N-ASSJ1BC')
		set @DebitSomajOcaz=dbo.iauParA('PS','N-ASSJ1OD')
		set @CreditSomajOcaz=dbo.iauParA('PS','N-ASSJ1OC')
		set @DebitCassActivi=dbo.iauParA('PS','N-ASNEAD')
		set @CreditCassActivi=dbo.iauParA('PS','N-ASNEAC')
		set @DebitCassOcazO=dbo.iauParA('PS','N-ASNEOD')
		set @CreditCassOcazO=dbo.iauParA('PS','N-ASNEOC')
		set @DebitCassOcazP=dbo.iauParA('PS','N-ASNEOPD')
		set @CreditCassOcazP=dbo.iauParA('PS','N-ASNEOPC')
		select @AtribContDebitCassOcazO=(case when sold_credit>10 then 0 else sold_credit end) from conturi where Subunitate=@Sub and Cont=@DebitCassOcazO
		select @AtribContDebitCassOcazP=(case when sold_credit>10 then 0 else sold_credit end) from conturi where Subunitate=@Sub and Cont=@DebitCassOcazP
		set @DebitCassFaambp=dbo.iauParA('PS','N-ASFABPD')
		set @CreditCassFaambp=dbo.iauParA('PS','N-ASFABPC')
		set @CreditFaambp=dbo.iauParA('PS','N-AS-FR1C')
		set @CreditCCI=dbo.iauParA('PS','N-AS-CCIC')
		set @DebitImpozitActivi=dbo.iauParA('PS','N-I-PMACD')
		set @CreditImpozitActivi=dbo.iauParA('PS','N-I-PMACC')
		set @DebitImpozitBolnavi=dbo.iauParA('PS','N-I-PMBOD')
		set @CreditImpozitBolnavi=dbo.iauParA('PS','N-I-PMBOC')
		set @DebitImpozitIpotetic=dbo.iauParA('PS','N-I-IPPMD')
		set @CreditImpozitIpotetic=dbo.iauParA('PS','N-I-IPPMC')
		set @DebitImpozitOcazO=dbo.iauParA('PS','N-I-OCAZD')
		set @CreditImpozitOcazO=dbo.iauParA('PS','N-I-OCAZC')
		set @DebitImpozitOcazP=dbo.iauParA('PS','N-I-OCZPD')
		set @CreditImpozitOcazP=dbo.iauParA('PS','N-I-OCZPC')
		set @DebitImpozitZilieri=dbo.iauParA('PS','N-I-ZILD')
		set @CreditImpozitZilieri=dbo.iauParA('PS','N-I-ZILC')

		set @lApelProcNC1=dbo.iauParL('PS','PROCNC1')
		set @lApelProcNC2=dbo.iauParL('PS','PROCNC2')
		set @Salubris=dbo.iauParL('SP','SALUBRIS')
		set @Somesana=dbo.iauParL('SP','SOMESANA')
		set @Remarul=dbo.iauParL('SP','REMARUL')
		set @Dafora=dbo.iauParL('SP','DAFORA')

		set @cDataDoc=left(convert(char(10),@dataSus,101),2)+right(convert(char(10),@dataSus,101),2)
		set @NumarDoc='SAL'+@cDataDoc
		set @NumarDocTich='TICH'+@cDataDoc
		set @cDataDoc1=left(convert(char(10),@dataSus,101),2)+right(convert(char(10),@dataSus,101),1)
		set @NumarDoc1='SAL'+@cDataDoc1

--	sterg tabele temporare
		if object_id('tempdb..#brut') is not null drop table #brut
		if object_id('tempdb..#brutMarca') is not null drop table #brutMarca
		if object_id('tempdb..#net') is not null drop table #net
		declare @parXML xml
		set @parXML=(select @dataJos datajos, @dataSus datasus, 'LC' lunaApelare, (case when @Remarul=1 then 1 else '' end) grupareremarul, 1 as ceselectez for xml raw)
		
--	creez tabele temporare #rectificaribrut si #rectificarinet cu structura similara tabelelor brut si net in care pun diferentele rezultate din rectificari
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
		insert into #brut
		exec BrutCuRectificari @parXML

		select top 0 Data, Marca, Loc_de_munca, VENIT_TOTAL, CM_incasat, CO_incasat, Suma_incasata, Suma_neimpozabila, Diferenta_impozit, Impozit, Pensie_suplimentara_3, Somaj_1, 
			Asig_sanatate_din_impozit, Asig_sanatate_din_net, Asig_sanatate_din_CAS, VENIT_NET, Avans, Premiu_la_avans, Debite_externe, Rate, Debite_interne, Cont_curent, REST_DE_PLATA, 
			CAS, Somaj_5, Fond_de_risc_1, Camera_de_Munca_1, Asig_sanatate_pl_unitate, Coef_tot_ded, Grad_invalid, Coef_invalid, Alte_surse, VEN_NET_IN_IMP, Ded_baza, Ded_suplim, 
			VENIT_BAZA, Chelt_prof, Baza_CAS, Baza_CAS_cond_norm, Baza_CAS_cond_deoseb, Baza_CAS_cond_spec
		into #net from net where data between @datajos and @datasus
		create unique index [Data_Marca] ON #net (Data, Marca)
--	tabela #net se completeaza in procedura NetCuRectificari
--		insert into #net 
		exec NetCuRectificari @parXML

		set @parXML=(select @dataJos datajos, @dataSus datasus, 'LC' lunaApelare, 1 gruparepemarca, 1 as ceselectez for xml raw)
		select top 0 * into #brutMarca from #brut where data between @datajos and @datasus
		create unique index [Data_Marca] ON #brutMarca (Data, Marca)
		insert into #brutMarca
		exec BrutCuRectificari @parXML

--	sterg si creez tabele temporara in care se vor mai intai datele 
--	comentat pana se va modifica wScriuPozadoc pt. a permite scriere mai multe documente + publicare wScriu-uri
--	scos comentariul, s-au publicat wScriu-uri. Pt. pozadoc am facut cursor, pana se vor putea trimite mai multe documente odata, sau le vom trece pe RS-uri.
		if object_id('tempdb..#docPozncon') is not null drop table #docPozncon
		create table #docPozncon (Subunitate char(9) not null, Tip char(2) not null, Numar char(13) not null, Data datetime not null,
			Cont_debitor varchar(20) not null, Cont_creditor varchar(20) not null, Suma float not null, Explicatii char(50) not null, 
			Nr_pozitie int not null, Loc_munca char(9) not null, Comanda char(40) not null, Jurnal char(3) not null, detalii xml) 

		if object_id('tempdb..#docPozplin') is not null drop table #docPozplin
		create table #docPozplin
			(Subunitate char(9) not null, Cont varchar(20) not null, Data datetime not null, Numar char(10) not null, Plata_incasare char(2) not null,
			Tert char(13) not null, Factura char(20) not null, Cont_corespondent varchar(20) not null, Suma float not null, Explicatii char(50) not null, Loc_de_munca char(9) not null,
			Comanda char(40) not null, Numar_pozitie int not null, Cont_dif varchar(20) not null, Jurnal char(3) not null, idDiurna int)

		if object_id('tempdb..#docPozadoc') is not null drop table #docPozadoc
		create table #docPozadoc(Subunitate char(9) not null, Numar_document char(8) not null, Data datetime not null, Tert char(13) not null, Tip char(2) not null,
			Factura_stinga char(20) not null, Factura_dreapta char(20) not null, Cont_deb varchar(20) not null, Cont_cred varchar(20) not null, Suma float not null,
			TVA11 float not null, TVA22 float not null, Numar_pozitie int not null, Explicatii char(50) not null, 
			Loc_munca char(9) not null, Comanda char(40) not null, Data_fact datetime not null, Data_scad datetime not null, Jurnal char(3) not null) 

		if object_id('tempdb..#docPozdoc') is not null drop table #docPozdoc
		create table #docPozdoc(Subunitate char(9) not null, Tip char(2) not null, Numar char(8) not null, Cod char(20) not null, Data datetime not null, 
			Gestiune char(9) not null, Cantitate float not null, Cont_corespondent varchar(20) not null, 
			Numar_pozitie int not null, Loc_de_munca char(9) not null, Comanda char(40) not null, Jurnal char(3) not null) 
		
		if object_id('tempdb..#rectificari') is not null drop table #rectificari
		create table #rectificari(numarDoc char(20) not null)

		if @ParteProc=0 or @ParteProc=1
			set @NrPozitie=1
		else 
			set @NrPozitie=dbo.iauParN('PS','NRPOZNC')
--		@ParteProc=1 -> stergere documente generate anterior 
		if @ParteProc=0 or @ParteProc=1
		Begin
			delete casbrut from CasBrut
				left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=casbrut.loc_de_munca	
			where (@multiFirma=0 or dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null) 	

			if @lApelProcNC1=1
				exec genncsp1 @dataJos, @dataSus
			if @StergNCSalarii=1
			Begin
--				stergere note contabile generate anterior (mai putin tichete de masa, care se sterg separat)
				delete pozncon from pozncon
					left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=pozncon.Loc_munca
				where subunitate=@Sub and tip='PS' and numar=@NumarDoc and data=@dataSus 
					and explicatii<>'Tichete de masa' and charindex('zilieri',explicatii)=0
					and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
				delete from ncon where subunitate=@Sub and tip='PS' and numar=@NumarDoc and data=@dataSus
--				stergere note contabile generate anterior aferent sumelor rezultate din rectificari
				delete pozncon from pozncon
					left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=pozncon.Loc_munca
				where subunitate=@Sub and tip='PS' and numar like 'SALR%' and data=@dataSus 
					and explicatii<>'Tichete de masa' and charindex('zilieri',explicatii)=0
					and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
				delete from ncon where subunitate=@Sub and tip='PS' and numar like 'SALR%' and data=@dataSus
--				stergere retineri generate ca si decont in pozplin
				delete pozplin from pozplin 
					left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=pozplin.Loc_de_munca
				where subunitate=@Sub and data=@dataSus and numar between (case when @NCNrDecNrDocRet=0 then rtrim(@cDataDoc1) else '' end) 
					and (case when @NCNrDecNrDocRet=0 then rtrim(@cDataDoc1) else '' end)+'ZZZ' 
					and Plata_incasare='PD' and explicatii like 'Retinere marca'+'%'
					and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
--				stergere cheltuieli colaboratori (cu cont creditor atribuit de tip furnizor) generate ca si FF-uri in pozadoc
				delete pozadoc from pozadoc 
					left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=pozadoc.Loc_munca
				where subunitate=@Sub and tip='FF' and numar_document like rtrim(@NumarDoc)+'%' 
					and data=@dataSus and tert like 'M'+'%' and (cont_cred=@CreditCheltOcazO or cont_cred=@CreditCheltOcazP)
					and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
--				stergere plati pentru cheltuieli colaboratori generate ca si PF-uri in pozplin
				delete pozplin from pozplin 
					left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=pozplin.Loc_de_munca
				where subunitate=@Sub and plata_incasare='PF' and numar like rtrim(@NumarDoc)+'%' 
					and data=@dataSus and tert like 'M'+'%' and factura=@NumarDoc
					and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)

				if @CheltSalComp=1
					delete from cheltcomp where data between @dataJos and @dataSus
			End
--			stergere tichete de masa
			if @StergNCTichete=1
			Begin
				if @cTipDoc='2'
--				generate ca si bonuri de consum
					delete pozdoc from pozdoc 
						left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=pozdoc.Loc_de_munca
					where pozdoc.subunitate=@Sub and tip='CM' and pozdoc.numar=@NumarDocTich 
						and pozdoc.data=@dataSus and pozdoc.gestiune=@GestiuneTichete and pozdoc.cod=@CodTichete
						and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
				else 
--				generate ca si note contabile
					delete pozncon from pozncon
						left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=pozncon.Loc_munca
					where subunitate=@Sub and tip='PS' and numar=@NumarDoc 
						and data=@dataSus and explicatii='Tichete de masa'
						and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
			End	
--		generate note contabile zilieri
			if @StergNCZilieri=1
				delete pozncon from pozncon
					left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=pozncon.Loc_munca
				where subunitate=@Sub and tip='PS' and numar=@NumarDoc 
					and data=@dataSus and charindex('zilieri',explicatii)<>0
					and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
		End	
		if @GenNCSalarii=1
		Begin
--		@ParteProc=2 -> generate NC de cheltuieli pe locuri de munca
			if @ParteProc=0 or @ParteProc=2
			Begin
				if @Continuare=1 and @NCIndBug=0
					exec GenNCCheltLM @dataJos, @dataSus, @pMarca, @Continuare output, @NrPozitie output, @NumarDoc
				if @Continuare=1 and @NCIndBug=1
					exec GenNCCheltLMBug @dataJos, @dataSus, @pMarca, @Continuare output, @NrPozitie output, @NumarDoc
				
				exec PSCorectieCASbrut @dataJos, @dataSus, @pMarca
			End
--		@ParteProc=3 -> generate NC de cheltuieli asigurari sociale pe locuri de munca
			if @ParteProc=0 or @ParteProc=3
			Begin
				if @Continuare=1 and @Somesana=0
					exec GenNCCasLM @dataJos, @dataSus, @pMarca, @Continuare output, @NrPozitie output, @TSomajUnitate output, @NumarDoc
				if @Continuare=1 and @Somesana=1
					exec GenNCCasLMSomesana @dataJos, @dataSus, @pMarca, @Continuare output, @NrPozitie output
			End		
--		@ParteProc=4 -> generate NC de retineri
			if @Continuare=1 and (@ParteProc=0 or @ParteProc=4)
				if @NCIndBug=1 and exists (select * from sysobjects where name ='GenerareNCRetineriBug')
					exec GenerareNCRetineriBug @dataJos, @dataSus, @pMarca, @Continuare output, @NrPozitie output, @NumarDoc
				else
					exec GenNCRetineri @dataJos, @dataSus, @pMarca, @Continuare output, @NrPozitie output

--		@ParteProc=5 -> generate NC de contributii individuale, avans, sume incasate
			if @ParteProc=0 or @ParteProc=5
			Begin
				select @LMSumaIncas=0, @LMCOIncasat=0, @LMImpozitActivi=0, @LMImpozitDanes=0, @LMImpozitBoln=0, @LMImpozitBolnDanes=0, @LMImpozitIpotetic=0, 
				@LMImpozitOcazITO=0, @LMImpozitOcazITP=0, @LMImpozitOcazRO=0, @LMCasActivi=0, @LMCasOcazPM=0, @LMCasOcazPCA=0, 
				@LMCasBoln=0, @LMSomajActivi=0, @LMSomajOcaz=0, @LMSomajBoln=0, @LMCassActivi=0, @LMCassOcazP=0, 
				@LMCassOcazO=0, @LMCassFaambp=0, @LMSumaNeimpActivi=0, @LMSumaNeimpBoln=0, @LMAvansActivi=0, @LMAvansBoln=0, 
				@LMAvansOcazO=0, @LMAvansOcazP=0, @LMSubvSomaj=0, @LMCCIFaambp=0
				if @Continuare=1 
					if @NCIndBug=1 and exists (select * from sysobjects where name ='GenerareNCContributiiAngajatiBug')
						exec GenerareNCContributiiAngajatiBug @dataJos, @dataSus, @pMarca, @Continuare output, @NrPozitie output, @NumarDoc
					else
						exec GenNCDinNet @dataJos, @dataSus, @pMarca, @Continuare output, @NrPozitie output, @NumarDoc, 
						@LMSumaIncas output, @LMCOIncasat output, 
						@LMImpozitActivi output, @LMImpozitDanes output, @LMImpozitBoln output, @LMImpozitBolnDanes output, @LMImpozitIpotetic output, 
						@LMImpozitOcazITO output, @LMImpozitOcazITP output, @LMImpozitOcazRO output, 
						@LMCasActivi output, @LMCasOcazPM output, @LMCasOcazPCA output, @LMCasBoln output, 
						@LMSomajActivi output, @LMSomajOcaz output, @LMSomajBoln output, 
						@LMCassActivi output, @LMCassOcazP output, @LMCassOcazO output, @LMCassFaambp output, 
						@LMSumaNeimpActivi output, @LMSumaNeimpBoln output, 
						@LMAvansActivi output, @LMAvansBoln output, @LMAvansOcazO output, @LMAvansOcazP output, 
						@LMSubvSomaj output, @LMCCIFaambp output
				if @Continuare=1 
					exec GenNCCorectii @dataJos, @dataSus, @Continuare output, @NrPozitie output
--		@ParteProc=5 -> generate NC pt. totalurile pe unitate
				if @ParteProc=0 or @ParteProc=5
				Begin
					if @Somesana=0 and @NCTaxePLM=0 and @GenNCSalarii=1 and @Continuare=1
					Begin
--					Avans
						if @MarcaCreditAvans=0
						Begin
							exec scriuNCsalarii @dataSus, @DebitAvansActiv, @CreditAvansActiv, @LMAvansActivi, @NumarDoc, 
							'Avans angajati - activi', @Continuare output, @NrPozitie output, '', '', '', 0, '', '', 0
							exec scriuNCsalarii @dataSus, @DebitAvansBoln, @CreditAvansBoln, @LMAvansBoln, @NumarDoc, 
							'Avans angajati - bolnavi', @Continuare output, @NrPozitie output, '', '', '', 0, '', '', 0
						End	
						if @MarcaCreditAvansOcazO=0
							exec scriuNCsalarii @dataSus, @DebitAvansOcazO, @CreditAvansOcazO, @LMAvansOcazO, @NumarDoc, 
							'Avans angajati - colab', @Continuare output, @NrPozitie output, '', '', '', 0, '', '', 0
						if @MarcaCreditAvansOcazP=0
							exec scriuNCsalarii @dataSus, @DebitAvansOcazP, @CreditAvansOcazP, @LMAvansOcazP, @NumarDoc, 
							'Avans angajati - colab', @Continuare output, @NrPozitie output, '', '', '', 0, '', '', 0
--					Asigurari sociale (CAS)
						exec scriuNCsalarii @dataSus, @DebitCASActivi, @CreditCASActivi, @LMCasActivi, @NumarDoc, 
						'Asigurari CAS individual - activi perm.', @Continuare output, @NrPozitie output, '', '', '', 0, '', '', 0
						exec scriuNCsalarii @dataSus, @DebitCASBoln, @CreditCASBoln, @LMCasBoln, @NumarDoc, 
						'Asigurari CAS individual - bolnavi', @Continuare output, @NrPozitie output, '', '', '', 0, '', '', 0
						if @AtribuireCreditCheltOcazP<>1
							exec scriuNCsalarii @dataSus, @CreditCheltOcazP, @CreditCASOcaz, @LMCasOcazPM, @NumarDoc, 
							'Asigurari CAS individual - ocazionali', @Continuare output, @NrPozitie output, '', '', '', 0, '', '', 0
						if @AtribuireCreditCheltOcazO<>1
							exec scriuNCsalarii @dataSus, @CreditCheltOcazO, @CreditCASOcaz, @LMCasOcazPCA, @NumarDoc, 
							'Asigurari CAS individual - ocazionali', @Continuare output, @NrPozitie output, '', '', '', 0, '', '', 0
--					Somaj
						set @Explicatii='Somaj '+rtrim(convert(char(6),@SomajInd))+'% - activi'
						exec scriuNCsalarii @dataSus, @DebitSomajActivi, @CreditSomajActivi, @LMSomajActivi, @NumarDoc, 
						@Explicatii, @Continuare output, @NrPozitie output, '', '', '', 0, '', '', 0
						set @Explicatii='Somaj '+rtrim(convert(char(6),@SomajInd))+'% - ocazionali'
						if @AtribuireCreditCheltOcazP<>1
							exec scriuNCsalarii @dataSus, @DebitSomajOcaz, @CreditSomajOcaz, @LMSomajOcaz, @NumarDoc, 
							@Explicatii, @Continuare output, @NrPozitie output, '', '', '', 0, '', '', 0
						set @Explicatii='Somaj '+rtrim(convert(char(6),@SomajInd))+'% - bolnavi'
						exec scriuNCsalarii @dataSus, @DebitSomajBolnavi, @CreditSomajBolnavi, @LMSomajBoln, @NumarDoc, 
						@Explicatii, @Continuare output, @NrPozitie output, '', '', '', 0, '', '', 0
--					Asigurari de sanatate
						exec scriuNCsalarii @dataSus, @DebitCassActivi, @CreditCassActivi, @LMCassActivi, @NumarDoc, 
						'Asigurari sanatate din net - activi', @Continuare output, @NrPozitie output, '', '', '', 0, '', '', 0
						if @AtribContDebitCassOcazO<>1
							exec scriuNCsalarii @dataSus, @DebitCassOcazO, @CreditCassOcazO, @LMCassOcazO, @NumarDoc, 
							'Asigurari sanatate din net - ocazionali', @Continuare output, @NrPozitie output, '', '', '', 0, '', '', 0
						if @AtribContDebitCassOcazP<>1
							exec scriuNCsalarii @dataSus, @DebitCassOcazP, @CreditCassOcazP, @LMCassOcazP, @NumarDoc, 
							'Asigurari sanatate din net - ocazionali', @Continuare output, @NrPozitie output, '', '', '', 0, '', '', 0
						exec scriuNCsalarii @dataSus, @DebitCassFaambp, @CreditCassFaambp, @LMCassFaambp, @NumarDoc, 
						'Total A.S. FAAMBP - ', @Continuare output, @NrPozitie output, '', '', '', 0, '', '', 0
--					Contributia de concedii si indemnizatii pe perioada de CM din cauza de accident de munca suportat din Faambp
						exec scriuNCsalarii @dataSus, @CreditFaambp, @CreditCCI, @LMCCIFaambp, @NumarDoc, 
						'Total CCI suportat din FAAMBP - ', @Continuare output, @NrPozitie output, '', '', '', 0, '', '', 0
--					Impozit
						if @AnPLImpozit=0
						begin
							exec scriuNCsalarii @dataSus, @DebitImpozitActivi, @CreditImpozitActivi, @LMImpozitActivi, @NumarDoc, 
							'Impozit personal permanenti - activi', @Continuare output, @NrPozitie output, '', '', '', 0, '', '', 0
							exec scriuNCsalarii @dataSus, @DebitImpozitBolnavi, @CreditImpozitBolnavi, @LMImpozitBoln, @NumarDoc, 
							'Impozit personal permanenti - bolnavi', @Continuare output, @NrPozitie output, '', '', '', 0, '', '', 0
						end
						exec scriuNCsalarii @dataSus, @DebitImpozitIpotetic, @CreditImpozitIpotetic, @LMImpozitIpotetic, @NumarDoc, 
						'Impozit ipotetic personal permanenti - activi', @Continuare output, @NrPozitie output, '', '', '', 0, '', '', 0
						if @AtribContDebitCassOcazO<>1
							exec scriuNCsalarii @dataSus, @DebitImpozitOcazO, @CreditImpozitOcazO, @LMImpozitOcazITO, @NumarDoc, 
							'Impozit - ocazionali', @Continuare output, @NrPozitie output, '', '', '', 0, '', '', 0
						if @AtribContDebitCassOcazP<>1
							exec scriuNCsalarii @dataSus, @DebitImpozitOcazP, @CreditImpozitOcazP, @LMImpozitOcazITP, @NumarDoc, 
							'Impozit - ocazionali', @Continuare output, @NrPozitie output, '', '', '', 0, '', '', 0

						if @MarcaCreditSumeIncas=0 
						Begin	
							set @ContDebitor=rtrim(@DebitSumeIncas)
							set @ContCreditor=rtrim(@CreditSumeIncas)
							if @NCIndBug=1
								select @IndBug=Comanda, @DenCorM=Denumire, @ContDebitor=Cont_debitor, @ContCreditor=Cont_creditor from config_nc where Numar_pozitie=55
							set @Explicatii='Total '+rtrim(@DenCorM)+' - '
							exec scriuNCsalarii @dataSus, @DebitSumeIncas, @CreditSumeIncas, @LMSumaIncas, @NumarDoc, 
							@Explicatii, @Continuare output, @NrPozitie output, '', '', @IndBug, 0, '', '', 0
							if @NCIndBug=1
							Begin
								select @IndBug=Comanda, @DenCorC=Denumire, @ContDebitor=Cont_debitor, @ContCreditor=Cont_creditor from config_nc where Numar_pozitie=57
								set @Explicatii='Total '+rtrim(@DenCorC)+' - '
								exec scriuNCsalarii @dataSus, @ContDebitor, @ContCreditor, @LMCOIncasat, @NumarDoc, 
								@Explicatii, @Continuare output, @NrPozitie output, '', '', @IndBug, 0, '', '', 0
							End	
						End
					End		
				End
			End		
		End
--	@ParteProc=2 -> generate NC de cheltuieli pe locuri de munca (zilieri)
		if @GenNCZilieri=1 and @Continuare=1 and (@ParteProc=0 or @ParteProc=2)
			exec GenNCCheltZilieri @dataJos, @dataSus, @pMarca, @Continuare output, @NrPozitie output
--	impozit zilieri
		if @GenNCZilieri=1 and @Continuare=1 and (@ParteProc=0 or @ParteProc=5)
		Begin
			set @LMImpozitZilieri=0
			exec GenNCImpozitZilieri @dataJos, @dataSus, @pMarca, @Continuare output, @NrPozitie output, @LMImpozitZilieri output
			if @NCTaxePLM=0
			Begin
				set @LMImpozitZilieri=ROUND(@LMImpozitZilieri,0)
				exec scriuNCsalarii @dataSus, @DebitImpozitZilieri, @CreditImpozitZilieri, @LMImpozitZilieri, @NumarDoc, 
				'Impozit - zilieri', @Continuare output, @NrPozitie output, '', '', '', 0, '', '', 0
			End	
		End		

--	@ParteProc=6 -> generate NC pt. tichete de masa
		if @GenNCTichete=1 and @Continuare=1 and (@ParteProc=0 or @ParteProc=6)
			exec GenNCTichete @dataJos, @dataSus, @pMarca, @Continuare output, @NrPozitie output

		if @GenNCSalarii=1 and @NCCnph=1 and @Continuare=1 and (@ParteProc=0 or @ParteProc=6)
		Begin 
			if @NCIndBug=1
				select @IndBug=Comanda from config_nc where Numar_pozitie=150 
			select @CotizPersHand=Val_numerica 
			from par where tip_parametru='PS' and parametru like 'CPH'+'%'
			and (substring(parametru,6,4)+substring(parametru,4,2) between '200101' and '205012') 
			and dbo.eom(convert(datetime,substring(parametru,4,2)+'/01/'+substring(parametru,6,4),102))=@dataSus
			if @CotizPersHand=0 and @multiFirma=0
				select @CotizPersHand=Suma_cnph from dbo.fCalcul_cnph(@dataJos,@dataSus,'','','ZZZ','',null,null)

			if @multiFirma=1 and @LmNCCnph=''
				select @LmNCCnph=isnull(min(Cod),'') from LMfiltrare where utilizator=@userASiS and cod in (select cod from lm where Nivel=1)

			exec scriuNCsalarii @dataSus, @DebitCNPH, @CreditCNPH, @CotizPersHand, @NumarDoc, 
			'Cotiz. neangajare persoane cu handicap - ', @Continuare output, @NrPozitie output, @LmNCCnph, '', @IndBug, 0, '', '', 0
		End

--		@ParteProc=7 -> generare note contabile pentru sume rezultate din rectificari
		if @GenNCSalarii=1 and @Continuare=1 and (@ParteProc=0 or @ParteProc=7)
		Begin
			declare @data_rectificata datetime, @cDataDocRectif char(4)
--		creez cursor pentru a genera cate un numar de document pentru fiecare luna rectificata
			declare rectificari cursor for
			select distinct p.data_rectificata
			from pozRectificariSalarii p
				inner join AntetRectificariSalarii a on a.idRectificare=p.idRectificare
			where a.Data=@dataSus
			order by p.data_rectificata
			
			open rectificari
			fetch next from rectificari into @data_rectificata
			While @@fetch_status = 0 
			Begin
				set @cDataDocRectif=left(convert(char(10),@data_rectificata,101),2)+right(convert(char(10),@data_rectificata,101),2)
				set @NumarDocRectif='SALR'+rtrim(@cDataDocRectif)

				delete from CasBrut
				set @parXML=(select dbo.BOM(@data_rectificata) datajos, dbo.EOM(@data_rectificata) datasus, 'LR' lunaApelare, (case when @Remarul=1 then 1 else '' end) grupareremarul, 2 as ceselectez, 1 as nc for xml raw)
				delete from #brut
				insert into #brut
				exec BrutCuRectificari @parXML
				delete from #net
				exec NetCuRectificari @parXML
				set @parXML=(select dbo.BOM(@data_rectificata) datajos, dbo.EOM(@data_rectificata) datasus, 'LR' lunaApelare, 1 gruparepemarca, 2 as ceselectez, 1 as nc for xml raw)
				delete from #brutMarca
				insert into #brutMarca
				exec BrutCuRectificari @parXML

				if @Continuare=1 and @NCIndBug=0
					exec GenNCCheltLM @dataJos, @dataSus, @pMarca, @Continuare output, @NrPozitie output, @NumarDocRectif
				if @Continuare=1 and @NCIndBug=1
					exec GenNCCheltLMBug @dataJos, @dataSus, @pMarca, @Continuare output, @NrPozitie output, @NumarDocRectif
				exec PSCorectieCASbrut @dataJos, @dataSus, @pMarca
				if @Continuare=1 and @Somesana=0
					exec GenNCCasLM @dataJos, @dataSus, @pMarca, @Continuare output, @NrPozitie output, @TSomajUnitate output, @NumarDocRectif
				if @Continuare=1
					exec GenNCDinNet @dataJos, @dataSus, @pMarca, @Continuare output, @NrPozitie output, @NumarDocRectif, 
					@LMSumaIncas output, @LMCOIncasat output, @LMImpozitActivi output, @LMImpozitDanes output, @LMImpozitBoln output, @LMImpozitBolnDanes output, @LMImpozitIpotetic output, 
					@LMImpozitOcazITO output, @LMImpozitOcazITP output, @LMImpozitOcazRO output, 
					@LMCasActivi output, @LMCasOcazPM output, @LMCasOcazPCA output, @LMCasBoln output, 
					@LMSomajActivi output, @LMSomajOcaz output, @LMSomajBoln output, 
					@LMCassActivi output, @LMCassOcazP output, @LMCassOcazO output, @LMCassFaambp output, 
					@LMSumaNeimpActivi output, @LMSumaNeimpBoln output, 
					@LMAvansActivi output, @LMAvansBoln output, @LMAvansOcazO output, @LMAvansOcazP output, 
					@LMSubvSomaj output, @LMCCIFaambp output

					insert into #rectificari (numarDoc)
					select @NumarDocRectif
				fetch next from rectificari into @data_rectificata
			End
			close rectificari
			Deallocate rectificari
		End	

		if exists (select * from sysobjects where name ='PSGenNCSalariiSP')
			exec PSGenNCSalariiSP @sesiune=null, @parXML=null

--	pt. pozadoc am facut cursor, pana se vor putea trimite mai multe documente odata, sau le vom trece pe RS-uri.
--	scriu note contabile
		declare @docPozncon xml, @NrPozitiePozncon int
		select @NrPozitiePozncon=max(Nr_pozitie) from pozncon where tip='PS' and numar=@NumarDoc and data=@dataSus
		select @NrPozitiePozncon=isnull(@NrPozitiePozncon,0)
		set @docPozncon=
			(select a.Data as '@data', a.Tip as '@tip', rtrim(a.Numar) as '@numar',
				(select rtrim(d.Cont_debitor) as '@cont_debitor', rtrim(d.Cont_creditor) as '@cont_creditor', convert(decimal(15,2),d.Suma) as '@suma',
					rtrim(d.Explicatii) as '@ex', @NrPozitiePozncon+d.Nr_pozitie as '@nr_pozitie', 
					rtrim(d.Loc_munca) as '@lm', rtrim(left(d.Comanda,20)) as '@comanda', rtrim(substring(d.Comanda,21,20)) as '@indbug', 
				    rtrim(d.Jurnal) as '@jurnal', d.detalii
				from #docPozncon d
					left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=d.Loc_munca
				where (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
					and d.Subunitate=a.Subunitate and d.Tip=a.Tip and d.Numar=a.Numar and d.Data=a.Data
				order by d.Nr_pozitie
				for XML path,type)
			from #docPozncon a
			Group by a.Subunitate, a.Numar, a.Data, a.Tip
			for xml path,root('Date'))

		exec wScriuNcon @sesiune=null, @parXML=@docPozncon

		if OBJECT_ID('tempdb..#diurne') is not null drop table #diurne
		Create table #diurne (marca varchar(6))
		exec CreeazaDiezDiurne @numeTabela='#Diurne'
		insert into #diurne
		exec pCalculDiurne @dataJos, @dataSus, @marca='', @lm=''

--	scriu plati incasari
		declare @docPozplin xml
		set @docPozplin=
			(select 'DE' as '@tip', rtrim(a.Cont) as '@cont', a.data as '@data', 
				(select rtrim(d.Cont_corespondent) as '@contcorespondent', convert(decimal(15,2),d.Suma) as '@suma',
					rtrim(d.numar) as '@numar', rtrim(d.numar) as '@decont', rtrim(d.Cont_dif) as '@marca', d.plata_incasare as '@subtip', 
					d.Numar_pozitie as '@numarpozitie', rtrim(d.Cont_dif) as '@contdif', 
					rtrim(d.Loc_de_munca) as '@lm', rtrim(left(d.Comanda,20)) as '@comanda', rtrim(substring(d.Comanda,21,20)) as '@indbug', 
				    rtrim(tert) as '@tert', rtrim(factura) as '@factura', rtrim(jurnal) as '@jurnal', 
					convert(decimal(12,4),isnull(di.Curs,0)) as '@curs', rtrim(isnull(di.valuta,'')) as '@valuta', isnull(di.diurna,0) as '@sumavaluta',
					left(rtrim(d.Explicatii)+(case when isnull(d.idDiurna,0)<>0 
						then ' ('+left(convert(char(10),di.Data_inceput,103),5)+'-'+left(convert(char(10),di.Data_sfarsit,103),5)+')' else '' end),50) as '@explicatii'
				from #docPozplin d
					left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=d.Loc_de_munca
					left outer join #diurne di on d.idDiurna=di.idDiurna
				where (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
					and d.Subunitate=a.Subunitate and d.Cont=a.Cont and d.Data=a.Data
				for XML path,type)
			from #docPozplin a
			Group by Subunitate, a.Cont, a.Data
			for xml path,root('Date'))

		if @docPozplin is not null
			exec wScriuPlin @sesiune=null, @parXML=@docPozplin

--	scriu pozitii alte documente (FF-uri)
		declare @docPozadoc xml, @tip char(2), @numar_document varchar(10), @data datetime, @tert varchar(20)

		declare FFPozadoc cursor for
		select distinct tip, numar_document, data, tert
		from #docPozadoc a
		open FFPozadoc
		fetch next from FFPozadoc into @tip, @numar_document, @data, @tert
		While @@fetch_status = 0 
		Begin
			set @docPozadoc=
				(select @Tip as '@tip', @Data as '@data', rtrim(@numar_document) as '@numar', rtrim(@tert) as '@tert', 
					(select d.Tip as '@subtip', rtrim(d.Cont_deb) as '@contdeb', rtrim(d.Cont_cred) as '@contcred', 
						rtrim(d.Factura_stinga) as '@facturastinga', rtrim(d.Factura_dreapta) as '@facturadreapta', 
						convert(decimal(15,2),d.Suma) as '@suma',
						rtrim(d.Explicatii) as '@explicatii', d.Numar_pozitie as '@numarpozitie', 
						rtrim(d.Loc_munca) as '@lm', rtrim(left(d.Comanda,20)) as '@comanda', rtrim(substring(d.Comanda,21,20)) as '@indbug', 
						d.Data_fact as '@datafacturii', d.Data_scad as '@dataSuscadentei', rtrim(d.Jurnal) as '@jurnal'
					from #docPozadoc d
						left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=d.Loc_munca
					where (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null) 
						and d.tip=@tip and d.numar_document=@numar_document and d.data=@data and d.Tert=@tert
					for XML path,type)
				for xml path,type)

				if @docPozadoc is not null
					exec wScriuPozadoc @sesiune=null, @parXML=@docPozadoc
	
			fetch next from FFPozadoc into @tip, @numar_document, @data, @tert
		End
		close FFPozadoc
		Deallocate FFPozadoc

--	scriu pozitii documente (CM-uri tichete de masa)
		if @NCTichete=1 and @cTipDoc='2'
		Begin
			declare @docPozdoc xml
			set @docPozdoc=
				(select top 1 a.tip as '@tip', rtrim(a.Numar) as '@numar', a.Data as '@data', 1 as '@numarpozitii', 
					(select d.Tip as '@subtip', rtrim(d.Cod) as '@cod', rtrim(d.Gestiune) as '@gestiune', 
						convert(decimal(15,2),d.Cantitate) as '@cantitate', RTRIM(d.Cont_corespondent) as '@contcorespondent',
						rtrim(d.Loc_de_munca) as '@lm', rtrim(left(d.Comanda,20)) as '@comanda', rtrim(substring(d.Comanda,21,20)) as '@indbug', rtrim(d.Jurnal) as '@jurnal'
					from #docPozdoc d
						left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=d.Loc_de_munca
					where (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
						and d.Subunitate=a.Subunitate and d.Tip=a.Tip and d.Numar=a.Numar and d.Data=a.Data
					for XML path,type)
				from #docPozdoc a	
				for xml path,type)

			if @docPozdoc is not null
				if exists (select * from sysobjects where name ='wScriuDoc')
					exec wScriuDoc @sesiune=null, @parXML=@docPozdoc
				else
					if exists (select * from sysobjects where name ='wScriuDocBeta')
						exec wScriuDocBeta @sesiune=null, @parXML=@docPozdoc
					else
						exec wScriuPozdoc @sesiune=null, @parXML=@docPozdoc
		End		

		if @ParteProc=0 or @ParteProc=7
		begin
--		pus aici apelarea procedurii specifice sp2
			if @lApelProcNC2=1
				exec genncsp2 @dataJos, @dataSus

			if exists (select * from sysobjects where name ='faInregistrariContabile')
			begin
				if object_id('tempdb..#DocDeContat') is not null
					drop table #DocDeContat
				else
					create table #DocDeContat (subunitate varchar(9), tip varchar(2), numar varchar(20), data datetime)

				insert into #DocDeContat (subunitate, tip, numar, data)
				select @sub, 'PS', @NumarDoc, @datasus	-- note contabile standard
				union all
				select distinct @sub, 'PS', NumarDoc, @datasus	-- note contabile din rectificari
				from #rectificari
				union all
				select @sub, 'CM', @NumarDocTich, @datasus	-- consumuri pentru tichete de masa
				where @NCTichete=1 and @cTipDoc='2'	
				union all
				select distinct @sub, 'PI', cont, @datasus	-- retineri generate ca si deconturi
				from pozplin
				where @NCRetCaDecont=1 and Subunitate=@sub and data=@dataSus and Plata_incasare='PD' 
					and numar between (case when @NCNrDecNrDocRet=0 then rtrim(@cDataDoc1) else '' end) and (case when @NCNrDecNrDocRet=0 then rtrim(@cDataDoc1) else '' end)+'ZZZ' 
					and explicatii like 'Retinere marca'+'%'
				union all
				select distinct @sub, 'PI', cont, @datasus	-- contributii individuale pentru salariati ocazionali generate ca plati furnizor
				from pozplin
				where subunitate=@Sub and plata_incasare='PF' and numar like rtrim(@NumarDoc)+'%' 
					and data=@dataSus and tert like 'M'+'%' and factura=@NumarDoc
				union all
				select distinct @sub, 'AD', Numar_document, @datasus	-- salarii pentru salariati ocazionali generate ca Facturi furnizori
				from pozadoc 
				where Subunitate=@sub and data=@dataSus and tip='FF' and tert like 'M%' and Numar_document like rtrim(@NumarDoc)+'%'

				exec faInregistrariContabile @dinTabela=2
			end

			if @multiFirma=1
				select @lm=isnull(min(Cod),'') from LMfiltrare where utilizator=@userASiS and cod in (select cod from lm where Nivel=1)

			declare @comandaSql nvarchar(max)
			SET @comandaSql = N'delete from '+(case when @multiFirma=0 then 'par' else 'parlm' end)
				+' where '+(case when @multiFirma=1 then 'loc_de_munca=@lm and' else '' end)+' Tip_parametru=''PS'' and Parametru=''NRPOZNC'''
			exec sp_executesql @statement=@comandaSql, @params=N'@lm char(9)', @lm=@lm

			Set @parGNC='NC_'+@cDataDoc
			Set @val_a=rtrim(@userASiS)+' '+convert(char(10),getdate(),103)+' '+convert(char(8),getdate(),108)
			exec setare_par 'PS', @parGNC, 'Ultima generare nota sal.', 0, 0, @val_a
		end
		else 
			exec setare_par 'PS','NRPOZNC',	'Ultimul nr. poz. NC salarii', 1, @NrPozitie, Null

	End

	if object_id('tempdb..#brut') is not null drop table #brut
	if object_id('tempdb..#brutMarca') is not null drop table #brutMarca
	if object_id('tempdb..#net') is not null drop table #net
End try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura PSGenNCSalarii (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch

/*
	exec PSGenNCSalarii '12/01/2012', '12/31/2012', '', 1, 1, 0, 1, 1, 0, 0
*/
