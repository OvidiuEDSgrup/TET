
CREATE PROCEDURE wACFormulare (@sesiune VARCHAR(50), @parXML XML)
AS
BEGIN
	DECLARE @searchText VARCHAR(100)

	SELECT @searchText = '%' + replace(isnull(@parXML.value('(row/@searchText)[1]', 'varchar(100)'), ' '), ' ', '%') + '%'

	SELECT TOP 100
		rtrim(xf.Numar_formular) AS cod, RTRIM(af.Denumire_formular) AS denumire
	FROM XMLFormular xf
	INNER JOIN antform af
		ON xf.Numar_formular = af.Numar_formular
	where xf.Numar_formular like @searchText or af.Denumire_formular like @searchText
	ORDER BY rtrim(af.Denumire_formular)
	FOR XML raw, root('Date')
END
