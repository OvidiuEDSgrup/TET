/****** Object:  StoredProcedure [dbo].[wUAScriuDocfiscale]    Script Date: 01/05/2011 23:51:25 ******/
--***
Create PROCEDURE  [dbo].[wUAScriuDocfiscale] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
declare	@mesajeroare varchar(500),@utilizator char(10), @userASiS varchar(20),@sub char(9),@tip char(2)
	
	set @Utilizator=dbo.iauUtilizatorCurent()
	set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')
	
	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	
	DECLARE   @update bit,@id int,@tipdoc varchar(3),@serie varchar(9),@numarinf int,@numarsup int,@ultimulnr int


 begin try       
    select 
         @update = isnull(@parXML.value('(/row/@update)[1]','bit'),0),
         @id=isnull(@parXML.value('(/row/@id)[1]', 'int'), ''),
         @tipdoc=isnull(@parXML.value('(/row/@tipdoc)[1]', 'varchar(3)'), ''),
		 @serie=isnull(@parXML.value('(/row/@serie)[1]', 'varchar(9)'), ''),
	     @numarinf=isnull(@parXML.value('(/row/@numarinf)[1]', 'int'), ''),
	     @numarsup=isnull(@parXML.value('(/row/@numarsup)[1]', 'int'), ''),	     
	     @ultimulnr=isnull(@parXML.value('(/row/@ultimulnr)[1]', 'int'), '')
	     
	if exists (select 1 from sys.objects where name='wUAScriuDocfiscaleSP' and type='P')  
	exec wUAScriuDocfiscaleSP @sesiune, @parXML
else  
begin
-- exec wUAValidareDocfiscale  @parXML 

	
if @update=1
begin
  update docfiscale set tipdoc=@tipdoc,serie=@serie,NumarInf=@numarinf,NumarSup=@numarsup,UltimulNr=@ultimulnr where  id=@id
  end
else 
   insert into docfiscale(tipdoc,Serie,NumarInf,NumarSup,ultimulnr)
             select @tipdoc,@serie,@numarinf,@numarsup,@ultimulnr				
end
end try
begin catch
set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
