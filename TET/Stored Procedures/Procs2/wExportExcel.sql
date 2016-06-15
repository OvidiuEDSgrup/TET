CREATE PROCEDURE [dbo].wExportExcel @sesiune VARCHAR(50), @parXML XML output
AS
DECLARE @mesaj varchar(4000), @filePath varchar(2000), @caleForm varchar(2000),
		@cmdShellCommand nvarchar(4000), @raspunsCmd int, @numeFisier varchar(2000), @comanda nvarchar(4000),
		@pathExe varchar(8000), @idRulare int, @procedura varchar(50), @faraMesaje int

set transaction isolation level read uncommitted
BEGIN TRY
	select	@procedura = @parXML.value('(/*/@procedura)[1]', 'varchar(50)'),
			@numeFisier = @parXML.value('(/*/@numefisier)[1]', 'varchar(50)'),
			@faraMesaje = @parXML.value('(/*/@faramesaje)[1]', 'int')
	
	declare @tblRulare table(idRulare int)
	
	insert into ASiSRIA..ProceduriDeRulat(BD, procedura, parXML, sesiune, dataStart, dataUltimeiActiuni, dataStop)
		output inserted.idRulare into @tblRulare(idRulare)
	values (DB_NAME(), @procedura, @parXML, @sesiune, GETDATE(), GETDATE(), GETDATE())
	
	select top 1 @idRulare = idRulare from @tblRulare
	
	select @caleForm=rtrim(val_alfanumerica)
	from par where Tip_parametru='AR' and Parametru='CALEFORM'
	
	if @numeFisier is null
	begin
		set @numeFisier='sit'+CONVERT(varchar(50), @idRulare)+'.xlsx'
		-- trimit inapoi in XML numele fisierului generat, pentru cazurile in care apelul se face din SQL, si nu din frame
		-- sper ca nu trimitem cu nume element = parametru in parXML care e output
		set @parXML.modify('insert attribute numefisier {sql:variable("@numeFisier")} into /*[1]') 
	end
	-- daca path spre executabil contine spatii, xp_cmdshell nu merge bine, si nu se pot adauga ghilimele doar la inceput si sfarsit. Am tratat doar cazul program files
	SET @pathExe = replace(REPLACE(@caleForm, '\formulare\', '\mobria\'), 'program files','"program files"')
	
	CREATE TABLE #raspCmdShell (raspunsCmdShell VARCHAR(MAX))
	SET @cmdShellCommand = @pathExe + 'SqlQueryToExcel.exe ' + convert(varchar(30),@idRulare) + ' "' + @caleForm + @numeFisier + '"'

	--select @cmdShellCommand
	INSERT #raspCmdShell
	EXEC xp_cmdshell @statement = @cmdShellCommand
	
	delete from #raspCmdShell where isnull(raspunsCmdShell,'')=''
	if exists(select * from #raspCmdShell)
	begin
		select @mesaj = isnull(@mesaj,'')+ isnull(r.raspunsCmdShell,'')
		from #raspCmdShell r
		
		-- nu dau mesaje de eroare - din executabil se trimit si mesaje de avertizare, iar erorile din proceduri ajung prin tabela proceduriDeRulat
		select @mesaj as textMesaj, 'Erori rulare' as titluMesaj for xml raw, root('Mesaje')
	end
	-- eroare se scrie tot in tabela...
	select @mesaj = mesajEroare
	from ASiSRIA..ProceduriDeRulat
	where idRulare = @idRulare
	
	if len(@mesaj)>0
		raiserror(@mesaj, 11, 1)
	
	if ISNULL(@faraMesaje,0)<>1
		select @numeFisier as fisier, 'wTipFormular' as numeProcedura for xml raw, root('Mesaje')
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wExportExcel)'

	RAISERROR (@mesaj, 11, 1)
END CATCH


-- exec wExportExcel
