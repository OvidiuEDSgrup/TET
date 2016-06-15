--***
Create 
procedure wValidareBenret (@sesiune varchar(50), @document xml)
as 
begin
	declare @marca varchar(6)
	if @document.exist('/row/row')=1 and isnull(@document.value('(/row/row/@denumire)[1]', 'varchar(30)'), '') = ''
	begin
		raiserror('Denumire beneficiar retinere necompletata!',11,1)
		return -1
	end
	if @document.exist('/row/row')=1 and isnull(@document.value('(/row/row/@tipret)[1]', 'varchar(1)'), '') = ''
	begin
		raiserror('Tip retinere necompletat!',11,1)
		return -1
	end
end
