
CREATE PROCEDURE wIaPozOrdineDePlata @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @idOP INT

SET @idOP = @parXML.value('(/*/@idOP)[1]', 'int')

SELECT pop.idOP idOP, pop.idPozOP idPozOP, RTRIM(pop.banca_tert) AS banca, 
	RTRIM((case when ISNULL(bb.Denumire,'')='' then pop.banca_tert else bb.Denumire end)) AS denbanca, RTRIM(pop.IBAN_tert) AS iban, 
	RTRIM(pop.tip) AS tipPoz, RTRIM(pop.explicatii) AS explicatii, CONVERT(DECIMAL(15, 2), pop.suma) suma, RTRIM(pop.stare) AS stare, 
	pop.detalii, 'OL' AS subtip, (CASE pop.tip WHEN 'F' THEN 'Facturi' WHEN 'D' THEN 'Deconturi' WHEN 'S' THEN 'Salarii' END) dentipPoz, 
	(CASE pop.stare WHEN 'I' THEN 'Invalid' WHEN 'V' THEN 'Valid' END
		) denstare
FROM PozOrdineDePlata pop
LEFT JOIN bancibnr bb
	ON bb.Cod = pop.banca_tert
WHERE pop.idOp = @idOP
FOR XML raw, root('Date')

SELECT '1' AS areDetaliiXml
FOR XML raw, root('Mesaje')
