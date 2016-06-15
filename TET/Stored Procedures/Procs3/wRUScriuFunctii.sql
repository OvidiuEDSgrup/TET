/****** Object:  StoredProcedure [dbo].[wRUScriuFunctii]    Script Date: 01/05/2011 23:51:25 ******/
--***
Create PROCEDURE [dbo].[wRUScriuFunctii]
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
declare	@mesajeroare varchar(500),@utilizator char(10), @userASiS varchar(20)
	
	set @Utilizator=dbo.iauUtilizatorCurent()
	set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')
	
	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	
	DECLARE     @id_functie int,@denumire varchar(30),@descriere varchar(max), 
				@studii varchar(max),@update bit
				
 begin try       
    select 
         @update = isnull(@parXML.value('(/row/@update)[1]','bit'),0),
         @id_functie = isnull(@parXML.value('(/row/@id_functie)[1]','int'),0),
         @denumire =isnull(@parXML.value('(/row/@denumire)[1]','varchar(30)'),''),
         @descriere =isnull(@parXML.value('(/row/@descriere)[1]','varchar(max)'),''),
         @studii= isnull(@parXML.value('(/row/@studii)[1]','varchar(max)'),'')
         
		
	if exists (select 1 from sys.objects where name='wRUScriuFunctiiSP' and type='P')  
	exec wRUScriuFunctiiSP @sesiune, @parXML
else  
begin

	---------
	set @Utilizator=dbo.iauUtilizatorCurent()  
	set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')  

	
	---------
	 
	
if @update=1
begin
  update  ru_functii set denumire=@denumire,descriere=@descriere,studii=@studii
  where id_functie=@id_functie 
  end
else 
   insert into ru_functii(denumire,descriere,studii)
             select @denumire,@descriere,@studii 				
end
end try
begin catch
set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
