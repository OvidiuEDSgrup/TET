
create procedure wStergFisiereTehnologie @sesiune varchar(50), @parXML XML  
as
	declare
		@idFisier varchar(20), @idPozTehnologie int

	select
		@idFisier = @parXML.value('(/*/@idFisier)[1]','int')

	select @idPozTehnologie = idPozTehnologie from FisiereProductie where idFisier=@idFisier
	delete FisiereProductie where idFisier=@idFisier
	update pozTehnologii set detalii.modify('delete (/*/@desen)[1]') where id=@idPozTehnologie and detalii IS NOT NULL
