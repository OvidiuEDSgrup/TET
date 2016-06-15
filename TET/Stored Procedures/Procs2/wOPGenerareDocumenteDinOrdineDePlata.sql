
CREATE PROCEDURE wOPGenerareDocumenteDinOrdineDePlata @sesiune varchar(50), @parXML xml
AS
BEGIN TRY
	DECLARE
		@utilizator varchar(50), @data datetime, @idOrdinPlata int, @xml xml,
		@stare int, @stareJurnal varchar(20)

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	SELECT
		@data = @parXML.value('(/parametri/@data)[1]', 'datetime'),
		@idOrdinPlata = @parXML.value('(/parametri/@idOP)[1]', 'int')

	IF ISNULL(@idOrdinPlata, 0) = 0
		RAISERROR('Nu s-a putut identifica ordinul de plata!', 16, 1)
	
	IF OBJECT_ID('tempdb..#stareOrdin') IS NOT NULL
		DROP TABLE #stareOrdin

	SELECT * INTO #stareOrdin
	FROM
	(
		SELECT 
			j.idOP, j.stare, RANK() OVER (PARTITION BY j.idOP ORDER BY j.Data DESC, j.idJurnalOP DESC) AS ordine
		FROM JurnalOrdineDePlata j
	) a
	WHERE a.ordine = 1
		AND a.idOP = @idOrdinPlata

	SELECT @stare = (CASE WHEN ISNULL(so.stare, '') = 'Generat' THEN 1 ELSE 0 END) FROM #stareOrdin so

	IF @stare = 1
		RAISERROR('Nu se pot genera documente daca ordinul de plata este deja in starea generat!', 16, 1)

	/** Creare xml si trimitere la wScriuPlin */
	SET @xml =
	(
		SELECT
			RTRIM(cont_contabil) AS cont, @data AS data,
			(
				SELECT
					RTRIM(podp.detalii.value('(/row/@ordin)[1]', 'varchar(20)')) AS numar,
					RTRIM(podp.tert) AS tert, RTRIM(podp.factura) AS factura,
					podp.suma AS suma, 'PF' AS subtip
				FROM PozOrdineDePlata podp
				WHERE podp.stare = '1'
					AND podp.idOP = @idOrdinPlata
				FOR XML RAW, TYPE
			)
		FROM OrdineDePlata odp
		LEFT JOIN #stareOrdin so ON so.idOP = odp.idOP
		WHERE odp.idOP = @idOrdinPlata
		FOR XML RAW, ROOT('Date')
	)

	EXEC wScriuPlin @sesiune = @sesiune, @parXML = @xml

	/** Jurnalizare operatie */
	SET @parXML.modify('insert attribute operatie {"Generare documente"} into (/*[1])')

	IF @parXML.value('(/*/@stare)[1]', 'varchar(20)') IS NOT NULL
	BEGIN
		SET @stareJurnal = 'Generat'
		SET @parXML.modify('replace value of (/*/@stare)[1] with sql:variable("@stareJurnal")') 
	END	
	ELSE
		SET @parXML.modify('insert attribute stare {"Generat"} into (/*[1])')

	EXEC wScriuJurnalOrdineDePlata @sesiune = @sesiune, @parXML = @parXML

	/** Mesaj final */
	SELECT
		'Succes' AS titluMesaj,
		'S-a generat documentul "PF" in data de ' + CONVERT(varchar(10), @data, 103) + '.'  AS textMesaj
	FOR XML RAW, ROOT('Mesaje')
	
END TRY
BEGIN CATCH
	DECLARE @mesajEroare varchar(500)
	SET @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	RAISERROR(@mesajEroare, 16, 1)
END CATCH
