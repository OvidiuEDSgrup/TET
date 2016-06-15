--***
create function  wfValidareNcon (@document xml) returns xml
as begin
	declare @eroare xml
	set @eroare='<error coderoare="0" msgeroare=""/>'
	
	--if @document.exist('/row/row')=1 and isnull(@document.value('(/row/row/@cod)[1]', 'char(20)'), '') = ''
	--begin
	--	set @eroare.modify('replace value of (/error/@coderoare)[1]	with "1"')
	--	set @eroare.modify('replace value of (/error/@msgeroare)[1]	with "Cod necompletat"')
	--	set @eroare.modify ('insert attribute camp {"@cod"} into (/error)[1]')
		
	--	--set @eroare.modify('replace value of (/error/@msgeroare)[1]	with "Eroare gestiune"')
	--	--set @eroare.modify ('insert attribute camp {"@gestiune"} into (/error)[1]')
	--	return @eroare
	--end
	
	--if @document.exist('/row')=1 and isnull(@document.value('(/row/@tip)[1]', 'char(2)'), '') in ('RM', 'RS', 'AP', 'AS') 
	--	and isnull(@document.value('(/row/@tert)[1]', 'char(13)'), '') = ''
	--begin
	--	set @eroare.modify('replace value of (/error/@coderoare)[1]	with "1"')
	--	set @eroare.modify('replace value of (/error/@msgeroare)[1]	with "Tert necompletat"')
	--	set @eroare.modify ('insert attribute camp {"@tert"} into (/error)[1]')
		
	--	return @eroare
	--end

	--if @document.exist('/row')=1 and isnull(@document.value('(/row/@tip)[1]', 'char(2)'), '') in ('RM', 'RS')--, 'AP', 'AS')
	--	and isnull(@document.value('(/row/@factura)[1]', 'char(20)'), '') = ''
	--begin
	--	set @eroare.modify('replace value of (/error/@coderoare)[1]	with "1"')
	--	set @eroare.modify('replace value of (/error/@msgeroare)[1]	with "Factura necompletata"')
	--	set @eroare.modify ('insert attribute camp {"@factura"} into (/error)[1]')
		
	--	return @eroare
	--end

	return @eroare
end
