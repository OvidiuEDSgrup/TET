
create procedure wOPTerminareProgramLucru @sesiune VARCHAR(50), @parXML XML
as
begin try
	declare @mesaj VARCHAR(500), @idProgramDeLucru int, @datasfarsit datetime

	set @idProgramDeLucru = @parXML.value('(/*/@idProgramDeLucru)[1]', 'int')
	set @datasfarsit = @parXML.value('(/*/@datasfarsit)[1]', 'datetime')

	if @idProgramDeLucru IS NULL
		raiserror ('Nu s-a putut identifica pozitia! Selectati un program de lucru', 11, 1)

	update ProgramLucru set data_sfarsit = @datasfarsit
	WHERE idProgramDeLucru = @idProgramDeLucru

end try

begin catch
	set @mesaj = ERROR_MESSAGE() + ' (wOPTerminareProgramLucru)'

	raiserror (@mesaj, 11, 1)
end catch
