
create procedure wIaUMProdus @sesiune varchar(50), @parXML XML
as
	declare 
		@cod varchar(20)

	select 
		@cod = @parXML.value('(/row/@cod)[1]','varchar(20)')

	select 
		u.um um, rtrim(um.Denumire) denum, convert(decimal(15,3), u.coeficient) coeficient
	from UMProdus u
	JOIN UM on u.UM=um.UM
	where u.cod=@cod
	for xml raw, root('Date')
