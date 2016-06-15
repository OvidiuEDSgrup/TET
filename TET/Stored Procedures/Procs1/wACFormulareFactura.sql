
/** Autocomplete-ul aduce formularele RDL asociate facturilor */
CREATE PROCEDURE wACFormulareFactura @sesiune varchar(50), @parXML xml
AS
BEGIN
	DECLARE @searchText VARCHAR(100)

	SELECT @searchText = '%' + replace(isnull(@parXML.value('(row/@searchText)[1]', 'varchar(100)'), ' '), ' ', '%') + '%'

	SELECT DISTINCT TOP 100 RTRIM(a.Numar_formular) AS cod, RTRIM(a.Denumire_formular) AS denumire
	FROM antform a
	INNER JOIN webConfigFormulare wcf ON wcf.cod_formular = a.Numar_formular
	WHERE (a.Numar_formular LIKE @searchText OR a.Denumire_formular LIKE @searchText)
		AND a.CLFrom = 'raport' -- doar formularele noi
		AND wcf.tip IN ('AP', 'AS', 'AC') -- doar formularele asociate facturilor
	ORDER BY RTRIM(a.Denumire_formular)
	FOR XML RAW, root('Date')
END
