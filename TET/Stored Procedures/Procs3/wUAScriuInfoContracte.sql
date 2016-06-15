/****** Object:  StoredProcedure [dbo].[wUAScriuInfoContracte]    Script Date: 01/05/2011 23:51:25 ******/
--***
Create PROCEDURE [dbo].[wUAScriuInfoContracte] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
declare	@mesajeroare varchar(500),@utilizator char(10), @userASiS varchar(20),@sub char(9),@tip char(2)
	
	set @Utilizator=dbo.iauUtilizatorCurent()
	set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')
	
	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	
	DECLARE @cod varchar(3),@o_cod varchar(3),@descriere varchar(50),@lm varchar(9),@update bit,@info1 varchar(50)
			,@info2 varchar(50),@info3 varchar(50)
 begin try       
    select 
         @update = isnull(@parXML.value('(/row/@update)[1]','bit'),0),
         @cod =isnull(@parXML.value('(/row/@cod)[1]','varchar(3)'),''),
         @descriere =isnull(@parXML.value('(/row/@descriere)[1]','varchar(50)'),''),
         @info1 =isnull(@parXML.value('(/row/@info1)[1]','varchar(50)'),''),
         @info2 =isnull(@parXML.value('(/row/@info2)[1]','varchar(50)'),''),
         @info3 =isnull(@parXML.value('(/row/@info3)[1]','varchar(50)'),''),
         @lm= isnull(@parXML.value('(/row/@lm)[1]','varchar(9)'),''),
         @o_cod= isnull(@parXML.value('(/row/@o_cod)[1]','varchar(8)'),'')

		
	if exists (select 1 from sys.objects where name='wUAScriuCentreSP' and type='P')  
	exec wUAScriuInfoContracteSP @sesiune, @parXML
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
	
if @update=1
begin
  update InfoContracte set Cod=@cod,Descriere=@descriere,Loc_de_munca=@lm,Info1=@info1,Info2=@info2,Info3=@info3
  where Cod=@o_cod
  end
else 
   insert into InfoContracte(Cod,Descriere,Loc_de_munca,Info1,Info2,Info3)
             select @cod,@descriere,@lm,@info1,@info2,@info3 				
end
end try
begin catch
set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
--select * from infocontracte
