--***
/****** Object:  StoredProcedure [dbo].[wUAStergNomenclabon]    Script Date: 01/05/2011 23:51:25 ******/
Create PROCEDURE  [dbo].[wUAStergNomenclabon] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
DECLARE @cod varchar(20)       
        
     select
         @cod = @parXML.value('(/row/@cod)[1]','varchar(20)')         

declare @mesajeroare varchar(500)
set @mesajeroare=''
select @mesajeroare=
      case when exists (select 1 from uapozcon a where a.cod=@cod) then 'Nu se poate sterge un cod folosit in pozitii contracte!' 
      when exists (select 1 from  pozitiifactabon a where a.cod=@cod) then 'Nu se poate sterge un cod folosit in pozitii facturi!' 
      else ''  end
     
if @mesajeroare=''
	begin
	delete from nomenclabon where cod=@cod
	delete from UAPreturi  where cod=@cod
	end
else 
	raiserror(@mesajeroare, 11, 1)
