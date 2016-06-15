/****** Object:  StoredProcedure [dbo].[wUAOPCompensareAvans]    Script Date: 01/05/2011 23:20:13 ******/
--***
/* descriere... */
create procedure  [dbo].[wUAOPCompensareAvans] (@sesiune varchar(50), @parXML xml) 
as     
begin
declare @data datetime,@data_jos_fact datetime,@data_sus_fact datetime,@data_scadentei datetime,@compPen bit,@ordonare varchar(1),@filtruContract int,
        @filtruAbonat varchar(13),@filtruGrupa varchar(13),@filtruCentru varchar(13),@filtruZona varchar(13),@zi_facturare int,@userASiS varchar(13),
        @utilizator varchar(13),@mesaj varchar(200),@tipinc varchar(2)
begin try
exec wIaUtilizator @sesiune, @utilizator output

select	@data=ISNULL(@parXML.value('(/parametri/@data)[1]', 'datetime'), ''),
        @data_jos_fact=ISNULL(@parXML.value('(/parametri/@data_jos_fact)[1]', 'datetime'), ''),
        @data_sus_fact=ISNULL(@parXML.value('(/parametri/@data_sus_fact)[1]', 'datetime'), ''),
        @compPen=isnull(@parXML.value('(/parametri/@compPen)[1]','bit'),0),
        @tipinc=isnull(@parXML.value('(/parametri/@tipinc)[1]','varchar(2)'),''),
        @filtruContract = isnull(@parXML.value('(/parametri/@filtruContract)[1]','int'),0),
		@filtruAbonat = isnull(@parXML.value('(/parametri/@filtruAbonat)[1]','varchar(13)'),''),	
		@filtruGrupa = isnull(@parXML.value('(/parametri/@filtruGrupa)[1]','varchar(13)'),''),
		@filtruCentru = isnull(@parXML.value('(/parametri/@filtruCentru)[1]','varchar(13)'),''),
		@filtruZona = isnull(@parXML.value('(/parametri/@filtruZona)[1]','varchar(13)'),'')
		
	set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')
    if @data_jos_fact>=@data_sus_fact
  		begin
			set @mesaj='Intervalul de facturare nu este corect!!!'
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
   
    exec CompUA @filtruAbonat,@filtruContract,@data, @UserAsis, @filtruGrupa, @filtruCentru, @filtruZona, @data_jos_fact, @data_sus_fact,@compPen,@tipinc
    select 'Operatia de compensare avansuri s-a incheiat cu succes!! ' as textMesaj, 'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
end try
begin catch
set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch	
end
