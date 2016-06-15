--***

create procedure [dbo].[wmTiparesteFactura] @sesiune varchar(50), @parXML xml
as
if exists(select * from sysobjects where name='wmTiparesteFacturaSP' and type='P')
begin
	exec wmTiparesteFacturaSP @sesiune, @parXML 
	return 0
end

set transaction isolation level READ UNCOMMITTED  
begin try
	declare @utilizator varchar(100),@subunitate varchar(9), @tert varchar(30), @stareBkFacturabil varchar(20),
			@idpunctlivrare varchar(100), @comanda varchar(100), @eroare varchar(4000), @data datetime,
			@xml xml, @numarDoc varchar(10), @stare varchar(20), @gestiune varchar(20), @lm varchar(20), @numedelegat varchar(80),
			@codFormular varchar(100), @tiparesteTif int, @caleForm varchar(500), @pathMobria varchar(500), @reportFormat varchar(50), @tipdoc varchar(20)


	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output  

	select	@data=isnull(@parXML.value('(/row/@data)[1]','datetime'),GETDATE()),
			@numarDoc=@parXML.value('(/row/@numar)[1]','varchar(20)'),
			@tiparesteTif = 1 -- de facut SP1 care sa insereze acesta, sau prop pe utilizator

	select top 1 @tipDoc=tip
	from pozdoc where subunitate='1' and data=@data and numar=@numarDoc and tip in ('AP','AS')
	order by tip
	if @tipDoc is null set @tipDoc='AP'

	select @codFormular= isnull(rtrim(dbo.wfProprietateUtilizator('FormAP', @utilizator)),'')
	if @codFormular=''
		raiserror('Formularul folosit la tiparire factura nu este configurat! Verificati proprietatea FormAP pe utilizatorul curent.',11,1)
	
	-- daca formularul nu contine '/', generez fisier cu wTipFormular; alfel consider ca e formular-raport 
	if charindex('/',@codFormular)=0
	begin 
		select @reportFormat=isnull(nullif(Clorder,''),'PDF') -- alegem aceasta refolosire de CLOrder pana la o solutie standard
		from antform a
		where a.Numar_formular=@codFormular

		if @reportFormat<>'IMAGE' 
		begin
			set @xml = (select @codFormular nrform, @tipDoc tip, @numarDoc numar, convert(varchar,isnull(@data,getdate()),101) data, @tert tert, @gestiune gestiune, '0' debug,
							@reportFormat reportFormat for xml raw)
			exec wTipFormular @sesiune=@sesiune, @parXML=@xml
		end
		else -- if @reportFormat<>'IMAGE'  -> generam PNG alb-negru folosit pentru tiparire din Android
		begin
			set @xml = (select @codFormular nrform, @tipDoc tip, @numarDoc numar, convert(varchar,isnull(@data,getdate()),101) data, @tert tert, @gestiune gestiune, '0' debug,
							@reportFormat as reportFormat, 1 as faraMesaje, @numarDoc numeFisier
					for xml raw)
			exec wTipFormular @sesiune=@sesiune, @parXML=@xml

			SELECT @caleForm = RTRIM(val_alfanumerica) FROM par WHERE Tip_parametru = 'AR' AND Parametru = 'CALEFORM'
			SET @pathMobria = REPLACE(@caleForm, '\formulare\', '\mobria\')
			
			declare @cmdShellCommand varchar(4000)
			set @cmdShellCommand = @pathMobria+'ConvertTiffPng.exe "'+@caleForm+@numarDoc+'.tif"'

			CREATE TABLE #raspCmdShell(raspunsCmdShell Varchar(MAX))
			insert #raspCmdShell
			exec xp_cmdshell @cmdShellCommand

			if not exists (select * from #raspCmdShell where raspunsCmdShell like 'Ok%') -- fiind apelat din mobile, nu are rost sa trimit mesaje lungi din .NET
				raiserror('Eroare la generarea formularului cerut.', 16, 1)

			SELECT @numarDoc + '.png' fisier, 'wTipFormular' AS numeProcedura FOR XML raw, root('Mesaje')
		end

	end
	else
	begin
		-- generare formular din raport
		set @xml = (select @numarDoc+'.pdf' numeFisier, @codFormular caleRaport, DB_NAME() BD,
			@tipDoc tip, @numarDoc numar, convert(varchar(10), @data,120) data, '1' nrExemplare
					for xml raw)
		exec wExportaRaport @sesiune=@sesiune, @parXML=@xml
	end
end try
begin catch
	set @eroare=ERROR_MESSAGE() 
	raiserror(@eroare, 16, 1) 
end catch	

-- nu mai trimit mesaj, trimite wTipFormular
--select 'Facturare comanda '+@comanda as titlu, 'wmComandaDeFacturatHandler' as detalii,0 as areSearch, 'back(1)' actiune
--for xml raw,Root('Mesaje')   

