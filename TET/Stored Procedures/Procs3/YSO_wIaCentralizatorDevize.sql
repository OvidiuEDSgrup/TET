
--***

CREATE procedure [dbo].[YSO_wIaCentralizatorDevize] @sesiune varchar(50), @parXML XML
as
begin
	if @parXML.value('(/row/@filtrutipdeviz)[1]', 'varchar(100)') is null                  
		set @parXML.modify ('insert attribute filtrutipdeviz {"%"} into (/row)[1]')
    
	print convert(varchar(1000),@parxml)

	exec YSO_wIaDevizeLucru @sesiune,@parXML
end
