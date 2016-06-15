--***
/**	proc. bucla brut net	*/
Create procedure psBuclaBrutNet 
	@dataJos datetime, @dataSus datetime, @DataCor datetime, @marcaJos char(6), @locmJos char(9), @Precizie int, @pTipCorectie char(2),
	@pSumaNeta decimal(7), @GrpMunca char(1), @TipImpoz char(1), @pSomajPers float, @DataAngajarii datetime, 
	@TipDeducere char(3), @GradInvalid char(1), @pCASSPers float, @regimLucru float, @oreJustificate int, @NrPersIntr int, @IndCM8Neimpoz decimal(7), 
	@pVenitTotal decimal(7), @pVenitBaza decimal(7), @pImpozit decimal(7), @pBazaCASInd decimal(7), @CASIndTNet decimal(7), 
	@pBazaCASSInd decimal(7), @CASSTNet decimal(7), @pBazaSomaj decimal(7), @SomajTNet decimal(7), 
	@pVenitSalarNet decimal(7), @pVenitNetInImp decimal(7), @pDedPers decimal(7), @pPensieFacult decimal(7), 
	@RetSindicat decimal(7), @SomajTehnic decimal(7), @pValTichCompexit decimal(7,2), @ValoareTichete decimal(7,2), @AvantajeMat decimal(7), 
	@CorectieBazaCAS decimal(7) OUTPUT, @CorectieBazaCASS decimal(7) OUTPUT, @CorectieBazaSomaj decimal(7) OUTPUT, 
	@CorectieCAS decimal(7) OUTPUT, @CorectieCASS decimal(7) OUTPUT, @CorectieSomaj decimal(7) OUTPUT, 
	@CorectieVenitBrut decimal(7) OUTPUT, @CorectieVenitNetInImp decimal(7) OUTPUT, @CorectieVenitBaza decimal(7) OUTPUT, 
	@CorectieSalarNetBaza decimal(7) OUTPUT, @CorectieVenitSalarNet decimal(7) OUTPUT
