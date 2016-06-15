--***
/**	procedura pt. operatia de calcul net din brut (apelata separat de calcul lichidare) pt. verificari de sume */
Create procedure OPCalculNetDinBrut @parXML xml output
As
Begin
	declare @pAsigSanatate float, @pCASIndiv float, @pSomajIndiv float, 
		@dataSus datetime, @venitbrut decimal(10), @NrPersIntr int, @FaraDeducere int, 
		@asigsanatate float, @casindiv float, @somajindiv float, @dedBaza decimal(10), @tipimpozit int, @ProcentSindicat float, @Impozit decimal(10), @venitNet decimal(7), 
		@SalarMediu float, @venitBrutFaraContrib float, @BazaImpozit decimal(10) 

	select @dataSus = ISNULL(@parXML.value('(/row/@datasus)[1]', 'datetime'), ''),
		@venitbrut = ISNULL(@parXML.value('(/row/@venitbrut)[1]', 'decimal(10)'), ''),
		@NrPersIntr = ISNULL(@parXML.value('(/row/@nrpersintr)[1]', 'int'), 0),
		@FaraDeducere = ISNULL(@parXML.value('(/row/@faradeducere)[1]', 'int'), 0),
		@tipimpozit = ISNULL(@parXML.value('(/row/@tipimpozit)[1]', 'int'), 1),
		@ProcentSindicat = ISNULL(@parXML.value('(/row/@procsindicat)[1]', 'float'), 0)

--	citire parametrii(salar mediu brut, procente contributii).
	set @SalarMediu=dbo.iauParLN(@dataSus,'PS','SALMBRUT')
	if @pAsigSanatate is null
		set @pAsigSanatate=dbo.iauParLN(@dataSus,'PS','CASSIND')
	if @pCASIndiv is null
		set @pCASIndiv=dbo.iauParLN(@dataSus,'PS','CASINDIV')
	if @pSomajIndiv is null 
		set @pSomajIndiv=dbo.iauParLN(@dataSus,'PS','SOMAJIND')

	if @NrPersIntr is null
		set @NrPersIntr=0
	if @FaraDeducere is null
		set @FaraDeducere=0
	if @tipimpozit is null
		set @tipimpozit=1

	select @DedBaza=0, @casindiv=0, @SomajIndiv=0, @asigSanatate=0, @BazaImpozit=0, @Impozit=0

--	stabilire contributii individuale
	select @casindiv=round((case when @venitbrut>5*@SalarMediu and @SalarMediu<>0 then 5*@SalarMediu else @venitbrut end)*@pCASIndiv/100,0) 
		,@asigSanatate=round(@venitbrut*@pAsigSanatate/100,0)
		,@SomajIndiv=round(@venitbrut*@pSomajIndiv/100,0)
	set @venitBrutFaraContrib=@venitbrut-@casindiv-@asigSanatate-@SomajIndiv

--	determinare deducere
	if @FaraDeducere=0
		exec calcul_deducere @venitBrut, @NrPersIntr, @DedBaza output

--	determinare baza de calcul impozit/impozit
	set @BazaImpozit=round((@venitBrutFaraContrib-@DedBaza-round(@ProcentSindicat/100*@venitBrut,0)),0,1)

	select @BazaImpozit=(case when @tipimpozit=2 then @venitBrut when @BazaImpozit<0 then 0 else @BazaImpozit end)
	select @Impozit=dbo.fCalcul_impozit_salarii(@BazaImpozit,0,@Impozit) 
	where @BazaImpozit>=0 and @tipimpozit<>3

	set @venitNet = @venitBrutFaraContrib-@Impozit

	set @parXML.modify ('insert attribute asigsanatate {sql:variable("@asigsanatate")} into (/row)[1]') 
	set @parXML.modify ('insert attribute casindiv {sql:variable("@casindiv")} into (/row)[1]') 
	set @parXML.modify ('insert attribute somajindiv {sql:variable("@somajindiv")} into (/row)[1]') 
	set @parXML.modify ('insert attribute impozit {sql:variable("@impozit")} into (/row)[1]') 
	set @parXML.modify ('insert attribute dedbaza {sql:variable("@dedbaza")} into (/row)[1]') 
	set @parXML.modify ('insert attribute venitnet {sql:variable("@venitnet")} into (/row)[1]') 
	
End
