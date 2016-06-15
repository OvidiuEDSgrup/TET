
CREATE PROCEDURE wOPReprocesareDate @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @status VARCHAR(200), @tip VARCHAR(2), @id INT, @date XML, @utilizator VARCHAR(100), @subunitate VARCHAR(9), @comanda VARCHAR(20), @data DATETIME, @tert VARCHAR(20)

SET @status = @parXML.value('(/parametri/@status)[1]', 'varchar(200)')
SET @tip = @parXML.value('(/parametri/@TipDetaliere)[1]', 'varchar(2)')
SET @id = @parXML.value('(/parametri/@id)[1]', 'int')

EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate OUTPUT

IF @status = 'ok'
BEGIN
	RAISERROR ('Randul nu poate fi reprocesat (nu a generat eroare la sincronizare)!', 11, 1)

	RETURN - 1
END
ELSE
	SELECT @date = detalii
	FROM dateSincronizare
	WHERE id = @id

SET @tert = @parXML.value('(/parametri/@tert)[1]', 'varchar(20)')
SET @data = @parXML.value('(/parametri/@data)[1]', 'datetime')

--Procesari pe tipuri
IF @tip = 'CO'
BEGIN
	--reprocesare comanda
	SET @comanda = @parXML.value('(/parametri/@comanda)[1]', 'varchar(20)')

	BEGIN TRY
		EXEC wScriuPozContracte @sesiune = @sesiune, @parXML = @date

		--UPDATE con
		--SET stare = '1'
		--WHERE Subunitate = @subunitate
		--	AND tip = 'BK'
		--	AND data = @data
		--	AND Contract = @comanda
		--	AND tert = @tert

		UPDATE dateSincronizare
		SET STATUS = 'ok'
		WHERE id = @id
	END TRY

	BEGIN CATCH
		UPDATE dateSincronizare
		SET STATUS = ERROR_MESSAGE()
		WHERE id = @id
	END CATCH
END
ELSE
	IF @tip = 'IN'
	BEGIN
		--reprocesare sume incasate
		DECLARE @suma FLOAT, @numar VARCHAR(20), @serie VARCHAR(20)

		SET @suma = @parXML.value('(/parametri/@suma)[1]', 'float')
		SET @numar = @parXML.value('(/parametri/@numar)[1]', 'varchar(20)')
		SET @serie = @parXML.value('(/parametri/@serie)[1]', 'varchar(20)')

		DELETE dateSincronizare
		WHERE id = @id

		SELECT @date = (
				SELECT 1 AS '@eIncasare', (
						SELECT @suma AS suma, @numar AS numar, @serie AS serie, @data AS data, @tert AS tert
						FOR XML raw, type
						)
				FOR XML path('Incasari')
				)

		EXEC wSincronFacturiSiSume @sesiune = @sesiune, @parXML = @date
	END
	ELSE
		IF @tip = 'FT'
		BEGIN
			--reprocesare facturi
			BEGIN TRY
				EXEC wScriuPozplin @sesiune = @sesiune, @parXML = @date

				UPDATE dateSincronizare
				SET STATUS = 'ok'
				WHERE id = @id
			END TRY

			BEGIN CATCH
				UPDATE dateSincronizare
				SET STATUS = ERROR_MESSAGE()
				WHERE id = @id
			END CATCH
		END
