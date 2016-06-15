/****** Object:  StoredProcedure [dbo].[wRUScriuCompPosturi]    Script Date: 01/05/2011 23:51:25 ******/
--***
Create PROCEDURE [dbo].[wRUScriuCompPosturi] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
declare	@mesajeroare varchar(500),@utilizator char(10), @userASiS varchar(20),@tip char(2),@id_comp_posturi int,
        @update bit,@id_post int,@id_comp int,@pondere float,@o_id_comp int,@id_categ_comp int,@o_id_categ_comp int
	
	set @Utilizator=dbo.iauUtilizatorCurent()
	set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')	
   
 begin try       
    select 
         @update = isnull(@parXML.value('(/row/row/@update)[1]','bit'),0),
         @id_post = isnull(@parXML.value('(/row/@ID_post)[1]','int'),0),
         @id_comp = isnull(@parXML.value('(/row/row/@ID_comp)[1]','int'),0),
         @id_comp_posturi = isnull(@parXML.value('(/row/row/@ID_comp_posturi)[1]','int'),0),
         @id_categ_comp = isnull(@parXML.value('(/row/row/@ID_categ_comp)[1]','int'),0),
         @o_id_categ_comp = isnull(@parXML.value('(/row/row/@o_ID_categ_comp)[1]','int'),0),
         @o_id_comp = isnull(@parXML.value('(/row/row/@o_ID_comp)[1]','int'),0),
         @pondere = isnull(@parXML.value('(/row/row/@pondere)[1]','float'),0)             
		
	if exists (select 1 from sys.objects where name='wRUScriuCompPosturiSP' and type='P')  
	exec wRUScriuCompPosturiSP @sesiune, @parXML
else  
begin

	---------
	set @Utilizator=dbo.iauUtilizatorCurent()  
	set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '') 	
	---------	 
	
if @update=1
begin
  update  RU_competente_posturi set ID_comp=@id_comp,Pondere=@pondere,id_categ_comp=@id_categ_comp
  where ID_comp_posturi=@id_comp_posturi
  end
else 
   insert into RU_competente_posturi(ID_comp,ID_post,id_categ_comp,Pondere)
             select @id_comp,@id_post,@id_categ_comp,@pondere				
end
end try
begin catch
set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
