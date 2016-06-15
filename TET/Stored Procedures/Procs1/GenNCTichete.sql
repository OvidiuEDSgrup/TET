/* operatie pt. generare CM pt. tichete */
Create procedure GenNCTichete
	@dataJos datetime, @dataSus datetime, @pMarca char(6), @Continuare int output, @NrPozitie int output
As
Begin
	declare @Sub char(9), @Buget int, @dataJosTichete datetime, @dataSusTichete datetime, @ImpozitareTichete int, 
		@NCIndBug int, @nTipDoc decimal(10,2), @cTipDoc char(1), @NumarDoc char(8), @cDataDoc char(4), @Explicatii char(50), @NCticheteCM int, 
		@AnaliticLm int, @ContDebitTich varchar(20), @ContCreditTich varchar(20), @ContDebitTichSupl varchar(20), @ContCreditTichSupl varchar(20), 
		@ContDebitor varchar(20), @ContCreditor varchar(20), @Suma decimal(10,2), 
		@Data datetime, @Marca char(6), @Loc_de_munca char(9), @Comanda char(20), @IndBug char(20)

	set @Sub=dbo.iauParA('PS','SUBPRO')
	set @Buget=dbo.iauParL('PS','UNITBUGET')
	set @ImpozitareTichete=dbo.iauParLL(@dataSus,'PS','DJIMPZTIC')
	set @dataJosTichete=dbo.iauParLD(@dataSus,'PS','DJIMPZTIC')
	set @dataSusTichete=dbo.iauParLD(@dataSus,'PS','DSIMPZTIC')
	set @nTipDoc=dbo.iauParN('PS','NC-TICHM')
	set @cTipDoc=left(convert(char(2),convert(int, @nTipDoc)),1)
	set @cTipDoc=(case when @cTipDoc='' then '2' else @cTipDoc end)
	set @NCIndBug=dbo.iauParL('PS','NC-INDBUG')
	set @ContDebitTich=dbo.iauParA('PS','N-C-TICDB')
	set @ContCreditTich=dbo.iauParA('PS','N-C-TICCR')
	set @ContDebitTichSupl=dbo.iauParA('PS','N-C-TISDB')
	set @ContCreditTichSupl=dbo.iauParA('PS','N-C-TISCR')

	set @cDataDoc=left(convert(char(10),@dataSus,101),2)+right(convert(char(10),@dataSus,101),2)
	set @AnaliticLm=0
	set @NCticheteCM=(case when @cTipDoc='2' then 1 else 0 end)
	set @IndBug=''
	select @IndBug=isnull(Comanda,'') from config_nc where Numar_pozitie=70 and @NCIndBug=1
	set @NumarDoc=(case when @cTipDoc='2' then 'TICH' else 'SAL' end)+@cDataDoc

	if OBJECT_ID('tempdb..#NCtichete') is not null 
		drop table #NCtichete

	select Data, Marca, Loc_de_munca, Comanda, Tip_tichete, Numar_tichete, Valoare_tichete, 
		(case when Tip_tichete='S' then @ContDebitTichSupl else @ContDebitTich end) as Cont_debitor,
		(case when Tip_tichete='S' then @ContCreditTichSupl else @ContCreditTich end) as Cont_creditor,
		(case when @cTipDoc='2' then Numar_tichete else Valoare_tichete end) as suma,
		'Tichete de masa'+(case when Tip_tichete='S' then ' suplimentare' else '' end) as explicatii
	into #NCtichete
	from dbo.fNC_tichete (@dataJosTichete, @dataSusTichete, @pMarca, 2) where @ImpozitareTichete=1

	if exists (select * from sysobjects where name ='GenNCTicheteSP' and xtype='P')
		exec GenNCTicheteSP @dataJos=@dataJos, @dataSus=@dataSus, @pMarca=@pMarca, @Continuare=@Continuare output, @NrPozitie=@NrPozitie output

	declare NCTichete cursor for
	select Data, Loc_de_munca, Comanda, Cont_debitor, Cont_creditor, sum(suma) as suma, max(explicatii) as explicatii
	from #NCtichete
	group by Data, Loc_de_munca, Comanda, Cont_debitor, Cont_creditor

	open NCTichete
	fetch next from NCTichete into @Data, @Loc_de_munca, @Comanda, @ContDebitor, @ContCreditor, @Suma, @Explicatii
	While @@fetch_status = 0 
	Begin
		if @suma<>0 and @Continuare=1
			exec scriuNCsalarii @dataSus, @ContDebitor, @ContCreditor, @Suma, @NumarDoc, @Explicatii, @Continuare output, @NrPozitie output, 
				@Loc_de_munca, @Comanda, @IndBug, @AnaliticLm, '', '', @NCticheteCM

		fetch next from NCTichete into @Data, @Loc_de_munca, @Comanda, @ContDebitor, @ContCreditor, @Suma, @Explicatii 
	End
	close NCTichete
	Deallocate NCTichete
End

/*
	exec GenNCTichete '02/01/2011', '02/28/2011', '', 1, 309014
*/
