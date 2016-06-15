--***
/****** Object:  StoredProcedure [dbo].[wUAStergTipurideincasare]    Script Date: 01/05/2011 23:51:25 ******/
Create PROCEDURE  [dbo].[wUAStergTipurideincasare] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
DECLARE @id varchar(3)       
        
     select
         @id = @parXML.value('(/row/@id)[1]','varchar(3)')         

declare @mesajeroare varchar(500)
set @mesajeroare=''
select @mesajeroare=
      case when exists (select distinct(tip_incasare) from incasarifactabon a where tip_incasare=@id)  then 'Nu se poate sterge un tip de incasare folosit in incasari!' 
      else ''  end

if @mesajeroare=''
	delete from tipuri_de_incasare where id=@id
else 
	raiserror(@mesajeroare, 11, 1)
