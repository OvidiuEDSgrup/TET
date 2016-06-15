/*
	Procedura primeste o plaja de facturi, si genereaza un fisier PDF cu toate facturile tiparite.
	Pentru acesta se face un cursor pt toate documentele de tiparit, si se apeleaza wExportaRaport pentru fiecare, salvand numele fisierelor generate, pentru concatenare.
	Apoi, fiecare fisier este alipit in un document PDF nou, folosind un utilitar de concatenare.
	In final, se trimite un email cu linkul spre fisierul generat.
*/
create PROCEDURE JobListareFacturiReporting @idRulare int  --@sesiune VARCHAR(50), @parXML XML 
AS
declare @sesiune VARCHAR(50), @parXML XML
DECLARE @xml xml, @eroare varchar(4000), @crs cursor, @fStatus int, @numar varchar(50), @data_facturii datetime, @formular varchar(50), @utilizator varchar(100),
		@tert varchar(50), @filePath varchar(2000), @caleForm varchar(2000), @tipdoc varchar(20), @nServer varchar(500), @cTextSelect nvarchar(4000),
		@cmdShellCommand nvarchar(4000), @raspunsCmd int, @emailResponsabil varchar(4000), @mailcount int, @email_factura varchar(500), -- trimis in XML din operatii, pt debug.
		@curs decimal(12,5), @dentert varchar(100), @numeFisier varchar(2000), @facturaJos varchar(50), @facturaSus varchar(50), @numeTabel varchar(500),
		@pathPdfConcat varchar(5000), @numeFisierParametru varchar(5000), @counter int, @body varchar(8000), @caleRaport varchar(4000),
		@urlRia varchar(5000), @datadebug datetime, @emailErori varchar(500)

