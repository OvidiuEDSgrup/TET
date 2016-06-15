create procedure wOPDealocareBon_p @sesiune varchar(40), @parXML xml
as

declare @bon varchar(30), @casamarcat varchar(30), @databon datetime, @factura varchar(30),
		@datafacturii datetime, @vanzator varchar(40), @datascadentei varchar(30), @client varchar(50)

 select	@bon=isnull(@parXML.value('(/row/@numar)[1]','varchar(30)'),''),
		@casamarcat=isnull(@parXML.value('(/row/@casam)[1]','varchar(30)'),''),
		@vanzator=isnull(@parXML.value('(/row/@vanzator)[1]','varchar(30)'),''),
		@databon=isnull(@parXML.value('(/row/@data)[1]','datetime'),''),
		@factura=isnull(@parXML.value('(/row/@factura)[1]','varchar(30)'),''),
		@datafacturii=isnull(@parXML.value('(/row/@data_facturii)[1]','datetime'),''),
		@client=isnull(@parXML.value('(/row/@dentert)[1]','varchar(50)'),'')
select @bon bon, convert(varchar(20),@databon,101) databon, @factura factura, convert(varchar(20),@datafacturii,101) datafacturii, @client client
for xml raw