As
Begin
	declare @oreLuna float, @SalarMediu float, @pCasind float, @DedPersLCrt int, @DedPersOreLucrate int, @ReglSalNetTN int, @AdVenNet_Q int, @Drumor int, @Colas int, @Velpitar int, 
	@BrutInf float, @BrutSup float, @BrutManevra float, @SumaNeta decimal(7), @CASBrutManevra decimal(7), 
	@CASSBrutManevra decimal(7), @SomajBrutManevra decimal(7), @VenitBazaImp float, @SalarNetBaza float, 
	@BazaImpozitManevra decimal(10), @ImpozitManevra float, @SalarNetManevra float, @VenitBazaCASInd float, 
	@CASIndividual decimal(7), @BazaCASSInd decimal(7), @CASSInd decimal(7), @BazaSomajInd decimal(7), @SomajInd decimal(7), 
	@VenitSalarNet decimal(7), @DifVenitNetInImp float, @VenitBrut float, @VenitNetInImp float, @ImpozitSumaImpSep float, @Iteratia int, @BrutManevraCuDed float, 
	@DedPers float, @PensieFacult decimal(7), @BrutPtDeducere float, @CASManevra decimal(7), @CASSManevra decimal(7), @SomajManevra decimal(7), 
	@CorectieCASPoz decimal(7), @CorectieCASSPoz decimal(7), @CorectieSomajPoz decimal(7), @CorectezBrutManevra decimal (7), @ConditieUpdate int, @ConditieDedPers int

	set @oreLuna=dbo.iauParLN(@dataSus,'PS','ORE_LUNA')
	set @SalarMediu=dbo.iauParLN(@dataSus,'PS','SALMBRUT')
	set @pCASInd=dbo.iauParLN(@dataSus,'PS','CASINDIV')
	set @DedPersLCrt=dbo.iauParL('PS','CHINDLCRT')
	set @DedPersOreLucrate=dbo.iauParL('PS','CHINDPON')
	set @ReglSalNetTN=dbo.iauParL('PS','REGSALNTN')
	set @AdVenNet_Q=dbo.iauParL('PS','ADVNET-Q')
	set @Drumor=dbo.iauParL('SP','DRUMOR')
	set @Colas=dbo.iauParL('SP','COLAS')
	set @Velpitar=dbo.iauParL('SP','VELPITAR')
	set @ConditieDedPers=(case when @GrpMunca not in ('O','P') and @TipDeducere<>'FDP' and not(day(@DataAngajarii)<>1 and month(@DataAngajarii)=month(@dataJos) and year(@DataAngajarii)=year(@dataJos) 
		and @Drumor=0 and @DedPersLCrt=0) then 1 else 0 end)

	select @Iteratia=0, @DedPers=0, @ImpozitSumaImpSep=0, @DifVenitNetInImp=0, @BazaImpozitManevra=0, @ImpozitManevra=0, @CorectezBrutManevra=0, @CASBrutManevra=0, 
		@CASSBrutManevra=0, @SomajBrutManevra=0
	if @ReglSalNetTN=1 and @Velpitar=0 and @pTipCorectie='H-'
	Begin
		set @VenitSalarNet=0 
		set @VenitBazaImp=@pVenitBaza+@CorectieVenitBaza
		set @SalarNetBaza=@pVenitBaza-@pImpozit+@CorectieSalarNetBaza
		set @VenitBazaCASInd=@pBazaCASInd+@CorectieBazaCAS
		set @CASIndividual=@CASIndTNet+@CorectieCAS
		set @VenitSalarNet=@pVenitSalarNet+@CorectieVenitSalarNet
		select @DifVenitNetInImp=@pVenitNetInImp-@pDedPers where @pVenitNetInImp<@pDedPers
		set @VenitBrut=@pVenitTotal+@CorectieVenitBrut
		set @VenitNetInImp=@pVenitNetInImp+@CorectieVenitNetInImp
		set @PensieFacult=@pPensieFacult
		set @BazaCASSInd=@pBazaCASSInd+@CorectieBazaCASS
		set @CASSInd=@CASSTNet+@CorectieCASS
		set @BazaSomajInd=@pBazaSomaj+@CorectieBazaSomaj
		set @SomajInd=@SomajTNet+@CorectieSomaj
	End 
	set @SumaNeta=@pSumaNeta-(case when @ReglSalNetTN=1 and @Velpitar=0 and @pTipCorectie='H-' then @pValTichCompexit+@pVenitSalarNet else 0 end)
	set @BrutInf=@SumaNeta 
	set @BrutSup=5*@SumaNeta
	set @BrutManevra=round((@BrutInf+@BrutSup)/2.00,0)
	if not(@ReglSalNetTN=1 and @Velpitar=0 and @pTipCorectie='H-')
	Begin
		set @VenitBazaImp=@pVenitBaza+@CorectieVenitBaza
		set @SalarNetBaza=@pVenitBaza-@pImpozit+@CorectieSalarNetBaza
		set @VenitBazaCASInd=@pBazaCASInd+@CorectieBazaCAS
		set @CASIndividual=@CASIndTNet+@CorectieCAS
		set @VenitSalarNet=@pVenitSalarNet+@CorectieVenitSalarNet
		select @DifVenitNetInImp=@pVenitNetInImp-@pDedPers where @pVenitNetInImp<@pDedPers
		set @VenitBrut=@pVenitTotal+@CorectieVenitBrut
		set @VenitNetInImp=@pVenitNetInImp+@CorectieVenitNetInImp
		set @PensieFacult=@pPensieFacult
		set @BazaCASSInd=@pBazaCASSInd+@CorectieBazaCASS
		set @CASSInd=@CASSTNet+@CorectieCASS
		set @BazaSomajInd=@pBazaSomaj+@CorectieBazaSomaj
		set @SomajInd=@SomajTNet+@CorectieSomaj
	End
