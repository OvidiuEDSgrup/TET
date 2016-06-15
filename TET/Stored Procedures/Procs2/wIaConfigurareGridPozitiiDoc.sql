
--***
CREATE PROCEDURE wIaConfigurareGridPozitiiDoc @sesiune VARCHAR(30), @parXML XML
AS
--Declare @sesiune varchar(30), @parXML xml  
--Set @sesiune = ''  
--Set @parXML = '<row tipMacheta="D" codMeniu="DO" Tip="RM"/>'  
DECLARE @parTipMacheta VARCHAR(2), @parCodMeniu VARCHAR(20), @parTip VARCHAR(2), @parSubtip VARCHAR(2)

SET @parTipMacheta = @parXML.value('(/row/@tipMacheta)[1]', 'varchar(2)')
SET @parCodMeniu = @parXML.value('(/row/@codMeniu)[1]', 'varchar(20)')
SET @parTip = isnull(@parXML.value('(/row/@Tip)[1]', 'varchar(2)'), '')
SET @parSubtip = isnull(@parXML.value('(/row/@subtip)[1]', 'varchar(2)'), '')

DECLARE @utilizator VARCHAR(255), @limba VARCHAR(50)

EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

SET @limba = dbo.wfProprietateUtilizator('LIMBA', @utilizator)

SELECT tip, dbo.wfTradu(@limba, numecol) AS numecol, datafield, TipObiect, latime
FROM webConfigGrid
WHERE --tipMacheta = @parTipMacheta	AND
	Meniu = @parCodMeniu
	AND isnull(Tip, '') = @parTip
	AND InPozitii = 1
	AND Vizibil = 1
	AND (
		ISNULL(subtip, '') = ''
		OR isnull(@parSubtip, '') <> ''
		)
ORDER BY Ordine
FOR XML raw
	--Testare   
	--exec wIaConfigurareGridPozitiiDoc '','<row tipMacheta="D" codMeniu="DO" Tip="RM"/>'  
