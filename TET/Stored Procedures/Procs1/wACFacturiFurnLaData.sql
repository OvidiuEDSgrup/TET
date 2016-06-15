--***
create procedure wACFacturiFurnLaData @sesiune varchar(50), @parXML XML  
as  
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wACFacturiFurnLaDataSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wACFacturiFurnLaDataSP @sesiune, @parXML output
	return @returnValue
end
declare @mesaj varchar(200), @furnbenef varchar(1)
begin try
	if @parXML.value('/*[1]/@facturi_la_data', 'char(1)') is null
		set @parXML.modify ('insert attribute facturi_la_data {"1"} into (/*)[1]')
	else
		set @parXML.modify ('replace value of /*[1]/@facturi_la_data with "1" ')

	exec wACFacturiFurn @sesiune=@sesiune,@parXML=@parXML
end try
begin catch
	set @mesaj = ERROR_MESSAGE()+' ('+object_name(@@procid)+')'
end catch
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
	
