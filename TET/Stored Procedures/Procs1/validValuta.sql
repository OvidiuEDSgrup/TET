create procedure validValuta
as
begin try
	/*
		Se valideaza din tabela #valute (tip, numar, data, valuta, curs)
			- valuta inexistenta in catalogul de valute
			- daca s-a operat valuta si fara curs
	*/

	declare @tip varchar(2), @numar varchar(20), @data datetime, @err varchar(200)

	if exists (select 1 from #valute vd where vd.valuta<>'' and not exists (select 1 from valuta v where v.Valuta=vd.Valuta))
		raiserror('Valuta inexistenta in catalogul de valute!',16,1)

	/*	Validare document in valuta si curs necompletat*/
	if exists (select 1 from #valute where valuta<>'' and curs=0)
	begin
		select top 1 @tip=rtrim(tip), @numar=rtrim(numar), @data=data from #valute where valuta<>'' and curs=0
		set @err='Eroare operare: Document in valuta si curs necompletat '+'('+@Tip+': '+@Numar+' din '+convert(char(10),@Data,103)+')'+'!'
		raiserror(@err,16,1)
	end

	/*	Validat si cazul invers de mai sus. Se calculeaza diferente de curs eronate la generare diferente de curs la facturi (in procedura DifCursFact). */
	if exists (select 1 from #valute where valuta='' and curs<>0 and numar not like 'ITVA%')
	begin
		select top 1 @tip=rtrim(tip), @numar=rtrim(numar), @data=data from #valute where valuta='' and curs<>0
		set @err='Eroare operare: Document fara valuta si curs completat '+'('+@Tip+': '+@Numar+' din '+convert(char(10),@Data,103)+')'+'!'
		raiserror(@err,16,1)
	end

end try
begin catch
	DECLARE @mesaj varchar(max)
	set @mesaj=ERROR_MESSAGE()+' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror(@mesaj, 16,1)
end catch
