
create procedure wStergComenziDePrelucrat @sesiune varchar(50),@parXML xml
as
	declare @idContract int

	set @idContract=@parXML.value('(/*/@idContract)[1]','int')

	update Contracte
		set detalii.modify('delete (/*/@comanda)[1]')
	where idContract=@idContract and detalii.value('(/*/@comanda)[1]','varchar(20)') IS NOT NULL

	delete tmpComenziDePrelucrat where idCOntract=@idContract
