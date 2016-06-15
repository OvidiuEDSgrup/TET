create procedure wACConturiAn @sesiune varchar(50), @parXML xml
as

declare @input xml, @searchText varchar(80)
select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), '')

set @searchText=REPLACE(@searchText, ' ', '%')
set @input=(select @searchText as 'searchText', 1 as 'faraAnalitic' for xml raw)
select @input
exec wACConturi '', @input


