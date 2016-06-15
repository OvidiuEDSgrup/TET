--***

create procedure wIaDevizeDeFacturat @sesiune varchar(50), @parXML XML
as
begin
	if @parXML.value('(/row/@filtrutipdeviz)[1]', 'varchar(100)') is null                  
		set @parXML.modify ('insert attribute filtrutipdeviz {"de facturat"} into (/row)[1]')

	exec wIaDevizeLucru @sesiune,@parXML
end
