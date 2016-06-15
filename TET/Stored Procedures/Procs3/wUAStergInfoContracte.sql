--***
/****** Object:  StoredProcedure [dbo].[wUAStergInfoContracte]    Script Date: 01/05/2011 23:51:25 ******/
Create PROCEDURE  [dbo].[wUAStergInfoContracte] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
begin
DECLARE @cod varchar(8)       
        
     select
         @cod = isnull(@parXML.value('(/row/@cod)[1]','varchar(3)'),'')         

declare @mesajeroare varchar(500)
set @mesajeroare=''
select @mesajeroare=
      case when exists (select 1 from uacon a where a.info_contract=@cod) then 'Nu se poate sterge aceasta informatie intrucat este atasata unui contract in catalogul de abonati!' 
      else ''  end

if @mesajeroare=''
	delete from InfoContracte where Cod=@cod
else 
	raiserror(@mesajeroare, 11, 1)
end
