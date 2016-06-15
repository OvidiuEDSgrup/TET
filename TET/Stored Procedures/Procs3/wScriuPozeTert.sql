
CREATE PROCEDURE wScriuPozeTert @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @cod VARCHAR(20), @poza VARCHAR(255), @update BIT, @mesaj VARCHAR(400), @o_poza VARCHAR(255), @upload varchar(255)

SET @cod = @parXML.value('(/*/@tert)[1]', 'varchar(20)')
SET @poza = @parXML.value('(/*/*/@poza)[1]', 'varchar(255)')
SET @upload = @parXML.value('(/*/*/@upload)[1]', 'varchar(255)')
SET @o_poza = @parXML.value('(/*/*/@o_poza)[1]', 'varchar(255)')
SET @update = isnull(@parXML.value('(/*/*/@update)[1]', 'bit'), 0)


if isnull(@upload,'')<> ''
	set @poza=@upload
BEGIN TRY
	IF @update = 0
		INSERT INTO pozeRIA (tip, Cod, Fisier)
		SELECT 'T', @cod, @poza
	ELSE
		UPDATE pozeRIA
		SET Fisier = @poza
		WHERE tip = 'T'
			AND cod = @cod
			AND Fisier = @o_poza
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wScriuPozeTert)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
