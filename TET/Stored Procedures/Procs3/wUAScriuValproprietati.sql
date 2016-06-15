/****** Object:  StoredProcedure [dbo].[wUAScriuValproprietati]    Script Date: 01/05/2011 23:51:25 ******/
--***
Create PROCEDURE  [dbo].[wUAScriuValproprietati] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
declare	@mesajeroare varchar(500),@utilizator char(10), @userASiS varchar(20),@sub char(9),@tip char(2)
	
	set @Utilizator=dbo.iauUtilizatorCurent()
	set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')
	
	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	
	DECLARE     @codproprietate varchar(20),@valoare varchar(200),@descriere varchar(80),@update bit,@o_codproprietate varchar(20),
				@o_valoare varchar(200)
 begin try       
    select 
         @update = isnull(@parXML.value('(/row/row/@update)[1]','bit'),0),
         @codproprietate =isnull(@parXML.value('(/row/@codproprietate)[1]','varchar(20)'),''),
         @valoare =isnull(@parXML.value('(/row/row/@valoare)[1]','varchar(200)'),''),
         @descriere =isnull(@parXML.value('(/row/row/@descriere)[1]','varchar(80)'),''),
         @o_codproprietate= isnull(@parXML.value('(/row/row/@o_codproprietate)[1]','varchar(20)'),''),
         @o_valoare =isnull(@parXML.value('(/row/row/@o_valoare)[1]','varchar(200)'),'')

		
	if exists (select 1 from sys.objects where name='wUAScriuValproprietatiSP' and type='P')  
	exec wUAScriuValproprietatiSP @sesiune, @parXML
else  
begin
--exec wUAValidarePropUA  @parXML 

	
if @update=1
begin
  update valproprietati set valoare=@valoare,descriere=@descriere
  where cod_proprietate=@codproprietate and Valoare=@o_valoare
  end
else 
   insert into valproprietati(cod_proprietate,valoare,descriere,valoare_proprietate_parinte)
             select @codproprietate,@valoare,@descriere,''				
end
end try
begin catch
set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
