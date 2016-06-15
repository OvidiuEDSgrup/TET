--***
/* descriere... */
create procedure [dbo].[wUAOPScriuDetaliiFacturare](@sesiune varchar(50), @parXML xml) 
as     
begin
declare @utilizator varchar(8),@mesaj varchar(200),@id_factura int,@factura varchar(13),@id_contract int,
        @userASiS varchar(20),@tip char(2),@numele_delegatului varchar(30),@seria_buletin varchar(10),@numar_buletin varchar(10),
        @eliberat varchar(30),@mijloc_de_transport varchar(30),@numarul_mijlocului varchar(13),@data_expedierii datetime,
        @ora_expedierii varchar(6),@observatii varchar(200),@explicatii varchar(100)
        
begin try
exec wIaUtilizator @sesiune, @utilizator output

select	@id_factura= isnull(@parXML.value('(/parametri/@id)[1]','int'),0),
		@factura= isnull(@parXML.value('(/parametri/@factura)[1]','varchar(13)'),''),
		@tip = isnull(@parXML.value('(/parametri/@tip)[1]','varchar(2)'),''),
		@id_contract=isnull(@parXML.value('(/parametri/@id_contract)[1]','int'),0),
		
		@numele_delegatului= isnull(@parXML.value('(/parametri/@numele_delegatului)[1]','varchar(30)'),''),
		@seria_buletin= isnull(@parXML.value('(/parametri/@seria_buletin)[1]','varchar(10)'),''),
		@numar_buletin= isnull(@parXML.value('(/parametri/@numar_buletin)[1]','varchar(10)'),''),
		@eliberat= isnull(@parXML.value('(/parametri/@eliberat)[1]','varchar(30)'),''),
		@mijloc_de_transport= isnull(@parXML.value('(/parametri/@mijloc_de_transport)[1]','varchar(30)'),''),
		@numarul_mijlocului= isnull(@parXML.value('(/parametri/@numarul_mijlocului)[1]','varchar(13)'),''),
		@explicatii= isnull(@parXML.value('(/parametri/@explicatii)[1]','varchar(100)'),''),
		@observatii= isnull(@parXML.value('(/parametri/@observatii)[1]','varchar(200)'),''),
		@ora_expedierii= isnull(@parXML.value('(/parametri/@ora_expedierii)[1]','varchar(6)'),''),
		@data_expedierii= isnull(@parXML.value('(/parametri/@data_expedierii)[1]','datetime'),'')
		
		
		set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')    	
	
	delete uaanexafac where id_factura=@id_factura
	insert into uaanexafac 
	    select @id_factura,@numele_delegatului,@seria_buletin,@numar_buletin,@eliberat,@mijloc_de_transport,@numarul_mijlocului,
			   @data_expedierii,@ora_expedierii,@observatii,@explicatii
	
	select 'Detaliile pentru facturare au fost adaugate pe factura: '+rtrim(@factura) as textMesaj, 'Finalizare operatie' as titluMesaj 
		for xml raw, root('Mesaje')
				
    end try
begin catch
set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch	
end
--select * from  uaanexafac
