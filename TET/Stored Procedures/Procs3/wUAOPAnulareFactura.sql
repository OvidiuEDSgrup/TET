--***
/* descriere... */
create procedure [dbo].[wUAOPAnulareFactura](@sesiune varchar(50), @parXML xml) 
as     
begin
declare @utilizator varchar(8),@abonat_fact varchar(13),@docXML xml,@mesaj varchar(200),@id_factura int,@factura varchar(13),
        @filtruAbonat varchar(13),@data_fact datetime,@data_sus datetime,@userASiS varchar(20),@tip char(2)
begin try
exec wIaUtilizator @sesiune, @utilizator output

select	@id_factura= isnull(@parXML.value('(/parametri/@id)[1]','int'),0),
		@factura= isnull(@parXML.value('(/parametri/@factura)[1]','varchar(13)'),''),
		@tip = isnull(@parXML.value('(/parametri/@tip)[1]','varchar(2)'),'')
		--@data_fact= isnull(@parXML.value('(/parametri/@data)[1]','datetime'),0)
		
		set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')

    if @tip='AV'
    begin
    set @mesaj='Factura de avans poate fi anulata doar prin anularea chitantei cu care a fost incasata!!'
    raiserror(@mesaj,11,1)
    end	
    --select @id_factura ,@id_factura, '' ,'1901-01-01','2901-01-01',@userASiS,@utilizator
    
	exec UAAnulFact @id_factura ,@id_factura, '' ,'1901-01-01','2901-01-01',@userASiS,@utilizator

	IF (SELECT  COUNT(1) FROM FACTURI_NEANULATE where HostId=@utilizator) >0
	begin
	set @mesaj='Aceasta factura a fost incasata sau compensata, deci nu poate fi anulata!!'
	raiserror(@mesaj,11,1)
	end
	select 'Factura '+rtrim(@factura)+' a fost anulata cu succes! ' as textMesaj, 'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
	
	
    end try
begin catch
set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch	
end
--select * from facturi_neanulate
