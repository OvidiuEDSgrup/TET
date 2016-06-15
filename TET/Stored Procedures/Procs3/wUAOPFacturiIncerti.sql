--***
/* descriere... */
create procedure [dbo].[wUAOPFacturiIncerti](@sesiune varchar(50), @parXML xml) 
as     
begin
declare @utilizator varchar(8),@abonat_fact varchar(13),@docXML xml,@mesaj varchar(200),@id_factura int,@factura varchar(13),
        @filtruAbonat varchar(13),@data_fact datetime,@data_sus datetime,@userASiS varchar(20),@tip char(2),@da_incerti bit,@nu_incerti bit
begin try
exec wIaUtilizator @sesiune, @utilizator output

select	@id_factura= isnull(@parXML.value('(/parametri/@id)[1]','int'),0),
		@factura= isnull(@parXML.value('(/parametri/@factura)[1]','varchar(13)'),''),
		@tip = isnull(@parXML.value('(/parametri/@tip)[1]','varchar(2)'),''),
		@da_incerti= isnull(@parXML.value('(/parametri/@da_incerti)[1]','bit'),0),
		@nu_incerti= isnull(@parXML.value('(/parametri/@nu_incerti)[1]','bit'),0)
		
		set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')

	if @da_incerti=1 and @nu_incerti=1
		begin
			set @mesaj='Numai una dintre cele 2 optiuni poate fi bifata!!'
			raiserror(@mesaj,11,1)
		end	
	if @da_incerti=0 and @nu_incerti=0	
		begin
			set @mesaj='Cel putin una dintre cele 2 optiuni trebuie sa fie bifata!!'
			raiserror(@mesaj,11,1)
		end		
	
	if @da_incerti=1
	    begin
			update AntetFactAbon set stare=1 where Id_factura=@id_factura  
			select 'Factura '+rtrim(@factura)+' a fost trecuta la incerti! ' as textMesaj, 'Finalizare operatie' as titluMesaj 
			for xml raw, root('Mesaje')
		end
		else
    if @nu_incerti=1
		begin
			update AntetFactAbon set stare=0 where Id_factura=@id_factura
			select 'Factura '+rtrim(@factura)+' a fost scoasa de la incerti! ' as textMesaj, 'Finalizare operatie' as titluMesaj 
			for xml raw, root('Mesaje')
		end	
		
    end try
begin catch
set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch	
end
