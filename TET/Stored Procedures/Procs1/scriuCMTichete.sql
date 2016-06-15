/* operatie pt. scriere CM pt. tichete */
Create procedure scriuCMTichete
@Data datetime, @NumarDoc char(8), @ContDebitDoc varchar(13), @Suma decimal(7,3), @LocmDoc char(9), @ComandaDoc char(20), @cJurnal char(3)
As
Begin
	declare @Sub char(9), @DateTichete char(20), @GestiuneTichete char(9), @CodTichete char(20), @NrPozitie int, 
	@CodGestiune char(9), @Cod char(20), @CodIntrare char(20), @Pret float, @Stoc float, @Cont char(13), 
	@TvaNeexigibil decimal(4,2), @Cantitate decimal(7,3), @Utilizator char(10)

	set @Sub=dbo.iauParA('GE','SUBPRO')
	set @DateTichete=dbo.iauParA('PS','NC-TICHM')
	set @GestiuneTichete=(case when @DateTichete='' then '' else left(@DateTichete,charindex(',',@DateTichete)-1) end)
	set @CodTichete=(case when @DateTichete='' then '' else substring(@DateTichete,charindex(',',@DateTichete)+1,20) end)
	select @NrPozitie=dbo.iauParN('DO','POZITIE')
	set @Utilizator=dbo.fIaUtilizator(null)

	declare StocTichete cursor for
	select Cod_gestiune, Cod, Cod_intrare, Pret, Stoc, Cont, Tva_neexigibil
	from stocuri a
	where a.Subunitate=@Sub and a.Cod_gestiune=@GestiuneTichete and a.Cod=@CodTichete and a.stoc>=0.001
	order by Data 

	open StocTichete
	fetch next from StocTichete into @CodGestiune, @Cod, @CodIntrare, @Pret, @Stoc, @Cont, @TvaNeexigibil
	While @@fetch_status = 0 
	Begin
		Set @Cantitate=dbo.valoare_minima(@Stoc,@Suma,@Cantitate)
		Set @NrPozitie=(case when @NrPozitie>99999999 then 1 else @NrPozitie+1 end)
		exec scriuCM @NumarDoc, @Data, @CodGestiune, @Cod, @CodIntrare, @Cantitate, @LocmDoc, 
		@ComandaDoc, '', '', 0, '', @Utilizator, @cJurnal, 3, @NrPozitie output, 1, @ContDebitDoc

		Set @Suma=@Suma-@Cantitate
		exec setare_par 'DO','POZITIE', 'Ultimul numar la pozitii', 1, @NrPozitie, ''
		if @Suma=0
			break
		fetch next from StocTichete into @CodGestiune, @Cod, @CodIntrare, @Pret, @Stoc, @Cont, @TvaNeexigibil
	End
	close StocTichete
	Deallocate StocTichete
End
