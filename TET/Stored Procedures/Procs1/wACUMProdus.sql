CREATE PROCEDURE wACUMProdus @sesiune varchar(50), @parXML xml
as

	declare
		@cod varchar(20), @searchText varchar(250)

	select	
		@cod = @parXML.value('(//@cod)[1]','varchar(20)'),
		@searchText = replace(ISNULL(@parXML.value('(/*/@searchText)[1]','varchar(200)'),'%'),' ','%')
	select
		u.UM cod, RTRIM(um.Denumire) denumire
	from UMProdus u
	JOIN UM on u.um=um.um
	where u.cod=@cod and um.Denumire like @searchText
	FOR XML RAW, ROOT('Date')
