create procedure wOPDealocareBon @sesiune varchar(40), @parXML xml
as
begin
declare @bon varchar(30), @casamarcat varchar(30), @databon datetime, @factura varchar(30),
		@datafacturii datetime, @vanzator varchar(40)
select	@bon=isnull(@parXML.value('(/parametri/@numar)[1]','varchar(30)'),''),
		@casamarcat=isnull(@parXML.value('(/parametri/@casam)[1]','varchar(30)'),''),
		@vanzator=isnull(@parXML.value('(/parametri/@vanzator)[1]','varchar(30)'),''),
		@databon=isnull(@parXML.value('(/parametri/@data)[1]','datetime'),'')
update antetbonuri set factura='', data_facturii='',data_scadentei='',tert='' 
						where numar_bon=@bon and Data_bon=@databon and 
						vinzator=@vanzator and Casa_de_marcat=@casamarcat

update bp 	set client='' where numar_bon=@bon and Data=@databon and 
						vinzator=@vanzator and Casa_de_marcat=@casamarcat
select 'Operatie Dealocare bon efectuata cu succes!' as textMesaj for xml raw, root ('Mesaje')
end
