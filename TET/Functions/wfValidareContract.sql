--***
create function [dbo].[wfValidareContract] (@parXML xml) returns xml
as 
begin
declare @eroare xml
set @eroare='<error coderoare="0" msgeroare=""/>'

	if @parXML.exist('/row/row')=1 and isnull(@parXML.value('(/row/row/@subtip)[1]', 'char(2)'), '') <> 'BA'
	begin
	
	/*pot avea cod special - musai trigger*/
	if @parXML.exist('/row/row')=1 and isnull(@parXML.value('(/row/row/@cod)[1]', 'char(20)'), '') = '' 
		and isnull(@parXML.value('(/linie/row/@cod)[1]', 'char(20)'), '') = '' 
		and isnull(@parXML.value('(/row/row/@explicatii)[1]', 'char(20)'), '') = '' 
		and isnull(@parXML.value('(/row/row/@subtip)[1]', 'char(2)'), '') <> 'TE'
	begin
		set @eroare.modify('replace value of (/error/@coderoare)[1]	with "1"')
		set @eroare.modify('replace value of (/error/@msgeroare)[1]	with "wfValidareContract(pozcon): Nu ati completat codul de produs."')
		set @eroare.modify ('insert attribute camp {"@cod"} into (/error)[1]')
		
		return @eroare
	end
	
	if @parXML.exist('/row/row')=1 and ( @parXML.value('(/row/row/@tip)[1]', 'char(2)')<>'BF' and isnull(@parXML.value('(/row/row/@cantitate)[1]', 'float'), 0) = 0) 
	and ( @parXML.value('(/row/row/@tip)[1]', 'char(2)')='BF' and isnull(@parXML.value('(/row/row/@Tcantitate)[1]', 'float'), 0) = 0)
	begin
		set @eroare.modify('replace value of (/error/@coderoare)[1]	with "1"')
		set @eroare.modify('replace value of (/error/@msgeroare)[1]	with "wfValidareContract(pozcon): Cantitate invalida."')
		set @eroare.modify ('insert attribute camp {"@cantitate"} into (/error)[1]')
		
		return @eroare
	end
	
	if @parXML.exist('/row/row')=1 and @parXML.value('(/row/row/@tip)[1]', 'char(2)')='BK' 
	and isnull(@parXML.value('(/row/@categpret)[1]', 'float'), 0) <> 0
	and isnull(@parXML.value('(/row/row/@categpret)[1]', 'float'), 0) <> 0
	begin
		set @eroare.modify('replace value of (/error/@coderoare)[1]	with "1"')
		set @eroare.modify('replace value of (/error/@msgeroare)[1]	with "wfValidareContract(pozcon): Categoria de pret trebuie introdusa o singura data pe document."')
		set @eroare.modify ('insert attribute camp {"@categpret"} into (/error)[1]')
		
		return @eroare
	end
	
	if @parXML.exist('/row/row')=1 and isnull(@parXML.value('(/row/row/@pret)[1]', 'float'), 0) < 0
	begin
		set @eroare.modify('replace value of (/error/@coderoare)[1]	with "1"')
		set @eroare.modify('replace value of (/error/@msgeroare)[1]	with "wfValidareContract(pozcon):Pretul nu poate fi negativ."')
		set @eroare.modify ('insert attribute camp {"@pret"} into (/error)[1]')
		
		return @eroare
	end
	end
	
	return @eroare
end
