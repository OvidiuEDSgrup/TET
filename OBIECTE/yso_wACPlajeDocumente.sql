IF EXISTS (
		SELECT *
		FROM sysobjects
		WHERE NAME = 'yso_wACPlajeDocumente'
		)
	DROP PROCEDURE yso_wACPlajeDocumente
GO

CREATE PROCEDURE yso_wACPlajeDocumente @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @searchText VARCHAR(100), @tipAsociere VARCHAR(2)

SET @searchText = '%' + replace(ISNULL(@parXML.value('(/*/@searchText)[1]', 'varchar(100)'), ''), ' ', '%') + '%'


SELECT df.id as cod, rtrim(df.tipDoc)+' '+RTRIM(df.Serie)+' '+RTRIM(df.NumarInf)+'-'+RTRIM(df.UltimulNr) AS denumire
	, rtrim(td.denumire)
		+', serie in nr: '+(CASE isnull(df.serieinnumar, 0) WHEN 0 THEN 'Nu' ELSE 'Da' END) AS info
FROM docfiscale df
JOIN TipuriDocumente td ON df.TipDoc = td.tip
WHERE (CASE isnull(df.serieinnumar, 0) WHEN 0 THEN 'Nu' ELSE 'Da' END) LIKE @searchText
		OR df.serie LIKE @searchText
		OR df.tipDoc LIKE @searchText
FOR XML raw, root('Date')
