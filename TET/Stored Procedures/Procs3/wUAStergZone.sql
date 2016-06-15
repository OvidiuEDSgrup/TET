--***
/****** Object:  StoredProcedure [dbo].[wUAStergZone]    Script Date: 01/05/2011 23:51:25 ******/
Create PROCEDURE  [dbo].[wUAStergZone] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
DECLARE @zona varchar(8)       
        
     select
         @zona = @parXML.value('(/row/@zona)[1]','varchar(8)')         

declare @mesajeroare varchar(500)
set @mesajeroare=''
select @mesajeroare=
      case when exists (select 1 from abonati a where a.zona=@zona) then 'Nu se poate sterge o zona atasata unui abonat in catalogul de abonati!' 
      else ''  end

if @mesajeroare=''
	delete from zone where zona=@zona
else 
	raiserror(@mesajeroare, 11, 1)
