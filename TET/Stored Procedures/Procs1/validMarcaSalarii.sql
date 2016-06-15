create procedure validMarcaSalarii
as
begin try
	declare @mesajeroare varchar(max)
	/* apelare procedura standard */
	exec validMarca

	/*	Validare specifica salariilor 
		Se valideaza folosind tabela #marci (marca varchar(9),data datetime) - in raport cu data angajarii */
	if exists(select 1 from #marci m left outer join personal p on m.marca=p.Marca where m.marca<>'' and p.Data_angajarii_in_unitate>dbo.eom(m.Data))
	begin
		select @mesajeroare='Salariatul ('+rtrim(p.nume)+' - '+rtrim(m.Marca)+') este angajat abia incepand cu data de '+convert(char(10),p.Data_angajarii_in_unitate,103)+' !'
			from #marci m left outer join personal p on m.Marca=p.Marca 
			where m.marca<>'' and p.Data_angajarii_in_unitate>dbo.eom(m.Data)
		raiserror(@mesajeroare,16,1)
	end
	
end try
begin catch
	DECLARE @mesaj varchar(max)
	set @mesaj=ERROR_MESSAGE()+ ' (validMarcaSalarii)'
	raiserror(@mesaj, 16,1)
end catch

