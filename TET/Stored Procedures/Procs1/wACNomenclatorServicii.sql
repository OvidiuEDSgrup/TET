--***
CREATE procedure wACNomenclatorServicii @sesiune varchar(40), @parXML xml
as
declare @returnValue int, @msgEroare varchar(500)
if exists(select * from sysobjects where name='wACNomenclatorServiciiSP1' and type='P')
begin
	exec @returnValue = wACNomenclatorServiciiSP1 @sesiune=@sesiune,@parXML=@parXML output
	if @parXML is null
		return @returnValue 
end

begin try
	if @parXML.value('(/row/@tipNomencl)[1]','varchar(50)') is null
		set @parXML.modify('insert attribute tipNomencl {"S"} into (/row)[1]')
	else
		set @parXML.modify('replace value of (/row/@tipNomencl)[1] with "S"')
	
	exec wACNomenclator @sesiune=@sesiune, @parXML=@parXML
end try
begin catch
	set @msgEroare=ERROR_MESSAGE()+'(wACNomenclatorServicii)'
	raiserror(@msgEroare,11,1)
end catch	
