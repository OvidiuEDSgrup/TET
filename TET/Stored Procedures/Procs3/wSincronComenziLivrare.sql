
CREATE PROCEDURE wSincronComenziLivrare @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @docCon XML, @gestiune VARCHAR(20), @explicatii VARCHAR(80), @lm VARCHAR(50), @tert VARCHAR(20),
 @subunitate VARCHAR(9), @data DATETIME, @utilizator VARCHAR(100), @nrComenzi INT, @nrCurent INT, 
 @dataChar VARCHAR(10), @comanda VARCHAR(30), @dataSinc DATETIME, @numarComandaUser varchar(20)

--Iau utilizator        
EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

--Iau subunitate        
EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate OUTPUT

--Alte proprietati ale utilizatorului        
SELECT @gestiune = rtrim(ISNULL(@gestiune, dbo.wfProprietateUtilizator('GESTPV', @utilizator))), @lm = rtrim(ISNULL(@lm, dbo.wfProprietateUtilizator('LOCMUNCA', @utilizator))), @nrCurent = 1, @nrComenzi = @parXML.value('count (/Comenzi/row)', 'INT')

SELECT TOP 1 @dataSinc = data
FROM logSincronizare
WHERE utilizator = @utilizator
ORDER BY id DESC

DECLARE @NrDocFisc INT, @fXML XML, @tip VARCHAR(2)

SET @tip = 'CL'
SET @fXML = '<row/>'
SET @fXML.modify('insert attribute tip {sql:variable("@tip")} into (/row)[1]')
SET @fXML.modify('insert attribute utilizator {sql:variable("@utilizator")} into (/row)[1]')
SET @fXML.modify('insert attribute lm {sql:variable("@lm")} into (/row)[1]')

WHILE @nrCurent <= @nrComenzi
BEGIN
	SELECT @docCon = @parXML.query('/Comenzi/row[position()=sql:variable("@nrCurent")]')
	SET @numarComandaUser = @docCon.value('(/row/@cod)[1]', 'varchar(20)')

	IF @numarComandaUser LIKE 'NOU%'
		EXEC wIauNrDocFiscale @parXML = @fXML, @Numar = @NrDocFisc OUTPUT
	else
		set @NrDocFisc= CONVERT(int,@numarComandaUser)

	SELECT @tert = @docCon.value('(/row/@tert)[1]', 'varchar(20)'), @data = @docCon.value('(/row/@data)[1]', 'datetime'), @dataChar = convert(VARCHAR(10), @data, 101), @explicatii = ISNULL((
				SELECT TOP 1 rtrim(denumire)
				FROM terti
				WHERE tert = @tert
				), '')

	SET @comanda = @docCon.value('(/row/@cod)[1]', 'varchar(30)')
	SET @docCon.modify('delete /row/@comanda ')
	SET @docCon.modify('insert attribute numar {sql:variable("@NrDocFisc")} into (/row[1])')
	--SET @docCon.modify('insert attribute subunitate {sql:variable("@subunitate")} into (/row[1])')
	SET @docCon.modify('insert attribute tip {"CL"} into (/row[1])')
	SET @docCon.modify('insert attribute gestiune {sql:variable("@gestiune")} into (/row[1])')
	SET @docCon.modify('insert attribute lm {sql:variable("@lm")} into (/row[1])')
	SET @docCon.modify('replace value of (/row/@data)[1] with xs:string(sql:variable("@dataChar")) ')
	SET @docCon.modify('insert attribute explicatii {sql:variable("@explicatii")} into (/row[1])')
	SET @docCon.modify('replace value of (/row/@stare)[1] with "0" ')--daca se da inchidere comanda dea eroare wScriuPozContracte
	
	
	BEGIN TRY
		EXEC wScriuPozContracte @sesiune = @sesiune, @parXML = @docCon

		

		INSERT INTO dateSincronizare (utilizator, cod, cod2, tip, data, tert, STATUS, detalii)
		VALUES (@utilizator, @comanda, @NrDocFisc, 'C', @data, @tert, 'ok', @docCon)
	END TRY

	BEGIN CATCH
		INSERT INTO dateSincronizare (utilizator, cod, cod2, tip, data, tert, STATUS, detalii)
		VALUES (@utilizator, @comanda, @NrDocFisc, 'C', @data, @tert, ERROR_MESSAGE(), @docCon)
	END CATCH

	SELECT @nrCurent = @nrCurent + 1
END
