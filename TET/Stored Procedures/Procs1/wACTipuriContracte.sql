
CREATE PROCEDURE wACTipuriContracte @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @searchText VARCHAR(100), @tipAsociere VARCHAR(2)

SET @searchText = '%' + replace(ISNULL(@parXML.value('(/*/@searchText)[1]', 'varchar(100)'), ''), ' ', '%') + '%'

SELECT 'CB' AS cod, 'Contracte beneficiar' AS denumire

UNION ALL

SELECT 'CF' AS cod, 'Contracte furnizor' AS denumire

UNION ALL

SELECT 'CL' AS cod, 'Comenzi livrare' AS denumire

UNION ALL

SELECT 'CA' AS cod, 'Comenzi aprovizionare' AS denumire

UNION ALL

SELECT 'CT' as cod, 'Comenzi transport' as denumire
UNION ALL

SELECT 'CS' as cod, 'Contracte servcii' as denumire
UNION ALL

SELECT 'PR' as cod, 'Proforme' as denumire

FOR XML raw, root('Date')
