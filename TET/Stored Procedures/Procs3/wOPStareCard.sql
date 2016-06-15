
CREATE PROCEDURE wOPStareCard @sesiune varchar(50), @parXML xml
AS
DECLARE
	@blocat bit, @uid varchar(36), @userASiS VARCHAR(50), @eroare varchar(200)

BEGIN TRY
	SELECT @blocat = ISNULL(@parXML.value('(/row/@blocat)[1]','bit'), 0),
			@uid = @parXML.value('(/row/@uid)[1]','varchar(36)')

	UPDATE CarduriFidelizare SET blocat = @blocat
		WHERE uid = @uid	

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @userASiS OUTPUT

END TRY
BEGIN CATCH
	
	SET @eroare = ERROR_MESSAGE()
	RAISERROR(@eroare, 16, 1)

END CATCH


