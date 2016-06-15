

CREATE PROCEDURE wStergBanci @sesiune varchar(50), @parXML xml
AS

DECLARE @utilizator varchar(50), @mesaj varchar(100), @codbanca varchar(50)

BEGIN TRY
	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	SELECT 
		@codbanca = ISNULL(@parXML.value('(/row/@codbanca)[1]','varchar(50)'), '')

	DELETE FROM bancibnr WHERE Cod = @codbanca

END TRY
BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wStergBanci)'
	RAISERROR(@mesaj, 11, 1)
END CATCH
