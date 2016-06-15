
CREATE PROCEDURE wIaAsocieriPlaja @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @idPlaja INT

SET @idPlaja = @parXML.value('(/*/@idPlaja)[1]', 'int')

SELECT rtrim(adf.tipAsociere) AS tipasociere, (
		CASE adf.tipAsociere WHEN 'J' THEN 'Jurnal' WHEN 'U' THEN 'Utilizator' WHEN 'L' THEN 'Loc de munca' WHEN '' THEN 'Unitate' WHEN 'G' 
				THEN 'Grup de utilizatori' END
		) AS dentipasociere, rtrim(cod) AS cod, prioritate AS prioritate
FROM asocieredocfiscale adf
WHERE adf.id = @idPlaja
FOR XML raw, root('Date')
