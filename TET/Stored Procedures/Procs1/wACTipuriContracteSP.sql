
CREATE PROCEDURE wACTipuriContracteSP @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @searchText VARCHAR(100), @tipAsociere VARCHAR(2), @tip varchar(2), @codMeniu varchar(20)

SET @tip = @parXML.value('(/*/@tip)[1]', 'varchar(2)')
--SET @codMeniu = @parXML.value('(/*/@tip)[1]', 'varchar(2)')

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

SELECT 'CS' as cod, 'Contracte servicii' as denumire
--/*sp
UNION ALL
SELECT 'OB' as cod, 'Oferte beneficiar' as denumire --sp*/

FOR XML raw, root('Date')
