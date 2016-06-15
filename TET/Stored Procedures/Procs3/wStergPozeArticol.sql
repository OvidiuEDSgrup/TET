
CREATE PROCEDURE wStergPozeArticol @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @cod VARCHAR(20), @poza VARCHAR(255), @mesaj VARCHAR(500), @tip varchar(2)

SET @tip = @parXML.value('(/*/*/@tip)[1]', 'varchar(2)')

if @tip = 'PZ'
	SET @cod = @parXML.value('(/*/@cod)[1]', 'varchar(20)')

if @tip = 'PG'
	SET @cod = @parXML.value('(/*/@grupa)[1]', 'varchar(20)')

SET @poza = @parXML.value('(/*/*/@poza)[1]', 'varchar(255)')

BEGIN TRY
	DELETE TOP (1) pozeRIA
	WHERE tip = (case when @tip='PZ' then 'N' when @tip='PG' then 'G' end)
		AND cod = @cod
		AND Fisier = @poza
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wStergPozeArticol)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
