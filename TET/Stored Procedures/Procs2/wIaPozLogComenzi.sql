create procedure wIaPozLogComenzi @sesiune varchar(50), @parXML xml

as

	declare @id int, @comanda xml
	set @id=@parXML.value('(/row/@id)[1]','int')
	
	select @comanda=detalii from dateSincronizare where id=@id
	
	select 
		rtrim(r.value('@cod','varchar(20)')) as cod,
		CONVERT(decimal(10,3),r.value('@cantitate','float')) as cantitate, RTRIM(n.denumire) as denumire, RTRIM(g.Denumire) as grupa,
		CONVERT(varchar(10),r.value('@termen','datetime'),101) as termen
	from
	@comanda.nodes('/row/row') as cod(r)
	join nomencl n on n.Cod=r.value('@cod','varchar(20)')
	join grupe g on g.Grupa=n.Grupa
	for xml raw,root('Date')
