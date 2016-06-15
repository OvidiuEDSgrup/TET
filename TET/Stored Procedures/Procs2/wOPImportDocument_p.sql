
create procedure wOPImportDocument_p @sesiune varchar(50),@parXML XML      
as

declare @tip varchar(2)

select @tip = @parXML.value('(/row/@tip)[1]','varchar(2)')

select
	@tip as tip, '' as numar, getdate() as data, '' as gestiune, '' as den_gestiune, '' as tert, '' as den_tert, '' as factura, getdate() as datafacturii
for xml raw