--select @pVenitTotal, @pVenitBaza, @pImpozit, @pBazaCASInd
	if @ConditieDedPers=1
	Begin
		set @BrutPtDeducere = round(@VenitBrut + @BrutManevra+@DifVenitNetInImp+@ValoareTichete+@AvantajeMat,0) 
		exec calcul_deducere @BrutPtDeducere, @NrPersIntr, @DedPers output, @oreJustificate, @oreLuna, @GrpMunca, @regimLucru
		if exists(select * from sysobjects where name='DedBazaSP' and type='P') 
			exec DedBazaSP @dataJos, @dataSus, @marcaJos, @DedPers output
	End

	select @CASBrutManevra=round((case when year(@dataSus)>=2011 and @VenitBazaCASInd+(case when @pTipCorectie='Q-' then 0 else @BrutManevra end)>5*@SalarMediu 
		then 5*@SalarMediu-@VenitBazaCASInd
--	then (case when 5*@SalarMediu-(@VenitBazaCASInd+@BrutManevra)<0 then 0 else 5*@SalarMediu-(@VenitBazaCASInd+@BrutManevra) end) 
		else (case when @pTipCorectie='Q-' then 0 else @BrutManevra end) end)*@pCASInd/100,0) 
	where @GrpMunca<>'O' or @TipDeducere in ('DAC','CCC','ECT')
	select @CASSBrutManevra=round(@BrutManevra*@pCASSPers/10/100,0) where @pTipCorectie<>'Q-'
	select @SomajBrutManevra=round(@BrutManevra*@pSomajPers/100,0) where @pTipCorectie<>'Q-'
	set @BrutManevraCuDed=@BrutManevra-@CASBrutManevra-@CASSBrutManevra-@SomajBrutManevra
	select @BazaImpozitManevra=(case when @BazaImpozitManevra<0 then 0 else @BazaImpozitManevra end)
	set @BazaImpozitManevra=round((@VenitNetInImp+@BrutManevraCuDed+(case when @DifVenitNetInImp < 0 then 0 else @DifVenitNetInImp end)
		-@DedPers-@RetSindicat-@PensieFacult-@IndCM8Neimpoz-@SomajTehnic+@Valoaretichete+(case when @AdVenNet_Q=1 then 0 else @AvantajeMat end)),0,1)

--	aplicare impozit la venit brut 
	if @TipImpoz='9'
		set @BazaImpozitManevra=@pVenitTotal+@BrutManevra
	select @ImpozitManevra=dbo.fCalcul_impozit_salarii(@BazaImpozitManevra,0,@ImpozitManevra) where @TipImpoz<>'3' and @GradInvalid not in ('1','2') and @BazaImpozitManevra>=0
	set @SalarNetManevra = @VenitBazaImp+@BrutManevraCuDed-@ImpozitManevra-@ImpozitSumaImpSep
--	bucla 
	While abs(@pSumaNeta-(case when @ReglSalNetTN=1 and @Velpitar=0 and @pTipCorectie='H-' then @pValTichCompexit+ @VenitSalarNet else 0 end) 
		- (@SalarNetManevra - @SalarNetBaza))>@Precizie --and @iteratia<11
	Begin
		set @ConditieUpdate=(case when (case when @ReglSalNetTN=1 and @Velpitar=0 and @pTipCorectie='H-' then abs(@pSumaNeta-@pValTichCompexit-@VenitSalarNet) else @pSumaNeta end)
			<abs((@SalarNetManevra-@SalarNetBaza)) then 1 else 0 end)
		select @BrutSup=@BrutManevra where @ConditieUpdate=1
		select @BrutInf=@BrutManevra where @ConditieUpdate=0
		set @BrutManevra=round((@BrutInf+@BrutSup)/2.0,0)
		select @CASBrutManevra=round((case when year(@dataSus)>=2011 and @VenitBazaCASInd+(case when @pTipCorectie='Q-' then 0 else @BrutManevra end)>5*@SalarMediu 
			then 5*@SalarMediu-@VenitBazaCASInd
--	then (case when 5*@SalarMediu-(@VenitBazaCASInd+@BrutManevra)<0 then 0 else 5*@SalarMediu-(@VenitBazaCASInd+@BrutManevra) end)
			else (case when @pTipCorectie='Q-' then 0 else @BrutManevra end) end)*@pCASInd/100,0) where @GrpMunca<>'O' or @TipDeducere in ('DAC','CCC','ECT')
		select @CASSBrutManevra=round(@BrutManevra*@pCASSPers/10/100,0) where @pTipCorectie<>'Q-'
		select @SomajBrutManevra=round(@BrutManevra*@pSomajPers/100.00,0) where @pTipCorectie<>'Q-'
		set @BrutManevraCuDed=@BrutManevra-@CASBrutManevra-@CASSBrutManevra-@SomajBrutManevra
