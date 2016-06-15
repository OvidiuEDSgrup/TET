--***
/**	proc. calcul brut net	*/
Create procedure psCalculBrutNet 
	@dataJos datetime, @dataSus datetime, @MarcaJ char(6), @LocmJ char(9), @Precizie int, @pTipCorectieVenit char(2)
As
Begin
	declare @gMarca char(6), @OreLuna int, @pCASInd decimal(7,2), @pSomajInd decimal(7,2), @SalarMinim decimal(10), @SalarMediu decimal(10), 
	@CodSindicat char(13), @ProcSindicat float, @SindicatProc float, @STOUG28 int, @SalarNetRef decimal(10), 
	@NrTichete int, @ValTichet decimal(7,2), @ImpozitTichete int, @DataImpTicJ datetime, @DataImpTicS datetime, 
	@Compexit int, @Data datetime, @Marca char(6), @Loc_de_munca char(9), @Tip_corectie_venit char(2), 
	@Suma_corectie float, @Procent_corectie float, @SumaNeta float, @Salar_de_incadrare float, @Grupa_de_munca char(1), 
	@TipImpoz char(1), @SomajPers float, @CASSPers float, @Sindicalist int, @DataAngajarii datetime, @TipDeducere char(3), 
	@GradInvalid char(1), @SumaCorectieO float, @RetinutSindicat float, @NrPersIntr int, @regimLucru float, @oreJustificate int, 
	@ZileCM int, @IndemnizatieCAS decimal(10), @IndCM8Neimpoz decimal(10), @VenitTotal decimal(10), @RestDePlata float, @VenitBaza decimal(10), @Impozit decimal(10), @BazaCASInd decimal(10), 
	@CASInd decimal(10), @VenitSalarNet decimal(10),  @VenitNetInImp decimal(10), @DedPers float, @Ded_suplim float, 
	@PensieFacult decimal(10), @BazaCASSInd float, @CASSInd decimal(10), @BazaSomaj decimal(10), @SomajInd decimal(10), 
	@SomajTehnic decimal(7), @ValoareTichete decimal(7,2), @AvantajeMat decimal(7), @ValTichCompexit decimal(10), 
	@CorectieBazaCAS decimal(10), @CorectieBazaCASS decimal(10), @CorectieBazaSomaj decimal(10), @CorectieCAS decimal(10), @CorectieCASS decimal(10), @CorectieSomaj decimal(10), 
	@CorectieVenitBrut decimal(10), @CorectieVenitNetInImp decimal(10), @CorectieVenitBaza decimal(10), @CorectieSalarNetBaza decimal(10), @CorectieVenitSalarNet decimal(10)

	Exec Luare_date_par 'PS', 'SIND%', @SindicatProc OUTPUT, @ProcSindicat OUTPUT, @CodSindicat OUTPUT
