
create procedure wAlteIesiri_p (@sesiune varchar(50), @parXML xml)
as

declare @numar varchar(20), @data datetime
set @numar = @parXML.value('(/row/@idInventar)[1]','varchar(20)')
set @data = @parXML.value('(/row/@data)[1]','datetime')

select '1' as subunitate, 'AE' tip, 'INV' + convert(varchar(20),@numar) numar, @data data
for xml raw
