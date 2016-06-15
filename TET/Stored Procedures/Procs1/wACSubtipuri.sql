
/** Tipuri de documente folosite la definirea plajelor **/
CREATE PROCEDURE wACSubtipuri @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @searchText VARCHAR(100), @meniu VARCHAR(20), @tip varchar(20)

SET @searchText = '%' + replace(ISNULL(@parXML.value('(/*/@searchText)[1]', 'varchar(100)'), ''), ' ', '%') + '%'
SET @meniu = @parXML.value('(/*/@meniupl)[1]', 'varchar(20)')
SET @tip = @parXML.value('(/*/@tipdocument)[1]', 'varchar(20)')

SELECT 
	rtrim(wt.subtip) AS cod, RTRIM(wt.nume) AS denumire, 'Subtip: ' + rtrim(wt.subtip) AS info
from
	webConfigTipuri wt where wt.meniu=@meniu and wt.tip=@tip and ISNULL(fel,'')='' and ISNULL(Subtip,'')<>''			
FOR XML raw, root('Date')
