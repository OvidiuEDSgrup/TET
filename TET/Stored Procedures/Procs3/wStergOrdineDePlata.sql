
CREATE PROCEDURE wStergOrdineDePlata @sesiune VARCHAR(50), @parXML XML
AS
DECLARE 
	@mesaj VARCHAR(500),@idOP INT,@ultim_stare varchar(200)

BEGIN TRY
	SET @idOP = @parXML.value('(/*/@idOP)[1]', 'int')

	SELECT TOP 1 @ultim_stare = stare
		FROM JurnalOrdineDePlata
		WHERE idOP = @idOP
		ORDER BY data DESC

	if @ultim_stare <> 'Operat'
		raiserror('Documentul este intr-o stare care nu mai permite modificarea!',16, 1) 
	else
	begin
		delete FROM JurnalOrdineDePlata where idOP=@idOP
		delete from PozOrdineDePlata where idOP=@idop
		delete from OrdineDePlata where idOP=@idOP
	end

END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wStergOrdineDePlata)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
