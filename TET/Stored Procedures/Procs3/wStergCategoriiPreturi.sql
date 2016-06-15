
CREATE PROCEDURE wStergCategoriiPreturi @sesiune varchar(50), @parXML xml
AS

DECLARE
	@utilizator varchar(20), @mesaj varchar(100), @categoriepret smallint

BEGIN TRY
	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	SELECT
		@categoriepret = ISNULL(@parXML.value('(/row/@categoriepret)[1]','smallint'), 0)

	DELETE FROM categpret WHERE Categorie = @categoriepret

END TRY
BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wStergCategoriiPreturi)'
	RAISERROR(@mesaj, 11, 1)
END CATCH
