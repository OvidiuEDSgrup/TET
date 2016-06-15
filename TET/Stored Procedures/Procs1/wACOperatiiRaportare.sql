
CREATE PROCEDURE wACOperatiiRaportare @sesiune VARCHAR(50), @parXML XML
	AS
	
	DECLARE 
		@comanda VARCHAR(20), @searchText VARCHAR(100), @data DATETIME, @resursa VARCHAR(20)

	SELECT
		@searchText = ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(100)'), ''),
		@comanda = @parXML.value('(/row/@comanda)[1]', 'varchar(20)'),
		@resursa = @parXML.value('(/row/@idResursa)[1]', 'varchar(20)'),
		@data = ISNULL(@parXML.value('(/row/@dataOperarii)[1]', 'datetime'), ''),
		@searchText = '%' + REPLACE(@searchtext, ' ', '%') + '%'

	SELECT 
		RTRIM(c.Denumire) AS denumire, 'Comanda: ' + RTRIM(r.comanda) AS info, pr.id AS cod
	FROM planificare r
	INNER JOIN pozLansari pr ON pr.tip = 'O'
		AND pr.id = r.idOp
	INNER JOIN catop c ON c.Cod = pr.cod
		AND @data BETWEEN convert(DATE, r.dataStart)
			AND convert(DATE, r.dataStop)
	WHERE r.comanda = @comanda
		AND r.resursa = @resursa
	FOR XML raw, root('Date')
