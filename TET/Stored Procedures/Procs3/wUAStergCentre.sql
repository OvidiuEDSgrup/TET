--***
/****** Object:  StoredProcedure [dbo].[wUAStergCentre]    Script Date: 01/05/2011 23:51:25 ******/
Create PROCEDURE  [dbo].[wUAStergCentre] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
DECLARE @centru varchar(8)       
        
     select
         @centru = @parXML.value('(/row/@centru)[1]','varchar(20)')         

declare @mesajeroare varchar(500)
set @mesajeroare=''
select @mesajeroare=
      case when exists (select 1 from abonati a where a.centru=@centru) then 'Nu se poate sterge un centru atasat unui abonat in catalogul de abonati!' 
      else ''  end

if @mesajeroare=''
	delete from centre where centru=@centru
else 
	raiserror(@mesajeroare, 11, 1)
