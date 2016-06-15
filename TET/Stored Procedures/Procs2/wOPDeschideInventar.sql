
CREATE PROCEDURE wOPDeschideInventar @sesiune VARCHAR(50), @parXML XML
AS
IF EXISTS (
		SELECT 1
		FROM sysobjects
		WHERE [type] = 'P'
			AND [name] = 'wOPDeschideInventarSP'
		)
BEGIN
	DECLARE @returnValue INT

	EXEC @returnValue = wOPDeschideInventarSP @sesiune, @parXML OUTPUT

	RETURN @returnValue
END

DECLARE @userASiS VARCHAR(50), @mesaj VARCHAR(1000), @gestiune VARCHAR(50), @dataInventar DATETIME, @dataInceput DATETIME, 
	@dataSfarsit DATETIME, @locatie VARCHAR(30), @blocat BIT

BEGIN TRY
	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @userASiS OUTPUT

	SET @gestiune = isnull(@parXML.value('(/parametri/@gestiune)[1]', 'varchar(50)'), '')
	SET @dataInventar = isnull(@parXML.value('(/parametri/@data)[1]', 'datetime'), convert(DATETIME, convert(VARCHAR(10), 
					GETDATE(), 101)))
	SET @dataInceput = isnull(@parXML.value('(/parametri/@datainceput)[1]', 'datetime'), GETDATE())
	SET @dataSfarsit = isnull(@parXML.value('(/parametri/@datasfarsit)[1]', 'datetime'), GETDATE())
	SET @blocat = isnull(@parXML.value('(/parametri/@blocat)[1]', 'bit'), 1)
	SET @locatie = ''

	IF NOT EXISTS (
			SELECT 1
			FROM gestiuni g
			WHERE g.Cod_gestiune = @gestiune
			)
	BEGIN
		RAISERROR (' Selectati o gestiune valida', 11, 1);

		RETURN - 1;
	END

	IF (
			EXISTS (
				SELECT 1
				FROM antetinv a
				WHERE a.Tip = 'G'
					AND a.Gestiune = @gestiune
					AND a.Data = @dataInventar
					AND a.Locatie = @locatie
					AND a.Blocat IN (0, 1)
				)
			)
	BEGIN
		RAISERROR (' Exista un inventar deschis pe aceasta gestiune', 11, 1);

		RETURN - 1
	END

	INSERT INTO antetinv (tip, gestiune, data, locatie, blocat, data_inceput, data_sfarsit)
	SELECT 'G', @gestiune, @dataInventar, @locatie, @blocat, @dataInceput, @dataSfarsit
END TRY

BEGIN CATCH
	SET @mesaj = '(wOPDeschideInventar)' + ERROR_MESSAGE()
END CATCH

IF LEN(@mesaj) > 0
	RAISERROR (@mesaj, 11, 1)
