
CREATE PROCEDURE CalculRecapitulatie @sesiune VARCHAR(50), @parXML XML
AS
IF EXISTS (SELECT * FROM sysobjects WHERE NAME = 'CalculRecapitulatieSP' AND type = 'P')
BEGIN
	EXEC CalculRecapitulatieSP @sesiune = @sesiune, @parXML = @parXML
	RETURN
END

DECLARE 
	@elem VARCHAR(20), @nF INT, @cSQL VARCHAR(7000), @cFormula VARCHAR(7000), @nProcent INT, @nPas INT, @gPas INT, @cLinieUpdate VARCHAR(8000),@nValImp FLOAT, 
	@nivel INT, @id INT, @element VARCHAR(20), @procent FLOAT, @scriuPret BIT, @mesaj VARCHAR(500),@parCalcul XML, @curs FLOAT, @valuta VARCHAR(10)

BEGIN TRY
	SET @nivel = @parXML.value('(/row/@nivel)[1]', 'int')
	SET @id = @parXML.value('(/row/@id)[1]', 'int')
	SET @element = @parXML.value('(/row/@element)[1]', 'varchar(20)')
	SET @procent = @parXML.value('(/row/@procent)[1]', 'float')
	SET @scriuPret = isnull(@parXML.value('(/row/@scriuPret)[1]', 'bit'), 0)
	SET @curs = @parXML.value('(/row/@curs)[1]', 'float')
	SET @valuta = @parXML.value('(/row/@valuta)[1]', 'varchar(10)')

	IF EXISTS (SELECT * FROM sysobjects	WHERE NAME = 'tmp_updateuri')
		DROP TABLE tmp_updateuri

	CREATE TABLE tmp_updateuri (linie VARCHAR(8000), pas INT)

	IF OBJECT_ID('tempdb..##tmpElemAntec') IS NOT NULL
		DROP TABLE ##tmpElemAntec

	SELECT *
	INTO ##tmpElemAntec
	FROM elemantec

	IF object_id('tempdb..##ElemSterse') IS NOT NULL
	BEGIN
		UPDATE ##tmpElemAntec
		SET valoare_implicita = cantitate
		FROM ##ElemSterse
		WHERE ##tmpElemAntec.Element = ##ElemSterse.cod

		DROP TABLE ##ElemSterse
	END

	IF @procent IS NOT NULL
		AND ISNULL(@element, '') <> ''
		UPDATE ##tmpElemAntec
		SET valoare_implicita = @procent / 100
		WHERE element = @element
			AND procent = 1

	DECLARE @cursorelem CURSOR
	set @cursorelem = cursor local fast_forward for
	SELECT element, formula, procent, pas, valoare_implicita
	FROM ##tmpElemAntec
	WHERE pas > 1
	ORDER BY pas

	OPEN @cursorelem

	FETCH NEXT
	FROM @cursorelem
	INTO @elem, @cFormula, @nProcent, @nPas, @nValImp

	SET @gPas = @nPas
	SET @cLinieUpdate = 'update anteclcpeCoduri set '
	SET @nF = @@FETCH_STATUS

	WHILE @nF = 0
	BEGIN
		SET @cSQL = 'ALTER TABLE anteclcpeCoduri add [' + rtrim(ltrim(@elem)) + '] decimal(12,5)'

		IF @elem != 'TP'
			EXEC (@cSQL)

		IF @gPas != @nPas
		BEGIN
			SET @cLinieUpdate = LEFT(@cLinieUpdate, LEN(@cLinieUpdate) - 1)

			INSERT INTO tmp_updateuri (linie, pas)
			VALUES (@cLinieUpdate, @nPas)

			SET @gPas = @nPas
			SET @cLinieUpdate = 'update anteclcpeCoduri set '
		END

		SET @cLinieUpdate = @cLinieUpdate + '[' + RTRIM(LTRIM(@elem)) + ']=' + (CASE WHEN @nProcent = 0 THEN '' ELSE CONVERT(VARCHAR(20), @nValImp) + '*' END
				) + RTRIM(LTRIM(@cFormula)) + ','

		FETCH NEXT
		FROM @cursorelem
		INTO @elem, @cFormula, @nProcent, @nPas, @nValImp

		SET @nF = @@FETCH_STATUS
	END

	SET @cLinieUpdate = LEFT(@cLinieUpdate, LEN(@cLinieUpdate) - 1)

	INSERT INTO tmp_updateuri (linie, pas)
	VALUES (@cLinieUpdate, @nPas)
	
	DECLARE @calculat INT

	WHILE @nivel >= 0
	BEGIN
		SET @parCalcul = (SELECT @nivel nivel, @calculat calculat, @id id, @curs curs, @valuta valuta	FOR XML raw)
		
		set @parXML.modify('delete (/*/@*[local-name()=("nivel", "calculat","id")])')
		set @parXML.modify('insert attribute nivel {sql:variable("@nivel")} into (/*)[1]')
		set @parXML.modify('insert attribute id {sql:variable("@id")} into (/*)[1]')
		set @parXML.modify('insert attribute calculat {sql:variable("@calculat")} into (/*)[1]')
		
		EXEC CalculMaterialesiManopera @sesiune = @sesiune, @parXML = @parXML OUTPUT
		SELECT @calculat = @parXML.value('(/*/@calculat)[1]', 'int')
		
		IF @calculat > 0
		BEGIN
			/*Calculam elementele de antecalculatii dintr-un foc pentru un nivle*/
			SET @cSQL = dbo.fn_ConcatComandaSQL(@nivel)
			EXEC (@cSQL)
			
			IF @scriuPret = 1
				/*Facem update in nomenclator la semifabricate pentru a le lua cu un nivel mai sus*/
				UPDATE dbo.nomencl
				SET dbo.nomencl.Pret_stoc = anteclcpeCoduri.TP
				FROM anteclcpeCoduri
				WHERE anteclcpeCoduri.cod = nomencl.cod
					AND anteclcpeCoduri.nivel = @nivel
					AND anteclcpeCoduri.TP IS NOT NULL
		END
		SET @nivel = @nivel - 1
	END

END TRY
begin catch
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
