/****** Object:  StoredProcedure [dbo].[wUAOPGenerareFacturiUA]    Script Date: 01/05/2011 23:20:13 ******/
--***
/* descriere... */
create procedure  [dbo].[wUAOPGenerareFacturiUA] (@sesiune varchar(50), @parXML xml) 
as     
begin
declare @data_fact datetime,@data_jos datetime,@data_sus datetime,@data_scadentei datetime,@calcPen bit,@ordonare varchar(1),@filtruContract int,
        @filtruAbonat varchar(13),@filtruGrupa varchar(13),@filtruCentru varchar(13),@filtruZona varchar(13),@zi_facturare int,@userASiS varchar(13),
        @utilizator varchar(13),@mesaj varchar(200),@filtruLm varchar(13)
begin try
exec wIaUtilizator @sesiune, @utilizator output

select	@data_fact=ISNULL(@parXML.value('(/parametri/@data_fact)[1]', 'datetime'), ''),
        @data_jos=ISNULL(@parXML.value('(/parametri/@data_jos)[1]', 'datetime'), ''),
        @data_sus=ISNULL(@parXML.value('(/parametri/@data_sus)[1]', 'datetime'), ''),
        @data_scadentei=ISNULL(@parXML.value('(/parametri/@data_scadentei)[1]', 'datetime'), ''),
        @calcPen=isnull(@parXML.value('(/parametri/@calcPen)[1]','bit'),0),
        @ordonare=isnull(@parXML.value('(/parametri/@ordonare)[1]','varchar(1)'),''),
        @filtruLm = isnull(@parXML.value('(/parametri/@lm)[1]','varchar(13)'),''),
        @filtruContract = isnull(@parXML.value('(/parametri/@filtruContract)[1]','int'),0),
		@filtruAbonat = isnull(@parXML.value('(/parametri/@filtruAbonat)[1]','varchar(13)'),''),	
		@filtruGrupa = isnull(@parXML.value('(/parametri/@filtruGrupa)[1]','varchar(13)'),''),
		@filtruCentru = isnull(@parXML.value('(/parametri/@filtruCentru)[1]','varchar(13)'),''),
		@filtruZona = isnull(@parXML.value('(/parametri/@filtruZona)[1]','varchar(13)'),''),
		@zi_facturare = isnull(@parXML.value('(/parametri/@zi_facturare)[1]','int'),0)

	set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')
    
  	if @data_jos>=@data_sus
  		begin
			set @mesaj='Intervalul de facturare nu este corect!!!'
			raiserror(@mesaj,11,1)
		end	
		
  	if @data_scadentei<@data_fact
  		begin
			set @mesaj='Data scadentei este mai mica decat data facturilor generate!!!'
			raiserror(@mesaj,11,1)
		end			
  	
  	if not exists (select id_contract from uacon where Id_contract=@filtruContract)and @filtruContract<>0
		begin
			set @mesaj='Contractul introdus nu se regaseste in baza de date!!!'
			raiserror(@mesaj,11,1)
		end	
	
	if not exists (select abonat from Abonati where abonat=@filtruAbonat)and @filtruAbonat<>''
		begin
			set @mesaj='Abonatul introdus nu se regaseste in baza de date!!!'
			raiserror(@mesaj,11,1)
		end	
		
	if not exists (select grupa from Grabonat where @filtruGrupa=Grupa)and @filtruGrupa<>'' 
		begin
			set @mesaj='Grupa introdusa nu se regaseste in baza de date!!!'
			raiserror(@mesaj,11,1)
		end		
		
	if not exists (select Cod from lm where @filtruLm=Cod)and @filtruLm<>'' 
		begin
			set @mesaj='Locul de munca introdus nu se regaseste in baza de date!!!'
			raiserror(@mesaj,11,1)
		end			
	
	if not exists (select centru from Centre where @filtruCentru=Centru)and @filtruCentru<>'' 
		begin
			set @mesaj='Centrul introdus nu se regaseste in baza de date!!!'
			raiserror(@mesaj,11,1)
		end	
		
	if not exists (select zona from Zone where @filtruZona=Zona)and @filtruZona<>'' 
		begin
			set @mesaj='Zona introdusa nu se regaseste in baza de date!!!'
			raiserror(@mesaj,11,1)
		end			
			
	exec GenFactUA @data_fact,@data_jos,@data_sus,@filtruContract,@filtruAbonat,@filtruGrupa,@filtruCentru,@filtruZona,@calcPen,@data_scadentei,@userASiS,'',@ordonare,@utilizator,@zi_facturare,@filtruLm
   
    select 'Operatia de generare facturi s-a incheiat cu succes!! ' as textMesaj, 'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
end try
begin catch
set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch	
end
