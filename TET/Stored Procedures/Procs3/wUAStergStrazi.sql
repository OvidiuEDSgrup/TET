--***
/****** Object:  StoredProcedure [dbo].[wUAStergStrazi]    Script Date: 01/05/2011 23:51:25 ******/
Create PROCEDURE  [dbo].[wUAStergStrazi] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
begin
DECLARE @strada varchar(20)       
        
     select
         @strada = isnull(@parXML.value('(/row/@strada)[1]','varchar(20)'),'')   
 
declare @mesajeroare varchar(500)
set @mesajeroare=''
select @mesajeroare=
      case when exists (select 1 from abonati a where a.Strada=@strada) then 'Nu se poate sterge o strada atasata unui abonat in catalogul de abonati!' 
      else ''  end

if @mesajeroare=''
	delete from Strazi where Strada=@strada
else 
	raiserror(@mesajeroare, 11, 1)
end
