
CREATE PROCEDURE wACResurse @sesiune VARCHAR(50), @parXML XML
AS
	DECLARE 
		@searchText VARCHAR(100)

	select
		@searchText = '%' + REPLACE(ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(100)'), '%'), ' ', '%') + '%'

	SELECT 
		id AS cod, RTRIM(descriere) AS denumire, 
		'Tip: ' + (CASE WHEN tip = 'L' THEN 'Loc munca' WHEN tip = 'A' THEN 'Angajat' WHEN tip = 'U' THEN 'Utilaj' WHEN tip = 'E' THEN 'Extern' END) AS info
	FROM resurse where cod like @searchText OR descriere like @searchText
	FOR XML raw, root('Date')
