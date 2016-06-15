
CREATE PROCEDURE wSincronFacturiSiSume @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @nrComenzi INT, @nrCurent INT, @utilizator VARCHAR(100), @subunitate VARCHAR(9), @doc XML, @factura VARCHAR(50), @contPlata 
	VARCHAR(50), @docPlin XML, @tert VARCHAR(20), @data DATETIME, @numar VARCHAR(50), @serieTMP VARCHAR(50), @xml XML, @dataSinc 
	DATETIME

--Iau utilizator      
EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

--Iau subunitate      
EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate OUTPUT

--Alte proprietati ale utilizatorului        
SELECT @contPlata = rtrim(dbo.wfProprietateUtilizator('CONTPLIN', @utilizator))

IF @parXML.value('(Incasari/@eIncasare)[1]', 'int') = 1 --Incasare sume    
BEGIN
	SELECT @nrCurent = 1, @nrComenzi = @parXML.value('count (/Incasari/row)', 'INT')

	DECLARE @valoareFactura FLOAT, @suma FLOAT, @serie VARCHAR(50)

	SELECT TOP 1 @dataSinc = data
	FROM logSincronizare
	WHERE utilizator = @utilizator
	ORDER BY id DESC

	WHILE @nrCurent <= @nrComenzi
	BEGIN
		SELECT @doc = @parXML.query('/Incasari/row[position()=sql:variable("@nrCurent")]')

		DECLARE @sumaIncasare FLOAT

		SELECT @tert = @doc.value('(/row/@tert)[1]', 'varchar(20)'), @numar = @doc.value('(/row/@numar)[1]', 'varchar(20)'), 
			@serie = @doc.value('(/row/@serie)[1]', 'varchar(20)'), @suma = @doc.value('(/row/@suma)[1]', 'float'), @data = @doc.
			value('(/row/@data)[1]', 'datetime')

		SET @sumaIncasare = @suma

		IF OBJECT_ID('listaFacturiOffline') IS NOT NULL
			DROP TABLE listaFacturiOffline

		CREATE TABLE listaFacturiOffline (id INT identity PRIMARY KEY, factura VARCHAR(50), suma FLOAT)

		-- creez cursor facturi pentru a distribui suma pe factura    
		DECLARE listaFacturi CURSOR
		FOR
		SELECT rtrim(f.Factura), f.Valoare + f.TVA_22 - f.Achitat
		FROM facturi f
		WHERE f.Subunitate = @subunitate
			AND tip = 0x46
			AND tert = @tert
			AND ABS(sold) > 0.05
		ORDER BY data

		OPEN listaFacturi

		FETCH NEXT
		FROM listaFacturi
		INTO @factura, @valoareFactura

		WHILE @@FETCH_STATUS = 0
			AND @suma > 0
		BEGIN
			IF @valoareFactura > @suma
				SET @valoareFactura = @suma
			SET @suma = @suma - @valoareFactura

			INSERT listaFacturiOffline (factura, suma)
			SELECT rtrim(@factura), @valoareFactura

			FETCH NEXT
			FROM listaFacturi
			INTO @factura, @valoareFactura
		END

		CLOSE listaFacturi

		DEALLOCATE listaFacturi

		SET @docPlin = (
				SELECT 'RE' tip, @contPlata cont, convert(VARCHAR, @data, 101) data, (
						SELECT 'IB' '@subtip', l.factura '@factura', @numar '@numar', CONVERT(DECIMAL(12, 2), l.suma) '@suma', 
							@tert '@tert'
						FROM listaFacturiOffline l
						FOR XML path('row'), type
						)
				FOR XML raw
				)

		BEGIN TRY
			-- verific daca au mai ramas de incasat bani, si nu mai sunt facturi pe sold.    
			IF @suma > 0
				RAISERROR ('Suma depaseste soldul tertului!', 11, 1)

			-- verific daca am gasit cel putin o factura pe care sa fac incasari    
			IF NOT EXISTS (
					SELECT 1
					FROM listaFacturiOffline
					)
				RAISERROR ('Tertul nu are facturi scadente!!', 11, 1)

			EXEC wScriuPozPlin @sesiune = @sesiune, @parXML = @docPlin

			INSERT INTO dateSincronizare (utilizator, cod, cod2, suma, tip, data, tert, STATUS, detalii)
			VALUES (@utilizator, @numar, @serie, @sumaIncasare, 'S', @data, @tert, 'ok', @docPlin)
		END TRY

		BEGIN CATCH
			INSERT INTO dateSincronizare (utilizator, cod, cod2, suma, tip, data, tert, STATUS, detalii)
			VALUES (@utilizator, @numar, @serie, @sumaIncasare, 'S', @data, @tert, ERROR_MESSAGE(), @docPlin)
		END CATCH

		SELECT @nrCurent = @nrCurent + 1
	END
END
ELSE --incasare facturi    
BEGIN
	SELECT @nrCurent = 1, @nrComenzi = @parXML.value('count (/Facturi/row)', 'INT')

	WHILE @nrCurent <= @nrComenzi
	BEGIN
		SELECT @doc = @parXML.query('/Facturi/row[position()=sql:variable("@nrCurent")]')

		SELECT @tert = @doc.value('(/row/@tert)[1]', 'varchar(20)'), @factura = @doc.value('(/row/@cod)[1]', 'varchar(20)'), 
			@data = isnull(@doc.value('(/row/@data)[1]', 'datetime'), GETDATE())

		SET @xml = (
				SELECT 'IB' tip, @utilizator utilizator
				FOR XML raw
				)

		EXEC wIauNrDocFiscale @parXML = @xml, @Numar = @numar OUTPUT, @serie = @serieTMP OUTPUT

		SET @docPlin = (
				SELECT 'RE' AS tip, @contPlata AS cont, convert(VARCHAR, @data, 101) AS data, (
						SELECT 'IB' AS subtip, @factura AS factura, @numar AS numar, CONVERT(DECIMAL(12, 2), f.Valoare + f.TVA_22 - f.
								Achitat) suma, @tert AS tert
						FROM facturi f
						WHERE f.Subunitate = @subunitate
							AND f.Tip = 0x46
							AND f.Factura = @factura
							AND f.Tert = @tert
						FOR XML raw, type
						)
				FOR XML raw, type
				)

		BEGIN TRY
			EXEC wScriuPozplin @sesiune = @sesiune, @parXML = @docPlin

			INSERT INTO dateSincronizare (utilizator, cod, tip, data, tert, STATUS, detalii)
			VALUES (@utilizator, @factura, 'F', @data, @tert, 'ok', @docPlin)
		END TRY

		BEGIN CATCH
			INSERT INTO dateSincronizare (utilizator, cod, tip, data, tert, STATUS, detalii)
			VALUES (@utilizator, @factura, 'F', @data, @tert, ERROR_MESSAGE(), @docPlin)
		END CATCH

		SELECT @nrCurent = @nrCurent + 1
	END
END
