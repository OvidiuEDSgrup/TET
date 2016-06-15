
--***
CREATE PROCEDURE wStergOperatii @sesiune VARCHAR(50), @parXML XML
AS
IF EXISTS (
		SELECT *
		FROM sysobjects
		WHERE NAME = 'wStergOperatiiSP'
			AND type = 'P'
		)
	EXEC wStergOperatiiSP @sesiune, @parXML
ELSE
BEGIN
	BEGIN TRY
		DECLARE @cod VARCHAR(20), @mesajeroare VARCHAR(100)

		SET @cod = @parXML.value('(/row/@cod)[1]', 'varchar(20)')

		DELETE
		FROM catop
		WHERE Cod = @cod
	END TRY

	BEGIN CATCH
		SET @mesajeroare = ERROR_MESSAGE()

		RAISERROR (@mesajeroare, 11, 1)
	END CATCH
END
