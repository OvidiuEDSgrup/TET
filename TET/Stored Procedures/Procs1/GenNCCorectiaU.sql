/* operatie pt. generare NC pt. sume operate pe corectia U */
Create procedure GenNCCorectiaU
	@dataJos datetime, @dataSus datetime, @Continuare int output, @NrPozitie int output
As
Begin
	declare @Sub char(9), @NCCheltLM int, @NumarDoc char(8), @cDataDoc char(4), @Explicatii char(50), @NCticheteCM int, 
	@ContDebitor char(13), @ContCreditor char(13), @Valoare decimal(10,2), 
	@Data datetime, @Loc_de_munca char(9), @Comanda char(20)

	set @Sub=dbo.iauParA('PS','SUBPRO')
	set @NCCheltLM=dbo.iauParL('PS','N-C-CH-LM')
	set @cDataDoc=left(convert(char(10),@dataSus,101),2)+right(convert(char(10),@dataSus,101),2)
	set @NumarDoc='SAL'+@cDataDoc
	set @ContDebitor=dbo.iauParA('PS','N-C-PNEID')
	set @ContCreditor=dbo.iauParA('PS','N-C-PNEIC')
	set @Explicatii='Premii neimpozabile'

	declare NCCorectiaU cursor for
	select max(Data), Loc_de_munca, Comanda, sum(Valoare) 
	from dbo.fNCCorectiiU (@dataJos, @dataSus, '') 
	Group by Loc_de_munca, Comanda 
	Order by Loc_de_munca, Comanda

	open NCCorectiaU
	fetch next from NCCorectiaU into @Data, @Loc_de_munca, @Comanda, @Valoare 
	While @@fetch_status = 0 
	Begin
		if @Continuare=1
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @Valoare, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @Loc_de_munca, @Comanda, '', 0, '', '', 0

		fetch next from NCCorectiaU into @Data, @Loc_de_munca, @Comanda, @Valoare 
	End
	close NCCorectiaU
	Deallocate NCCorectiaU
End

/*
	exec GenNCCorectiaU '02/01/2011', '02/28/2011', '', 1, 309014
*/
