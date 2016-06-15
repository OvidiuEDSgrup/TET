--***
CREATE procedure wIaFormularePv @sesiune varchar(40), @parXML xml
as
declare @returnValue int, @msgEroare varchar(500)
if exists(select * from sysobjects where name='wIaFormularePvSP1' and type='P')      
begin
	exec @returnValue = wIaFormularePvSP1 @sesiune=@sesiune,@parXML=@parXML output
	if @parXML is null
		return @returnValue 
end

begin try
	if (@parXML.value('(/row/@codmeniu)[1]','varchar(50)')) is null
		set @parXML.modify ('insert attribute codmeniu {"PV"} into (/row)[1]')
	else
		set @parXML.modify('replace value of (/row/@codmeniu)[1] with "PV"')
	
	exec wIaFormulare @sesiune=@sesiune, @parXML=@parXML
end try
begin catch
set @msgEroare=ERROR_MESSAGE()+'(wIaFormularePv)'
raiserror(@msgEroare,11,1)
end catch	
