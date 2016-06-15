--***
Create 
function wfValidareResal (@document xml) returns xml
as 
begin
	declare @eroare xml, @data datetime, @marca varchar(6)
	set @eroare='<error coderoare="0" msgeroare=""/>'
	set @data=isnull(@document.value('(/row/row/@data)[1]','datetime'), isnull(@document.value('(/row/@data)[1]', 'datetime'), ''))
	Select @marca=xA.row.value('@marca','varchar(6)') from @document.nodes('/row') as xA(row)
	if @document.exist('/row/row')=1 and @marca not in (select marca from personal)
	begin
		set @eroare.modify('replace value of (/error/@coderoare)[1]	with "1"')
		set @eroare.modify('replace value of (/error/@msgeroare)[1]	with "Marca inexistenta!"')
		set @eroare.modify ('insert attribute camp {"@marca"} into (/error)[1]')
		return @eroare
	end
	if @document.exist('/row/row')=1 and @marca in (select marca from personal where loc_ramas_vacant=1 and Data_plec<dbo.bom(@data))
	begin
		set @eroare.modify('replace value of (/error/@coderoare)[1]	with "1"')
		set @eroare.modify('replace value of (/error/@msgeroare)[1]	with "Salariatul selectat este plecat din unitate!"')
		set @eroare.modify ('insert attribute camp {"@marca"} into (/error)[1]')
		return @eroare
	end
	if @document.exist('/row/row')=1 and isnull(@document.value('(/row/row/@codbenef)[1]', 'varchar(2)'), '') = ''
	begin
		set @eroare.modify('replace value of (/error/@coderoare)[1]	with "1"')
		set @eroare.modify('replace value of (/error/@msgeroare)[1]	with "Beneficiar retinere necompletat!"')
		set @eroare.modify ('insert attribute camp {"@codcodbenef"} into (/error)[1]')
	end
	return @eroare
end
