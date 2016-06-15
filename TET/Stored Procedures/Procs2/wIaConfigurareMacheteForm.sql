
CREATE PROCEDURE wIaConfigurareMacheteForm @sesiune VARCHAR(30), @parXML XML
AS


DECLARE @parTipMacheta VARCHAR(20), @parCodMeniu VARCHAR(20), @parInDetaliere INT, @parTipDetaliere VARCHAR(20), @parTip VARCHAR(20),
	@parSubtip VARCHAR(20)

SET @parTipMacheta = @parXML.value('(/row/@tipMacheta)[1]', 'varchar(20)')
SET @parCodMeniu = @parXML.value('(/row/@codMeniu)[1]', 'varchar(20)')
SET @parTipDetaliere = isnull(@parXML.value('(/row/@TipDetaliere)[1]', 'varchar(20)'), '')
SET @parSubtip = isnull(@parXML.value('(/row/@subtip)[1]', 'varchar(20)'), '')

DECLARE @utilizator VARCHAR(255), @limba VARCHAR(50)

EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

SET @limba = dbo.wfProprietateUtilizator('LIMBA', @utilizator)

SELECT	case when TipObiect='ACA' then 'AC' else rtrim(TipObiect) end as TipObiect, 
		rtrim(dbo.wfTradu(@limba, wf.Nume)) AS Nume, 
		rtrim(dbo.wfTradu(@limba, Tooltip)) AS Tooltip, 
		RTRIM(DataField) as DataField, 
		RTRIM(LabelField) as LabelField, 
		Latime, 
		RTRIM(ProcSQL) as ProcSQL, 
		RTRIM(ListaValori) as ListaValori, 
		RTRIM(ListaEtichete) as ListaEtichete, 
		RTRIM(Initializare) as Initializare, 
		rtrim(dbo.wfTradu(@limba, Prompt)) AS Prompt, 
		isnull(Modificabil,0) Modificabil, 
		rtrim(formula) as formula,
		case when TipObiect='ACA' then wf.detalii end detalii
FROM webConfigForm wf 
left join webconfigmeniu w on wf.meniu=w.meniu
WHERE 
	wf.Vizibil = 1
	AND wf.Meniu = @parCodMeniu
	AND ((w.TipMacheta='C' and (isnull(wf.Tip, '') = @parTipDetaliere OR @parSubtip<>'')) OR  isnull(wf.Tip, '') = @parTipDetaliere )
	AND @parSubtip=ISNULL(wf.subtip,'') 
ORDER BY wf.Ordine
FOR XML raw

SELECT (
		SELECT 
			rtrim(dbo.wfTradu(@limba, wcg.numecol)) AS numecol, rtrim(wcg.datafield) datafield, rtrim(wcg.TipObiect) TipObiect, wcg.latime latime, 
			isnull(wcg.modificabil,0) modificabil, rtrim(isnull(formula,'')) as formula
		FROM webConfigGrid wcg
		JOIN webConfigTipuri wct ON wcg.Meniu = wct.Meniu AND isnull(wcg.Tip,'') = isnull(wct.Tip,'') AND isnull(wcg.Subtip,'') = isnull(wct.Subtip,'')
		inner join webconfigmeniu w on w.meniu=wcg.meniu
		WHERE  
			(w.TipMacheta = 'O' OR wct.Fel = 'O')
			AND wcg.Meniu = @parCodMeniu
			AND isnull(wcg.Tip, '') = @parTipDetaliere
			AND (@parSubtip = '' OR wcg.Subtip = @parSubtip)
			AND wcg.Vizibil = 1
		ORDER BY wcg.Ordine
		FOR XML raw, type
		)
FOR XML path('ColoaneGrid'), root('Mesaje')
	--Testare   
	-- exec wIaConfigurareMacheteForm '','<row tipMacheta="C" codMeniu="T" />'  
	-- exec wIaConfigurareMacheteForm '','<row tipMacheta="C" codMeniu="T" TipDetaliere="PL" />'
	-- exec wIaConfigurareMacheteForm '','<row tipMacheta="D" codMeniu="DO" TipDetaliere="RM" />'
