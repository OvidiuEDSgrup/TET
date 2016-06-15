create procedure validMarca  
as
begin try
	declare @mesajeroare varchar(max)
	/*
		Se valideaza folosind tabela #marci (marca varchar(9),data datetime)
			- verificare validare stricta existenta in catalog
			- in raport cu data plecarii 
	*/
	if exists(select 1 from #marci where marca='')
		raiserror('Marca necompletata!',16,1)
	
	if exists(select 1 from #marci m left outer join personal mm on m.marca=mm.Marca where m.marca<>'' and mm.marca is null)
	begin
		declare
			@marca_err varchar(MAX)
		set @marca_err = ''
		select @marca_err = @marca_err + RTRIM(m.marca) + ',' from #marci m left join personal mm on m.marca=mm.Marca where m.marca<>'' and mm.marca is null
		set @marca_err = 'Marca inexistenta in catalogul de Personal (' + left(@marca_err,LEN(@marca_err)-1) + ')!'
		raiserror(@marca_err,16,1)
	end

	if exists(select 1 from #marci m left outer join personal mm on m.marca=mm.Marca where m.marca<>'' and mm.Loc_ramas_vacant='1' AND m.data>=mm.Data_plec and ISNULL(fictiv,0)<>1) and left(APP_NAME(),8)='ASiSria\' and 1=0
	begin
		select @mesajeroare='Salariatul ('+rtrim(mm.nume)+' - '+rtrim(m.Marca)+') este plecat din unitate la '+convert(char(10),mm.Data_plec,103)+' !'
			from #marci m left outer join personal mm on m.Marca=mm.Marca 
			where m.marca<>'' and mm.Loc_ramas_vacant='1' AND m.data>=mm.Data_plec
		raiserror(@mesajeroare,16,1)
	end

end try
begin catch
	DECLARE @mesaj varchar(max)
	set @mesaj=ERROR_MESSAGE()+ ' (validMarca)'
	raiserror(@mesaj, 16,1)
end catch

