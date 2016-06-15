
CREATE PROCEDURE wOPGenerareCMPPRealizari_p @sesiune VARCHAR(50), @parXML XML
AS
	declare 
		@idRealizare int

	set @idRealizare=@parXML.value('(/*/@idRealizare)[1]','int')

	IF (select top 1 isnull(detalii.value('(/*/@stare)[1]','int'),0) from realizari where id=@idRealizare) <> 0
	begin
		select '1' as inchideFereastra
		for xml raw, root('Mesaje')

		RAISERROR('S-au generat documente aferente acestui raport de productie!',16,1)

	END
