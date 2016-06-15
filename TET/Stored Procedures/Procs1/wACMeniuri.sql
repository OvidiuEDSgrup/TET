
CREATE PROCEDURE wACMeniuri (@sesiune VARCHAR(50), @parXML XML)
AS
BEGIN
	DECLARE @searchText VARCHAR(100)

	SELECT @searchText = '%' + replace(isnull(@parXML.value('(row/@searchText)[1]', 'varchar(100)'), ' '), ' ', '%') + '%'

	SELECT w.Meniu AS cod, w.Nume AS denumire, 'Grup: ' + w.MeniuParinte AS info
	FROM webconfigmeniu w
		left join webconfigmeniu p on w.meniuparinte=p.meniu and p.nrordine<>0
	WHERE w.MeniuParinte IS NOT NULL
		AND w.Nume LIKE @searchText
	order by patindex('%'+@searchText+'%',w.nume),
		isnull(p.NrOrdine,w.NrOrdine), (case when p.nrordine is null then 0 else w.NrOrdine end),
		1
	FOR XML raw, root('Date')
END
