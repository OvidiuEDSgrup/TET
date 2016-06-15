CREATE procedure [dbo].[wOPSalvarePret_p] @sesiune varchar(50), @parXML XML 
as
	declare @cod varchar(20), @pret float, @cantitate float
	
	set @cod=@parXML.value('(/row/@i_tehnologie)[1]','varchar(20)')
	set @pret=@parXML.value('(/row/@pret)[1]','float')
	set @cantitate=@parXML.value('(/row/@cantitate)[1]','float')
	
	select
		(select RTRIM(denumire) from nomencl where cod=@cod) as denumire,@cod as cod,
		CONVERT(decimal(15,6),@pret/@cantitate) as pret
	for xml raw, root('Date')