set nocount on
set transaction isolation level read uncommitted
BEGIN TRY
	set @datadebug=GETDATE()
	
	select @parXML= p.parXML
	from asisria..ProceduriDeRulat p
	where p.idRulare=@idrulare
	
	--exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	
	select @caleForm=rtrim(val_alfanumerica)
	from par where Tip_parametru='AR' and Parametru='CALEFORM'

	select @urlRia=rtrim(val_alfanumerica)
	from par where Tip_parametru='AR' and Parametru='URL'
	
	select @emailErori = valoare
	from ASiSRIA..parametriRIA
	where cod='emailResp'
	
	if OBJECT_ID('tempdb..#fisiere') is not null
		drop table #fisiere
	
	create table #fisiere(numeFisier varchar(500))
	
	select	@facturaJos = @parXML.value('(/*/@facturajos)[1]', 'varchar(4000)'),
			@facturaSus = @parXML.value('(/*/@facturasus)[1]', 'varchar(4000)'),
			@emailResponsabil = isnull(@parXML.value('(/*/@emailResponsabil)[1]', 'varchar(4000)'),''),
			@caleRaport = isnull(@parXML.value('(/*/@caleRaport)[1]', 'varchar(4000)'),''),
			@utilizator = @parXML.value('(/*/@utilizator)[1]', 'varchar(50)') -- userul trebuie sa vina in XML, suntem in cadrul unui Job
	
	if len(@caleRaport)=0
		raiserror('Eroare configurare aplicatie: Numele raportului care trebuie apelat nu este trimis in XML in @caleRaport', 16 ,1)
	
	if len(@emailResponsabil)=0
		raiserror('Adresa de email nu este completata!', 16, 1)
	
	-- parcurg facturile una cate una si generez PDF individual
	set @crs = cursor local fast_forward for
	select tip, numar, data, Cod_tert, ROW_NUMBER() over(order by numar)
	from doc p
	where p.Subunitate='1' and tip in ('AP', 'AS') and Factura between @facturaJos and @facturaSus
	order by p.Numar
	
	open @crs
	while 1=1
	begin
		fetch next from @crs into @tipdoc, @numar, @data_facturii, @tert, @counter
		IF (@@FETCH_STATUS <> 0) 
			BREAK 
		
		set @dentert = isnull((select top 1 rtrim(denumire) from terti where tert=@tert and subunitate='1'),'')
		set @dentert = rtrim((case when CHARINDEX(' ', @dentert)>0 then left(@dentert, charindex(' ', @dentert))
						else @dentert end ))
		
		set @numeFisier= @dentert+'_'+rtrim(@numar)
		print convert(varchar, @counter)+' export '+@numefisier
		set @xml = (select 1 faraMesaje, @numeFisier numeFisier, @caleRaport caleRaport, DB_NAME() BD,
			@tipdoc tip, @numar numar, convert(varchar(10), @data_facturii,120) data, '1' nrExemplare, (select @utilizator utilizator for xml raw) parXML
					for xml raw)
		exec wExportaRaport @sesiune='', @parXML=@xml
	
		insert into #fisiere(numeFisier) values (@numeFisier+'.pdf')
		
	end
	
	close @crs
	deallocate @crs
	
	-- daca am generat mai mult de o factura, le concatenez folosind un executabil special pt. aceasta
	-- scriu in un fisier text, numele tuturor fisierelor de concatenat, si trimit numele fisierului ca si parametru la exe.
	if isnull((select count(*) from #fisiere),0)>1
	begin
		if OBJECT_ID('tempdb..#raspCmdShell') is not null
			drop table #raspCmdShell
		CREATE TABLE #raspCmdShell (raspunsCmdShell VARCHAR(MAX))
		
		set @pathPdfConcat = REPLACE(@caleForm, '\formulare\', '\mobria\')
		set @numeTabel='##rap_'+REPLACE(NEWID(),'-','')
		set @numeFisierParametru = replace(@numeTabel,'#','') /* las fara extensie. pt. ca foloses .txt si .pdf */
		
		-- scriu in o tabela temporara globala
		-- o creez aici pt. ca sa nu fie dynamic sql mai sus unde nu e nevoie - oricum mutarea din una in alta e instant...
		SET @cTextSelect = 
		'if OBJECT_ID(''tempdb..' + @numeTabel+ ''') is not null
			drop table ' + @numeTabel
		EXEC sp_executesql @statement = @cTextSelect
		
		SET @cTextSelect = 'create table ' + @numeTabel + ' (valoare varchar(max))
		insert into ' + @numeTabel + '(valoare)
		select '''+@caleForm+'''+numeFisier from #fisiere'
		EXEC sp_executesql @statement = @cTextSelect
		
		if OBJECT_ID('tempdb..#fisiere') is not null
			drop table #fisiere
		
		SELECT	@nServer = convert(VARCHAR(1000), serverproperty('ServerName')), 
				@cmdShellCommand = 'bcp "select valoare from ' + @numeTabel + '" queryout "' + @caleForm + @numeFisierParametru + '.txt" -T -c -t -C UTF-8 -S' + @nServer
		
		INSERT #raspCmdShell
		EXEC xp_cmdshell @cmdShellCommand

		-- formare comanda pt generare raport
		SET @cmdShellCommand = '' + @pathPdfConcat + 'PdfConcat.exe "' + @caleForm + @numeFisierParametru + '.txt" "'+@caleForm+@numeFisierParametru+'.pdf"'

		--select @cmdShellCommand
		INSERT into #raspCmdShell
		EXEC xp_cmdshell @statement = @cmdShellCommand
		
		SET @cTextSelect = 
		'if OBJECT_ID(''tempdb..' + @numeTabel+ ''') is not null
			drop table ' + @numeTabel
		EXEC sp_executesql @statement = @cTextSelect
		if OBJECT_ID('tempdb..#raspCmdShell') is not null
			drop table #raspCmdShell
	end
	else
	begin -- aici ajungem cand nu s-au generat facturi sau s-a generat una singura
		set @numeFisierParametru = (select MAX(numeFisier) from #fisiere)
		if @numeFisierParametru is null
		begin
			set @body = 'Nu exista facturi de listat in plaja: '+@facturaJos + ' - ' + @facturaSus
			raiserror(@body, 16, 1)
		end
		set @numeFisierParametru = LEFT(@numeFisierParametru, LEN(@numeFisierParametru)-4) 
	end
	
	-- trimitem raspuns pe email
	set @body = 'Generarea fisierului s-a finalizat cu succes pentru facturile: '+@facturaJos + ' - ' + @facturaSus +
		'. Fisierul se gaseste la adresa: '+@urlRia+'formulare/'+@numeFisierParametru+'.pdf'
	
	exec msdb..sp_send_dbmail @recipients=@emailResponsabil ,@subject='Listare facturi ASiS.ERP', @body=@body--, @blind_copy_recipients=@emailErori
	
END TRY

BEGIN CATCH
	SET @eroare = ERROR_MESSAGE() + ' (JobListareFacturiReporting)'

	--RAISERROR (@eroare, 11, 1)
END CATCH

if len(@eroare)>0
begin
	if APP_NAME() like '%Microsoft SQL Server Management Studio%' or LEN(@emailResponsabil)=0 /* daca nu am unde trimite erori, doar raiserror */
		raiserror(@eroare, 11, 1)
	else
		exec msdb..sp_send_dbmail @recipients=@emailResponsabil ,@subject='Eroare listare facturi in ASiS.ERP', @body=@eroare--, @blind_copy_recipients=@emailErori  
end

-- exec wOPListareFacturiArobs '1AFC2E701E555', '<row facturajos="ABOSS22247" facturasus="ABOSS23435" />'
-- select * from asisria.. proceduriderulat order by idrulare desc

-- exec JobListareFacturiReporting 175
