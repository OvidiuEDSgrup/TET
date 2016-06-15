
CREATE PROCEDURE wIaPozLansari @sesiune VARCHAR(50), @parXML XML
AS
IF EXISTS (SELECT * FROM sysobjects WHERE NAME = 'wIaPozLansariSP' AND type = 'P')
BEGIN
	EXEC wIaPozLansariSP @sesiune = @sesiune, @parXML = @parXML
	RETURN
END

	DECLARE @cod VARCHAR(20), @fltcod VARCHAR(20), @fltdenumire VARCHAR(20), @flttip VARCHAR(20), @doc XML, @add XML, @id INT, @pretProdus 
		FLOAT, @codProdus VARCHAR(20), @denumireProdus VARCHAR(80), @tipLansare VARCHAR(20), @cantitateProdus FLOAT, @umProdus VARCHAR
		(20), @idPozTehnologii INT

	SELECT 
		@cod = ISNULL(@parXML.value('(/row/@comanda)[1]', 'varchar(20)'), ''), 
		@codProdus = ISNULL(@parXML.value('(/row/@cod)[1]', 'varchar(20)'), ''), 
		@cantitateProdus = ISNULL(@parXML.value('(/row/@cantitate)[1]', 'float'), '')

	SELECT 
		@id = id, @idPozTehnologii = idp, @cantitateProdus = cantitate
	FROM pozLansari
	WHERE tip = 'L' AND cod = @cod

	IF @codProdus = ''
		SELECT @codProdus = cod
		FROM pozTehnologii
		WHERE id = @idPozTehnologii

	SELECT 
		@denumireProdus = denumire, @umProdus = um, @pretProdus = Pret_stoc
	FROM nomencl
	WHERE cod = @codProdus

	SELECT @tipLansare = Val_numerica
	FROM par
	WHERE tip_Parametru = 'MP' AND parametru = 'TIPLANS'

	IF isnull(@tipLansare,0) = 0
	BEGIN
		--Ca sa nu fie eroare la .modify in caz ca nu sunt date  
		SET @doc = ''
		SET @doc = 
		(
				SELECT 
					@cod AS comanda, (CASE WHEN pl.tip = 'O' THEN 'Operatie' WHEN (pl.tip = 'M' AND n.tip = 'P') THEN 'Semifabricat' WHEN pl.tip = 'R' THEN 'Reper' ELSE 'Material' END) AS tip, 
					(CASE WHEN pl.tip IN ('M', 'Z') THEN rtrim(n.denumire) WHEN pl.tip = 'O' THEN rtrim(c.Denumire) WHEN pl.tip = 'R' THEN RTRIM(isnull(t.denumire, pl.detalii.value('(/row/@denumire)[1]', 'varchar(20)'))) END) AS denumire, 
					(CASE WHEN pl.tip IN ('M', 'Z') THEN rtrim(n.um) WHEN pl.tip = 'O' THEN rtrim(c.um) END) AS um, pl.id AS id, rtrim(pl.cod) AS cod, CONVERT(DECIMAL(10, 2), pl.cantitate) AS cantitate, 
					(CASE WHEN pl.tip = 'M' THEN 'MC' WHEN pl.tip = 'O' THEN 'OP' END) AS subtip, dbo.wfIaArboreLansare(pl.id), pl.detalii AS detalii
				FROM pozLansari pl
				LEFT JOIN nomencl n ON n.Cod = pl.cod
				LEFT JOIN catop c ON c.Cod = pl.cod
				LEFT JOIN tehnologii t ON pl.cod = t.cod
				WHERE pl.tip IN ('M', 'O', 'R')	AND pl.idp = @id
				ORDER BY pl.tip
				FOR XML raw, root('Pozitii')
		)

		IF @doc IS NOT NULL
		BEGIN
			SET @doc.modify('insert attribute tip {"Produs"} into (/Pozitii)[1]')
			SET @doc.modify('insert attribute cod {sql:variable("@codProdus")} into (/Pozitii)[1]')
			SET @doc.modify('insert attribute pret {sql:variable("@pretProdus")} into (/Pozitii)[1]')
			SET @doc.modify('insert attribute cantitate {sql:variable("@cantitateProdus")} into (/Pozitii)[1]')
			SET @doc.modify('insert attribute denumire {sql:variable("@denumireProdus")} into (/Pozitii)[1]')
			SET @doc.modify('insert attribute id {sql:variable("@id")} into (/Pozitii)[1]')
			SET @doc = (
					SELECT @doc
					FOR XML path('Ierarhie')
					)
			SET @doc.modify('insert attribute _expandat {"da"} into (/Ierarhie)[1]')
		END

		SELECT '1' AS areDetaliiXml
		FOR XML raw, root('Mesaje')

		SELECT @doc
		FOR XML path('Date')
	END
	ELSE
		SELECT 
			'Produs' AS _grupare, rtrim(@codProdus) AS cod, rtrim(@denumireProdus) AS denumire, convert(DECIMAL(12, 5),@cantitateProdus) AS cantitate, @umProdus AS um, convert(DECIMAL(12, 5), @pretProdus) AS pret
		FOR XML raw, root('Date')
