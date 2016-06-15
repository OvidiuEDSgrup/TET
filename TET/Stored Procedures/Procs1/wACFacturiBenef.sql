--***
create procedure wACFacturiBenef @sesiune varchar(50), @parXML XML  
as  
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wACFacturiBenefSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wACFacturiBenefSP @sesiune, @parXML output
	return @returnValue
end
declare @mesaj varchar(200), @furnbenef varchar(1)
begin try
	declare @tip varchar(2),@tert varchar(13)
	select @tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), '')
	
	set @furnbenef='B'
	set @parXML.modify ('insert attribute furnbenef{sql:variable("@furnbenef")} into (/row)[1]')
	
	if @tip='C3'
	begin	
		select @tert=ISNULL(@parXML.value('(/row/@tertbenef)[1]', 'varchar(13)'), '')
		
		if @parXML.value('(/row/@tert)[1]', 'varchar(13)') is not null                          
		begin
			set @parXML.modify('replace value of (/row/@tert)[1] with sql:variable("@tert")') 
		end                            
		else
		begin    
			set @parXML.modify ('insert attribute tert {sql:variable("@tert")} into (/row)[1]') 
		end
	end
	
	exec wACFacturi @sesiune=@sesiune,@parXML=@parXML
end try
begin catch
	set @mesaj = '(wACFacturiBenef)'+ERROR_MESSAGE()
end catch
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
	
