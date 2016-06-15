--***
CREATE function wfValidarePozadoc (@document xml) returns xml
as begin
	declare @eroare xml
	set @eroare='<error coderoare="0" msgeroare=""/>'
	
	--if @document.exist('/row/row')=1 and isnull(@document.value('(/row/row/@subtip)[1]', 'char(2)'), '') = ''
	--begin
	--	set @eroare.modify('replace value of (/error/@coderoare)[1]	with "1"')
	--	set @eroare.modify('replace value of (/error/@msgeroare)[1]	with "wfValidarePozadoc: Tip pozitie incorect!"')
	--	set @eroare.modify ('insert attribute camp {"@subtip"} into (/error)[1]')
	--	return @eroare
	--end
	
	--if @document.exist('/row')=1 and isnull(@document.value('(/row/@tip)[1]', 'char(2)'), '') in ('CO') 
	--	and isnull(@document.value('(/row/@tert)[1]', 'char(13)'), '') = ''
	--begin
	--	set @eroare.modify('replace value of (/error/@coderoare)[1]	with "1"')
	--	set @eroare.modify('replace value of (/error/@msgeroare)[1]	with "wfValidarePozadoc: Tert necompletat!"')
	--	set @eroare.modify ('insert attribute camp {"@tert"} into (/error)[1]')		
	--	return @eroare
	--end

	return @eroare
end
