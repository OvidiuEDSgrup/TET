
CREATE PROCEDURE wIaStocuriLocatie @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @codlocatie VARCHAR(13), @gestiune VARCHAR(9), @subunitate VARCHAR(10)

SET @codlocatie = @parXML.value('(/row/@codlocatie)[1]', 'varchar(13)')
SET @gestiune = @parXML.value('(/row/@gestiune)[1]', 'varchar(9)')

EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate OUTPUT

SELECT rtrim(st.cod) AS cod, CONVERT(VARCHAR(10), st.data, 101) AS data, RTRIM(st.Cod_intrare) AS codintrare, rtrim(n.um) AS um, 
	CONVERT(DECIMAL(15, 2), st.stoc) AS stoc, RTRIM(n.denumire) AS denumire
FROM stocuri st
JOIN nomencl n ON st.Cod = n.Cod
WHERE st.Subunitate = @subunitate
	AND (st.Cod_gestiune = @gestiune or @gestiune='')
	AND st.Locatie = @codlocatie
	and abs(st.stoc)>0
FOR XML raw, root('Date')
