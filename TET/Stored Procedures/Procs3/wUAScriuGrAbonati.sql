/****** Object:  StoredProcedure [dbo].[wUAScriuStrazi]    Script Date: 01/05/2011 23:51:25 ******/
--***
Create PROCEDURE [dbo].[wUAScriuGrAbonati] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
declare	@mesajeroare varchar(500),@utilizator char(10), @userASiS varchar(20),@sub char(9),@tip char(2)
	
	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	
	DECLARE @grupa varchar(8),@o_grupa varchar(8),@lm varchar(9),@update bit,@denumire varchar(30),@detaliat int,
		@cont varchar(20)
 begin try       
    select 
         @update = isnull(@parXML.value('(/row/@update)[1]','bit'),0),
         @grupa =isnull(@parXML.value('(/row/@grupa)[1]','varchar(8)'),''),
         @lm= isnull(@parXML.value('(/row/@lm)[1]','varchar(9)'),''),
         @denumire= isnull(@parXML.value('(/row/@denumire)[1]','varchar(30)'),''),
         @cont= isnull(@parXML.value('(/row/@cont)[1]','varchar(20)'),''),
         @detaliat= isnull(@parXML.value('(/row/@detaliat)[1]','int'),''),
         @o_grupa= isnull(@parXML.value('(/row/@o_grupa)[1]','varchar(8)'),'')

		
	if exists (select 1 from sys.objects where name='wUAScriuGrAbonatiSP' and type='P')  
	exec wUAScriuGrAbonatiSP @sesiune, @parXML
else  
begin

---------
	set @Utilizator=dbo.fIauUtilizatorCurent()  
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
	
	
if @update=1
begin
  update grabonat set Denumire=@denumire,Export_detaliat=@detaliat,Loc_de_munca=@lm
  where grupa=@o_grupa
  end
else 
   insert into grabonat(Grupa,Denumire,Export_detaliat,Cont,Loc_de_munca)
             select @grupa,@denumire,@detaliat,@cont,@lm 				
end
end try
begin catch
set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
