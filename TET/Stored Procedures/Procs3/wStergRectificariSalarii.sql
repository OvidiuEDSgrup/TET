
CREATE procedure wStergRectificariSalarii @sesiune VARCHAR(50), @parXML XML
as
declare @mesaj varchar(500), @idRectificare int

begin try
	set @idRectificare = @parXML.value('(/*/@idRectificare)[1]', 'int')

	delete
	from AntetRectificariSalarii
	where idRectificare = @idRectificare

end try

begin catch
	set @mesaj = ERROR_MESSAGE() + ' (wStergRectificariSalarii)'
	raiserror (@mesaj, 11, 1)
end catch
