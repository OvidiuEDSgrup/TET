/****** Object:  StoredProcedure [dbo].[wRUScriuCompetente]    Script Date: 01/05/2011 23:51:25 ******/
--***
Create PROCEDURE [dbo].[wRUScriuPosturi] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
declare	@mesajeroare varchar(500),@utilizator char(10), @userASiS varchar(20),@tip char(2),
        @id_post int,@descriere varchar(max),@scop varchar(max),@studii varchar(max),@experienta_necesara varchar(max),@update bit,@detalii xml
	
	set @Utilizator=dbo.iauUtilizatorCurent()
	set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')
	
   
 begin try       
    select 
         @update = isnull(@parXML.value('(/row/@update)[1]','bit'),0),
         @id_post = isnull(@parXML.value('(/row/@ID_post)[1]','int'),0),
         @descriere =isnull(@parXML.value('(/row/@descriere)[1]','varchar(MAX)'),''),
         @scop= isnull(@parXML.value('(/row/@scop)[1]','varchar(MAX)'),''),
         @studii= isnull(@parXML.value('(/row/@studii)[1]','varchar(MAX)'),''),
         @experienta_necesara= isnull(@parXML.value('(/row/@experienta_necesara)[1]','varchar(MAX)'),'')
         
		
	if exists (select 1 from sys.objects where name='wRUScriuPosturiSP' and type='P')  
	exec wRUScriuPosturiSP @sesiune, @parXML
else  
begin

	---------
	set @Utilizator=dbo.iauUtilizatorCurent()  
	set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '') 	
	---------	 
	
if @update=1
begin
  update  RU_posturi set Scop=@scop,Studii=@studii,Experienta_necesara=@experienta_necesara,descriere=@descriere
  where ID_post=@id_post
  end
else 
   insert into RU_posturi(Scop,Studii,Experienta_necesara,Descriere)
             select @scop,@studii,@experienta_necesara,@descriere				
end
end try
begin catch
set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
