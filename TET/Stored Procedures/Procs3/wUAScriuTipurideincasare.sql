/****** Object:  StoredProcedure [dbo].[wUAScriuTipurideincasare]    Script Date: 01/05/2011 23:51:25 ******/
--***
Create PROCEDURE [dbo].[wUAScriuTipurideincasare] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
declare	@mesajeroare varchar(500),@utilizator char(10), @userASiS varchar(20),@sub char(9),@tip char(2)
	
	set @Utilizator=dbo.iauUtilizatorCurent()
	set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')
	
	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	
	DECLARE     @id varchar(3),@o_id varchar(3),@denumire varchar(15), 
				@cont varchar(13),@lm varchar(9),@update bit,@export bit
 begin try       
    select 
         @update = isnull(@parXML.value('(/row/@update)[1]','bit'),0),
         @id =isnull(@parXML.value('(/row/@id)[1]','varchar(3)'),''),
         @denumire =isnull(@parXML.value('(/row/@denumire)[1]','varchar(15)'),''),
         @cont= isnull(@parXML.value('(/row/@cont)[1]','varchar(13)'),''),
         @lm= isnull(@parXML.value('(/row/@lm)[1]','varchar(9)'),''),
         @o_id= isnull(@parXML.value('(/row/@o_id)[1]','varchar(3)'),'')

		
	if exists (select 1 from sys.objects where name='wUAScriuTipurideincasareSP' and type='P')  
	exec wUAScriuTipurideincasareSP @sesiune, @parXML
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
	
exec wUAValidareTipurideincasari  @parXML 

	
if @update=1
begin
  update Tipuri_de_incasare set id=@id,denumire=@denumire,Cont_specific=@cont,Loc_de_munca=@lm
  where id=@o_id
  end
else 
   insert into Tipuri_de_incasare(id,denumire,cont_specific,export,loc_de_munca)
             select @id,@denumire,@cont,1,@lm 				
end
end try
begin catch
set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
