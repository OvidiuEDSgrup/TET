
--macheta de planificare resurse la operatii din lansare
CREATE PROCEDURE wACResursaOperatie @sesiune VARCHAR(50), @parXML XML
	AS
	DECLARE 
		@searchText VARCHAR(50), @codOp VARCHAR(20)

	select
		@searchText = '%' + replace(ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), ''), ' ', '%') + '%',
		@codOp = ISNULL(@parXML.value('(/row/linie/@codOperatie)[1]', 'varchar(20)'), '')

	SELECT 
		rs.id AS cod, RTRIM(rs.descriere) AS denumire, 'Tip: ' + RTRIM(rs.tip) AS info
	FROM Resurse rs
	INNER JOIN OpResurse ors ON rs.id = ors.idRes AND ors.cod = @codOp
	FOR XML raw, root('Date')
