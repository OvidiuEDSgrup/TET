
/** Procedura este aferenta machetei de Tipuri Documente **/
CREATE PROCEDURE wIaTipuriDoc @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @f_tip VARCHAR(50), @f_denumire VARCHAR(50)

SET @f_tip = '%' + @parXML.value('(/*/@f_tip)[1]', 'varchar(5)') + '%'
SET @f_denumire = '%' + @parXML.value('(/*/@f_denumire)[1]', 'varchar(50)') + '%'

SELECT idTip, rtrim(tip) AS tip, rtrim(denumire) AS denumire
FROM TipuriDocumente
WHERE (
		@f_tip IS NULL
		OR tip LIKE @f_tip
		)
	AND (
		@f_denumire IS NULL
		OR denumire LIKE @f_denumire
		)
FOR XML raw, root('Date')
