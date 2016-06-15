-- procedura dezarhiveaza un fisier docx pt. a fi procesat in wTipFormular
CREATE procedure DespachetareDocx @sesiune varchar(50),@parXML XML
as
begin try
	declare @cFisierCuPath varchar(1000), @cmdShellCommand varchar(4000), @indexInceputNumeSablon int, @numeSablon varchar(100), @fisierSablon varchar(1000), 
			@pathSablonDezarhivat varchar(1000), @existaDocx bit, @nrform varchar(13), @xml xml, @ErrorMessage varchar(1000), @debug bit

	select	@nrform = @parXML.value('(/row/@nrform)[1]','varchar(100)'), 
			@cFisierCuPath = @parXML.value('(/row/@cFisierCuPath)[1]','varchar(1000)'), 
			@fisierSablon = @parXML.value('(/row/@fisierSablon)[1]','varchar(1000)')

	CREATE TABLE #raspDespachetareDocx(raspunsCmdShell Varchar(MAX))

	-- sterg fisierul docx de pe server daca mai exista.
	set @cmdShellCommand='del "'+@cFisierCuPath+'.docx'+'"'
	truncate table #raspDespachetareDocx
	insert #raspDespachetareDocx
	exec xp_cmdshell @statement=@cmdShellCommand
	
	-- tiparirea in docx merge mai rapid, dar nu este optimizat segmentul care verifica daca este dezarhivat sablonul, sau daca a fost modificat. 
	-- ar trebui salvat undeva last modify date, care sa fie comparat cu fisierul sablon.
	select	@indexInceputNumeSablon=len(@fisierSablon)-charindex('\', reverse(@fisierSablon))+2,
			@numeSablon = substring(@fisierSablon, @indexInceputNumeSablon, 100),
			@pathSablonDezarhivat= substring(@fisierSablon,1, @indexInceputNumeSablon-1)+'SabloaneDezarhivate\'+ -- adaug inca un folder pt. ca uneori Word mai face foldere si el
				substring(@numeSablon,1,len(@numeSablon)-charindex('.', reverse(@numeSablon))) 

	-- verific daca este dezarhivat sablonul
	set @cmdShellCommand='DIR "'+@pathSablonDezarhivat+'" /B'
	truncate table #raspDespachetareDocx
	insert #raspDespachetareDocx
	exec xp_cmdshell @statement=@cmdShellCommand
	set @existaDocx=(case when (SELECT COUNT(raspunsCmdShell) FROM #raspDespachetareDocx WHERE raspunsCmdShell not in ('The system cannot find the file specified.' ,'File Not Found') AND raspunsCmdShell IS NOT NULL) = 0 then 0 else 1 end )

	if @existaDocx=0
	begin -- daca nu exista directorul care sa contina sablonul dezarhivat, dezarhivez sablonul
		set @xml= (select @fisierSablon as numefisier, @pathSablonDezarhivat as directoroutput, @nrform as codformular for xml raw)
		exec wDezarhivareFisier @sesiune=@sesiune, @parXML=@xml
		
		-- verific daca s-a dezarhivat - nu se dezarhiveaza bine daca userul care apeleaza comanda nu are drept de scriere
		truncate table #raspDespachetareDocx
		insert #raspDespachetareDocx
		exec xp_cmdshell @statement=@cmdShellCommand

		set @existaDocx=(case when (SELECT COUNT(raspunsCmdShell) FROM #raspDespachetareDocx WHERE raspunsCmdShell not in ('The system cannot find the file specified.' ,'File Not Found') AND raspunsCmdShell IS NOT NULL) = 0 then 0 else 1 end )
		if @existaDocx=0
		begin
			set @ErrorMessage= 'Eroare la dezarhivarea sablonului '+@numeSablon+' in locatia:'+@pathSablonDezarhivat+
				'. Verificati daca userul curent poate executz 7z.exe. Daca path-ul spre 7z.exe este diferit de "C:\Program Files\7-Zip\", '+
				'configurati parametrul "AR", "Cale7z" pentru path-ul corect. Apoi asigurati-va ca userul sub care ruleaza '+
				'instanta de SQL Server are drept de scriere in acest director.'
			raiserror (@ErrorMessage,11,1)
		end
	end

	-- sterg directorul in care generez fisiere - in caz ca exista...
	set @cmdShellCommand = 'rmdir /S /Q "'+@cFisierCuPath+'"'
	truncate table #raspDespachetareDocx
	insert #raspDespachetareDocx
	exec xp_cmdshell @cmdShellCommand

	-- copiez sablonul dezarhivat in alt folder(in path-ul de formulare)
	--print convert(varchar,datediff(millisecond, @dataStart, getdate()))+' Copiez sablon...'
	set @cmdShellCommand = 'xcopy /q /I /E /H /Y "'+@pathSablonDezarhivat+'" "'+@cFisierCuPath+'"'
	truncate table #raspDespachetareDocx
	insert #raspDespachetareDocx
	exec xp_cmdshell @statement=@cmdShellCommand
	if @debug=1
		select * from #raspDespachetareDocx

end try 
begin catch 
	SELECT @ErrorMessage = '(DespachetareDocx)'+ERROR_MESSAGE()
end catch

begin try -- drop la tabela care salveaza raspunsul diverselor comenzi cmdShell
	if OBJECT_ID('tempdb..#raspDespachetareDocx') is not null
		drop table #raspDespachetareDocx
end try begin catch end catch

if @ErrorMessage is not null
	raiserror(@ErrorMessage,11,1)
