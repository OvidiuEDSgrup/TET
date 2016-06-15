/****** Object:  StoredProcedure [dbo].[wRUScriuObiectivePosturi]    Script Date: 01/05/2011 23:51:25 ******/
--***
Create PROCEDURE [dbo].[wRUScriuObiectivePosturi] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
declare	@mesajeroare varchar(500),@utilizator char(10), @userASiS varchar(20),@tip char(2),@id_ob_posturi int,
        @update bit,@id_post int,@id_obiectiv int,@pondere float,@o_id_obiectiv int
	
	set @Utilizator=dbo.iauUtilizatorCurent()
	set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')	
   
 begin try       
    select 
         @update = isnull(@parXML.value('(/row/row/@update)[1]','bit'),0),
         @id_post = isnull(@parXML.value('(/row/@ID_post)[1]','int'),0),
         @id_obiectiv = isnull(@parXML.value('(/row/row/@ID_obiectiv)[1]','int'),0),
         @id_ob_posturi = isnull(@parXML.value('(/row/row/@ID_ob_posturi)[1]','int'),0),
         @o_id_obiectiv= isnull(@parXML.value('(/row/row/@o_ID_obiectiv)[1]','int'),0),
         @pondere = isnull(@parXML.value('(/row/row/@pondere)[1]','float'),0)             
		
	if exists (select 1 from sys.objects where name='wRUScriuObiectivePosturiSP' and type='P')  
	exec wRUScriuObiectivePosturiSP @sesiune, @parXML
else  
begin

	---------
	set @Utilizator=dbo.iauUtilizatorCurent()  
	set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '') 	
	---------	 
	
if @update=1
begin
  update  RU_obiective_posturi set ID_obiectiv=@id_obiectiv,Pondere=@pondere
  where ID_ob_posturi=@id_ob_posturi
  end
else 
   insert into RU_obiective_posturi(ID_obiectiv,ID_post,Pondere)
             select @id_obiectiv,@id_post,@pondere				
end
end try
begin catch
set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
