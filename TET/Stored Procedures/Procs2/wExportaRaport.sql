--***
/* 
	apeleaza un raport si exporta rezultatul in formatul specificat(implicit PDF)
*/
/*
	pentru cazurile in care este port forwarding sau proxypass, avem nevoie sa ne conectam pe serverul local pt ca
	altfel nu merge autentificarea. De ex. www.asw.ro/Reports = aswcj/Reports.
	astfel, se configureaza urmatorul parametru, care inlocuieste "REPSRVADR" pentru cererile acestea.
	Daca serverul reporting ruleaza sub alt port, setati portul corect.

	insert into par select 'AR', 'REPSRVLOC', 'Cale reporting locala', 0,0, 'http://127.0.0.1:80/ReportServer/'
	*/			
CREATE PROCEDURE wExportaRaport @sesiune VARCHAR(50), @parXML XML
AS
IF EXISTS (SELECT 1 FROM sysobjects WHERE [type] = 'P' AND [name] = 'wExportaRaportSP')
BEGIN
	DECLARE @returnValue INT
	EXEC @returnValue = wExportaRaportSP @sesiune = @sesiune, @parXML = @parXML
	RETURN @returnValue
END

IF EXISTS (SELECT 1 FROM sysobjects WHERE [type] = 'P' AND [name] = 'wExportaRaportSP1')
	EXEC wExportaRaportSP1 @sesiune = @sesiune, @parXML = @parXML output

set nocount on
DECLARE @mesaj VARCHAR(200), @userASiS VARCHAR(50), @mesajEroare VARCHAR(100), @pathReportToPdf VARCHAR(1000), @splitPage INT, @p2 
	XML, @paramXmlString VARCHAR(max), @ReportServerUrl VARCHAR(500), @numeFisier VARCHAR(100), @caleRaport VARCHAR(100), 
	@caleForm VARCHAR(1000), @reportFormat VARCHAR(50), @cTextSelect NVARCHAR(4000), @nServer VARCHAR(1000), @faraMesaje int,
	@serverReportingLocal VARCHAR(200), @serverReporting VARCHAR(200), @uri VARCHAR(max), @numeTabel varchar(200),
	@numeFisierTxt varchar(120)

