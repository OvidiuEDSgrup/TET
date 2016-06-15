
create procedure wOPAsociereComanda @sesiune varchar(50),@parXML xml
as
BEGIN TRY
	declare 
		@comanda_transport varchar(20), @utilizator varchar(100), @generezDocumente bit

	set @comanda_transport=@parXML.value('(/*/@comanda_transport)[1]','varchar(20)')
	set @generezDocumente=ISNULL(@parXML.value('(/*/@generezDocumente)[1]','BIT'),0)

	if ISNULL(@comanda_transport,'')=''
		raiserror('Nu s-a selectat o comanda!',16,1)
	
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	
	update c
		set detalii=(select @comanda_transport comanda for xml raw)
	from Contracte c
	JOIN tmpComenziDePrelucrat tp on c.idContract=tp.idContract
	where c.detalii IS NULL

	update c
		set detalii.modify('insert attribute comanda {sql:variable("@comanda_transport")} into (/row)[1]')
	from Contracte c 
	JOIN tmpComenziDePrelucrat tp on c.idContract=tp.idContract
	where c.detalii.value('(/*/@comanda)[1]','varchar(20)') IS NULL

	update c
		set detalii.modify('replace value of (/row/@comanda)[1] with sql:variable("@comanda_transport")')
	from Contracte c 
	JOIN tmpComenziDePrelucrat tp on c.idContract=tp.idContract
	where c.detalii.value('(/*/@comanda)[1]','varchar(20)') IS NOT NULL

	IF @generezDocumente = 1
	BEGIN
		SELECT 
			'Facturare comenzi de livrare'  nume, 'CECL' codmeniu, 'E' tipmacheta,'CE' tip,'GF' subtip,'O' fel
		FOR XML RAW('deschideMacheta'), ROOT('Mesaje')

		RETURN
	END
END TRY
BEGIN CATCH
	declare @mesaj  varchar(max)
	set @mesaj=ERROR_MESSAGE()+ ' (wOPAsociereComanda)'
	raiserror(@mesaj, 16,1)
END CATCH
