/* operatie pt. generare NC pt. sume operate pe corectia Q */
Create procedure GenNCCorectiaQ
	@dataJos datetime, @dataSus datetime, @Continuare int output, @NrPozitie int output
As
Begin
	declare @userASiS char(10), @Sub char(9), @NCCheltLM int, @NumarDoc char(8), @cDataDoc char(4), @Explicatii char(50), @NCticheteCM int, 
		@ContDebitor char(13), @ContCreditor char(13), @Valoare decimal(10,2), @Data datetime, @Loc_de_munca char(9), @Comanda char(20)

	set @userASiS=dbo.fIaUtilizator(null)
	set @Sub=dbo.iauParA('PS','SUBPRO')
	set @NCCheltLM=dbo.iauParL('PS','N-C-CH-LM')
	set @cDataDoc=left(convert(char(10),@dataSus,101),2)+right(convert(char(10),@dataSus,101),2)
	set @NumarDoc='SAL'+@cDataDoc
	set @ContDebitor=dbo.iauParA('PS','N-C-AVMD')
	set @ContCreditor=dbo.iauParA('PS','N-C-AVMC')
	set @Explicatii='Avantaje materiale'
	select @Explicatii=Denumire from tipcor where Tip_corectie_venit='Q-'

	declare NCCorectiaQ cursor for
	select a.Data, a.Loc_de_munca, '' as Comanda, sum(a.Suma_corectie) as Valoare
	from fSumeCorectie (@dataJos, @dataSus, 'Q-', '', '', 1) a
	group by a.Data, a.Loc_de_munca 
	Order by Loc_de_munca

	open NCCorectiaQ
	fetch next from NCCorectiaQ into @Data, @Loc_de_munca, @Comanda, @Valoare 
	While @@fetch_status = 0 
	Begin
		if @Continuare=1
			exec scriuNCsalarii @Data, @ContDebitor, @ContCreditor, @Valoare, @NumarDoc, 
				@Explicatii, @Continuare output, @NrPozitie output, @Loc_de_munca, @Comanda, '', 0, '', '', 0

		fetch next from NCCorectiaQ into @Data, @Loc_de_munca, @Comanda, @Valoare 
	End
	close NCCorectiaQ
	Deallocate NCCorectiaQ
End

/*
	exec GenNCCorectiaQ '03/01/2011', '03/31/2011', 1, 0 
*/
