/****** Object:  StoredProcedure [dbo].[wUAScriuCatproprietati]    Script Date: 01/05/2011 23:51:25 ******/
--***
Create PROCEDURE  [dbo].[wUAScriuCatproprietati] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
declare	@mesajeroare varchar(500),@utilizator char(10), @userASiS varchar(20),@sub char(9),@tip char(2)
	
	set @Utilizator=dbo.iauUtilizatorCurent()
	set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')
	
	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	
	DECLARE     @codproprietate varchar(20),@descriere varchar(80),@validare int,@catalog varchar(1),
				@proprietateparinte varchar(20),@update bit,@o_codproprietate varchar(20)
 begin try       
    select 
         @update = isnull(@parXML.value('(/row/@update)[1]','bit'),0),
         @codproprietate =isnull(@parXML.value('(/row/@codproprietate)[1]','varchar(20)'),''),
         @descriere =isnull(@parXML.value('(/row/@descriere)[1]','varchar(80)'),''),
         @validare= isnull(@parXML.value('(/row/@validare)[1]','int'),''),
         @catalog =isnull(@parXML.value('(/row/@catalog)[1]','varchar(1)'),''),
         @proprietateparinte =isnull(@parXML.value('(/row/@proprietateparinte)[1]','varchar(20)'),''),
         @o_codproprietate= isnull(@parXML.value('(/row/@o_codproprietate)[1]','varchar(20)'),'')

		
	if exists (select 1 from sys.objects where name='wUAScriuCatproprietatiSP' and type='P')  
	exec wUAScriuCatproprietatiSP @sesiune, @parXML
else  
begin
--exec wUAValidarePropUA  @parXML 

	
if @update=1
begin
  update Catproprietati set descriere=@descriere,validare=@validare,catalog=@catalog,proprietate_parinte=@proprietateparinte
  where cod_proprietate=@codproprietate 
  end
else 
   insert into Catproprietati(cod_proprietate,descriere,Validare,Catalog,proprietate_parinte)
             select @codproprietate,@descriere,@Validare,@Catalog,@proprietateparinte				
end
end try
begin catch
set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
