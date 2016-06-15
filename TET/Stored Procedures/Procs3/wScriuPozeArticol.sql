
CREATE PROCEDURE wScriuPozeArticol @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @cod VARCHAR(20), @poza VARCHAR(255), @update BIT, @mesaj VARCHAR(400), @o_poza VARCHAR(255), @upload varchar(255), @tip varchar(2)

set @tip = @parXML.value('(/row/@tip)[1]','varchar(2)')

if @tip='PZ'
	SET @cod = @parXML.value('(/*/@cod)[1]', 'varchar(20)')
if @tip='PG'
	SET @cod = @parXML.value('(/*/@grupa)[1]', 'varchar(20)')

SET @poza = @parXML.value('(/*/*/@poza)[1]', 'varchar(255)')
SET @upload = @parXML.value('(/*/*/@upload)[1]', 'varchar(255)')
SET @o_poza = @parXML.value('(/*/*/@o_poza)[1]', 'varchar(255)')
SET @update = isnull(@parXML.value('(/*/*/@update)[1]', 'bit'), 0)


if isnull(@upload,'')<> ''
	set @poza=@upload
BEGIN TRY
	IF @update = 0
	begin
		declare @ultPoz int
		set @ultPoz=0
		select top 1 @ultPoz=isnull(pozitie,0) from PozeRia where cod=@cod and tip=(case when @tip='PZ' then 'N' when @tip='PG' then 'G' end) order by pozitie desc
		set @ultPoz=@ultPoz+1
		INSERT INTO pozeRIA (tip, Cod, Fisier,Pozitie)
		SELECT (case when @tip='PZ' then 'N' when @tip='PG' then 'G' end), @cod, @poza,@ultPoz
	end
	ELSE
		UPDATE pozeRIA
		SET Fisier = @poza
		WHERE tip = (case when @tip='PZ' then 'N' when @tip='PG' then 'G' end)
			AND cod = @cod
			AND Fisier = @o_poza
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wScriuPozeArticol)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
