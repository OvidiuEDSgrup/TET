
create procedure wOPInchidPrelucrareComenzi @sesiune varchar(50),@parXML xml
as

	update c
		set detalii.modify('delete (/*/@comanda)[1]')
	from Contracte c 
	JOIN tmpComenziDePrelucrat t on c.idContract=t.idContract and c.detalii.value('(/*/@comanda)[1]','varchar(20)') IS NOT NULL

	truncate table tmpComenziDePrelucrat
