
CREATE PROCEDURE wIaJurnalComanda @sesiune VARCHAR(50), @parXML XML
AS
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE 
		@f_stare varchar(20), @f_denstare VARCHAR(100), @idComanda INT

	SELECT
		@f_denstare = '%' + @parXML.value('(/*/@f_denstare)[1]', 'varchar(20)') + '%',
		@f_stare = @parXML.value('(/*/@f_stare)[1]', 'varchar(20)'),
		@idComanda= @parXML.value('(/*/@idLansare)[1]', 'int')

	IF OBJECT_ID('tempdb.dbo.#stariComenzi') IS NOT NULL
		drop table #stariComenzi

	create table #stariComenzi (stare varchar(10), denumire varchar(500))
	insert into #stariComenzi  (stare, denumire)
	select 'S', 'Simulare' UNION
	select 'P', 'Pregatire' UNION
	select 'L', 'Lansata' UNION
	select 'A', 'Alocata' UNION
	select 'I', 'Inchisa'  UNION
	select 'N', 'Anulata'  UNION
	select 'B', 'Blocata'  

	SELECT 
		convert(VARCHAR(10), jc.data, 103) + ' ' + convert(VARCHAR(8), jc.data, 108) AS data, jc.stare AS stare, rtrim(sc.denumire) AS denstare, 
		rtrim(jc.explicatii) AS explicatii, RTRIM(jc.utilizator) AS utilizator,jc.idJurnal idJurnal,
		jc.detalii detalii, jc.detalii dateXML
	FROM JurnalComenzi jc
	INNER JOIN #stariComenzi sc ON sc.stare =jc.stare
	WHERE 
		(@f_stare IS NULL OR jc.stare = @f_stare) AND 
		(@f_denstare IS NULL OR sc.denumire LIKE @f_denstare)
		and idLansare=@idComanda
	ORDER BY jc.data
	FOR XML raw, root('Date')
