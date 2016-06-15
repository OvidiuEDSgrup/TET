--***
create procedure wACFacturiFurnNesosite @sesiune varchar(50), @parXML XML  
as  
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wACFacturiFurnNesositeSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wACFacturiFurnNesositeSP @sesiune, @parXML output
	return @returnValue
end
declare @mesaj varchar(200), @nesosite int
begin try
	set @nesosite=1
	set @parXML.modify ('insert attribute nesosite {sql:variable("@nesosite")} into (/row)[1]')
	
	exec wACFacturiFurn @sesiune=@sesiune,@parXML=@parXML
end try
begin catch
	set @mesaj = '(wACFacturiFurnNesosite)'+ERROR_MESSAGE()
end catch
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
	
