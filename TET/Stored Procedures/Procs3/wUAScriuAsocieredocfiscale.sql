/****** Object:  StoredProcedure [dbo].[wUAScriuAsocieredocfiscale]    Script Date: 01/05/2011 23:51:25 ******/
--***
Create PROCEDURE  [dbo].[wUAScriuAsocieredocfiscale] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
declare	@mesajeroare varchar(500),@utilizator char(10), @userASiS varchar(20),@sub char(9),@tip char(2)
	
	set @Utilizator=dbo.iauUtilizatorCurent()
	set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')
	
	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	
	DECLARE     @id int,@o_id int,@update bit,@codcasier varchar(20),@prioritate int


 begin try       
    select 
         @update = isnull(@parXML.value('(/row/row/@update)[1]','bit'),0),
         @codcasier=isnull(@parXML.value('(/row/@codcasier)[1]', 'varchar(20)'), ''),
		 @id=isnull(@parXML.value('(/row/row/@id)[1]', 'int'), ''),
	     @o_id=isnull(@parXML.value('(/row/row/@o_id)[1]', 'int'), ''),
	     @prioritate=isnull(@parXML.value('(/row/row/@prioritate)[1]', 'int'), 0)
	     
	     
	     
	if exists (select 1 from sys.objects where name='wUAScriuAsocieredocfiscaleSP' and type='P')  
	exec wUAScriuAsocieredocfiscaleSP @sesiune, @parXML
else  
begin
 exec wUAValidareAsocieredocfiscale  @parXML 

	
if @update=1
begin
  update asocieredocfiscale set id=@id,prioritate=@prioritate where cod=@codcasier and id=@o_id
  end
else 
   insert into asocieredocfiscale(id,tipasociere,cod,prioritate)
             select @id,'U',@codcasier,@prioritate				
end
end try
begin catch
set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
