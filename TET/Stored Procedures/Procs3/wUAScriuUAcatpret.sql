/****** Object:  StoredProcedure [dbo].[wUAScriuUAcatpret]    Script Date: 01/05/2011 23:51:25 ******/
--***
Create PROCEDURE  [dbo].[wUAScriuUAcatpret] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
declare	@mesajeroare varchar(500),@utilizator char(10), @userASiS varchar(20),@sub char(9),@tip char(2)
	
	set @Utilizator=dbo.iauUtilizatorCurent()
	set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')
	
	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	
	DECLARE     @categorie int,@denumire char(30),@update bit
 begin try       
    select 
         @update = isnull(@parXML.value('(/row/@update)[1]','bit'),0),
         @categorie = isnull(@parXML.value('(/row/@categorie)[1]','int'),0),
         @denumire =isnull(@parXML.value('(/row/@denumire)[1]','varchar(20)'),'')
         

		
	if exists (select 1 from sys.objects where name='wUAScriuUAcatpretSP' and type='P')  
	exec wUAScriuUAcatpretSP @sesiune, @parXML
else  
begin
--exec wUAValidarePropUA  @parXML 

	
if @update=1
begin
  update UAcatpret set denumire=@denumire
  where categorie=@categorie
  end
else 
   insert into UAcatpret(categorie,tip_categorie,denumire,valuta)
             select @categorie,1,@denumire,0			
end
end try
begin catch
set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
