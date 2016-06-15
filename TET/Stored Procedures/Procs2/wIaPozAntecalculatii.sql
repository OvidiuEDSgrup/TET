
CREATE PROCEDURE wIaPozAntecalculatii @sesiune VARCHAR(50), @parXML XML
AS
BEGIN
	IF EXISTS (SELECT *	FROM sysobjects	WHERE NAME = 'wIaPozAntecalculatiiSP' AND type = 'P')
	BEGIN
		EXEC wIaPozAntecalculatiiSP @sesiune = @sesiune, @parXML = @parXML
		RETURN
	END

	DECLARE 
		@id INT, @mat XML, @man XML, @rez XML

	SET @id = ISNULL(@parXML.value('(/row/@idAntec)[1]', 'int'), 0)
	SET @rez = (SELECT dbo.wfIaArboreElemAntec(@id, ''))
	--Obtinere xml-uri care vor contine elementele Materiale respectiv Operatii( Materiale directe, Manopera directa)
	SET @mat = (
			SELECT 
				RTRIM(n.denumire) +' ('+ rtrim(pa.cod)+')' AS denumireCod, RTRIM(n.denumire) AS denumire, RTRIM(n.um) AS um, 
				convert(DECIMAL(12, 5), pa.pret) AS pret, convert(DECIMAL(12, 5), pa.cantitate) AS cantitate, convert(DECIMAL(15, 6), pa.cantitate * pa.pret) AS valoare, 
				rtrim(pa.cod) AS cod, convert(DECIMAL(15, 6), (pa.cantitate * pa.pret) / a.curs) AS valuta, 'M' AS subtip, pa.id AS id
			FROM pozAntecalculatii pa
			LEFT JOIN antecalculatii a ON pa.idp = a.idPoz AND pa.tip = 'M'
			INNER JOIN nomencl n ON n.Cod = pa.cod
			WHERE a.idAntec = @id
			FOR XML raw
			)
	SET @man = (
			SELECT 
				RTRIM(c.denumire) + ' ('+ rtrim(pa.cod)+')' AS denumireCod, RTRIM(c.denumire) AS denumire, RTRIM(c.um) AS um, convert(DECIMAL(15, 6), pa.pret) AS pret,
				convert(DECIMAL(12,5), pa.cantitate) AS cantitate, convert(DECIMAL(15, 6), pa.cantitate * pa.pret) AS valoare, rtrim(pa.cod) AS cod, 
				convert(DECIMAL(12, 5), (pa.cantitate * pa.pret) / a.curs) AS valuta, 'M' AS subtip, pa.id AS id
			FROM pozAntecalculatii pa
			LEFT JOIN antecalculatii a ON pa.idp = a.idPoz AND pa.tip = 'O'
			INNER JOIN catop c ON c.Cod = pa.cod
			WHERE a.idAntec = @id
			FOR XML raw
			)

	IF @rez IS NOT NULL
	BEGIN
		--Adaugare MAT si MAN in structura antecalculatiei ( acolo unde sunt copii)
		SET @rez.modify('insert sql:variable("@man") into (//row[@cod="MAN"])[1]')
		SET @rez.modify('insert sql:variable("@mat") into (//row[@cod="MAT"])[1]')
	END

	SET @rez = (SELECT @rez FOR XML path('Ierarhie'))
	SET @rez.modify('insert attribute _expandat {"da"} into (/Ierarhie)[1]')

	SELECT @rez
	FOR XML path('Date')
END
