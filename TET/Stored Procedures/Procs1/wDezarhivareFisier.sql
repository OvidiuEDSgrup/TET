--***
/* dezarhiveaza un fisier in directorul primit ca parametru. 
	Daca se trimite atributul codformular, se considera ca se dezarhiveaza un fisier .docx, si se preia in tabela xmlFormular */
create procedure wDezarhivareFisier @sesiune varchar(50), @parXML xml                 
as
set nocount on 
begin try

	declare	@numeFisier varchar(1000), @cDirector varchar(1000), @raspunsCmd int, @cmdShellCommand nvarchar(4000), @codFormular varchar(20),
		@continut nvarchar(max), @comandaSql nvarchar(4000), @Cale7z varchar(500), @idFisier int, @numeFisierProcesat varchar(1000),
		@ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT

	select	@Cale7z=isnull((select rtrim(val_alfanumerica) from par where tip_parametru='AR' and Parametru='Cale7z'),'C:\"Program Files"\7-Zip\')
	
	select	@numeFisier = @parXML.value('(/row/@numefisier)[1]','varchar(1000)'), -- fisier(cu path) care se va dezarhiva
			@cDirector = @parXML.value('(/row/@directoroutput)[1]','varchar(1000)'),
			@codFormular = @parXML.value('(/row/@codformular)[1]','varchar(20)'),
			@cmdShellCommand = @Cale7z+'7z.exe x -y -o"'+@cDirector +'" "'+@numeFisier+'"'
	
	-- dezarhivare docx
	exec @raspunsCmd = xp_cmdshell @cmdShellCommand
	
	-- daca nu se trimite cod formular, doar dezarhivez fisier, nu inserez si formularul in xmlFormular
	if @codFormular is null
		return 0
	
	-- daca se trimite la dezarhivat un .docx, procesez document.xml, header1.xml si footer1.xml;
	
	-- sterg formularul vechi
	delete from XMLFormular where Numar_formular=@codFormular
	
	-- creez tabela temporara pentru citire fisiere
	create table #file_contents(
		line_number int identity not null, 
		line_contents nvarchar(max) null
		CONSTRAINT PK_line_number PRIMARY KEY CLUSTERED (line_number)
	)
	-- creez tabela temporara pentru lista fisiere de analizat
	create table #lista_fisiere(
		line_number int identity not null, 
		line_contents nvarchar(max) null
		CONSTRAINT PK_line_number2 PRIMARY KEY CLUSTERED (line_number)
	)
	
	-- iau lista de fisiere de analizat
	select	@cmdShellCommand = 'dir "'+@cDirector+'\word\*" /B /A-d',
			@continut=''
	insert #lista_fisiere(line_contents)
	exec master.dbo.xp_cmdshell @cmdShellCommand

	delete from #lista_fisiere where line_contents is null
	set @idFisier = (select MIN(line_number) from #lista_fisiere)

	-- parcurg linie cu linie lista de fisiere si verific daca trebuie prelucrate	
	while exists (select 1 from #lista_fisiere where line_number=@idFisier)
	begin
		truncate table #file_contents
		set @continut=''
		
		select	@numeFisierProcesat = '\word\'+f.line_contents,
				@cmdShellCommand = 'type "'+@cDirector+@numeFisierProcesat+'"' 
		from #lista_fisiere f
		where f.line_number=@idFisier
		
		insert #file_contents(line_contents)
		exec master.dbo.xp_cmdshell @cmdShellCommand

		select @continut = @continut + isnull(line_contents, '')
		from #file_contents

		-- nu procesez fisierele decat daca ele contin tag-uri !$MG...
		if charindex('!$MG',@continut)>0
			insert into XMLFormular(Numar_formular, Versiune, Nume_fisier, Continut)
			values (@codFormular, 0, @numeFisierProcesat, @continut)
		
		set @idFisier=@idFisier+1
	end
end try
begin catch	
	SELECT @ErrorMessage = '(wDezarhivareFisier)'+ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
end catch
	
if OBJECT_ID('#file_contents') is not null
	drop table #file_contents
if OBJECT_ID('#lista_fisiere') is not null
	drop table #lista_fisiere	
	
if @ErrorMessage is not null
	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState )
