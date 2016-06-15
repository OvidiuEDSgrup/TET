
/***--
Procedura stocata citeste antetul Inventar-ului.
	
param:	@sesiune	Sesiune utilizatorului curent, din care se identifica utilizatorul
		@parXML		Parametru xml in care vin datele. Se citeste:
					@searchText ->	Textul din autoComplete dupa care se face scanarea/cautarea
--***/
CREATE PROCEDURE wmIaWInventar @sesiune VARCHAR(50), @parXML XML
AS
-- apelare procedura specifica daca aceasta exista.
IF EXISTS (
		SELECT 1
		FROM sysobjects
		WHERE [type] = 'P'
			AND [name] = 'wmIaWInventarSP'
		)
BEGIN
	DECLARE @returnValue INT

	EXEC @returnValue = wmIaWInventarSP @sesiune, @parXML OUTPUT

	RETURN @returnValue
END

DECLARE @userASiS VARCHAR(50), @mesaj VARCHAR(100), @searchText VARCHAR(100)

BEGIN TRY
	/*Validare utilizator */
	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @userASiS OUTPUT

	/*Citeste variabile din parametrii */
	SELECT @searchText = '%' + ISNULL(REPLACE(@parXML.value('(/*/@searchText)[1]', 'varchar(100)'), ' ', '%'), '') + '%';

	SELECT TOP 25 RTRIM(ai.gestiune) AS cod,
		(CASE WHEN ai.gestiune = g.Cod_gestiune THEN 'Inventar gest. ' + ltrim(rtrim(g.Denumire_gestiune))
			WHEN ai.gestiune = p.Marca THEN 'Inventar fol. ' + ltrim(rtrim(p.Nume)) END) AS denumire, 'wmIaWPozInv' AS 
		_procdetalii, 'Articole scanate: ' + convert(VARCHAR, isnull(nr.pozitii,0)) AS info, ai.idInventar idInventar,
		(CASE ai.stare WHEN 0 THEN '0x00FF00' WHEN 1 THEN '0xFF0000' END) AS culoare, ai.stare as stareInventar
	FROM AntetInventar ai
	LEFT JOIN gestiuni g ON ai.tip='G' and g.Cod_gestiune = ai.gestiune
	LEFT JOIN personal p ON ai.tip='M' and ai.gestiune = p.Marca
	LEFT JOIN (
		SELECT p.idInventar, count(1) AS pozitii
		FROM PozInventar p
		GROUP BY p.idInventar
		) nr
		ON nr.idInventar = ai.idInventar
			AND (isnull(g.Denumire_gestiune, '%') LIKE @searchText OR isnull(p.Nume, '%') LIKE @searchText)
	WHERE ai.stare IN (0, 1)
		AND (g.Denumire_gestiune LIKE '%' + @searchText + '%' OR p.Nume LIKE '%' + @searchText + '%')
	FOR XML raw, root('Date')

	SELECT 1 AS areSearch, '1' AS _toateAtr
	FOR XML raw, root('Mesaje');
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + '( wmIaWInventar)'
END CATCH

IF LEN(@mesaj) > 0
	RAISERROR (@mesaj, 11, 1)
