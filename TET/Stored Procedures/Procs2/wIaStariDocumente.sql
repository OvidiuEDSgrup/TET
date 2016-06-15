
CREATE PROCEDURE wIaStariDocumente @sesiune VARCHAR(50), @parXML XML
AS
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @f_denumire VARCHAR(50), @f_stare INT, @f_tipdocument VARCHAR(20), @docXML XML

SET @f_denumire = '%' + @parXML.value('(/*/@f_denumire)[1]', 'varchar(50)') + '%'
SET @f_stare = @parXML.value('(/*/@f_stare)[1]', 'int')
SET @f_tipdocument = '%' + @parXML.value('(/*/@f_tipdocument)[1]', 'varchar(20)') + '%'

SELECT DISTINCT tipDocument
INTO #tipuriDocumente
FROM StariDocumente

SET @docXML = (
		SELECT rtrim(tp.tipDocument) tipDocument, (
				CASE tp.tipdocument WHEN 'AS' THEN 'Aviz servicii' WHEN 'AP' THEN 'Aviz produs' WHEN 'RM' THEN 
							'Receptii' WHEN 'RS' THEN 'Receptii servicii' WHEN 'PP' THEN 'Predare' WHEN 'CM' 
						THEN 'Consum' WHEN 'TE' THEN 'Transfer' when 'AC' then 'Aviz chitanta' when 'AI' then 'Alta intrare' 
						WHEN 'AE' then 'Alta iesire'
						END
				) AS dentipdocument, 1 AS _nemodificabil, (
				SELECT st.stare AS stare, rtrim(st.denumire) AS denumire, rtrim(tp.tipDocument) dentipdocument, rtrim(tp.
						tipdocument) tipdocument, st.idStare AS idStare, rtrim(st.culoare) as culoare,
						(case st.modificabil when '1' then 'Da' else 'Nu' end) as denmodificabil, st.modificabil modificabil, 
						isnull(st.inCurs,0) as inCurs, (case isnull(st.inCurs,0) when 0 then 'Nu' when 1 then 'Da' end) as deninCurs,
						isnull(st.initializare,0) as initializare, (case isnull(st.initializare,0) when 0 then 'Nu' when 1 then 'Da' end) as deninitializare
				FROM StariDocumente st
				WHERE st.tipDocument = tp.tipDocument
					AND (
						@f_stare IS NULL
						OR st.stare = @f_stare
						)
					AND (
						@f_denumire IS NULL
						OR st.denumire LIKE @f_denumire
						)
				FOR XML raw, type
				)
		FROM #tipuriDocumente tp
		WHERE (
				@f_tipdocument IS NULL
				OR (
				CASE tp.tipdocument WHEN 'AS' THEN 'Aviz servicii' WHEN 'AP' THEN 'Aviz produs' WHEN 'RM' THEN 
							'Receptii' WHEN 'RS' THEN 'Receptii servicii' WHEN 'PP' THEN 'Predare' WHEN 'CM' 
						THEN 'Consum' WHEN 'TE' THEN 'Transfer' when 'AC' then 'Aviz chitanta' when 'AI' then 'Alta intrare' 
						WHEN 'AE' then 'Alta iesire'
						END
				) LIKE @f_tipdocument
				or tp.tipdocument like @f_tipdocument
				)
		FOR XML raw, root('Ierarhie')
		)

IF @docXML IS NOT NULL
	SET @docXML.modify('insert attribute _expandat {"da"} into (/Ierarhie)[1]')

SELECT @docXML
FOR XML path('Date')
