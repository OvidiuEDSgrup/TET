--***
Create 
function wfValidareCorectii (@document xml) returns xml
as 
begin
	declare @eroare xml, @data datetime, @tipcor varchar(2), @marca varchar(6), @lm varchar(9)
	set @data=isnull(@document.value('(/row/row/@data)[1]', 'datetime'), isnull(@document.value('(/row/@data)[1]', 'datetime'), ''))
	set @tipcor=isnull(@document.value('(/row/@tipcor)[1]', 'varchar(2)'), isnull(@document.value('(/row/row/@tipcor)[1]', 'varchar(2)'), ''))
	set @marca=isnull(@document.value('(/row/@marca)[1]', 'varchar(6)'), isnull(@document.value('(/row/row/@marca)[1]', 'varchar(6)'),''))
	set @lm=isnull(@document.value('(/row/row/@lm)[1]', 'varchar(9)'), '')
	set @eroare='<error coderoare="0" msgeroare=""/>'
	if @document.exist('/row/row')=1 and @tipcor = ''
	begin
		set @eroare.modify('replace value of (/error/@coderoare)[1]	with "1"')
		set @eroare.modify('replace value of (/error/@msgeroare)[1]	with "Tip corectie venit necompletat!"')
		set @eroare.modify ('insert attribute camp {"@tipcor"} into (/error)[1]')
		return @eroare
	end
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
	if @document.exist('/row/row')=1 and @lm<>'' and @lm not in (select cod from lm)
	begin
		set @eroare.modify('replace value of (/error/@coderoare)[1]	with "1"')
		set @eroare.modify('replace value of (/error/@msgeroare)[1]	with "Loc de munca inexistent!"')
		set @eroare.modify ('insert attribute camp {"@lm"} into (/error)[1]')
		return @eroare
	end
	return @eroare
end
