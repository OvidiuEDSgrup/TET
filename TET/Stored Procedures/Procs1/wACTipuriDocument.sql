
/** Tipuri de documente folosite la definirea plajelor **/
CREATE PROCEDURE wACTipuriDocument @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @searchText VARCHAR(100), @meniu VARCHAR(20)

SET @searchText = '%' + replace(ISNULL(@parXML.value('(/*/@searchText)[1]', 'varchar(100)'), ''), ' ', '%') + '%'
SET @meniu = ISNULL(@parXML.value('(/*/@meniupl)[1]', 'varchar(20)'),@parXML.value('(/*/@meniu)[1]', 'varchar(20)'))
select @searchText
SELECT rtrim(ft.tip) AS cod, RTRIM(ft.nume) AS denumire, 'Tip: ' + rtrim(ft.tip) AS info
FROM dbo.wfIaTipuriDocumente(NULL) ft
WHERE (
		ft.tip LIKE @searchText
		OR ft.nume LIKE @searchText
		)
	AND ft.meniu = @meniu

FOR XML raw, root('Date')
