
/** Procedura este folosita in cadrul operatiilor de invalidare cataloage
	Ex. Gestiuni, Conturi, Locuri de munca, Nomenclator, ... */
CREATE PROCEDURE invalideazaObiectCatalog @sesiune varchar(50), @parXML xml
AS
BEGIN
	DECLARE @cod_invalidare varchar(1), @data datetime, @anulare bit,
		@data_invalid_jos datetime, @data_invalid_sus datetime

	SELECT @cod_invalidare = @parXML.value('(/row/@cod_invalidare)[1]', 'varchar(1)'),
		@data = @parXML.value('(/row/@data)[1]', 'datetime'),
		@anulare = @parXML.value('(/row/@anulare)[1]', 'bit'),
		@data_invalid_jos = '1901-01-01', @data_invalid_sus = '2999-12-31'

	IF EXISTS (SELECT 1 FROM #tempCatalog WHERE detalii IS NULL)
	BEGIN
		UPDATE #tempCatalog SET detalii = '<row />'
		WHERE detalii IS NULL
	END

	IF @anulare = 1
	BEGIN
		IF @cod_invalidare = 'D'
		BEGIN
			UPDATE #tempCatalog SET detalii.modify('delete (/row/@data_invalid_jos)[1]')
			UPDATE #tempCatalog SET detalii.modify('insert attribute data_invalid_jos {sql:variable("@data_invalid_jos")} into (/row)[1]')
			WHERE #tempCatalog.detalii.value('(/row/@data_invalid_sus)[1]', 'datetime') <> @data_invalid_sus
		END
		ELSE
		BEGIN
			UPDATE #tempCatalog SET detalii.modify('delete (/row/@data_invalid_sus)[1]')
			UPDATE #tempCatalog SET detalii.modify('insert attribute data_invalid_sus {sql:variable("@data_invalid_sus")} into (/row)[1]')
			WHERE #tempCatalog.detalii.value('(/row/@data_invalid_jos)[1]', 'datetime') <> @data_invalid_jos
		END
	END
	ELSE
	/** Daca nu se anuleaza, vom scrie/modifica data in detalii, tot in functie de combo. */
	BEGIN
		IF @cod_invalidare = 'D'
		BEGIN
			UPDATE #tempCatalog SET detalii.modify('delete (/row/@data_invalid_jos)[1]')
			UPDATE #tempCatalog SET detalii.modify('insert attribute data_invalid_jos {sql:variable("@data")} into (/row)[1]')

			UPDATE #tempCatalog SET detalii.modify('insert attribute data_invalid_sus {sql:variable("@data_invalid_sus")} into (/row)[1]')
			WHERE #tempCatalog.detalii.value('(/row/@data_invalid_sus)[1]', 'datetime') IS NULL
		END
		ELSE
		BEGIN
			UPDATE #tempCatalog SET detalii.modify('delete (/row/@data_invalid_sus)[1]')
			UPDATE #tempCatalog SET detalii.modify('insert attribute data_invalid_sus {sql:variable("@data")} into (/row)[1]')
			
			UPDATE #tempCatalog SET detalii.modify('insert attribute data_invalid_jos {sql:variable("@data_invalid_jos")} into (/row)[1]')
			WHERE #tempCatalog.detalii.value('(/row/@data_invalid_jos)[1]', 'datetime') IS NULL
		END
	END

	UPDATE l
	SET l.invalid =
		(CASE WHEN dat.data_invalid_jos IS NULL AND dat.data_invalid_sus IS NULL THEN ''
			WHEN dat.data_invalid_jos IS NULL THEN 'pana la ' + CONVERT(char(10), dat.data_invalid_sus, 103)
			WHEN dat.data_invalid_sus IS NULL THEN 'de la ' + CONVERT(char(10), dat.data_invalid_jos, 103)
			ELSE 'de la ' + CONVERT(char(10), dat.data_invalid_jos, 103) + ' pana la ' + CONVERT(char(10), dat.data_invalid_sus, 103)
		END)
	FROM #tempCatalog l
	CROSS APPLY (SELECT NULLIF(detalii.value('(/row/@data_invalid_jos)[1]', 'datetime'), @data_invalid_jos) AS data_invalid_jos,
		NULLIF(detalii.value('(/row/@data_invalid_sus)[1]', 'datetime'), @data_invalid_sus) AS data_invalid_sus FROM #tempCatalog) AS dat

	/** Stergem si apoi inseram in detalii, atributul invalid, ca sa il afisam in form pe macheta. */
	UPDATE #tempCatalog SET detalii.modify('delete (/row/@invalid)[1]')

	UPDATE l
	SET detalii.modify('insert attribute invalid {sql:column("l.invalid")} into (/row)[1]')
	FROM #tempCatalog l
END
