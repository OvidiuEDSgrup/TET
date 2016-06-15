create procedure validLunaInchisaSalarii
as
begin try
	/**
		Se valideaza in raport cu data construita din EOM la LUNABLOC+ANULBLOC / LUNA-INCH+ANUL-INCH
		Tabelul este #lunasalarii (data datetime, nume_tabela varchar(50))
	**/

	declare @data_inchisa datetime, @aninch int, @lunainch int, @data_blocata datetime, @anbloc int, @lunabloc int, @numeTabela varchar(50)

	select @lunainch=isnull((case when parametru='LUNA-INCH' then val_numerica else @lunainch end),0)
			,@aninch=isnull((case when parametru='ANUL-INCH' then val_numerica else @aninch end),0)
			,@lunabloc=isnull((case when parametru='LUNABLOC' then val_numerica else @lunabloc end),0)
			,@anbloc=isnull((case when parametru='ANULBLOC' then val_numerica else @anbloc end),0)
	from par where tip_parametru='PS' and parametru in ('LUNA-INCH','ANUL-INCH','LUNABLOC','ANULBLOC')

	if @lunainch not between 1 and 12 or @aninch<=1901
		raiserror ('Nu s-a configurat ultima luna inchisa. Verificati Configurari, Module, Istoric!',16,1)

	select @data_inchisa=CAST(CAST(@aninch AS varchar) + '-' + CAST(@lunainch AS varchar) + '-' + CAST('01' AS varchar) AS DATETIME)
	select @data_inchisa=dbo.EOM(@data_inchisa)
	select @data_blocata=CAST(CAST(@anbloc AS varchar) + '-' + CAST(@lunabloc AS varchar) + '-' + CAST('01' AS varchar) AS DATETIME)
	select @data_blocata=dbo.EOM(@data_blocata)

	if exists (select 1 from #lunasalarii where data<=@data_inchisa) or exists (select 1 from #lunasalarii where data<=@data_blocata)
	begin
		declare @mesajEroare varchar(1000)
		set @numeTabela=isnull((select top 1 nume_tabela from #lunasalarii),'')
		set @mesajEroare='Violare integritate date. Incercare de modificare date in luna inchisa / blocata salarii '+(case when @numeTabela<>'' then '('+@numeTabela+')' else '' end)+'!'
		raiserror (@mesajEroare,16,1)
	end

	if exists (select 1 from sysobjects where [type]='P' and [name]='validLunaInchisaSalariiSP')
		exec validLunaInchisaSalariiSP
end try
begin catch
	DECLARE @mesaj varchar(max)
	set @mesaj=ERROR_MESSAGE()+ ' (validLunaInchisaSalarii)'
	raiserror(@mesaj, 16,1)
end catch

