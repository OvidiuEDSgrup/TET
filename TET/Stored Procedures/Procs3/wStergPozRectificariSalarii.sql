
CREATE procedure wStergPozRectificariSalarii @sesiune VARCHAR(50), @parXML XML
as
declare @mesaj varchar(500), @idPozRectificare int, @idRectificare int, @docPozitii xml

begin try
	set @idPozRectificare = @parXML.value('(/*/@idPozRectificare)[1]', 'int')
	set @idRectificare = @parXML.value('(/*/@idRectificare)[1]', 'int')

	delete
	from PozRectificariSalarii
	where idPozRectificare = @idPozRectificare

	set @docPozitii = (select @idRectificare idRectificare for xml raw)

	exec wIaPozRectificariSalarii @sesiune = @sesiune, @parXML = @docPozitii

end try

begin catch
	set @mesaj = ERROR_MESSAGE() + ' (wStergPozRectificariSalarii)'

	raiserror (@mesaj, 11, 1)
end catch
