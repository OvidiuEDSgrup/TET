--***
create procedure wACFacturiBenefNeintocmite @sesiune varchar(50), @parXML XML  
as  
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wACFacturiBenefNeintocmiteSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wACFacturiBenefNeintocmiteSP @sesiune, @parXML output
	return @returnValue
end
declare @mesaj varchar(200), @nesosite int
begin try
	
	set @nesosite=1
	set @parXML.modify ('insert attribute nesosite {sql:variable("@nesosite")} into (/row)[1]')
	
	exec wACFacturiBenef @sesiune=@sesiune,@parXML=@parXML
end try
begin catch
	set @mesaj = '(wACFacturiBenefNeintocmite)'+ERROR_MESSAGE()
end catch
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
	
