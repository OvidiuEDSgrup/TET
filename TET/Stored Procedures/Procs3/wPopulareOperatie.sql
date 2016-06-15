
--***
CREATE PROCEDURE wPopulareOperatie @sesiune VARCHAR(30), @parXML XML
AS
DECLARE @utilizator VARCHAR(100), @obiectSQL VARCHAR(100), @meniu VARCHAR(20), @tip VARCHAR(20), @subtip VARCHAR(20), @tipMacheta 
	VARCHAR(20)

EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

SET @tipMacheta = @parXML.value('(/row/@tipMacheta)[1]', 'varchar(20)')
SET @meniu = @parXML.value('(/row/@codMeniu)[1]', 'varchar(20)')
SET @tip = isnull(@parXML.value('(/row/@TipDetaliere)[1]', 'varchar(20)'), ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(20)')
			, ''))
SET @subtip = isnull(@parXML.value('(/row/@subtip)[1]', 'varchar(20)'), '')

SELECT @obiectSQL = ProcScriere
FROM webConfigTipuri t inner join webconfigmeniu m on t.meniu=m.meniu
WHERE m.TipMacheta = @tipMacheta
	AND (
		@tipMacheta = 'O'
		AND t.meniu = @meniu
		)
	OR (
		t.meniu = @meniu
		AND t.tip = @tip
		AND t.subtip = @subtip
		AND t.fel = 'O'
		)

SELECT isnull((
			SELECT TOP 1 parametruXML
			FROM webJurnalOperatii
			WHERE obiectSQL = @obiectSQL
				AND utilizator = @utilizator
			ORDER BY data DESC
			), (
			SELECT TOP 1 parametruXML
			FROM webJurnalOperatii
			WHERE obiectSQL = @obiectSQL
			ORDER BY data DESC
			))
