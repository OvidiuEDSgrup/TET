
CREATE PROCEDURE wIaJurnalDocument @sesiune VARCHAR(50), @parXML XML
AS
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE 
		@f_stare INT, @f_denstare VARCHAR(10), @subunitate varchar(1), @tip varchar(20), @numar varchar(20), @data datetime

	SELECT
		@f_denstare = '%' + @parXML.value('(/*/@f_denstare)[1]', 'varchar(20)') + '%',
		@f_stare = @parXML.value('(/*/@f_stare)[1]', 'int'),
		@subunitate = ISNULL(@parXML.value('(/*/@subunitate)[1]', 'varchar(1)'),'1'),
		@tip = @parXML.value('(/*/@tipdocument)[1]', 'varchar(2)'),
		@numar = @parXML.value('(/*/@numar)[1]', 'varchar(20)'),
		@data = @parXML.value('(/*/@data)[1]', 'datetime')

	SELECT 
		convert(VARCHAR(10), jd.data_operatii, 103) + ' ' + convert(VARCHAR(8), jd.data_operatii, 108) AS data, jd.stare AS stare, rtrim(sd.denumire) AS denstare, 
		rtrim(jd.explicatii) AS explicatii, RTRIM(jd.utilizator) AS utilizator,jd.idJurnal idJurnal
	FROM JurnalDocumente jd
	INNER JOIN StariDocumente sd on sd.tipDocument=@tip 
	where 
		jd.tip=@tip and jd.numar=@numar and CONVERT(datetime,jd.data)=@data and jd.stare=sd.stare and
		(@f_stare IS NULL OR jd.stare = @f_stare) AND 
		(@f_denstare IS NULL OR sd.denumire LIKE @f_denstare)
	ORDER BY jd.data_operatii
	FOR XML raw, root('Date')
