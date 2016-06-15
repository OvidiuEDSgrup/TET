--***
/****** Object:  StoredProcedure [dbo].[wUAStergValproprietati]    Script Date: 01/05/2011 23:51:25 ******/
Create PROCEDURE  [dbo].[wUAStergValproprietati] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
DECLARE @codproprietate varchar(20),@valoare varchar(200)       
      
     
    select
         @codproprietate = @parXML.value('(/row/@codproprietate)[1]','varchar(20)'),         
		 @valoare = @parXML.value('(/row/row/@valoare)[1]','varchar(200)')
declare @mesajeroare varchar(500)
set @mesajeroare=''
select @mesajeroare=
      case when exists (select Top 1 * from proprietati where valoare=@valoare ) then 'Nu se poate sterge o valoare poprietate atasata unui cod!' 
      else ''  end

if @mesajeroare=''
	delete from valproprietati where Cod_proprietate=@codproprietate and Valoare=@valoare
else 
	raiserror(@mesajeroare, 11, 1)
