/****** Object:  StoredProcedure [dbo].[wUAStergCasieri]    Script Date: 01/05/2011 23:51:25 ******/
--***
Create PROCEDURE  [dbo].[wUAStergCasieri] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
DECLARE @codcasier varchar(10)       
        
     select
         @codcasier = @parXML.value('(/row/@codcasier)[1]','varchar(10)')         

declare @mesajeroare varchar(500)
set @mesajeroare=''
select @mesajeroare=
      case when exists (select 1 from incasarifactabon a where a.casier=@codcasier) then 'Nu se poate sterge un casier, pe care s-au facut incasari!' 
      else ''  end

if @mesajeroare=''
	
delete from casieri where cod_casier=@codcasier


else 
	raiserror(@mesajeroare, 11, 1)
