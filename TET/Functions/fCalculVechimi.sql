--***
/**	functie pentru calcul vechime (in munca si la intrare) functie de date introduse in tabela vechimi*/
Create function fCalculVechimi 
	(@pMarca char(6), @TipVechime char(1))
returns char(10)
As
Begin
	declare @CalculVechRL int, @Vechime datetime, @Marca char(6), @Numar_pozitie int, 
	@Data_inceput datetime, @Data_sfarsit datetime,	@ZileSuspendare int, @RegimLucru int, @PrimaPozitie int,
	@VechimeLaIntrare_InMeserie char(6)
	set @CalculVechRL=dbo.iauParL('PS','VECHPRL')
	
	declare tmpVechimi cursor for
	select a.Marca, a.Numar_pozitie, a.Data_inceput, a.Data_sfarsit, 
	isnull(convert(int,b.Loc_de_munca),0), isnull(convert(int,b.Functie),0)
	from Vechimi a
		left outer join Vechimi b on a.Marca=b.Marca and a.Numar_pozitie=b.Numar_pozitie and b.Tip=(case when a.Tip='T' then '1' when a.Tip='I' then '2' when a.Tip='M' then '3' end)
	where a.Marca=@pMarca and a.Tip=@TipVechime

	set @Vechime='01/01/1900'
	set @PrimaPozitie=1
	
	open tmpVechimi
	fetch next from tmpVechimi into @Marca, @Numar_pozitie, @Data_inceput, @Data_sfarsit, @ZileSuspendare, @RegimLucru
	while @@fetch_status=0
	begin
		set @Vechime=DateAdd(month,(case when @PrimaPozitie=1 then -1 else 0 end),
		Dateadd(day,round((DATEDIFF(day,@Data_inceput,@Data_sfarsit)-(case when @ZileSuspendare<>0 then @ZileSuspendare else 0 end))
		*(case when @CalculVechRL=1 and @RegimLucru<>0 then @RegimLucru/8.00 else 1 end),0),@Vechime))
		set @PrimaPozitie=0

		fetch next from tmpVechimi into @Marca, @Numar_pozitie, @Data_inceput, @Data_sfarsit, @ZileSuspendare, @RegimLucru
	End	
--	vechimea la intrare / vechimea in meserie, se pun intr-un camp de tip caracter
	if @TipVechime in ('I','M')
	Begin
		Set @VechimeLaIntrare_InMeserie=convert(char(6),@Vechime,12)
		if month(@Vechime)=12
			Set @VechimeLaIntrare_InMeserie=(case when year(@Vechime)=1899 then '00' 
			else (case when convert(int,left(@VechimeLaIntrare_InMeserie,2))+1<10 then '0' else '' end)
			+rtrim(convert(char(2),convert(int,left(@VechimeLaIntrare_InMeserie,2))+1)) end)
			+'00'+right(@VechimeLaIntrare_InMeserie,2)
		if day(@Vechime)=31
			Set @VechimeLaIntrare_InMeserie=left(@VechimeLaIntrare_InMeserie,2)
			+(case when convert(int,substring(@VechimeLaIntrare_InMeserie,3,2))+1<10 then '0' else '' end)
			+rtrim(convert(char(2),convert(int,substring(@VechimeLaIntrare_InMeserie,3,2))+1))+'00'
	End	

	return (case when @TipVechime='T' then convert(char(10),@Vechime,111) else @VechimeLaIntrare_InMeserie end)
End

/*
	update personal set Vechime_totala=dbo.fCalculVechimi (marca, 'T') where marca='9405'
	update infopers set Vechime_la_intrare=dbo.fCalculVechimi (marca, 'I') where marca='9405'
	select dbo.fCalculVechimi ('9405', 'T')
	select dbo.fCalculVechimi ('9405', 'I')
*/
