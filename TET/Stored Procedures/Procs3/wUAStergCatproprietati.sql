/****** Object:  StoredProcedure [dbo].[wUAStergCatproprietati]    Script Date: 01/05/2011 23:51:25 ******/
--***
Create PROCEDURE  [dbo].[wUAStergCatproprietati] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
DECLARE @codproprietate varchar(20)       
      
     
    select
         @codproprietate = @parXML.value('(/row/@codproprietate)[1]','varchar(20)')           

declare @mesajeroare varchar(500)
set @mesajeroare=''
select @mesajeroare=
      case when exists (select Top 1 * from proprietati where Cod_proprietate=@codproprietate ) then 'Nu se poate sterge o poprietate atasata unui cod!' 
      else ''  end

if @mesajeroare=''
	delete from catproprietati where Cod_proprietate=@codproprietate
else 
	raiserror(@mesajeroare, 11, 1)
