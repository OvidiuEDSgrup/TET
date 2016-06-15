
CREATE PROCEDURE wACComenziTransport @sesiune VARCHAR(50), @parXML XML
AS
	DECLARE
		@searchText VARCHAR(200)
	/**
		Arata transporturile (comenzi de tip CT)

	**/

	SET @searchText = '%'+replace(ISNULL(@parXML.value('(/*/@searchText)[1]', 'varchar(80)'), ''), ' ', '%')+'%'


	SELECT top 100
		ct.idContract AS cod, 
		RTRIM(ct.numar) + '/' + replace(CONVERT(VARCHAR(10), ct.data, 103),'/','-')+ISNULL('('+rtrim(ct.explicatii)+')','') AS denumire, 
		'Gest. ' + RTRIM(g.Denumire_gestiune) AS info
	FROM Contracte ct
	left JOIN gestiuni g ON g.Cod_gestiune = ct.gestiune and g.Subunitate='1'
	left JOIN terti t ON t.tert = ct.tert and t.Subunitate='1'
	where (RTRIM(ct.numar) + '/' + replace(CONVERT(VARCHAR(10), ct.data, 103),'/','-')+ISNULL('('+rtrim(ct.explicatii)+')','') like @searchText)
	AND ct.tip='CT'
	FOR XML raw, root('Date')
