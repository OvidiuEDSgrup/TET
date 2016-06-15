/****** Object:  StoredProcedure [dbo].[wUAScriuZone]    Script Date: 01/05/2011 23:51:25 ******/
--***
Create PROCEDURE  [dbo].[wUAScriuZone] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
declare	@mesajeroare varchar(500),@utilizator char(10), @userASiS varchar(20),@sub char(9),@tip char(2),@lm varchar(13)
	
	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	
	DECLARE     @zona varchar(8),@o_zona varchar(8),@denzona varchar(50), 
				@localitate varchar(8),@centru varchar(8),@update bit
 begin try       
    select 
         @update = isnull(@parXML.value('(/row/@update)[1]','bit'),0),
         @zona =isnull(@parXML.value('(/row/@zona)[1]','varchar(8)'),''),
         @denzona =isnull(@parXML.value('(/row/@denzona)[1]','varchar(50)'),''),
         @localitate= isnull(@parXML.value('(/row/@localitate)[1]','varchar(8)'),''),
         @centru= isnull(@parXML.value('(/row/@centru)[1]','varchar(8)'),''),
         @o_zona= isnull(@parXML.value('(/row/@o_zona)[1]','varchar(8)'),'')

		
	if exists (select 1 from sys.objects where name='wUAScriuZoneSP' and type='P')  
	exec wUAScriuZoneSP @sesiune, @parXML
else  
begin

		---------
	set @Utilizator=dbo.iauUtilizatorCurent()  
	set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')  

	declare @lista_lm int
	set @lm=(select Loc_de_munca from centre where Centru=@centru )
	set @lista_lm=(case when exists (select 1 from proprietati 
	where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='LOCMUNCA' and Valoare<>'') then 1 else 0 end)

	---------
		
	if (@lista_lm=1 and not exists (select cod from LMFiltrare where Cod=@lm and utilizator=@utilizator))
		begin     
			set @mesajeroare='Nu puteti adauga o zona care se afla intr-un centru dintr-un loc de munca pentru care nu aveti drept de operare!!'  
			raiserror(@mesajeroare,11,1)  
		end			
	
	
 --exec wUAValidareZone  @parXML 

	if @update=1
begin
  update zone set denumire_zona=@denzona,localitate=@localitate,centru=@centru
  where zona=@o_zona 
  end
else 
   insert into zone(zona,denumire_zona,localitate,centru)
             select @zona,@denzona,@localitate,@centru 				
end
end try
begin catch
set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
--select * from zone
