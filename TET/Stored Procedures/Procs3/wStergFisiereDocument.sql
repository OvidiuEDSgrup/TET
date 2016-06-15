
CREATE PROCEDURE wStergFisiereDocument @sesiune varchar(50), @parXML xml
AS
BEGIN TRY
	DECLARE
		@idFisier int

	SELECT @idFisier = @parXML.value('(/row/@idFisier)[1]', 'int')

	IF ISNULL(@idFisier, 0) = 0
		RAISERROR('Eroare la stergere: nu s-a putut identifica documentul!', 16, 1)

	DELETE FROM FisiereDocument
	WHERE idFisier = @idFisier

END TRY
BEGIN CATCH
	DECLARE @mesajEroare varchar(500)
	SET @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	RAISERROR(@mesajEroare, 16, 1)
END CATCH