--	select @BrutManevraCuDed, @CASBrutManevra, @CASSBrutManevra, @SomajBrutManevra
		if @ConditieDedPers=1
		Begin
			set @BrutPtDeducere=round(@VenitBrut+@BrutManevra+@DifVenitNetInImp+@ValoareTichete+@AvantajeMat,0) 
			exec calcul_deducere @BrutPtDeducere, @NrPersIntr, @DedPers output, @oreJustificate, @oreLuna, @GrpMunca, @regimLucru
			if exists(select * from sysobjects where name='DedBazaSP' and type='P') 
				exec DedBazaSP @dataJos, @dataSus, @marcaJos, @DedPers output
		End
		set @BazaImpozitManevra=round((@VenitNetInImp+@BrutManevraCuDed+(case when @DifVenitNetInImp < 0 then 0 else @DifVenitNetInImp end)
			-@DedPers-@RetSindicat-@PensieFacult-@IndCM8Neimpoz-@SomajTehnic+@Valoaretichete+(case when @AdVenNet_Q=1 then 0 else @AvantajeMat end)),0,1)
		select @BazaImpozitManevra=(case when @BazaImpozitManevra<0 then 0 else @BazaImpozitManevra end)
--		aplicare impozit la venit brut 
		if @TipImpoz='9'
			set @BazaImpozitManevra=@pVenitTotal+@BrutManevra
		select @ImpozitManevra=dbo.fCalcul_impozit_salarii(@BazaImpozitManevra,0,@ImpozitManevra) 
		where @TipImpoz<>'3' and @GradInvalid not in ('1','2') and @BazaImpozitManevra>=0
		set @SalarNetManevra=@VenitBazaImp+@BrutManevraCuDed-@ImpozitManevra-@ImpozitSumaImpSep
/*
		select 'brut', @BrutManevra, 'snb', @SalarNetBaza, 'snm', @SalarNetManevra, 'vbi', @VenitBazaImp,
		'cmcud', @BrutManevraCuDed, 'im', @ImpozitManevra, 'bim', @BazaImpozitManevra
*/		if @Iteratia>50
		begin
			declare @mesajEroare varchar(1000)
			select @mesajEroare='La marca '+rtrim(@marcajos)+' ('+rtrim(nume)+') nu s-a reusit calculul brut din net. Verificati datele introduse pentru acest salariat!'
			from personal where marca=@marcajos
			raiserror (@mesajEroare,11,1)
			break
		end

		set @Iteratia=@Iteratia+1
	End
