
CREATE PROCEDURE wOPRezervareStocDinTransport_p @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	IF EXISTS (SELECT * FROM sysobjects WHERE NAME = 'wOPRezervareStocDinTransport_pSP')
	BEGIN
		exec wOPRezervareStocDinTransport_pSP @sesiune=@sesiune, @parXML=@parXML OUTPUT

		IF @parXML IS NULL
			RETURN
	END

	declare
		@grupare varchar(20), @idContract int, @doc_jurnal xml, @stare_preg int

	select
		@grupare = ISNULL(@parXML.value('(/row/@grupare)[1]','varchar(100)'),''),
		@idContract = NULLIF(@parXML.value('(/row/@idcontract)[1]','int'),0)

	IF @idContract is null
		raiserror('Selectati o comanda din sectiunea "Comenzi nealocate" pentru a rezerva stoc si a trece comanda in alta stare!',16,1)

	IF @grupare <> 'N'
		raiserror('Doar comenzilor nealocate li se poate generare rezervare si schimbare automata de stare!',16,1)	
	
	select top 1 @stare_preg = stare from StariContracte where tipContract='CL' and modificabil=0		

	set @doc_jurnal = (SELECT @idContract idContract, @stare_preg stare, GETDATE() AS data, 'Schimbare stare din centralizator transport' AS explicatii FOR XML raw )	
	EXEC wScriuJurnalContracte @sesiune = @sesiune, @parXML = @doc_jurnal

	update tmpArticoleCentralizatorTransport set cantitate=cantitate_comanda where idContract=@idContract and grupare='N'

	select '1' as inchideFereastra for xml raw, root('Mesaje')
	
END TRY
BEGIN CATCH
	select '1' as inchideFereastra for xml raw, root('Mesaje')
	declare
		@mesaj varchar(500)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
END CATCH	