BEGIN TRY
	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @userASiS OUTPUT

	-- citesc nume fisier si il trimit inapoi in mesaje
	SET @numeFisier = @parXML.value('(/row/@numeFisier)[1]', 'varchar(2000)')
	SET @faraMesaje = isnull(@parXML.value('(/row/@faraMesaje)[1]', 'int'), -1)
	SET @reportFormat = ISNULL(@parXML.value('(/row/@reportFormat)[1]', 'varchar(2000)'),'PDF')
	
	-- daca nu este trimis nume fisier incercam sa il formam noi
	if isnull(@numeFisier,'')=''
	begin
		-- cautam @numar
		SET @numeFisier = isnull(@parXML.value('(/row/@numar)[1]', 'varchar(2000)'),'')

		if @numefisier='' -- daca nu gasim @numar valid, generam noi ceva random
			set @numefisier= 'rap_'+left(convert(varchar(50),newid()),8)
	end
	
	if @parXML.exist('/row[1]/@faraMesaje')=1
		SET @parXML.modify('delete (/row/@faraMesaje)[1]')

	select @serverReporting=rtrim(ISNULL((select val_alfanumerica from par where Tip_parametru='AR' and Parametru='REPSRVLOC'),
		isnull((select val_alfanumerica from par where Tip_parametru='AR' and Parametru='REPSRVADR'),'http://localhost/reportserver/')))

	SET @uri = @parXML.value('(/row/@uri)[1]', 'varchar(2000)')
	
	set @uri = @serverReporting+substring(@uri, charindex('/Pages/ReportViewer.aspx',@uri), LEN(@uri)+1/* daca charindex(...)=0, nu apare ultimul caracter -> +1 */)
	set @uri = REPLACE(@uri, '//Pages/ReportViewer.aspx', '/Pages/ReportViewer.aspx') -- dupa cum se vede in @serverReporting implicit, in tabela par ar trebui sa fie un / la finalul stringului, ceea ce face sa apara 2 // ...

	--select @uri URI, @serverReporting SRVREP, @serverReportingLocal SRVREPLOC
	-- Daca nu exista configurat parametrul REPSRVADR se merge pe implicit
	SET @parXML.modify('replace value of (/row/@uri)[1]	with sql:variable("@uri")')

	--Urmatoare portiune se refera la apelul rapoartelor din mobile( vezi chitanta, factura) inafara de cele apelate
	--prin modulul de reporting mobile.
	IF ISNULL(@uri, '') = ''
	BEGIN
		DECLARE @nrAtt INT, @attCur INT, @valoare VARCHAR(max), @nume VARCHAR(100)
		
		SET @nrAtt= @parXML.value ('count(/row/@*)', 'INT')
		SET @attCur = 1

		SET @caleRaport = @parXML.value('(/row/@caleRaport)[1]', 'varchar(100)')
		SET @uri = @serverReporting + '/Pages/ReportViewer.aspx?' + @caleRaport + '&rs:Format='+@reportFormat+'&rs:command=render&BD=' + DB_NAME()
		set @uri = REPLACE(@uri, '//Pages/ReportViewer.aspx', '/Pages/ReportViewer.aspx')

		/* citesc parametri definiti in raport */
		declare @param xml
		set @param=(select @caleRaport as path, 1 as fara_luare_date for xml raw)
		exec wReportParam @sesiune='', @parXML=@param output

		declare @parametri table(numeParam varchar(500))

		insert into @parametri(numeParam)
		select xA.row.value('Name[1]', 'varchar(50)') as Name
		from @param.nodes('Parameters/Parameter') as xA(row)
		/* gata citire parametri definiti in raport */

		-- daca nu se trimite @sesiune si exista parametrul in raport, il trimitem
		if exists (select * from @parametri p where p.numeParam='sesiune')
				and CHARINDEX(@uri, '&sesiune=')=0
				and len(@sesiune)>0
		begin
			SET @uri = @uri + '&sesiune=' + isnull(@sesiune, '')
		end

		WHILE @attCur <= @nrAtt
		BEGIN
			SELECT	@nume = @parXML.value('local-name((/row/@*[position()=sql:variable("@attCur")])[1])', 'varchar(200)'), 
					@valoare = @parXML.value('(/row/@*[position()=sql:variable("@attCur")])[1]', 'varchar(max)'), @attCur = @attCur + 1
	
			IF @nume NOT IN ('numeFisier', 'caleRaport', 'BD') /* parametri hard-codati */
				and exists(select * from @parametri where numeParam=@nume)
			begin
				SET @uri = @uri + '&' + @nume + '=' + isnull(@valoare, '')
			end
		END

		SET @parXML = '<row />'
		SET @parXML.modify('insert attribute numeFisier {sql:variable("@numeFisier")} into (/row)[1]')
		SET @parXML.modify('insert attribute uri {sql:variable("@uri")} into (/row)[1]')
	END
	
	-- trimit @caleform la executabil - rapoartele generate se salveaza in folderul formulare
	SELECT @caleForm = RTRIM(val_alfanumerica)
	FROM par
	WHERE Tip_parametru = 'AR'
		AND Parametru = 'CALEFORM'

	if right(@caleForm,1) <> '\'
		select @caleForm = @caleForm + '\' 

	SET @parXML.modify('insert attribute caleForm {sql:variable("@caleForm")} into (/row)[1]')
	-- executabilul pt. generare pdf este in folderul mobRIA.
	-- momentan pt. a afla locatia folderului mobria, iau caleform si schimb 'formulare' cu 'mobria'
	SET @pathReportToPdf = REPLACE(@caleForm, '\formulare\', '\mobria\')
	SET @paramXmlString = convert(VARCHAR(max), @parXML, 1) -- modificat AICI!

	DECLARE @cmdShellCommand NVARCHAR(4000)
	CREATE TABLE #raspCmdShell (raspunsCmdShell VARCHAR(MAX))
	
	set @numeTabel='[##rap_'+REPLACE(NEWID(),'-','')+']'
	set @numeFisierTxt = ISNULL(@sesiune, LEFT(replace(newid(),'-',''),10))+'.txt'
	
	-- nu pot trimite bine XML ca si parametru la executabil.
	-- de aceea il scriu in tabela temporara si de acolo in un fisier pe disk
	SET @cTextSelect = 'create table ' + @numeTabel + ' (valoare varchar(max))
	insert into ' + @numeTabel + '(valoare) values(@paramXmlString)'

	EXEC sp_executesql @statement = @cTextSelect, @params = N'@paramXmlString as varchar(max)', @paramXmlString = @paramXmlString

	SELECT	@nServer = convert(VARCHAR(1000), serverproperty('ServerName')), 
			@cmdShellCommand = 'bcp "select valoare from ' + @numeTabel + '" queryout "' + @pathReportToPdf + @numeFisierTxt + '" -T -c  -t -C UTF-8 -S' + @nServer
	INSERT #raspCmdShell
	EXEC xp_cmdshell @cmdShellCommand
	
	truncate table #raspCmdShell
	-- formare comanda pt generare raport
	SET @cmdShellCommand = '' + @pathReportToPdf + 'ReportToPdf.exe "' + @pathReportToPdf + @numeFisierTxt + '"'

	--select @cmdShellCommand
	INSERT #raspCmdShell
	EXEC xp_cmdshell @statement = @cmdShellCommand

	-- de tratat daca raspunsul nu e ok , sa zica ceva 'frumos' si eventual sa trimita mail la responsabil :)
	DELETE
	FROM #raspCmdShell
	WHERE raspunsCmdShell IS NULL
		OR raspunsCmdShell = 'OK'

	SET @mesaj = ''

	SELECT @mesaj = @mesaj + ' ' + raspunsCmdShell
	FROM #raspCmdShell

	IF LEN(@mesaj) > 0
		RAISERROR (@mesaj, 11, 1)
	
	if @faraMesaje<>1
	begin
		SELECT @numeFisier + case	--when len(@extensia)>0 then @extensia 
									when @reportFormat = 'Excel' then '.xls' 
									when @reportFormat = 'IMAGE' then '.tif' 
									when @reportFormat = 'word' then '.doc' 
									else '.'+@reportFormat end AS fisier, 
			'wTipFormular' AS numeProcedura
		FOR XML raw, root('Mesaje')
	end
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + '(wExportaRaport)'
END CATCH

SET @cTextSelect = 'if OBJECT_ID(''tempdb..' + replace(replace(@numeTabel,'[',''),']','') + ''') is not null
		drop table ' + @numeTabel
EXEC sp_executesql @statement = @cTextSelect

IF LEN(@mesaj) > 0
	RAISERROR (@mesaj, 11, 1)
