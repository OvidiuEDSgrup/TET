/* operatie pt. generare NC pt. diferenta cheltuieli manopera pe locuri de munca si comenzi-Pasmatex */
Create procedure GenNCDifManopera
	@dataJos datetime, @dataSus datetime, @Lm char(9), @NumarDoc char(8), 
	@Sub char(9), @DebitCheltPerm varchar(20), @CreditCheltPerm varchar(20), @AnLMCheltPerm int, 
	@RealizatRegie decimal(10), @RealizatAcord decimal(10), @ValRealizatMarca decimal(10,2),
	@TotalRealizat decimal(10,2), @Continuare int output, @NrPozitie int output, @TCheltLMPerm decimal(10,2) output
As
Begin
	declare @Explicatii char(50), @Comanda char(20), @ValRealizatCom decimal(10,2), @DifManopera decimal(10,2)

	declare DifManopera cursor for
	select Comanda, sum(Cantitate*Tarif_unitar)
	from realcom 
	where data between @dataJos and @dataSus
	group by Comanda

	open DifManopera
	fetch next from DifManopera into @Comanda, @ValRealizatCom
	While @@fetch_status = 0 
	Begin
		if @Continuare=1
		Begin
			set @DifManopera=round((@RealizatRegie+@RealizatAcord-@ValRealizatMarca)*@ValRealizatCom/@TotalRealizat,2)
			set @TCheltLMPerm=@TCheltLMPerm-@DifManopera
			set @Explicatii='Manopera directa - '+rtrim(@Lm)+' '+rtrim(@Comanda)
			exec scriuNCsalarii @dataSus, @DebitCheltPerm, @CreditCheltPerm, @DifManopera, @NumarDoc, 
			@Explicatii, @Continuare output, @NrPozitie output, @Lm, @Comanda, '', @AnLMCheltPerm, '', '', 0
		End
		fetch next from DifManopera into @Comanda, @ValRealizatCom
	End
	close DifManopera
	Deallocate DifManopera
End
/*
	exec GenNCCasLMCom '02/01/2011', '02/28/2011', '', 1, 309014
*/
