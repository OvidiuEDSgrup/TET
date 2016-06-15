create PROCEDURE [dbo].[wUAStergAbonati]  
 @sesiune [varchar](50),  
 @parXML [xml]  
WITH EXECUTE AS CALLER
AS  
set transaction isolation level READ UNCOMMITTED  
  
 Declare  @codabonat varchar(30),
	@update int,@mesajeroare varchar(500),@utilizator varchar(10), @userASiS varchar(20)
	
set @Utilizator=dbo.fIauUtilizatorCurent()  
set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')  

declare @iDoc int
EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML  

begin try        
    select
        @codabonat=rtrim(ltrim(isnull(@parXML.value('(/row/@codabonat)[1]', 'varchar(30)'), '')))
  
    if @codabonat in (select abonat from uacon)
		begin     
			set @mesajeroare='Codul de abonat '+@codabonat+' are contract; nu se poate sterge abonatul !'  
			raiserror(@mesajeroare,11,1)  
		end
	else delete from abonati where abonat=@codabonat
end try
begin catch
set @mesajeroare = ERROR_MESSAGE()
 raiserror(@mesajeroare, 11, 1)
end catch
