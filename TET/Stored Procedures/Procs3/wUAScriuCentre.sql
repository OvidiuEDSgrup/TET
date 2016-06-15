/****** Object:  StoredProcedure [dbo].[wUAScriuCentre]    Script Date: 01/05/2011 23:51:25 ******/
--***
Create PROCEDURE [dbo].[wUAScriuCentre] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
declare	@mesajeroare varchar(500),@utilizator char(10), @userASiS varchar(20),@sub char(9),@tip char(2)
	
	set @Utilizator=dbo.iauUtilizatorCurent()
	set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')
	
	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	
	DECLARE     @centru varchar(8),@o_centru varchar(8),@dencentru varchar(30), 
				@localitate varchar(8),@denlocalitate varchar(40),@lm varchar(9),@update bit
 begin try       
    select 
         @update = isnull(@parXML.value('(/row/@update)[1]','bit'),0),
         @centru =isnull(@parXML.value('(/row/@centru)[1]','varchar(8)'),''),
         @dencentru =isnull(@parXML.value('(/row/@dencentru)[1]','varchar(30)'),''),
         @localitate= isnull(@parXML.value('(/row/@localitate)[1]','varchar(13)'),''),
         @lm= isnull(@parXML.value('(/row/@lm)[1]','varchar(9)'),''),
         @o_centru= isnull(@parXML.value('(/row/@o_centru)[1]','varchar(8)'),'')

		
	if exists (select 1 from sys.objects where name='wUAScriuCentreSP' and type='P')  
	exec wUAScriuCentreSP @sesiune, @parXML
else  
begin

	---------
	set @Utilizator=dbo.iauUtilizatorCurent()  
	set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')  

	declare @lista_lm int
	set @lista_lm=(case when exists (select 1 from proprietati 
	where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='LOCMUNCA' and Valoare<>'') then 1 else 0 end)

	---------
	
	if (@lista_lm=1 and @lm='') or (@lista_lm=1 and not exists (select cod from lm where Cod=@lm))
		begin     
			set @mesajeroare='Intorduceti un loc de munca valid!!'  
			raiserror(@mesajeroare,11,1)  
		end
	
	if (@lista_lm=1 and not exists (select cod from LMFiltrare where Cod=@lm and utilizator=@utilizator))
		begin     
			set @mesajeroare='Nu aveti drept de operare pentru acest loc de munca!!'  
			raiserror(@mesajeroare,11,1)  
		end

 exec wUAValidareCentre  @parXML 

	
if @update=1
begin
  update centre set centru=@centru,denumire_centru=@dencentru,localitate=@localitate,Loc_de_munca=@lm
  where centru=@o_centru 
  end
else 
   insert into centre(centru,denumire_centru,localitate,loc_de_munca)
             select @centru,@dencentru,@localitate,@lm 				
end
end try
begin catch
set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
