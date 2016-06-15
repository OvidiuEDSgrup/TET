create procedure validLunaInchisaConta  
as
begin try
	/**
		Se valideaza in raport cu data construita din EOM la LUNABLOC+ANULBLOC
		Tabelul este #lunaconta (data datetime)
	**/

	if exists (select 1 from sysobjects where [type]='P' and [name]='validLunaInchisaContaSP1')
	begin
		exec validLunaInchisaContaSP1
		return
	end

	declare 
		@data_inchisa datetime, @anbloc int, @lunabloc int

	exec luare_date_par 'GE','LUNABLOC',0,@lunabloc OUTPUT,''
	exec luare_date_par 'GE','ANULBLOC',0,@anbloc OUTPUT,''
	
	select @data_inchisa=CAST(CAST(@anbloc AS varchar) + '-' + CAST(@lunabloc AS varchar) + '-' + CAST('01' AS varchar) AS DATETIME)
	select @data_inchisa=dbo.EOM(@data_inchisa)

	if exists (select 1 from #lunaconta where data<=@data_inchisa)
		raiserror ('Violare integritate date. Incercare de modificare inainte de luna inchisa contabilitate',16,1)

	if exists (select 1 from sysobjects where [type]='P' and [name]='validLunaInchisaContaSP')
		exec validLunaInchisaContaSP
end try
begin catch
	DECLARE @mesaj varchar(max)
	set @mesaj=ERROR_MESSAGE()+ ' (validLunaInchisaConta)'
	raiserror(@mesaj, 16,1)
end catch

