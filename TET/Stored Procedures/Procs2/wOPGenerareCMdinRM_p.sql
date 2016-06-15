create procedure wOPGenerareCMdinRM_p @sesiune varchar(50), @parXML xml
as
declare @data datetime
select @data=isnull(@parXML.value('(/row/@data)[1]','datetime'),convert(varchar(20),getdate(),101))

select convert(varchar(20),@data,101) dataCM
for xml raw
