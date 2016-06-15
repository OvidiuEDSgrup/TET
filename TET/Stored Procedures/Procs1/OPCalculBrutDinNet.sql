--***
/**	procedura pt. operatia de calcul brut din net (apelata separat de calcul lichidare) pt. verificari de sume */
Create procedure OPCalculBrutDinNet
	@dataSus datetime, @pSumaNeta decimal(10), @pVenitBrut decimal(10) OUTPUT, 
	@pAsigSanatate float, @pCASInd float, @pSomajInd float, @NrPersIntr int, @FaraDeducere int, 
	@pDedBaza decimal(10) OUTPUT, @tipimpozit int, @ProcentSindicat float, @Rotunjire int, 
	@pImpozit decimal(10) OUTPUT, @Spor decimal(10), @pSalarIncadrare decimal(7) OUTPUT
As
Begin
	declare @SalarMediu float, @BrutInf float, @BrutSup float, @BrutManevra float, 
	@CASBrutManevra decimal(7), @CASSBrutManevra decimal(7), @SomajBrutManevra decimal(7), 
	@BazaImpozitManevra decimal(10), @ImpozitManevra float, @SalarNetManevra float, 
	@Iteratia int, @BrutManevraCuDed float, @DedBaza float, @BrutPtDeducere float, @ConditieUpdate int

--	citire parametrii(salar mediu brut, procente contributii).
	set @SalarMediu=dbo.iauParLN(@dataSus,'PS','SALMBRUT')
	if @pAsigSanatate is null
		set @pAsigSanatate=dbo.iauParLN(@dataSus,'PS','CASSIND')
	if @pCASInd is null
		set @pCASInd=dbo.iauParLN(@dataSus,'PS','CASINDIV')
	if @pSomajInd is null 
		set @pSomajInd=dbo.iauParLN(@dataSus,'PS','SOMAJIND')

	if @NrPersIntr is null
		set @NrPersIntr=0
	if @FaraDeducere is null
		set @FaraDeducere=0
	if @tipimpozit is null
		set @tipimpozit=1

	select @DedBaza=0, @BrutManevraCuDed=0, @CASBrutManevra=0, @SomajBrutManevra=0, @CASSBrutManevra=0, @BazaImpozitManevra=0, @ImpozitManevra=0

	set @BrutInf=@pSumaNeta 
	set @BrutSup=5*@pSumaNeta
	set @BrutManevra=round((@BrutInf+@BrutSup)/2.00,0)
--	stabilire contributii individuale
	select @CASBrutManevra=round((case when @BrutManevra>5*@SalarMediu and @SalarMediu<>0
		then 5*@SalarMediu else @BrutManevra end)*@pCASInd/100,0) 
	set @CASSBrutManevra=round(@BrutManevra*@pAsigSanatate/100,0)
	set @SomajBrutManevra=round(@BrutManevra*@pSomajInd/100,0)
	set @BrutManevraCuDed=@BrutManevra-@CASBrutManevra-@CASSBrutManevra-@SomajBrutManevra
--	determinare deducere
	if @FaraDeducere=0
	Begin
		set @BrutPtDeducere = round(@BrutManevra,0) 
		exec calcul_deducere @BrutPtDeducere, @NrPersIntr, @DedBaza output
	End
--	determinare baza de calcul impozit/impozit
	set @BazaImpozitManevra=round((@BrutManevraCuDed-@DedBaza-round(@ProcentSindicat/100*@BrutManevra,0)),0,1)
	select @BazaImpozitManevra=(case when @tipimpozit=2 then @BrutManevra 
		when @BazaImpozitManevra<0 then 0 else @BazaImpozitManevra end)
	select @ImpozitManevra=dbo.fCalcul_impozit_salarii(@BazaImpozitManevra,0,@ImpozitManevra) 
	where @BazaImpozitManevra>=0 and @tipimpozit<>3
	set @SalarNetManevra = @BrutManevraCuDed-@ImpozitManevra

--	bucla pt. stabilire venit brut
	While abs(@pSumaNeta-@SalarNetManevra)>@Rotunjire --and @iteratia<11
	Begin
		set @ConditieUpdate=(case when @pSumaNeta<@SalarNetManevra then 1 else 0 end)
		select @BrutSup=@BrutManevra where @ConditieUpdate=1
		select @BrutInf=@BrutManevra where @ConditieUpdate=0
		set @BrutManevra=round((@BrutInf+@BrutSup)/2.0,0)
--		stabilire contributii individuale		
		select @CASBrutManevra=round((case when @BrutManevra>5*@SalarMediu and @SalarMediu<>0
			then 5*@SalarMediu else @BrutManevra end)*@pCASInd/100,0) 
		set @CASSBrutManevra=round(@BrutManevra*@pAsigSanatate/100,0)
		set @SomajBrutManevra=round(@BrutManevra*@pSomajInd/100.00,0)
		set @BrutManevraCuDed=@BrutManevra-@CASBrutManevra-@CASSBrutManevra-@SomajBrutManevra
--		determinare deducere
		if @FaraDeducere=0
		Begin
			set @BrutPtDeducere=round(@BrutManevra,0) 
			exec calcul_deducere @BrutPtDeducere, @NrPersIntr, @DedBaza output
		End
--		determinare baza de calcul impozit/impozit
		set @BazaImpozitManevra=round((@BrutManevraCuDed-@DedBaza-round(@ProcentSindicat/100*@BrutManevra,0)),0,1)
		select @BazaImpozitManevra=(case when @tipimpozit=2 then @BrutManevra 
			when @BazaImpozitManevra<0 then 0 else @BazaImpozitManevra end)
		select @ImpozitManevra=dbo.fCalcul_impozit_salarii(@BazaImpozitManevra,0,@ImpozitManevra) where @BazaImpozitManevra>=0 and @tipimpozit<>3
		set @SalarNetManevra=@BrutManevraCuDed-@ImpozitManevra

--		select 'brut man ', @BrutManevra, @BrutManevraCuDed, @ImpozitManevra, @DedPers

		set @Iteratia=@Iteratia+1
	End
	set @pImpozit=@ImpozitManevra
	set @pVenitBrut=@BrutManevra
	set @pDedBaza=@DedBaza
	set @pSalarIncadrare=@pVenitBrut/(1+@Spor/100)
End

/*
	declare @pVenitBrut decimal(7), @pImpozit decimal(7)=0, @pDedBaza decimal(7), @pSalarIncadrare decimal(10)
	exec OPCalculBrutDinNet '12/31/2011', 1000, @pVenitBrut OUTPUT, 5.5, 10.5, 0.5, 0, 0, @pDedBaza OUTPUT, 3, 0, 0, @pImpozit OUTPUT, 25, @pSalarIncadrare OUTPUT
	select @pVenitBrut, @pDedBaza
*/
