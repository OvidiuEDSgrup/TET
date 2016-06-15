--***
/****** Object:  StoredProcedure [dbo].[wUAStergLocatari]    Script Date: 01/05/2011 23:51:25 ******/
Create PROCEDURE  [dbo].[wUAStergLocatari] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
begin
DECLARE @abonat varchar(13),@locatar varchar(20)       
        
     select
        @abonat = isnull(@parXML.value('(/row/@codabonat)[1]','varchar(13)'),'') ,        
	    @locatar = isnull(@parXML.value('(/row/row/@locatar)[1]','varchar(20)'),'') 

declare @mesajeroare varchar(500)
set @mesajeroare=''
	
delete from locatari where Abonat=@abonat and locatar=@locatar
end
