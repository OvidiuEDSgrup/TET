--***
create procedure wPopulareNormativ @sesiune varchar(50),@parXML XML      
as
begin
	declare @cod varchar(100), @interval int, @UM varchar(100), @tipMasina varchar(100)
	select	@cod=ISNULL(@parXML.value('(/row/row/@cod)[1]', 'varchar(100)'), ''),
			@interval=ISNULL(@parXML.value('(/row/row/@interval)[1]', 'int'), ''),
			@UM=ISNULL(@parXML.value('(/row/row/@UM)[1]', 'varchar(100)'), ''),
			@tipMasina=ISNULL(@parXML.value('(/row/@tipMasina)[1]', 'varchar(100)'), '')
	
	select @cod cod, @interval interval, @UM um, @tipMasina tipMasina
	for xml raw
end
