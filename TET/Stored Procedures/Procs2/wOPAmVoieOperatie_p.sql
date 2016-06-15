CREATE PROCEDURE wOPAmVoieOperatie_p @sesiune VARCHAR(50), @parXML XML
AS
	declare @ultim_stare varchar(20), @idOP int

	set @idOP=@parXML.value('(/*/@idOP)[1]','int')

	SELECT TOP 1 @ultim_stare = stare
		FROM JurnalOrdineDePlata
		WHERE idOP = @idOP
		ORDER BY data DESC

	if @ultim_stare <> 'Operat'
	begin
		select '1' as inchideFereastra
		for xml RAW, root('Mesaje')

		RAISERROR('Documentul este intr-o stare care nu mai permite modificarea!',16,1)
	end
