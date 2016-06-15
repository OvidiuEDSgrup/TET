/****** Object:  StoredProcedure [dbo].[wRUScriuCatCompetente]    Script Date: 01/05/2011 23:51:25 ******/
--***
Create PROCEDURE [dbo].[wRUScriuCatCompetente] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
declare	@mesajeroare varchar(500),@utilizator char(10), @userASiS varchar(20),@tip char(2),
        @id_categ_comp int,@descriere varchar(100),@denumire varchar(30),@update bit
	
	set @Utilizator=dbo.iauUtilizatorCurent()
	set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')
	
   
 begin try       
    select 
         @update = isnull(@parXML.value('(/row/@update)[1]','bit'),0),
         @id_categ_comp = isnull(@parXML.value('(/row/@ID_categ_comp)[1]','int'),0),
         @descriere =isnull(@parXML.value('(/row/@descriere)[1]','varchar(100)'),''),
         @denumire= isnull(@parXML.value('(/row/@denumire)[1]','varchar(30)'),'')         
		
	if exists (select 1 from sys.objects where name='wRUScriuCatCompetenteSP' and type='P')  
	exec wRUScriuCatCompetenteSP @sesiune, @parXML
else  
begin
	---------
	set @Utilizator=dbo.iauUtilizatorCurent()  
	set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')  
	
	---------	 
	
if @update=1
begin
  update  RU_categ_comp set descriere=@descriere,Denumire=@denumire
  where ID_categ_comp=@id_categ_comp
  end
else 
   insert into RU_categ_comp(Denumire,Descriere)
             select @denumire,@descriere				
end
end try
begin catch
set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
