
--***
CREATE PROCEDURE wOPDefinitivareComanda @sesiune VARCHAR(30), @parXML XML
AS
IF EXISTS (
		SELECT *
		FROM sysobjects
		WHERE NAME = 'wOPDefinitivareComandaSP'
			AND type = 'P'
		)
BEGIN
	EXEC wOPDefinitivareComandaSP @sesiune = @sesiune, @parXML = @parXML

	RETURN
END

DECLARE @contract VARCHAR(20), @subunitate VARCHAR(20), @mesaj VARCHAR(254), @stare VARCHAR(10)

SET @contract = @parXML.value('(/*/@contract)[1]', 'varchar(20)')

EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate OUTPUT

BEGIN TRY
	SELECT @stare = stare
	FROM con
	WHERE subunitate = @subunitate
		AND contract = @contract

	IF ISNULL(@stare, '') = ''
	BEGIN
		SET @mesaj = 'Nu s-a gasit comanda ' + @contract + ' !'

		RAISERROR (@mesaj, 15, 1)
	END

	IF @stare > 1
	BEGIN
		SET @mesaj = 'Comanda ' + @contract + ' se afla in starea ' + '( ' + @stare + ' ) ' + (
				(
					CASE @stare WHEN '0' THEN 'Operat' WHEN '1' THEN 'Definitiv' WHEN '2' THEN 'Blocat' WHEN '3' THEN 'Confirmat' WHEN '4' 
							THEN 'Expediat' WHEN '5' THEN 'In vama' WHEN '6' THEN 'Realizat' WHEN '7' THEN 'Reziliat' ELSE @stare END
					)
				)

		RAISERROR (@mesaj, 15, 1)
	END

	UPDATE con
	SET stare = '1'
	WHERE subunitate = @subunitate
		AND contract = @contract

	SELECT 'Comanda ' + @contract + ' s-a trecut in stare definitiva!' AS textMesaj
	FOR XML raw, root('Mesaje')
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wOPDefinitivareComanda)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
