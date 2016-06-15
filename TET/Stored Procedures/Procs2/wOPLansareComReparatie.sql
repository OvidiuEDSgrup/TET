
CREATE PROCEDURE wOPLansareComReparatie @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @codmasina VARCHAR(20), @codtehnologie VARCHAR(20), @data DATETIME, @mesaj VARCHAR(400), @xmlPozLansari XML, @fisa VARCHAR(
		20), @xmlPozActivitati XML, @interventie VARCHAR(20), @nrPozitie INT

BEGIN TRY
	SET @codmasina = @parXML.value('(/*/@masina)[1]', 'varchar(20)')
	SET @fisa = @parXML.value('(/*/@fisa)[1]', 'varchar(20)')
	SET @codtehnologie = @parXML.value('(/*/@codtehnologie)[1]', 'varchar(20)')
	SET @data = @parXML.value('(/*/@data)[1]', 'datetime')
	SET @interventie = @parXML.value('(/*/@element)[1]', 'varchar(20)')

	IF isnull(@codmasina, '') = ''
		RAISERROR ('Codul masinii nu poate fi identificat. Selectati o intrare din tabel!', 11, 1)

	IF ISNULL(@codtehnologie, '') = ''
		RAISERROR ('Codul tehnologiei de reparatie nu este completat', 11, 1)

	IF ISNULL(@interventie, '') = ''
		RAISERROR ('Elementul nu poate fi identificat. Selectati o intrare din tabel!', 11, 1)

	/** NU stiu cum se aloca numarul de fisa **/
	SELECT @nrPozitie = 1

	/** 
		Se scrie o Foaia de interventie cu acest element ( interventie )
	**/
	SET @xmlPozActivitati = (
			SELECT rtrim(cast(DAY(@data) AS CHAR(2))) + rtrim(cast(month(@data) AS CHAR(2))) + substring(RTRIM(cast(@nrPozitie AS 
							CHAR(20))), 1, 6) fisa, @data data, @codmasina masina, 0 KmBord, 'FI' AS tip, (
					SELECT @interventie interventie, 'Generat automat cu comanda de reparatie' explicatii, 'FI' subtip
					FOR XML raw, type
					)
			FOR XML raw
			)

	EXEC wScriuPozActivitati @sesiune = @sesiune, @parXML = @xmlPozActivitati

	/**
		Se scrie comanda de reparatie ca si comanda Auxiliara cu beneficiarul=masina curenta	
	**/
	SET @xmlPozLansari = (
			SELECT @codtehnologie cod, '1' AS cantitate, '' AS tert, GETDATE() AS data, '' AS termen, '' AS contract, @codmasina AS resursa, 
				'X' AS tipComanda, @codmasina AS comandaBenef
			FOR XML raw
			)

	EXEC wScriuPozLansari @sesiune = @sesiune, @parXML = @xmlPozLansari
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + '(wOPLansareComReparatie)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
