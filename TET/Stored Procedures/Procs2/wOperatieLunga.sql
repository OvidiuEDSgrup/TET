CREATE PROCEDURE wOperatieLunga @sesiune VARCHAR(50)=null, @parXML XML=null, @procedura varchar(500)=null, @idRulare int=0 output
AS
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

set nocount on
DECLARE @utilizator VARCHAR(100), @eroare varchar(8000), @procentFinalizat int, @mesaje XML, @statusText varchar(500),
		@secundeRefresh int, @dataStop datetime, @userWindows varchar(500)

begin try
	exec wIaUtilizator @sesiune=@sesiune, @utilizator = @utilizator output

	if isnull(@procedura,'')=''
		raiserror('Nu s-a specificat procedura care trebuie rulata prin job SQL', 16, 1)

	set @idRulare = isnull(@parXML.value('/*[1]/@idRulare', 'int'),0)
	set @secundeRefresh = isnull(@parXML.value('/*[1]/@secundeRefresh', 'int'),5)
	set @userWindows = @parXML.value('/*[1]/@userWindows', 'varchar(500)') -- nu se insereaza cu SUSER_NAME() -> avem clienti la care userii au drepturi limitate pe server (eg. arobs, BTfinop, vitalia, etc)

	if @idRulare=0 -- e prima rulare din frame => insert in tabela
	begin
		declare @tblRulare table(id int)
		insert into asisria..ProceduriDeRulat(bd, sesiune, procedura, parXML, utilizatorWindows)
			output inserted.idRulare into @tblRulare(id)
		select DB_NAME(), @sesiune, @procedura, @parXML, @userWindows
		
		-- pornesc job-ul 
		exec asisria..startJob 'ASIS_Job'

		select @idrulare = id
		from @tblRulare

		select @idRulare as idRulare, @secundeRefresh as secundeRefresh, 1 as _operatieLunga
		for xml raw, root('Mesaje')
	end
	else -- exista deja in tabela ProceduriDeRulat, citesc procent finalizare
	begin
		select @procentFinalizat = p.procent_finalizat, @mesaje=p.mesaje, @eroare=p.mesajEroare, @statusText=p.statusText, @dataStop = p.dataStop
		from asisria..ProceduriDeRulat p
		where p.idRulare=@idRulare

		if len(@eroare)>0
			raiserror(@eroare, 16,1)

		if @dataStop is null -- procedura inca lucreaza
			select @procentFinalizat procentFinalizat, @idRulare as idRulare, @secundeRefresh as secundeRefresh, @statusText statusText, 1 as _operatieLunga
			for xml raw, root('Mesaje')
		else -- facem curat in tabela; deja trimitem mesajul userului
			delete from asisria..ProceduriDeRulat where idRulare=@idRulare

		select @mesaje
	end
	
end try
begin catch
	set @eroare=ERROR_MESSAGE() + ' (wOperatieLunga)'
end catch

if len(@eroare)>0
	raiserror(@eroare,16,1)

-- exec wOperatieLunga '', '<parametri update="1" test="0" tipMacheta="O" codMeniu="LUNG" />'
-- exec wOperatieLunga @idRulare=67
-- exec asisria..RuleazaProceduri
-- select * from asisria..proceduriderulat order by idrulare desc
-- update asisria..proceduriderulat set datastop=null where idrulare=85

-- delete from asisria..proceduriderulat where idrulare>85

-- exec asisria..ruleazaproceduri

-- sp_who
