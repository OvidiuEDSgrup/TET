--***
/****** Object:  StoredProcedure [dbo].[wUAStergUAcatpret]    Script Date: 01/05/2011 23:51:25 ******/
Create PROCEDURE [dbo].[wUAStergUAcatpret] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
DECLARE @categorie int        
        
     select
         @categorie = @parXML.value('(/row/@categorie)[1]','int')    
		

declare @mesajeroare varchar(500)
set @mesajeroare=''
select @mesajeroare=
case when exists (select 1 from uapreturi  where categorie=@categorie) then 'Nu se poate sterge o categorie de preturi atasata in preturi!' 
      else ''  end

if @mesajeroare=''
	
	delete from UAcatpret where categorie=@categorie 
else 
	raiserror(@mesajeroare, 11, 1)