/*
	if not exists (select * from sysobjects where name ='MarciBN')
		Create table MarciBN (Marca char(6), Tip_corectie char(2), nr int identity)
	if exists (select * from sysobjects where name ='MarciBN')
		truncate table MarciBN 
*/
	set @OreLuna=dbo.iauParLN(@dataSus,'PS','ORE_LUNA')
	set @pCASInd=dbo.iauParLN(@dataSus,'PS','CASINDIV')
	set @pSomajInd=dbo.iauParLN(@dataSus,'PS','SOMAJIND')
	set @SalarMinim=dbo.iauParLN(@dataSus,'PS','S-MIN-BR')
	set @SalarMediu=dbo.iauParLN(@dataSus,'PS','SALMBRUT')
	set @SalarNetRef=dbo.iauParN('PS','S-NET-REF')
	set @NrTichete=dbo.iauParLN(@dataSus,'PS','NRTICHETE')
	set @ValTichet=dbo.iauParLN(@dataSus,'PS','VALTICHET')
	set @ImpozitTichete=dbo.iauParLL(@dataSus,'PS','DJIMPZTIC')
	set @DataImpTicJ=dbo.iauParLD(@dataSus,'PS','DJIMPZTIC')
	set @DataImpTicS=dbo.iauParLD(@dataSus,'PS','DSIMPZTIC')
	set @DataImpTicJ=(case when @DataImpTicJ='01/01/1901' then @dataJos else @DataImpTicJ end)
	set @DataImpTicS=(case when @DataImpTicS='01/01/1901' then @dataSus else @DataImpTicS end)
	set @STOUG28=dbo.iauParLL(@dataSus,'PS','STOUG28')
	set @Compexit=dbo.iauParL('SP','COMPEXIT')

	set @ValTichCompexit=(case when @Compexit=1 and @SalarNetRef<>0 then round(@NrTichete*@ValTichet,0) else 0 end)
	select @CorectieBazaCAS=0, @CorectieBazaCASS=0, @CorectieBazaSomaj=0, @CorectieCAS=0, 
		@CorectieCASS=0, @CorectieSomaj=0, @CorectieVenitBrut=0, @CorectieVenitNetInImp=0, 
		@CorectieVenitBaza=0, @CorectieSalarNetBaza=0, @CorectieVenitSalarNet=0, @gMarca=''
	
	if object_id('tempdb..#brut') is not null drop table #brut
	select data, marca, sum(Ind_invoiri) as somaj_tehnic, 
		sum(ore_lucrate_regim_normal+Ore_intrerupere_tehnologica+ore_obligatii_cetatenesti+ore_concediu_de_odihna+ore_concediu_medical
			+ore_invoiri+ore_nemotivate+ore_concediu_fara_salar) as ore_justificate
	into #brut
	from brut
	where Data between @dataJos and @dataSus and (@MarcaJ='' or Marca=@MarcaJ) 
	group by data, marca

	declare CalculBrutNet cursor for
	select a.Data, a.Marca, a.Loc_de_munca, a.Tip_corectie_venit, a.Suma_corectie, a.Procent_corectie, a.Suma_neta, 
		p.Salar_de_incadrare, p.Grupa_de_munca, p.Tip_impozitare, (case when p.Somaj_1=1 then @pSomajInd else 0 end), 
		p.As_sanatate, convert(char(1),p.Sindicalist), p.Data_angajarii_in_unitate, 
		(case when p.Grupa_de_munca in ('N','D','S','C') and p.tip_colab='' 
		and exists (select 1 from vechimi v where v.Marca=b.Marca and v.Tip='T' and v.Data_sfarsit between @datajos and p.Data_angajarii_in_unitate) then 'FDP' else p.tip_colab end), 
		p.Grad_invalid, (case when 1=1 then 0 else isnull(co.Suma_corectie,0) end), 
		isnull(r.Retinut_la_lichidare,0)*(case when @SindicatProc=1 and @ProcSindicat>1 then 1/@ProcSindicat else 1 end), 
		isnull(d.Zile_lucratoare,0), isnull(d.Indemnizatie_cas,0), n.Venit_total, n.Rest_de_plata, n.Venit_baza, n.Impozit, 
		n.Baza_cas, n.Pensie_suplimentara_3, n.Venit_net, n.VEN_NET_IN_IMP, n.Ded_baza, n.Ded_suplim, isnull(n1.Ded_baza,0), 
		n.Venit_total-isnull(d1.Indemnizatie_CM,0)-(case when @STOUG28=1 then isnull(b.somaj_tehnic,0) else 0 end), 
		n.Asig_sanatate_din_net, n.Asig_sanatate_din_CAS, n.Somaj_1, 
		(case when @STOUG28=1 then isnull(b.somaj_tehnic,0) else 0 end), 
		(case when @dataJos>='07/01/2010' then isnull(t.Valoare_tichete,0) else 0 end), isnull(q.Suma_corectie,0), 
		isnull((select count(1) from persintr s where s.data=@dataSus and s.marca=a.marca and s.coef_ded<>0),0), rl.RL, b.ore_justificate
	from corectii a 
		left outer join personal p on a.Marca=p.Marca
		left outer join dbo.fDate_pontaj_automat (@dataJos, @dataSus, @dataSus, 'RL', '', 0, 0) rl on a.Marca=rl.Marca
		left outer join corectii co on co.Data=@dataSus and a.Marca=co.Marca and co.Tip_corectie_venit='O-' 
		left outer join #brut b on a.Marca=b.Marca and b.data=@dataSus
		left outer join extinfop e on e.marca=a.marca and e.cod_inf='SINDICAT' and e.Val_inf<>''
		left outer join resal r on r.Data=@dataSus and a.Marca=r.Marca and r.Cod_beneficiar=isnull(e.Val_inf,@CodSindicat) and (not(p.sindicalist=1 and @ProcSindicat<>0) or r.numar_document='SINDICAT')
		left outer join (select Marca, Data, sum(zile_lucratoare) as Zile_lucratoare, sum(indemnizatie_cas) as Indemnizatie_cas, sum(indemnizatie_unitate) as Indemnizatie_unitate 
			from conmed where Data=@dataSus and (Tip_diagnostic='8-' or Tip_diagnostic='9-' or Tip_diagnostic='15') group by Data, Marca) d on d.Data=@dataSus and a.Marca=d.Marca
		left outer join (select Marca, Data, sum(zile_lucratoare) as Zile_lucratoare, sum(indemnizatie_cas+indemnizatie_unitate) as Indemnizatie_CM 
			from conmed where Data=@dataSus group by Data, Marca) d1 on d1.Data=@dataSus and a.Marca=d1.Marca
		left outer join net n on n.Data=@dataSus and a.Marca=n.Marca  
		left outer join net n1 on n1.Data=@dataJos and a.Marca=n1.Marca  
		left outer join dbo.fNC_tichete (@DataImpTicJ, @DataImpTicS, @MarcaJ, 1) t on @ImpozitTichete=1 and a.Marca=t.Marca /*t.Data=@dataSus*/
		left outer join dbo.fSumeCorectie (@dataJos, @dataSus, 'Q-', @MarcaJ, '', 0) q on q.Data=a.Data and q.Marca=a.Marca 
	where a.Data between @dataJos and @dataSus and (@MarcaJ='' or a.Marca=@MarcaJ) 
		and (@LocmJ='' or a.Loc_de_munca like rtrim(@LocmJ)+'%') and a.Suma_neta>=1 and a.Tip_corectie_venit=@pTipCorectieVenit 
	Order by a.Data, a.Marca, a.Loc_de_munca, a.Tip_corectie_venit

	open CalculBrutNet
	fetch next from CalculBrutNet into @Data, @Marca, @Loc_de_munca, @Tip_corectie_venit, @Suma_corectie, @Procent_corectie, 
		@SumaNeta, @Salar_de_incadrare, @Grupa_de_munca, @TipImpoz, @SomajPers, @CASSPers, @Sindicalist, @DataAngajarii, 
		@TipDeducere, @GradInvalid, @SumaCorectieO, @RetinutSindicat, @ZileCM, @IndemnizatieCAS, @VenitTotal, 
		@RestDePlata, @VenitBaza, @Impozit, @BazaCASInd, @CASInd, @VenitSalarNet, @VenitNetInImp, @DedPers, @Ded_suplim, 
		@PensieFacult, @BazaCASSInd, @CASSInd, @BazaSomaj, @SomajInd, @SomajTehnic, @ValoareTichete, @AvantajeMat, @NrPersIntr, @regimLucru, @oreJustificate
	While @@fetch_status = 0 
	Begin
		select @CorectieBazaCAS=0, @CorectieBazaCASS=0, @CorectieBazaSomaj=0, @CorectieCAS=0, @CorectieCASS=0, 			
			@CorectieSomaj=0, @CorectieVenitBrut=0, @CorectieVenitNetInImp=0, @CorectieVenitBaza=0, @CorectieSalarNetBaza=0, 		
			@CorectieVenitSalarNet=0 
		where @gMarca<>@Marca
		set @IndCM8Neimpoz=@IndemnizatieCAS-round(@ZileCM*0.35*@SalarMediu/(@OreLuna/8)*@pCASInd/100,0)
