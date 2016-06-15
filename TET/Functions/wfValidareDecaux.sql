--***
create function  [wfValidareDecaux] (@parXML xml) returns xml
as begin
	declare @eroare xml
	set @eroare='<error coderoare="0" msgeroare=""/>'
	
	if @parXML.exist('/row')=1 and isnull(@parXML.value('(/row/row/@data)[1]', 'datetime'), isnull(@parXML.value('(/row/@data)[1]', 'datetime'), '')) = ''
	begin
		set @eroare.modify('replace value of (/error/@coderoare)[1]	with "1"')
		set @eroare.modify('replace value of (/error/@msgeroare)[1]	with "Data necompletata"')
		set @eroare.modify ('insert attribute camp {"@data"} into (/error)[1]')
		return @eroare
	end
	
	if @parXML.exist('/row')=1 and isnull(@parXML.value('(/row/@l_m_furnizor)[1]', 'varchar(9)'), '') = ''
	begin
		set @eroare.modify('replace value of (/error/@coderoare)[1]	with "1"')
		set @eroare.modify('replace value of (/error/@msgeroare)[1]	with "LM furnizor necompletat"')
		set @eroare.modify ('insert attribute camp {"@l_m_furnizor"} into (/error)[1]')
		return @eroare
	end
	
	if @parXML.exist('/row')=1 and isnull(@parXML.value('(/row/@comanda_furnizor)[1]', 'varchar(13)'), '') = ''
	begin
		set @eroare.modify('replace value of (/error/@coderoare)[1]	with "1"')
		set @eroare.modify('replace value of (/error/@msgeroare)[1]	with "Comanda furnizor necompletata"')
		set @eroare.modify ('insert attribute camp {"@comanda_furnizor"} into (/error)[1]')
		return @eroare
	end	

	if @parXML.exist('/row')=1 and isnull(@parXML.value('(/row/@comanda_furnizor)[1]', 'varchar(13)'), '')<>'' and (select tip_comanda from comenzi where comanda=isnull(@parXML.value('(/row/@comanda_furnizor)[1]', 'varchar(13)'), '')) not in ('T', 'X') 
	begin
		set @eroare.modify('replace value of (/error/@coderoare)[1]	with "1"')
		set @eroare.modify('replace value of (/error/@msgeroare)[1]	with "Comanda furnizor trebuie sa fie de tip T sau X!"')
		set @eroare.modify ('insert attribute camp {"@comanda_furnizor"} into (/error)[1]')
		return @eroare
	end		
	
	return @eroare
end
