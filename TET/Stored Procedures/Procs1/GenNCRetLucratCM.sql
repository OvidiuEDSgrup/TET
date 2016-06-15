/* operatie pt. calcul net din timp lucrat si CM  - specific Salubris - poate fi si un caz general pe viitor */
Create procedure GenNCRetLucratCM
	@DataJ datetime, @DataS datetime, @Marca char(6), @Continuare int output, @NumarDoc char(10), 
	@Explicatii char(50), @NrPozitie int output, @Loc_de_munca char(9), 
	@pCont_debitor varchar(20), @pCont_creditor varchar(20), @NetLucrat decimal(10,2) output, 
	@NetCMUnitate decimal(10,2) output, @NetCMCas decimal(10,2) output, @RetinereDeContat decimal(10,2),
	@CodBeneficiar char(13)=''
As
Begin
	declare @NCRetCaDecont int, @CreditChelt varchar(20), @CreditCMUnitate1 varchar(20), @CreditCMCas1 varchar(20),
	@ContDebitor varchar(20), @ContCreditor varchar(20), @RetinereContata decimal(10,2)
	Set @NCRetCaDecont=dbo.iauParL('PS','NC-RET-M')
	Set @CreditChelt=dbo.iauParA('PS','N-C-SAL1C')
	Set @CreditCMUnitate1=dbo.iauParA('PS','N-C-CMU1C')
	Set @CreditCMCas1=dbo.iauParA('PS','N-C-CMC1C')
	
	While not(@NetLucrat=0 AND @NetCMUnitate=0 AND @NetCMCas=0 OR @RetinereDeContat=0)
	Begin
		Set @RetinereContata=(case when @CodBeneficiar='1256' then @RetinereDeContat when @NetLucrat>0 then dbo.Valoare_minima(@RetinereDeContat,@NetLucrat,0)
		else (case when @NetCMUnitate>0 then dbo.Valoare_minima(@RetinereDeContat,@NetCMUnitate,0) 
		else dbo.Valoare_minima(@RetinereDeContat,@NetCMCas,0) end) end)
		Set @ContDebitor=(case when @NetLucrat>0 or @CodBeneficiar='1256' then @pCont_debitor when @NetCMUnitate>0 then @CreditCMUnitate1 else @CreditCMCas1 end)
		Set @ContCreditor=rtrim(@pCont_creditor)+(case when @NCRetCaDecont=1 then '' else '.'+rtrim(@Marca) end)
		if @Continuare=1
			exec scriuNCsalarii @DataS, @ContDebitor, @ContCreditor, @RetinereContata, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @Loc_de_munca, '', '', 0, @Marca, '', 0

		Set @RetinereDeContat=@RetinereDeContat-@RetinereContata
		if @NetCMCas<>0 and @NetLucrat=0 and @NetCMUnitate=0
			Set @NetCMCas=@NetCMCas-@RetinereContata
		if @NetCMUnitate<>0 and @NetLucrat=0
			Set @NetCMUnitate=@NetCMUnitate-@RetinereContata
		if @NetLucrat<>0
			Set @NetLucrat=@NetLucrat-@RetinereContata
	End
End
