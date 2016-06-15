/****** Object:  StoredProcedure [dbo].[wRUScriuIerarhiiPosturi]    Script Date: 01/05/2011 23:51:25 ******/
--***
Create PROCEDURE [dbo].[wRUScriuIerarhiiPosturi] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
declare	@mesajeroare varchar(500),@utilizator char(10), @userASiS varchar(20),@tip char(2),@id_ierarhie_post int,
        @update bit,@id_post int,@id_ierarhie int,@id_post_parinte int,@data_inceput datetime,@data_sfarsit datetime
	
	set @Utilizator=dbo.iauUtilizatorCurent()
	set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')	
   
 begin try       
    select 
         @update = isnull(@parXML.value('(/row/row/@update)[1]','bit'),0),
         @id_post = isnull(@parXML.value('(/row/@ID_post)[1]','int'),0),
         @id_ierarhie = isnull(@parXML.value('(/row/row/@ID_ierarhie)[1]','int'),0),
         @id_ierarhie_post = isnull(@parXML.value('(/row/row/@ID_ierarhie_post)[1]','int'),0),
         @id_post_parinte = isnull(@parXML.value('(/row/row/@ID_post_parinte)[1]','int'),0),
         @data_inceput = isnull(@parXML.value('(/row/row/@data_inceput)[1]','datetime'),''),
         @data_sfarsit = isnull(@parXML.value('(/row/row/@data_sfarsit)[1]','datetime'),'')               
		
	if exists (select 1 from sys.objects where name='wRUScriuIerarhiiPosturiSP' and type='P')  
	exec wRUScriuIerarhiiPosturiSP @sesiune, @parXML
else  
begin

	---------
	set @Utilizator=dbo.iauUtilizatorCurent()  
	set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '') 	
	---------	 
	
if @update=1
begin
  update  RU_ierarhie_post set ID_ierarhie=@id_ierarhie,ID_post_parinte=@id_post_parinte,Data_inceput=@data_inceput,Data_sfarsit=@data_sfarsit
  where ID_ierarhie_post=@id_ierarhie
  end
else 
   insert into RU_ierarhie_post(ID_ierarhie,ID_post,ID_post_parinte,Data_inceput,Data_sfarsit)
             select @id_ierarhie,@id_post,@id_post_parinte,@data_inceput,@data_sfarsit			
end
end try
begin catch
set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