--	specific Colas (au mai multe pozitii cu suma neta pe acelasi tip de corectie)
	if @Colas=1 and not(@ReglSalNetTN=1 and @Velpitar=0 and @pTipCorectie='H-') or 1=1 -- permis corectarea sumei nete pe caz general, pentru a nu mai avea diferente de +/- cativa lei.
	Begin
		select @CorectieCASPoz=(case when abs(round((@VenitBazaCASInd+@BrutManevra)*@pCASInd/100,0)-(@CASIndividual+round(@BrutManevra*@pCASInd/100,0)))=1 
			then round((@VenitBazaCASInd+@BrutManevra)*@pCASInd/100,0)-(@CASIndividual+round(@BrutManevra*@pCASInd/100,0)) else 0 end) --where @CASBrutManevra>0
		set @CorectieCASSPoz=(case when abs(round((@BazaCASSInd+@BrutManevra)*@pCASSPers/10/100,0)-(@CASSInd+round(@BrutManevra*@pCASSPers/10/100,0)))=1 
			then round((@BazaCASSInd+@BrutManevra)*@pCASSPers/10/100,0)-(@CASSInd+round(@BrutManevra*@pCASSPers/10/100,0)) else 0 end)
		set @CorectieSomajPoz=(case when abs(round((@BazaSomajInd+@BrutManevra)*@pSomajPers/100,0)-(@SomajInd+round(@BrutManevra*@pSomajPers/100,0)))=1 
			then round((@BazaSomajInd+@BrutManevra)*@pSomajPers/100,0)-(@SomajInd+round(@BrutManevra*@pSomajPers/100,0)) else 0 end)
		set @CASManevra=(@VenitBazaCASInd+@BrutManevra+@CorectieCASPoz+@CorectieCASSPoz+@CorectieSomajPoz)*@pCASInd/100
		set @CASSManevra=(@BazaCASSInd+@BrutManevra+@CorectieCASPoz+@CorectieCASSPoz+@CorectieSomajPoz)*@pCASSPers/10/100
		set @SomajManevra=(@BazaSomajInd+@BrutManevra+@CorectieCASPoz+@CorectieCASSPoz+@CorectieSomajPoz)*@pSomajPers/100
--	inlocuit @pSumaNeta cu @SumaNeta, pentru a functiona si in cazul in care se lucreaza cu salar net in lei (corectie H)
		set @CorectezBrutManevra=(case when abs(@VenitSalarNet+(case when 1=1 then @SumaNeta else @pSumaNeta end)-(@VenitBrut+@BrutManevra-@CASManevra-@CASSManevra-@SomajManevra-@ImpozitManevra))<4 
			then @VenitSalarNet+(case when 1=1 then @SumaNeta else @pSumaNeta end)-(@VenitBrut+@BrutManevra-@CASManevra-@CASSManevra-@SomajManevra-@ImpozitManevra) else 0 end)
		set @CorectieBazaCAS=@CorectieBazaCAS+@BrutManevra+@CorectezBrutManevra
		set @CorectieBazaCASS=@CorectieBazaCASS+@BrutManevra+@CorectezBrutManevra
		set @CorectieBazaSomaj=@CorectieBazaSomaj+@BrutManevra+@CorectezBrutManevra
		set @CorectieCAS=@CorectieCAS+(@BrutManevra+@CorectezBrutManevra)*@pCASInd/100
		set @CorectieCASS=@CorectieCASS+(@BrutManevra+@CorectezBrutManevra)*@pCASSPers/10/100
		set @CorectieSomaj=@CorectieSomaj+(@BrutManevra+@CorectezBrutManevra)*@pSomajPers/100
		set @CorectieVenitBrut=@CorectieVenitBrut+@BrutManevra+@CorectezBrutManevra
		set @CorectieVenitNetInImp=@CorectieVenitNetInImp+@BrutManevraCuDed
		set @CorectieVenitBaza=@CorectieVenitBaza+@BrutManevraCuDed
		set @CorectieSalarNetBaza=@CorectieSalarNetBaza+@VenitBazaImp+@BrutManevraCuDed-@ImpozitManevra-@SalarNetBaza
		set @CorectieVenitSalarNet=@CorectieVenitSalarNet+@SumaNeta
	End

	update corectii set suma_corectie = @BrutManevra+@CorectezBrutManevra
	where data = @DataCor and marca = @marcaJos and Loc_de_munca=@locmJos and tip_corectie_venit=@pTipCorectie
End
