
CREATE PROCEDURE wACPromotii @sesiune VARCHAR(50), @parXML XML
AS
set transaction isolation level read uncommitted

	DECLARE 
		@searchText VARCHAR(200)

	select
		@searchText = '%'+replace(ISNULL(@parXML.value('(/*/@searchText)[1]', 'varchar(80)'), ''), ' ', '%')+'%'
	
	SELECT top 100
		p.idPromotie cod, p.denumire denumire, 'Art.: '+rtrim(n.denumire) info		
	FROM Promotii p
	JOIN Nomencl n on n.cod=p.cod and convert(datetime, getdate()) between p.dela and p.panala
	where p.denumire like @searchText or n.Denumire like @searchText
	for xml raw, root('Date')
