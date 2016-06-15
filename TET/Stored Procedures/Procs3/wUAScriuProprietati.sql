/****** Object:  StoredProcedure [dbo].[wUAScriuProprietati]    Script Date: 01/05/2011 23:51:25 ******/
--***
Create PROCEDURE  [dbo].[wUAScriuProprietati] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
declare	@mesajeroare varchar(500),@utilizator char(10), @userASiS varchar(20),@sub char(9),@tip char(2)
	
	set @Utilizator=dbo.iauUtilizatorCurent()
	set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')
	
	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	
	DECLARE     @cod varchar(20),@codabonat varchar(13),@contract varchar(20),@centru varchar(8),@zona varchar(8),@codcasier varchar(10),@codproprietate varchar(20),@valoare varchar(200),@update bit
				
 begin try       
    select 
		 
         @cod =isnull(@parXML.value('(/row/@cod)[1]','varchar(20)'),''),
         @codabonat=isnull(@parXML.value('(/row/@codabonat)[1]','varchar(13)'),''),
         @contract=isnull(@parXML.value('(/row/@contract)[1]','varchar(20)'),''),
         @centru =isnull(@parXML.value('(/row/@centru)[1]','varchar(8)'),''),
         @codcasier=isnull(@parXML.value('(/row/@codcasier)[1]','varchar(10)'),''),
         @zona =isnull(@parXML.value('(/row/@zona)[1]','varchar(8)'),''),
         @update = isnull(@parXML.value('(/row/row/@update)[1]','bit'),0),
         @codproprietate =isnull(@parXML.value('(/row/row/@codproprietate)[1]','varchar(20)'),1),
         @valoare =isnull(@parXML.value('(/row/row/@valoare)[1]','varchar(200)'),1)
         
   declare @catalog  varchar(1)
   set @catalog=(select catalog from catproprietati where cod_proprietate=@codproprietate)    
	
	if exists (select 1 from sys.objects where name='wUAScriuProprietatiSP' and type='P')  
	exec wUAScriuProprietatiSP @sesiune, @parXML
else  

begin
--exec wUAValidareProprietati  @parXML 
 if @update=1 and @catalog='1'

   begin
   update proprietati set cod_proprietate=@codproprietate,valoare=@valoare 
   where    cod=@cod and tip=@catalog
   end

if @update=1 and @catalog='2'

   begin
   update proprietati set cod_proprietate=@codproprietate,valoare=@valoare 
   where    cod=@codabonat and tip=@catalog
   end

if @update=1 and @catalog='3'

   begin
   update proprietati set cod_proprietate=@codproprietate,valoare=@valoare 
   where    cod=@contract and tip=@catalog
   end


 if @update=1 and @catalog='4'

   begin
   update proprietati set cod_proprietate=@codproprietate,valoare=@valoare 
   where    cod=@codcasier and tip=@catalog
   end
 
 if @update=1 and @catalog='5'

   begin
   update proprietati set cod_proprietate=@codproprietate,valoare=@valoare 
   where    cod=@zona and tip=@catalog
   end
 if @update=1 and @catalog='6'

   begin
   update proprietati set cod_proprietate=@codproprietate,valoare=@valoare 
   where    cod=@centru and tip=@catalog
   end

else 	
begin   

   
if @catalog='1'
   insert into proprietati(tip,cod,cod_proprietate,valoare,valoare_tupla) 
   select 
   
			@catalog,@cod,@codproprietate,@valoare,'' 				

if @catalog='2'
   insert into proprietati(tip,cod,cod_proprietate,valoare,valoare_tupla) 
   select 
   
			@catalog,@codabonat,@codproprietate,@valoare,'' 	

if @catalog='3'
   insert into proprietati(tip,cod,cod_proprietate,valoare,valoare_tupla) 
   select 
   
			@catalog,@contract,@codproprietate,@valoare,'' 


if @catalog='4'
   insert into proprietati(tip,cod,cod_proprietate,valoare,valoare_tupla) 
   select 
   
			@catalog,@codcasier,@codproprietate,@valoare,'' 


if @catalog='5'
   insert into proprietati(tip,cod,cod_proprietate,valoare,valoare_tupla) 
   select 
   
			@catalog,@zona,@codproprietate,@valoare,'' 


if @catalog='6'
   insert into proprietati(tip,cod,cod_proprietate,valoare,valoare_tupla) 
   select 
   
			@catalog,@centru,@codproprietate,@valoare,'' 



end
end
end try
begin catch
set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
