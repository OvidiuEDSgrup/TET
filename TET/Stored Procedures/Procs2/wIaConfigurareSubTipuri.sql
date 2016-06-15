
--***
CREATE PROCEDURE wIaConfigurareSubTipuri @sesiune VARCHAR(30), @parXML XML
AS
--Declare @sesiune varchar(30), @parXML xml
--Set @sesiune = ''
--Set @parXML = '<row tipMacheta="D"  codMeniu="DO" Tip="RM"/>'
DECLARE @parTipMacheta VARCHAR(2), @parCodMeniu VARCHAR(20), @parTip VARCHAR(20)

SET @parTipMacheta = @parXML.value('(/row/@tipMacheta)[1]', 'varchar(2)')
SET @parCodMeniu = @parXML.value('(/row/@codMeniu)[1]', 'varchar(20)')
SET @parTip = isnull(@parXML.value('(/row/@Tip)[1]', 'varchar(20)'), '')

DECLARE @utilizator VARCHAR(255), @limba VARCHAR(50)

EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

SET @limba = dbo.wfProprietateUtilizator('LIMBA', @utilizator)

SELECT subtip, dbo.wfTradu(@limba, (CASE WHEN fel = 'O' THEN wt.Nume + case when isnull(tasta,'')<>'' then ' (Ctrl+' + rtrim(tasta) + ')' else '' end ELSE rtrim(wt.Nume) END)) 
	AS Nume, ProcDate, ISNULL(fel, '') AS fel, RTRIM(dbo.wfTradu(@limba, TextAdaugare)) AS TextAdaugare, NULLIF(ProcPopulare,'') ProcPopulare, RTRIM(tasta) 
	tasta
FROM webConfigTipuri wt
left join webConfigMeniu wm on wt.Meniu=wm.Meniu
WHERE --tipMacheta = @parTipMacheta	AND
	wt.Meniu = @parCodMeniu
	AND (isnull(wm.TipMacheta,'C')='C' or isnull(wt.Tip, '') = @parTip)
	AND ISNULL(subtip, '') <> ''
	AND wt.Vizibil = 1 --and ISNULL(fel,'')<>'O'
ORDER BY Ordine
FOR XML raw
	--Testare 
	-- exec wIaConfigurareSubTipuri '','<row tipMacheta="D"  codMeniu="DO" Tip="RM"/>'
	-- exec wIaConfigurareSubTipuri '','<row tipMacheta="C"  codMeniu="T" Tip="RM"/>'
