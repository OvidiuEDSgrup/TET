
CREATE procedure wStergProgramLucru @sesiune VARCHAR(50), @parXML XML
as
declare @mesaj varchar(500), @idProgramDeLucru int

begin try
	set @idProgramDeLucru = @parXML.value('(/*/@idProgramDeLucru)[1]', 'int')

	delete
	from ProgramLucru
	where idProgramDeLucru = @idProgramDeLucru

end try

begin catch
	set @mesaj = ERROR_MESSAGE() + ' (wStergProgramLucru)'

	raiserror (@mesaj, 11, 1)
end catch
