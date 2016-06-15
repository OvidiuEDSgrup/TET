--***
/****** Object:  StoredProcedure [dbo].[wUAStergPozDateLunare]    Script Date: 01/05/2011 23:08:45 ******/
create procedure  [dbo].[wUAStergPozDateLunare] @sesiune varchar(50), @parXML xml
as
begin
begin try
	DECLARE @id_contract int,@id int    
     select
         @id_contract = isnull(@parXML.value('(/row/@id_contract)[1]','int'),''),
         @id = isnull(@parXML.value('(/row/row/@id)[1]','int'),'')
         
         
         
	declare @mesajeroare varchar(100)
	
	if (select Facturat from UACantitati where Id=@id)=1
		begin
		set @mesajeroare='Cantitatea a fost deja facturata si nu poate fi stearsa!! '
		raiserror(@mesajeroare,11,1)
		end
	
	delete from UACantitati where id=@id								
	
	declare @docXML xml
	set @docXML='<row id_contract="'+rtrim(@id_contract)+'"/>'
	exec wUAIaPozDateLunare @sesiune=@sesiune, @parXML=@docXML


end try
begin catch
	set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)	
end catch
end
