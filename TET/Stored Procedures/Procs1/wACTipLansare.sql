
CREATE PROCEDURE wACTipLansare @sesiune VARCHAR(50), @parXML XML
AS
IF EXISTS (
		SELECT *
		FROM sysobjects
		WHERE NAME = 'wACTipLansareSP'
			AND type = 'P'
		)
BEGIN
	EXEC wACTipLansareSP @sesiune = @sesiune, @parXML = @parXML

	RETURN
END

DECLARE @searchText VARCHAR(100), @tip VARCHAR(1)

SET @searchText = '%' + REPLACE(ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(100)'), '%'), ' ', '%') + '%'
SET @tip = ISNULL(@parXML.value('(/row/@tipL)[1]', 'varchar(100)'), 'P')

IF @tip IN ('P', 'S')
	SELECT RTRIM(t.denumire) AS denumire, 'Tehnologie' AS info, RTRIM(t.cod) AS cod
	FROM tehnologii t
	WHERE t.cod LIKE @searchText
		OR t.Denumire LIKE @searchText
	FOR XML raw, root('Date')
ELSE
	IF @tip = 'R'
		SELECT RTRIM(cod) AS denumire, 'Antecalculatie' AS info, RTRIM(cod) AS cod
		FROM antecalculatii
		WHERE cod LIKE @searchText
		FOR XML raw, root('Date')
