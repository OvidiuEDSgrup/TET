/****** Object:  StoredProcedure [dbo].[wRUScriuIerarhii]    Script Date: 01/05/2011 23:51:25 ******/
--***
Create PROCEDURE [dbo].[wRUScriuIerarhii] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
declare	@mesajeroare varchar(500),@utilizator char(10), @userASiS varchar(20),@tip char(2),
        @id_ierarhie int,@descriere varchar(50),@nivel_ierarhic int,@update bit
	
	set @Utilizator=dbo.iauUtilizatorCurent()
	set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')
	
   
 begin try       
    select 
         @update = isnull(@parXML.value('(/row/@update)[1]','bit'),0),
         @id_ierarhie = isnull(@parXML.value('(/row/@ID_ierarhie)[1]','int'),0),
         @descriere =isnull(@parXML.value('(/row/@descriere)[1]','varchar(MAX)'),''),
         @nivel_ierarhic= isnull(@parXML.value('(/row/@nivel_ierarhic)[1]','varchar(50)'),'')
         
		
	if exists (select 1 from sys.objects where name='wRUScriuIerarhiiSP' and type='P')  
	exec wRUScriuIerarhiiSP @sesiune, @parXML
else  
begin

	---------
	set @Utilizator=dbo.iauUtilizatorCurent()  
	set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')  

	
	---------	 
	
if @update=1
begin
  update  RU_ierarhii set Nivel_ierarhic=@nivel_ierarhic, descriere=@descriere
  where ID_ierarhie=@id_ierarhie
  end
else 
   insert into RU_ierarhii(Nivel_ierarhic,descriere)
             select @nivel_ierarhic,@descriere				
end
end try
begin catch
set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
