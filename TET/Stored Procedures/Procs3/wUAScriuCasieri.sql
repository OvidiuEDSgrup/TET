/****** Object:  StoredProcedure [dbo].[wUAScriuCasieri]    Script Date: 01/05/2011 23:51:25 ******/
--***
Create PROCEDURE [dbo].[wUAScriuCasieri] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
declare	@mesajeroare varchar(500),@utilizator char(10), @userASiS varchar(20),@sub char(9),@tip char(2)
	
	set @Utilizator=dbo.iauUtilizatorCurent()
	set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')
	
	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	
	DECLARE     @codcasier varchar(10),@casier varchar(30),@seriebi varchar(2),@numarbi varchar(8), 
				@cnp varchar(13),@update bit,@serie varchar(8),@tipincasare varchar(8),@formchit varchar(200),
				@formchitav varchar(200),@formchitsoldav varchar(200),@formfactura varchar(200),@lm varchar(9)
 begin try       
    select 
         
         @codcasier =isnull(@parXML.value('(/row/@codcasier)[1]','varchar(10)'),''),
         @casier =isnull(@parXML.value('(/row/@casier)[1]','varchar(30)'),''),
         @seriebi =isnull(@parXML.value('(/row/@seriebi)[1]','varchar(2)'),''),
         @numarbi= isnull(@parXML.value('(/row/@numarbi)[1]','varchar(8)'),''),
         @cnp= isnull(@parXML.value('(/row/@cnp)[1]','varchar(13)'),''),
         @update = isnull(@parXML.value('(/row/@update)[1]','bit'),0),
		 @serie= isnull(@parXML.value('(/row/@serie)[1]','varchar(8)'),''),
		 @tipincasare= isnull(@parXML.value('(/row/@tipincasare)[1]','varchar(8)'),''),
		 @formchit= isnull(@parXML.value('(/row/@formchit)[1]','varchar(200)'),''),
		 @formchitav= isnull(@parXML.value('(/row/@formchitav)[1]','varchar(200)'),''),
		 @formchitsoldav= isnull(@parXML.value('(/row/@formchitsoldav)[1]','varchar(200)'),''),
		 @formfactura= isnull(@parXML.value('(/row/@formfactura)[1]','varchar(200)'),''),
		 @lm= isnull(@parXML.value('(/row/@lm)[1]','varchar(9)'),'')
		 
	if exists (select 1 from sys.objects where name='wUAScriuCasieriSP' and type='P')  
	exec wUAScriuCasieriSP @sesiune, @parXML
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

exec wUAValidareCasieri  @parXML 

	if @update=1
begin
  update casieri set casier=@casier,serie_bi=@seriebi,numar_bi=@numarbi,cnp=@cnp,Serie=@serie,tip_incasare=@tipincasare,
  formular_chitanta=@formchit,formular_factura=@formfactura,formular_chitanta_avans=@formchitav,Loc_de_munca=@lm,formular_chitanta_sold_avans=@formchitsoldav
  where cod_casier=@codcasier 
  end
else 
   insert into casieri(cod_casier,casier,serie_bi,Numar_BI,Nr_incasare,serie,CNP,Terminal,tip_incasare,Data,Info,Suma,Formular_chitanta,formular_factura,formular_chitanta_avans,
   formular_chitanta_sold_avans,Loc_de_munca,Alfa1,Alfa2,Val1,val2)
             select @codcasier,@casier,@seriebi,@numarbi,'',@serie,@cnp,'',@tipincasare,'','','',@formchit,@formfactura,@formchitav,@formchitsoldav,@lm,'','',0,0		
end
end try
begin catch
set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
