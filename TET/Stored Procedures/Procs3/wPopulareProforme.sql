--***
Create procedure wPopulareProforme @sesiune varchar(50), @parXML xml output                                      
as 
begin try
	declare @idContract int, @mesaj varchar(500)
	set @idContract=@parXML.value('(/row/@idContract)[1]',' int')
	                                     
	--sterg atributul pentru idContract
	SET @parXML.modify('delete /row/@idContract')

	--inserez atributul pentru idContractCorespondent
	if @parXML.value('(/row/@idContractCorespondent)[1]', 'int') is not null                          
		set @parXML.modify('replace value of (/row/@idContractCorespondent)[1] with sql:variable("@idContract")') 
	else
		set @parXML.modify ('insert attribute idContractCorespondent{sql:variable("@idContract")} into (/row)[1]') 
		
	select @parXML
	exec wIaContracte @sesiune=@sesiune, @parXML=@parXML
				
end try

begin catch
	set @mesaj='(wPopulareProforme):'+ERROR_MESSAGE()
	raiserror(@mesaj,16,1)
end catch
