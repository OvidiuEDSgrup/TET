--***
create procedure wACFacturiFurn @sesiune varchar(50), @parXML XML  
as  
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wACFacturiFurnSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wACFacturiFurnSP @sesiune, @parXML output
	return @returnValue
end
declare @mesaj varchar(200), @furnbenef varchar(1)
begin try
	set @furnbenef='F'
	set @parXML.modify ('insert attribute furnbenef{sql:variable("@furnbenef")} into (/row)[1]')
	
	exec wACFacturi @sesiune=@sesiune,@parXML=@parXML
end try
begin catch
	set @mesaj = '(wACFacturiFurn)'+ERROR_MESSAGE()
end catch
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
	