/*	
		if isnull((select count(1) from MarciBN where Marca=@Marca and Tip_corectie=@pTipCorectieVenit),0)=0
		insert into MarciBN values(@marca, @pTipCorectieVenit)
*/	
		exec psBuclaBrutNet @dataJos, @dataSus, @Data, @Marca, @Loc_de_munca, @Precizie, @pTipCorectieVenit,
		@SumaNeta, @Grupa_de_munca, @TipImpoz, @SomajPers, @DataAngajarii, @TipDeducere, @GradInvalid, 
		@CASSPers, @regimLucru, @oreJustificate, @NrPersIntr, @IndCM8Neimpoz, @VenitTotal, @VenitBaza, @Impozit, @BazaCASInd, @CASInd, 
		@BazaCASSInd, @CASSInd, @BazaSomaj, @SomajInd, @VenitSalarNet, @VenitNetInImp, @DedPers, 
		@PensieFacult, @RetinutSindicat, @SomajTehnic, @ValTichCompexit, @ValoareTichete, @AvantajeMat, 
		@CorectieBazaCAS OUTPUT, @CorectieBazaCASS OUTPUT, @CorectieBazaSomaj OUTPUT, @CorectieCAS OUTPUT, 	
		@CorectieCASS OUTPUT, @CorectieSomaj OUTPUT, @CorectieVenitBrut OUTPUT, @CorectieVenitNetInImp OUTPUT, 		
		@CorectieVenitBaza OUTPUT, @CorectieSalarNetBaza OUTPUT, @CorectieVenitSalarNet OUTPUT
		set @gMarca=@Marca

		fetch next from CalculBrutNet into @Data, @Marca, @Loc_de_munca, @Tip_corectie_venit, @Suma_corectie, 			
			@Procent_corectie, @SumaNeta, @Salar_de_incadrare, @Grupa_de_munca, @TipImpoz, @SomajPers, @CASSPers, 			
			@Sindicalist, @DataAngajarii, @TipDeducere, @GradInvalid, @SumaCorectieO, @RetinutSindicat, @ZileCM, 				
			@IndemnizatieCAS, @VenitTotal, @RestDePlata, @VenitBaza, @Impozit, @BazaCASInd, @CASInd, @VenitSalarNet, 			
			@VenitNetInImp, @DedPers, @Ded_suplim, @PensieFacult, @BazaCASSInd, @CASSInd, @BazaSomaj, @SomajInd, 			
			@SomajTehnic, @ValoareTichete, @AvantajeMat, @NrPersIntr, @regimLucru, @oreJustificate
	End
	close CalculBrutNet
	Deallocate CalculBrutNet
End
