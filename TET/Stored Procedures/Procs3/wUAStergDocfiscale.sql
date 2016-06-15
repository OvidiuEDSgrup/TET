--***
/****** Object:  StoredProcedure [dbo].[wUAStergDocfiscale]    Script Date: 01/05/2011 23:51:25 ******/
Create PROCEDURE  [dbo].[wUAStergDocfiscale] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
DECLARE @id int      
        
     select
        
        @id=isnull(@parXML.value('(/row/@id)[1]', 'int'), '')       

declare @mesajeroare varchar(500)
set @mesajeroare=''
select @mesajeroare=
      case when exists (select 1 from asocieredocfiscale where id=@id) then 'Nu se poate sterge o plaja asociata unui utilizator!' 
      
      else ''  end
     
if @mesajeroare=''
begin
 delete from docfiscale where id=@id 
end
else 
	raiserror(@mesajeroare, 11, 1)
