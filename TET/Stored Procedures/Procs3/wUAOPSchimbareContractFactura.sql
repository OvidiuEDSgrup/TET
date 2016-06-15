--***
/* descriere... */
create procedure [dbo].[wUAOPSchimbareContractFactura](@sesiune varchar(50), @parXML xml) 
as     
begin
declare @utilizator varchar(8),@abonat_fact varchar(13),@docXML xml,@mesaj varchar(200),@id_factura int,@factura varchar(13),@id_contract int,
        @filtruAbonat varchar(13),@data_fact datetime,@data_sus datetime,@userASiS varchar(20),@tip char(2),@da_incerti bit,@nu_incerti bit
begin try
exec wIaUtilizator @sesiune, @utilizator output

select	@id_factura= isnull(@parXML.value('(/parametri/@id)[1]','int'),0),
		@factura= isnull(@parXML.value('(/parametri/@factura)[1]','varchar(13)'),''),
		@tip = isnull(@parXML.value('(/parametri/@tip)[1]','varchar(2)'),''),
		@id_contract=isnull(@parXML.value('(/parametri/@id_contract)[1]','int'),0)
		
		set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')    	
	
	if @id_contract<>0
	    begin
			update AntetFactAbon set Id_contract=@id_contract where Id_factura=@id_factura  
			select 'Contractul de pe factura '+rtrim(@factura)+' a fost modificat! ' as textMesaj, 'Finalizare operatie' as titluMesaj 
			for xml raw, root('Mesaje')
		end
	
		
    end try
begin catch
set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch	
end
