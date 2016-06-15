/****** Object:  StoredProcedure [dbo].[wRUScriuDomeniiCompetente]    Script Date: 01/05/2011 23:51:25 ******/
--***
Create PROCEDURE [dbo].[wRUScriuDomeniiCompetente] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
declare	@mesajeroare varchar(500),@utilizator char(10), @userASiS varchar(20),
        @ID_domeniu_comp int,@denumire varchar(50),@descriere varchar(100),@update bit
	
	set @Utilizator=dbo.iauUtilizatorCurent()
	set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')
	
   
 begin try       
    select 
         @update = isnull(@parXML.value('(/row/@update)[1]','bit'),0),
         @ID_domeniu_comp = isnull(@parXML.value('(/row/@ID_domeniu_comp)[1]','int'),0),
         @denumire =isnull(@parXML.value('(/row/@denumire)[1]','varchar(50)'),''),
         @descriere= isnull(@parXML.value('(/row/@descriere)[1]','varchar(100)'),'')
         
		
	if exists (select 1 from sys.objects where name='wRUScriuDomeniiCompetenteSP' and type='P')  
	exec wRUScriuDomeniiCompetenteSP @sesiune, @parXML
else  
begin

	---------
	set @Utilizator=dbo.iauUtilizatorCurent()  
	set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')  

	
	---------	 
	
if @update=1
begin
  update  RU_domenii_competente set denumire=@denumire,descriere=@descriere
  where ID_domeniu_comp=@ID_domeniu_comp
  end
else 
   insert into RU_domenii_competente(denumire,descriere)
             select @denumire,@descriere				
end
end try
begin catch
set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
