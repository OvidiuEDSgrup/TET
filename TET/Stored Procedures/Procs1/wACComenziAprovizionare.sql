
CREATE PROCEDURE wACComenziAprovizionare @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @tert VARCHAR(50), @searchText VARCHAR(200)

SET @searchText = replace(ISNULL(@parXML.value('(/*/@searchText)[1]', 'varchar(80)'), ''), ' ', '%')
SET @tert = @parXML.value('(/*/@tert)[1]', 'varchar(50)')

SELECT ct.idContract AS cod, 'Nr. com. ' + RTRIM(ct.numar) + '- ' + CONVERT(VARCHAR(10), ct.data, 103) AS denumire, 'Gest. ' + RTRIM(g.
		Denumire_gestiune) AS info
FROM Contracte ct
INNER JOIN gestiuni g
	ON g.Cod_gestiune = ct.gestiune
		AND ct.tip = 'CA'
		AND (
			isnull(@tert,'')='' 
			OR ct.tert = @tert
			)
		AND (
			ct.numar LIKE @searchText
			OR ct.explicatii LIKE @searchText
			)
FOR XML raw, root('Date')
