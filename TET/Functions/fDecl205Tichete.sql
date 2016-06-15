Create function fDecl205Tichete (@dataJos datetime, @dataSus datetime)
returns @tichete205 table 
	(data datetime, marca varchar(6), valoare_tichete decimal(12,2))
as
Begin
	Declare @dataLunii datetime, @ImpozitTichete int, @DataJTich datetime, @DataSTich datetime

	Declare tichete205 Cursor For
	Select distinct data_lunii from dbo.fCalendar(@dataJos,@dataSus)
	Open tichete205
	Fetch next from tichete205 Into @dataLunii
	While @@fetch_status = 0 
	Begin
		set @ImpozitTichete=dbo.iauParLL(@dataLunii,'PS','DJIMPZTIC')
		set @DataJTich=dbo.iauParLD(@dataLunii,'PS','DJIMPZTIC')
		set @DataSTich=dbo.iauParLD(@dataLunii,'PS','DSIMPZTIC')

		insert into @tichete205
		select @datalunii, Marca, round(Valoare_tichete,0) from dbo.fNC_tichete(@DataJTich, @DataSTich, '', 1) where @ImpozitTichete=1

		Fetch next from tichete205 Into @dataLunii
	End
	Close tichete205
	Deallocate tichete205
	
	return
End
